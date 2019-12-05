from airflow.contrib.sensors.file_sensor import FileSensor
from airflow.operators.python_operator   import PythonOperator
from airflow.operators.postgres_operator import PostgresOperator
from airflow.hooks.postgres_hook         import PostgresHook
from airflow.utils.trigger_rule import TriggerRule
from psycopg2.extras import execute_values
from datetime import datetime as dts
import datetime
import airflow
import glob
import pandas as pd
import inspect

receive_path = '/usr/local/airflow/from/'
parsed_path  = '/usr/local/airflow/parsed/'
default_args = {
    "start_date"      : airflow.utils.dates.days_ago(1),
    "retry_delay"     : datetime.timedelta(hours=5)
}

def retrieve_name(var):
    callers_local_vars = inspect.currentframe().f_back.f_locals.items()
    return [var_name for var_name, var_val in callers_local_vars if var_val is var]

def move_csv_to_stagging_area(**kwargs):
    import shutil
    import time
    import os
    filepath = kwargs['filepath']
    csv_list = glob.glob(filepath + '*.csv')
    ti = kwargs['ti']
    if csv_list == []:
        return None
    currently = csv_list.pop()
    file_name = currently.split("/").pop()
    destination = "/usr/local/airflow/stagging/" + file_name
    shutil.move(currently, destination)
    file_size = os.path.getsize(destination)
    if os.path.exists("/usr/local/airflow/from/.DS_Store"):
        os.remove("/usr/local/airflow/from/.DS_Store")
    ti.xcom_push(key='currently_processing', value=destination)
    ti.xcom_push(key='source', value=currently)
    ti.xcom_push(key='file_size', value=file_size)
    return destination

def generate_unique_lote_id(**kwargs):
    import random
    ti = kwargs['ti']
    lote_id = random.getrandbits(32)
    ti.xcom_push(key='lote_id', value=lote_id)
    return lote_id

def set_base_table(**kwargs):
    import random
    ti = kwargs['ti']
    file      = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='currently_processing')

    header = tuple(pd.read_csv(file, sep=';', nrows=1).columns)
    header = header + ('loteid',)
    strfy_header = '(' + ','.join(str(s) for s in header) + ')'
    strfy_header = strfy_header.lower()
    query_tables = """ SELECT table_name FROM information_schema.tables WHERE table_schema='public';"""
    dest_conn = PostgresHook(postgres_conn_id='etl_stage_extract').get_conn()
    dest_cursor = dest_conn.cursor()
    dest_cursor.execute(query_tables)
    tables = dest_cursor.fetchmany(size=100)
    for table_tuple in tables:
        table_name = table_tuple[0]
        query_header = """ select column_name from information_schema.columns where table_name = '{}';""".format(table_name)
        dest_cursor.execute(query_header)
        headers = dest_cursor.fetchmany(size=1000)
        hd = '(' + ','.join(str(s[0]).lower() for s in headers) + ')'
        if hd == strfy_header:
            ti.xcom_push(key='table', value=table_name)
            break
    return tables

def set_lote_id_begin(dest_cursor, lote_id, source, file_size):
    dt = dts.now()
    values = """('{}', '{}', NULL, '{}', NULL, '{}')""".format(source, file_size, dt, lote_id)
    query = """INSERT INTO lote (source, file_size, rows, loteStartProcessTimestamp, loteEndProcessTimestamp, loteId)
        VALUES {} ON CONFLICT (loteId) DO UPDATE
        SET loteStartProcessTimestamp = '{}', source = '{}', file_size ='{}';""".format(values, dt, source, file_size)
    dest_cursor.execute(query)
    return lote_id

def set_lote_id_end(dest_cursor, lote_id, rows, source, file_size):
    dt = dts.now()
    values = """('{}', '{}', '{}', NULL, '{}', '{}')""".format(source, file_size, rows, dt, lote_id)
    query = """INSERT INTO lote (source, file_size, rows, loteStartProcessTimestamp, loteEndProcessTimestamp, loteId)
        VALUES {} ON CONFLICT (loteId) DO UPDATE
        SET loteEndProcessTimestamp = '{}', rows = '{}', source = '{}', file_size ='{}';""".format(values, dt, rows, source, file_size)
    dest_cursor.execute(query)
    return lote_id

def load_csv_extract_db(**kwargs):
    ti = kwargs['ti']
    file      = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='currently_processing')
    lote_id   = ti.xcom_pull(task_ids='generate_unique_lote_id', key='lote_id')
    source    = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='source')
    file_size = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='file_size')
    table     = ti.xcom_pull(task_ids='set_base_table', key='table')

    dest_conn = PostgresHook(postgres_conn_id='etl_stage_extract').get_conn()
    dest_cursor = dest_conn.cursor()

    header = tuple(pd.read_csv(file, sep=';', nrows=1).columns)
    header = header + ('loteid',)
    strfy_header = '(' + ','.join(str(s) for s in header) + ')'
    count = 0
    set_lote_id_begin(dest_cursor, lote_id, source, file_size)
    for df_row in pd.read_csv(file, sep=';', chunksize=1):
        row = [tuple(x) for x in df_row.values]
        row = row[0]
        row = row + (lote_id, )
        strfy_row = '(' + ','.join('\'' + str(s) + '\'' for s in row) + ')'

        query = """INSERT INTO {} {} VALUES {};""".format(table, strfy_header, strfy_row)
        dest_cursor.execute(query)
        count += 1
        if count >= 100:
            break
    set_lote_id_end(dest_cursor, lote_id, count, source, file_size)
    dest_conn.commit()
    dest_cursor.close()
    dest_conn.close()
    return True

def delete_parsed_csv(**kwargs):
    import os
    ti = kwargs['ti']
    filepath = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='currently_processing')
    os.remove(filepath)
    filepath = None
    ti.xcom_push(key='currently_processing', value=filepath)
    return True

def cleaning(records):
    t_record = list(records[0])
    for id, item in enumerate(t_record):
        if item == 'nan':
            t_record[id] = 'NULL'
        else:
            t_record[id] = " ".join(item.split())

    records = []
    records.append(tuple(t_record))
    return records

def move_extract_to_clean(**kwargs):
    ti = kwargs['ti']
    file      = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='currently_processing')
    lote_id   = ti.xcom_pull(task_ids='generate_unique_lote_id', key='lote_id')
    source    = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='source')
    file_size = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='file_size')
    table     = ti.xcom_pull(task_ids='set_base_table', key='table')
    query = """SELECT * FROM {} WHERE loteId = '{}';""".format(table, lote_id)

    src_conn = PostgresHook(postgres_conn_id='etl_stage_extract').get_conn()
    dest_conn = PostgresHook(postgres_conn_id='etl_stage_clean').get_conn()

    src_cursor = src_conn.cursor()
    dest_cursor = dest_conn.cursor()

    src_cursor.execute(query)
    count = 0
    set_lote_id_begin(dest_cursor, lote_id, source, file_size)
    while True:
        records = src_cursor.fetchmany(size=1)
        if not records:
            break
        clean_records = cleaning(records)


        query_insert = """INSERT INTO {} VALUES %s""".format(table)
        execute_values(dest_cursor, query_insert, clean_records)
        dest_conn.commit()
        count += 1
    set_lote_id_end(dest_cursor, lote_id, count, source, file_size)
    dest_conn.commit()
    src_cursor.close()
    dest_cursor.close()
    src_conn.close()
    dest_conn.close()
    return True

def clear_extract_db(**kwargs):
    ti = kwargs['ti']
    file      = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='currently_processing')
    lote_id   = ti.xcom_pull(task_ids='generate_unique_lote_id', key='lote_id')
    source    = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='source')
    file_size = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='file_size')
    table     = ti.xcom_pull(task_ids='set_base_table', key='table')
    query = """DELETE FROM {};""".format(table)
    dest_conn = PostgresHook(postgres_conn_id='etl_stage_extract').get_conn()
    dest_cursor = dest_conn.cursor()
    dest_cursor.execute(query)
    dest_conn.commit()
    dest_conn.close()
    return True

def move_clean_to_conform(**kwargs):
    ti = kwargs['ti']
    file      = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='currently_processing')
    lote_id   = ti.xcom_pull(task_ids='generate_unique_lote_id', key='lote_id')
    source    = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='source')
    file_size = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='file_size')
    table     = ti.xcom_pull(task_ids='set_base_table', key='table')
    query = """SELECT * FROM {} WHERE loteId = '{}';""".format(table, lote_id)

    src_conn = PostgresHook(postgres_conn_id='etl_stage_clean').get_conn()
    dest_conn = PostgresHook(postgres_conn_id='etl_stage_conform').get_conn()

    src_cursor = src_conn.cursor()
    dest_cursor = dest_conn.cursor()

    src_cursor.execute(query)
    count = 0
    set_lote_id_begin(dest_cursor, lote_id, source, file_size)
    while True:
        records = src_cursor.fetchmany(size=1)
        if not records:
            break
        query_insert = """INSERT INTO {} VALUES %s""".format(table)
        execute_values(dest_cursor, query_insert, records)
        dest_conn.commit()
        count += 1
    set_lote_id_end(dest_cursor, lote_id, count, source, file_size)
    dest_conn.commit()
    src_cursor.close()
    dest_cursor.close()
    src_conn.close()
    dest_conn.close()
    return True

def clear_clean_db(**kwargs):
    ti = kwargs['ti']
    file      = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='currently_processing')
    lote_id   = ti.xcom_pull(task_ids='generate_unique_lote_id', key='lote_id')
    source    = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='source')
    file_size = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='file_size')
    table     = ti.xcom_pull(task_ids='set_base_table', key='table')
    query = """DELETE FROM {};""".format(table)
    dest_conn = PostgresHook(postgres_conn_id='etl_stage_clean').get_conn()
    dest_cursor = dest_conn.cursor()
    dest_cursor.execute(query)
    dest_conn.commit()
    dest_conn.close()
    return True

def get_values_from_headers(headers, record, selected_headers):
    head_rec = {}
    ret = []
    for index, colum in enumerate(headers):
        head_rec[colum] = record[index]
    for i in selected_headers:
        if i.lower() in head_rec:

            ret.append(head_rec[i.lower()])
    return tuple(ret)

def get_next_id_from_table(table, dest_cursor):
    query_column = """ select column_name from information_schema.key_column_usage WHERE TABLE_NAME = '{}'; """.format(table.lower())
    dest_cursor.execute(query_column)
    id_column = dest_cursor.fetchmany(size=1)


    query_last_id = """ SELECT {} FROM {} ORDER BY 1 DESC LIMIT 1""".format(id_column[0][0], table.lower())

    dest_cursor.execute(query_last_id)
    last_id = dest_cursor.fetchmany(size=1)

    if len(last_id) == 0:
        return 1
    return int(last_id[0][0])+1

def extract_ano(data):
    return int(data.split('/').pop())

def extract_mes(data):
    return int(data.split('/')[1])

def extract_dia(data):
    return int(data.split('/')[0])

def add_location(location, dest_cursor):
    idLocalizacao = get_next_id_from_table('Localizacao', dest_cursor)
    query_insert = """INSERT INTO Localizacao (idLocalizacao) VALUES %s"""
    value = [(idLocalizacao,)]
    execute_values(dest_cursor, query_insert, value)
    return idLocalizacao

def add_data(data, dest_cursor):
    if data == 'NULL':
        idData = get_next_id_from_table('Data', dest_cursor)
        query_insert = """INSERT INTO Data (idData, data) VALUES %s"""
        value = [(idData, data)]
        execute_values(dest_cursor, query_insert, value)
        return idData

    idAno = get_next_id_from_table('Ano', dest_cursor)
    ano = extract_ano(data)
    query_insert = """INSERT INTO Ano (idAno, ano) VALUES %s"""
    value = [(idAno, ano)]
    execute_values(dest_cursor, query_insert, value)

    idMes = get_next_id_from_table('Mes', dest_cursor)
    mes = extract_mes(data)
    query_insert = """INSERT INTO Mes (idMes, mes, idAno) VALUES %s"""
    value = [(idMes, mes, idAno)]
    execute_values(dest_cursor, query_insert, value)

    idDia = get_next_id_from_table('Dia', dest_cursor)
    dia = extract_dia(data)
    query_insert = """INSERT INTO Dia (idDia, dia, idMes) VALUES %s"""
    value = [(idDia, dia, idMes)]
    execute_values(dest_cursor, query_insert, value)

    idData = get_next_id_from_table('Data', dest_cursor)
    query_insert = """INSERT INTO Data (idData, idDia, data) VALUES %s"""
    value = [(idData, idDia, data)]
    execute_values(dest_cursor, query_insert, value)

    return idData

def add_pessoa_mae(dest_cursor, table, record, headers):
    idPessoa = get_next_id_from_table('Pessoa', dest_cursor)
    nome = get_values_from_headers(headers, record, ['NO_MAE_HASH'])[0]
    sexo = 'F'
    dataNasc = add_data(get_values_from_headers(headers, record, ['DT_NASCIMENTO_MAE'])[0], dest_cursor)
    cns = get_values_from_headers(headers, record, ['CO_SEQ_DN'])[0]
    locResidencia = add_location('', dest_cursor)
    locNascimento = add_location('', dest_cursor)
    loteid = get_values_from_headers(headers, record, ['loteid'])[0]

    value = [(idPessoa, nome, sexo, dataNasc, cns, locResidencia, locNascimento, loteid)]
    query_insert = """INSERT INTO Pessoa (idPessoa, nome, sexo, dataNasc, cns, locResidencia, locNascimento, loteid) VALUES %s"""
    execute_values(dest_cursor, query_insert, value)

    return idPessoa

def add_pessoa_bebe(dest_cursor, table, record, headers):
    idPessoa = get_next_id_from_table('Pessoa', dest_cursor)
    sexo = get_values_from_headers(headers, record, ['SG_SEXO'])[0]
    dataNasc = add_data(get_values_from_headers(headers, record, ['DT_NASCIMENTO'])[0], dest_cursor)
    locResidencia = add_location('', dest_cursor)
    locNascimento = add_location('', dest_cursor)
    loteid = get_values_from_headers(headers, record, ['loteid'])[0]

    value = [(idPessoa, sexo, dataNasc, locResidencia, locNascimento, loteid)]
    query_insert = """INSERT INTO Pessoa (idPessoa, sexo, dataNasc, locResidencia, locNascimento, loteid) VALUES %s"""
    execute_values(dest_cursor, query_insert, value)

def add_escolaridade(headers, record, dest_cursor):
    idEscolaridade = get_next_id_from_table('Escolaridade', dest_cursor)
    escolaridade = get_values_from_headers(headers, record, ['TP_ESCOLARIDADE'])[0]
    loteid = get_values_from_headers(headers, record, ['loteid'])[0]

    value = [(idEscolaridade, escolaridade, loteid)]
    query_insert = """INSERT INTO Escolaridade (idEscolaridade, escolaridade, loteid) VALUES %s"""
    execute_values(dest_cursor, query_insert, value)

    return idEscolaridade

def add_ocupacao(headers, record, dest_cursor):
    idOcupacao = get_next_id_from_table('Ocupacao', dest_cursor)
    ocupacao = get_values_from_headers(headers, record, ['CO_OCUPACAO'])[0]
    loteid = get_values_from_headers(headers, record, ['loteid'])[0]

    value = [(idOcupacao, ocupacao, loteid)]
    query_insert = """INSERT INTO Ocupacao (idOcupacao, ocupacao, loteid) VALUES %s"""
    execute_values(dest_cursor, query_insert, value)

    return idOcupacao

def add_tp_parto(headers, record, dest_cursor):
    idTipoParto = get_next_id_from_table('Tipo_Parto', dest_cursor)
    tipoParto = get_values_from_headers(headers, record, ['CO_OCUPACAO'])[0]

    value = [(idTipoParto, tipoParto)]
    query_insert = """INSERT INTO Tipo_Parto (idTipoParto, tipoParto) VALUES %s"""
    execute_values(dest_cursor, query_insert, value)

    return idTipoParto

def add_tp_apresentacao(headers, record, dest_cursor):
    idTipoApresentacao = get_next_id_from_table('Tipo_Apresentacao_RN', dest_cursor)
    tipoApresentacao = get_values_from_headers(headers, record, ['TP_APRESENTACAO'])[0]

    value = [(idTipoApresentacao, tipoApresentacao)]
    query_insert = """INSERT INTO Tipo_Apresentacao_RN (idTipoApresentacao, tipoApresentacao) VALUES %s"""
    execute_values(dest_cursor, query_insert, value)

    return idTipoApresentacao

def add_trab_part_indu(headers, record, dest_cursor):
    idTrabalho = get_next_id_from_table('Trabalho_Parto_Induzido', dest_cursor)
    partoInduzido = get_values_from_headers(headers, record, ['ST_TRABALHO_PARTO'])[0]

    value = [(idTrabalho, partoInduzido)]
    query_insert = """INSERT INTO Trabalho_Parto_Induzido (idTrabalho, partoInduzido) VALUES %s"""
    execute_values(dest_cursor, query_insert, value)

    return idTrabalho

def add_ces_parto(headers, record, dest_cursor):
    idCesariaParto = get_next_id_from_table('Cesaria_Antes_Trabalho_Parto', dest_cursor)
    cesariaParto = get_values_from_headers(headers, record, ['ST_CESAREA_PARTO'])[0]

    value = [(idCesariaParto, cesariaParto)]
    query_insert = """INSERT INTO Cesaria_Antes_Trabalho_Parto (idCesariaParto, cesariaParto) VALUES %s"""
    execute_values(dest_cursor, query_insert, value)

    return idCesariaParto

def add_tp_nasc_assi(headers, record, dest_cursor):
    idNascAssis = get_next_id_from_table('Nascimento_Assistido', dest_cursor)
    nascAssis = get_values_from_headers(headers, record, ['TP_NASCIMENTO_ASSISTIDO'])[0]

    value = [(idNascAssis, nascAssis)]
    query_insert = """INSERT INTO Nascimento_Assistido (idNascAssis, nascAssis) VALUES %s"""
    execute_values(dest_cursor, query_insert, value)

    return idNascAssis

def add_parto(dest_cursor, table, record, headers, id_mae, id_pessoa):
    idParto = get_next_id_from_table('Parto', dest_cursor)
    idMae = id_mae
    idPessoa = id_pessoa
    horaNasc = get_values_from_headers(headers, record, ['HR_NASCIMENTO'])[0]
    escolaridadeMae = add_escolaridade(headers, record, dest_cursor)
    ocupacaoMae = add_ocupacao(headers, record, dest_cursor)
    tpParto = add_tp_parto(headers, record, dest_cursor)
    tpApresent = add_tp_apresentacao(headers, record, dest_cursor)
    trabPartIndu = add_trab_part_indu(headers, record, dest_cursor)
    cesParto = add_ces_parto(headers, record, dest_cursor)
    tpNascAssi = add_tp_nasc_assi(headers, record, dest_cursor)
    tpRobson = get_values_from_headers(headers, record, ['TP_GRUPO_ROBSON'])[0]
    loteid = get_values_from_headers(headers, record, ['loteid'])[0]

    value = [(idParto, idMae, idPessoa, horaNasc,
        escolaridadeMae ,ocupacaoMae, tpParto ,tpApresent, trabPartIndu, cesParto,
        tpNascAssi, tpRobson, loteid)]
    query_insert = """INSERT INTO Parto (idParto, idMae, idPessoa, horaNasc,
        escolaridadeMae ,ocupacaoMae, tpParto ,tpApresent, trabPartIndu, cesParto,
        tpNascAssi, tpRobson, loteid) VALUES %s"""
    execute_values(dest_cursor, query_insert, value)
    return idParto

def add_gestacao(dest_cursor, table, record, headers, idMae, idParto):
    idGestacao = get_next_id_from_table('Gestacao', dest_cursor)
    qtdFilhoMort = get_values_from_headers(headers, record, ['QT_NASCIDOS_MORTOS'])[0]
    semGestac = get_values_from_headers(headers, record, ['NU_SEMANA_GESTACAO'])[0]
    dtUltiMenst = add_data(get_values_from_headers(headers, record, ['DT_ULTIMA_MENSTRUACAO'])[0], dest_cursor)
    mesPrenatal = get_values_from_headers(headers, record, ['NU_MES_GESTACAO_PRENATAL'])[0]
    qtdConsulta = get_values_from_headers(headers, record, ['NU_CONSULTA_PRENATAL'])[0]
    tpGravidez = get_values_from_headers(headers, record, ['TP_GRAVIDEZ'])[0]
    loteid = get_values_from_headers(headers, record, ['loteid'])[0]

    all_colums = {
        'idGestacao': idGestacao,
        'qtdFilhoMort': qtdFilhoMort,
        'semGestac': semGestac,
        'dtUltiMenst': dtUltiMenst,
        'mesPrenatal': mesPrenatal,
        'qtdConsulta': qtdConsulta,
        'tpGravidez': tpGravidez,
        'loteid': loteid,
        'idMae': idMae,
        'idParto': idParto
    }
    not_null = []
    string_not_null = []
    for item in all_colums:
        val = all_colums[item]
        if val != 'NULL':
            string_not_null.append(item)
            not_null.append(val)

    query = '(' + ', '.join(string_not_null) + ')'
    query_insert = """INSERT INTO Gestacao {} VALUES %s""".format(query)
    execute_values(dest_cursor, query_insert, [tuple(not_null)])
    return idGestacao

def insert_final_table(dest_cursor, table, records, headers):
    if table == 'sinasc':
        id_mae = add_pessoa_mae(dest_cursor, table, records[0], headers)
        id_bebe = add_pessoa_bebe(dest_cursor, table, records[0], headers)
        id_parto = add_parto(dest_cursor, table, records[0], headers, id_mae, id_bebe)
        id_gestacao = add_gestacao(dest_cursor, table, records[0], headers, id_mae, id_parto)
    elif table == 'sim':
        pass
    else:
        return

def move_conform_to_final(**kwargs):
    ti = kwargs['ti']
    file      = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='currently_processing')
    lote_id   = ti.xcom_pull(task_ids='generate_unique_lote_id', key='lote_id')
    source    = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='source')
    file_size = ti.xcom_pull(task_ids='move_csv_to_stagging_area', key='file_size')
    table     = ti.xcom_pull(task_ids='set_base_table', key='table')
    query = """SELECT * FROM {} WHERE loteId = '{}';""".format(table, lote_id)

    src_conn = PostgresHook(postgres_conn_id='etl_stage_conform').get_conn()
    dest_conn = PostgresHook(postgres_conn_id='etl_stage_final').get_conn()

    src_cursor = src_conn.cursor()
    dest_cursor = dest_conn.cursor()

    query_header = """ select column_name from information_schema.columns where table_name = '{}';""".format(table)
    src_cursor.execute(query_header)
    headers_result = src_cursor.fetchmany(size=1000)
    headers = [str(s[0]).lower() for s in headers_result]

    src_cursor.execute(query)
    count = 0
    set_lote_id_begin(dest_cursor, lote_id, source, file_size)
    while True:
        records = src_cursor.fetchmany(size=1)
        if not records:
            break
        insert_final_table(dest_cursor, table, records, headers)
        count += 1
    set_lote_id_end(dest_cursor, lote_id, count, source, file_size)
    dest_conn.commit()
    src_cursor.close()
    dest_cursor.close()
    src_conn.close()
    dest_conn.close()
    return True

with airflow.DAG("ETL.PROCESS", default_args=default_args, schedule_interval="0 * * * *", max_active_runs=2) as dag:
    is_new_csv = FileSensor(
        task_id="is_new_csv",
        poke_interval=30,
        filepath=receive_path
    )
    move_csv_to_stagging_area = PythonOperator(
        task_id='move_csv_to_stagging_area',
        python_callable=move_csv_to_stagging_area,
        provide_context=True,
        op_kwargs={ 'filepath': receive_path },
        trigger_rule='all_success',
        depends_on_past=True
    )
    generate_unique_lote_id = PythonOperator(
        task_id='generate_unique_lote_id',
        python_callable=generate_unique_lote_id,
        provide_context=True,
        op_kwargs={ 'filepath': receive_path },
        trigger_rule='all_success',
        depends_on_past=True
    )
    set_base_table = PythonOperator(
        task_id='set_base_table',
        python_callable=set_base_table,
        provide_context=True,
        op_kwargs={ 'filepath': receive_path },
        trigger_rule='all_success',
        depends_on_past=True
    )
    load_csv_extract_db = PythonOperator (
        task_id='load_csv_extract_db',
        python_callable=load_csv_extract_db,
        provide_context=True,
        op_kwargs={ 'parsed_path': parsed_path },
        trigger_rule='all_success',
        depends_on_past=True
    )
    delete_parsed_csv = PythonOperator (
        task_id='delete_parsed_csv',
        python_callable=delete_parsed_csv,
        provide_context=True,
        op_kwargs={ 'filepath': receive_path },
        trigger_rule='all_success',
        depends_on_past=True
    )
    move_extract_to_clean = PythonOperator (
        task_id='move_extract_to_clean',
        python_callable=move_extract_to_clean,
        provide_context=True,
        op_kwargs={ 'parsed_path': parsed_path },
        trigger_rule='all_success',
        depends_on_past=True
    )
    clear_extract_db = PythonOperator (
        task_id='clear_extract_db',
        python_callable=clear_extract_db,
        provide_context=True,
        op_kwargs={ 'parsed_path': parsed_path },
        trigger_rule='all_success',
        depends_on_past=True
    )
    move_clean_to_conform = PythonOperator (
        task_id='move_clean_to_conform',
        python_callable=move_clean_to_conform,
        provide_context=True,
        op_kwargs={ 'parsed_path': parsed_path },
        trigger_rule='all_success',
        depends_on_past=True
    )
    clear_clean_db = PythonOperator (
        task_id='clear_clean_db',
        python_callable=clear_clean_db,
        provide_context=True,
        op_kwargs={ 'parsed_path': parsed_path },
        trigger_rule='all_success',
        depends_on_past=True
    )
    move_conform_to_final = PythonOperator (
        task_id='move_conform_to_final',
        python_callable=move_conform_to_final,
        provide_context=True,
        op_kwargs={ 'parsed_path': parsed_path },
        trigger_rule='all_success',
        depends_on_past=True
    )

is_new_csv > move_csv_to_stagging_area > generate_unique_lote_id > \
    load_csv_extract_db > delete_parsed_csv > move_extract_to_clean > \
    clear_extract_db > move_clean_to_conform > clear_clean_db > move_conform_to_final
