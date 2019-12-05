create sequence lote_seq;

create table lote (
  loteSeq int NOT NULL DEFAULT NEXTVAL ('lote_seq'),
  source varchar(500),
  file_size varchar(25),
  rows varchar(40),
  loteStartProcessTimestamp timestamp(0),
  loteEndProcessTimestamp timestamp(0),
  loteId varchar(40),
  CONSTRAINT loteid_unique UNIQUE (loteId),
  PRIMARY KEY (loteSeq)
);
-- -- -----------------------------------------------------
-- -- Schema mydb
-- -- -----------------------------------------------------
-- DROP SCHEMA IF EXISTS mydb ;
--
-- -- -----------------------------------------------------
-- -- Schema mydb
-- -- -----------------------------------------------------
-- CREATE SCHEMA IF NOT EXISTS mydb;

-- -----------------------------------------------------
-- Table `mydb`.`Ano`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Ano ;

CREATE TABLE IF NOT EXISTS /**/Ano (
  idAno INT NOT NULL,
  ano INT NULL,
  PRIMARY KEY (idAno))
;


-- -----------------------------------------------------
-- Table `mydb`.`Pais`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Pais ;

CREATE TABLE IF NOT EXISTS /**/Pais (
  idPais INT NOT NULL,
  pais VARCHAR(45) NULL,
  PRIMARY KEY (idPais))
;
-- -----------------------------------------------------
-- Table `mydb`.`Estado`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Estado ;

CREATE TABLE IF NOT EXISTS /**/Estado (
  idEstado INT NOT NULL,
  codEstado VARCHAR(45) NULL,
  estado VARCHAR(45) NULL,
  idPais INT NOT NULL,
  PRIMARY KEY (idEstado),
  CONSTRAINT fk_Estado_Pais1
    FOREIGN KEY (idPais)
    REFERENCES /**/Pais (idPais)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Estado_Pais1_idx ON /**/Estado (idPais ASC);


-- -----------------------------------------------------
-- Table `mydb`.`Regiao`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Regiao ;

CREATE TABLE IF NOT EXISTS /**/Regiao (
  idRegiao INT NOT NULL,
  codRegiao VARCHAR(45) NULL,
  idEstado INT NOT NULL,
  PRIMARY KEY (idRegiao),
  CONSTRAINT fk_Regiao_Estado1
    FOREIGN KEY (idEstado)
    REFERENCES /**/Estado (idEstado)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Regiao_Estado1_idx ON /**/Regiao (idEstado ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`Municipio`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Municipio ;

CREATE TABLE IF NOT EXISTS /**/Municipio (
  idMunicipio INT NOT NULL,
  municipio VARCHAR(45) NULL,
  codMunicipio VARCHAR(45) NULL,
  idRegiao INT NOT NULL,
  PRIMARY KEY (idMunicipio),
  CONSTRAINT fk_Municipio_Regiao1
    FOREIGN KEY (idRegiao)
    REFERENCES /**/Regiao (idRegiao)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Municipio_Regiao1_idx ON /**/Municipio (idRegiao ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`Bairro`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Bairro ;

CREATE TABLE IF NOT EXISTS /**/Bairro (
  idBairro INT NOT NULL,
  bairro VARCHAR(45) NULL,
  codBairro VARCHAR(45) NULL,
  idMunicipio INT NOT NULL,
  PRIMARY KEY (idBairro),
  CONSTRAINT fk_Bairro_Municipio1
    FOREIGN KEY (idMunicipio)
    REFERENCES /**/Municipio (idMunicipio)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Bairro_Municipio1_idx ON /**/Bairro (idMunicipio ASC)  ;


-- -----------------------------------------------------
-- Table `mydb`.`Endereco`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Endereco ;

CREATE TABLE IF NOT EXISTS /**/Endereco (
  idEndereco INT NOT NULL,
  logradouro VARCHAR(45) NULL,
  cep VARCHAR(45) NULL,
  codEndereco VARCHAR(45) NULL,
  idBairro INT NOT NULL,
  PRIMARY KEY (idEndereco),
  CONSTRAINT fk_Endereco_Bairro1
    FOREIGN KEY (idBairro)
    REFERENCES /**/Bairro (idBairro)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Endereco_Bairro1_idx ON /**/Endereco (idBairro ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`Localizacao`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Localizacao ;

CREATE TABLE IF NOT EXISTS /**/Localizacao (
  idLocalizacao INT NOT NULL,
  complemento VARCHAR(45) NULL,
  codDistrito INT NULL,
  numero VARCHAR(45) NULL,
  idEndereco INT NULL,
  PRIMARY KEY (idLocalizacao)
  -- CONSTRAINT fk_Localizacao_Endereco1
  --   FOREIGN KEY (idEndereco)
  --   REFERENCES /**/Endereco (idEndereco)
  --   ON DELETE NO ACTION
  --   ON UPDATE NO ACTION
  )
;

-- CREATE INDEX fk_Localizacao_Endereco1_idx ON /**/Localizacao (idEndereco ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`Estabelecimento`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Estabelecimento ;

CREATE TABLE IF NOT EXISTS /**/Estabelecimento (
  idEstabelecemento INT NOT NULL,
  cnes INT NULL,
  locEstab INT NOT NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idEstabelecemento),
  CONSTRAINT fk_Estabelecimento_Localizacao1
    FOREIGN KEY (locEstab)
    REFERENCES /**/Localizacao (idLocalizacao)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Estabelecimento_Localizacao1_idx ON /**/Estabelecimento (locEstab ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`CID_Versao`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/CID_Versao ;

CREATE TABLE IF NOT EXISTS /**/CID_Versao (
  idVersao INT NOT NULL,
  versao VARCHAR(45) NULL,
  PRIMARY KEY (idVersao))

;
-- -----------------------------------------------------
-- Table `mydb`.`CID_Capitulos`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/CID_Capitulos ;

CREATE TABLE IF NOT EXISTS /**/CID_Capitulos (
  idCapitulo VARCHAR(45) NOT NULL,
  capitulo VARCHAR(45) NULL,
  idVersao INT NOT NULL,
  PRIMARY KEY (idCapitulo),
  CONSTRAINT fk_CID_Capitulos_CID_Versao1
    FOREIGN KEY (idVersao)
    REFERENCES /**/CID_Versao (idVersao)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_CID_Capitulos_CID_Versao1_idx ON /**/CID_Capitulos (idVersao ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`CID_Grupos`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/CID_Grupos ;

CREATE TABLE IF NOT EXISTS /**/CID_Grupos (
  idGrupo INT NOT NULL,
  grupo VARCHAR(45) NULL,
  idCapitulo VARCHAR(45) NOT NULL,
  PRIMARY KEY (idGrupo),
  CONSTRAINT fk_CID_Grupos_CID_Capitulos1
    FOREIGN KEY (idCapitulo)
    REFERENCES /**/CID_Capitulos (idCapitulo)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_CID_Grupos_CID_Capitulos1_idx ON /**/CID_Grupos (idCapitulo ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`CID_Categorias`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/CID_Categorias ;

CREATE TABLE IF NOT EXISTS /**/CID_Categorias (
  idCategorias INT NOT NULL,
  categorias VARCHAR(45) NULL,
  idGrupo INT NOT NULL,
  PRIMARY KEY (idCategorias),
  CONSTRAINT fk_CID_Categorias_CID_Grupos1
    FOREIGN KEY (idGrupo)
    REFERENCES /**/CID_Grupos (idGrupo)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_CID_Categorias_CID_Grupos1_idx ON /**/CID_Categorias (idGrupo ASC)  ;


-- -----------------------------------------------------
-- Table `mydb`.`CID_Subcategorias`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/CID_Subcategorias ;

CREATE TABLE IF NOT EXISTS /**/CID_Subcategorias (
  idSubcategorias INT NOT NULL,
  subcategorias VARCHAR(45) NULL,
  idCategoria INT NOT NULL,
  PRIMARY KEY (idSubcategorias),
  CONSTRAINT fk_CID_Subcategorias_CID_Categorias1
    FOREIGN KEY (idCategoria)
    REFERENCES /**/CID_Categorias (idCategorias)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_CID_Subcategorias_CID_Categorias1_idx ON /**/CID_Subcategorias (idCategoria ASC)  ;


-- -----------------------------------------------------
-- Table `mydb`.`CID`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/CID ;

CREATE TABLE IF NOT EXISTS /**/CID (
  idCid INT NOT NULL,
  idSubCategoria INT NOT NULL,
  descricao VARCHAR(200) NULL,
  cid VARCHAR(45) NULL,
  PRIMARY KEY (idCid),
  CONSTRAINT fk_CID_CID_Subcategorias1
    FOREIGN KEY (idSubCategoria)
    REFERENCES /**/CID_Subcategorias (idSubcategorias)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_CID_CID_Subcategorias1_idx ON /**/CID (idSubCategoria ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`Mes`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Mes ;

CREATE TABLE IF NOT EXISTS /**/Mes (
  idMes INT NOT NULL,
  mes INT NOT NULL,
  idAno INT NOT NULL,
  PRIMARY KEY (idMes),
  CONSTRAINT fk_Mes_Ano1
    FOREIGN KEY (idAno)
    REFERENCES /**/Ano (idAno)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Mes_Ano1_idx ON /**/Mes (idAno ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`Dia`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Dia ;

CREATE TABLE IF NOT EXISTS /**/Dia (
  idDia INT NOT NULL,
  dia INT NOT NULL,
  idMes INT NOT NULL,
  PRIMARY KEY (idDia),
  CONSTRAINT fk_Dia_Mes1
    FOREIGN KEY (idMes)
    REFERENCES /**/Mes (idMes)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Dia_Mes1_idx ON /**/Dia (idMes ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`Data`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Data ;

CREATE TABLE IF NOT EXISTS /**/Data (
  idData INT NOT NULL,
  idDia INT NULL,
  data VARCHAR(45),
  PRIMARY KEY (idData),
  CONSTRAINT fk_Data_Dia1
    FOREIGN KEY (idDia)
    REFERENCES /**/Dia (idDia)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Data_Dia1_idx ON /**/Data (idDia ASC)  ;


-- -----------------------------------------------------
-- Table `mydb`.`Atendimento`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Atendimento ;

CREATE TABLE IF NOT EXISTS /**/Atendimento (
  idAtendimento INT NOT NULL,
  cidCAs VARCHAR(45) NULL,
  idEstabelecimento INT NOT NULL,
  dt INT NOT NULL,
  cidPri INT NOT NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idAtendimento),
  CONSTRAINT fk_Atendimento_Estabelecimento1
    FOREIGN KEY (idEstabelecimento)
    REFERENCES /**/Estabelecimento (idEstabelecemento)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Atendimento_Data1
    FOREIGN KEY (dt)
    REFERENCES /**/Data (idData)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Atendimento_CID1
    FOREIGN KEY (cidPri)
    REFERENCES /**/CID (idCid)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Atendimento_Estabelecimento1_idx ON /**/Atendimento (idEstabelecimento ASC)  ;

CREATE INDEX fk_Atendimento_Data1_idx ON /**/Atendimento (dt ASC)  ;

CREATE INDEX fk_Atendimento_CID1_idx ON /**/Atendimento (cidPri ASC)  ;




-- -----------------------------------------------------
-- Table `mydb`.`Carater_Internacao`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Carater_Internacao ;

CREATE TABLE IF NOT EXISTS /**/Carater_Internacao (
  idCarInternacao INT NOT NULL,
  carInternacao VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idCarInternacao))
;
-- -----------------------------------------------------
-- Table `mydb`.`Cesaria_Antes_Trabalho_Parto`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Cesaria_Antes_Trabalho_Parto ;

CREATE TABLE IF NOT EXISTS /**/Cesaria_Antes_Trabalho_Parto (
  idCesariaParto INT NOT NULL,
  cesariaParto VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idCesariaParto))
;
-- -----------------------------------------------------
-- Table `mydb`.`CID_Secundario`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/CID_Secundario ;

CREATE TABLE IF NOT EXISTS /**/CID_Secundario (
  idAtendimento INT NOT NULL,
  cidSec INT NOT NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idAtendimento, cidSec),
  CONSTRAINT fk_Atendimento_has_CID_Atendimento1
    FOREIGN KEY (idAtendimento)
    REFERENCES /**/Atendimento (idAtendimento)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Atendimento_has_CID_CID1
    FOREIGN KEY (cidSec)
    REFERENCES /**/CID (idCid)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Atendimento_has_CID_CID1_idx ON /**/CID_Secundario (cidSec ASC)  ;

CREATE INDEX fk_Atendimento_has_CID_Atendimento1_idx ON /**/CID_Secundario (idAtendimento ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`Escolaridade`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Escolaridade ;

CREATE TABLE IF NOT EXISTS /**/Escolaridade (
  idEscolaridade INT NOT NULL,
  escolaridade VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idEscolaridade))
;
-- -----------------------------------------------------
-- Table `mydb`.`Especialidade`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Especialidade ;

CREATE TABLE IF NOT EXISTS /**/Especialidade (
  idEspecialidade INT NOT NULL,
  especialidade VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idEspecialidade))
;

-- -----------------------------------------------------
-- Table `mydb`.`Pessoa`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Pessoa ;

CREATE TABLE IF NOT EXISTS /**/Pessoa (
  idPessoa INT NOT NULL,
  nome VARCHAR(200) NULL, /*siga, sim, sih, sia*/
  sexo VARCHAR(1) NULL, /*siga, sinasc, sim, sih, sia*/
  dataNasc INT NULL, /* siga, sinasc, sim, sih, sia */
  cns VARCHAR(200) NULL, /* siga, sinasc, sim, sih, sia */
  locResidencia INT NULL,
  locNascimento INT NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idPessoa),
  CONSTRAINT fk_Pessoa_Data1
    FOREIGN KEY (dataNasc)
    REFERENCES /**/Data (idData)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Pessoa_Localizacao1
    FOREIGN KEY (locResidencia)
    REFERENCES /**/Localizacao (idLocalizacao)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Pessoa_Localizacao2
    FOREIGN KEY (locNascimento)
    REFERENCES /**/Localizacao (idLocalizacao)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Pessoa_Data1_idx ON /**/Pessoa (dataNasc ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`Ocupacao`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Ocupacao ;

CREATE TABLE IF NOT EXISTS /**/Ocupacao (
  idOcupacao INT NOT NULL,
  ocupacao VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idOcupacao))
;
-- -----------------------------------------------------
-- Table `mydb`.`Tipo_Parto`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Tipo_Parto ;

CREATE TABLE IF NOT EXISTS /**/Tipo_Parto (
  idTipoParto INT NOT NULL,
  tipoParto VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idTipoParto))
;

-- -----------------------------------------------------
-- Table `mydb`.`Obito_na_Gravidez`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Obito_na_Gravidez ;

CREATE TABLE IF NOT EXISTS /**/Obito_na_Gravidez (
  idObitoGravidez INT NOT NULL,
  obitoGravidez VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idObitoGravidez))
;


-- -----------------------------------------------------
-- Table `mydb`.`Obito_no_Puerperio`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Obito_no_Puerperio ;

CREATE TABLE IF NOT EXISTS /**/Obito_no_Puerperio (
  idObitoPuerperio INT NOT NULL,
  obitoPuerperio VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idObitoPuerperio))
;


-- -----------------------------------------------------
-- Table `mydb`.`Obito_Parto`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Obito_Parto ;

CREATE TABLE IF NOT EXISTS /**/Obito_Parto (
  idObitoParto INT NOT NULL,
  quandoObito VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idObitoParto))
;



-- -----------------------------------------------------
-- Table `mydb`.`Procedimento`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Procedimento ;

CREATE TABLE IF NOT EXISTS /**/Procedimento (
  idProcedimento INT NOT NULL,
  procedimento VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idProcedimento))
;





-- -----------------------------------------------------
-- Table `mydb`.`Tipo_Apresentacao_RN`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Tipo_Apresentacao_RN ;

CREATE TABLE IF NOT EXISTS /**/Tipo_Apresentacao_RN (
  idTipoApresentacao INT NOT NULL,
  tipoApresentacao VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idTipoApresentacao))
;


-- -----------------------------------------------------
-- Table `mydb`.`Tipo_Obito`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Tipo_Obito ;

CREATE TABLE IF NOT EXISTS /**/Tipo_Obito (
  idTpObito INT NOT NULL,
  tipoObito VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idTpObito))
;




-- -----------------------------------------------------
-- Table `mydb`.`Trabalho_Parto_Induzido`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Trabalho_Parto_Induzido ;

CREATE TABLE IF NOT EXISTS /**/Trabalho_Parto_Induzido (
  idTrabalho INT NOT NULL,
  partoInduzido VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idTrabalho))
;


-- -----------------------------------------------------
-- Table `mydb`.`Nascimento_Assistido`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Nascimento_Assistido ;

CREATE TABLE IF NOT EXISTS /**/Nascimento_Assistido (
  idNascAssis INT NOT NULL,
  nascAssis VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idNascAssis))
;


-- -----------------------------------------------------
-- Table `mydb`.`Internacao`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Internacao ;

CREATE TABLE IF NOT EXISTS /**/Internacao (
  idInternacao INT NOT NULL,
  numAih INT NULL,
  numAihAnt INT NULL,
  numAihProx INT NULL,
  diarias INT NULL,
  motSaida VARCHAR(45) NULL,
  procedimentoQtd INT NULL,
  diariasUti INT NULL,
  diariasUi INT NULL,
  utineoMesesGestacao INT NULL,
  utineoMotSaida VARCHAR(45) NULL,
  idAtendimento INT NOT NULL,
  especialidade INT NOT NULL,
  carInternacao INT NOT NULL,
  dtInternacao INT NOT NULL,
  dtSaida INT NOT NULL,
  procRealizado INT NOT NULL,
  procedimento INT NOT NULL,
  procSolicitado INT NOT NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idInternacao),
  CONSTRAINT fk_Internacao_Atendimento1
    FOREIGN KEY (idAtendimento)
    REFERENCES /**/Atendimento (idAtendimento)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Internacao_Especialidade1
    FOREIGN KEY (especialidade)
    REFERENCES /**/Especialidade (idEspecialidade)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Internacao_Carater_Internacao1
    FOREIGN KEY (carInternacao)
    REFERENCES /**/Carater_Internacao (idCarInternacao)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Internacao_Data1
    FOREIGN KEY (dtInternacao)
    REFERENCES /**/Data (idData)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Internacao_Data2
    FOREIGN KEY (dtSaida)
    REFERENCES /**/Data (idData)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Internacao_Procedimento1
    FOREIGN KEY (procRealizado)
    REFERENCES /**/Procedimento (idProcedimento)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Internacao_Procedimento2
    FOREIGN KEY (procedimento)
    REFERENCES /**/Procedimento (idProcedimento)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Internacao_Procedimento3
    FOREIGN KEY (procSolicitado)
    REFERENCES /**/Procedimento (idProcedimento)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Internacao_Atendimento1_idx ON /**/Internacao (idAtendimento ASC)  ;

CREATE INDEX fk_Internacao_Especialidade1_idx ON /**/Internacao (especialidade ASC)  ;

CREATE INDEX fk_Internacao_Carater_Internacao1_idx ON /**/Internacao (carInternacao ASC)  ;

CREATE INDEX fk_Internacao_Data1_idx ON /**/Internacao (dtInternacao ASC)  ;

CREATE INDEX fk_Internacao_Data2_idx ON /**/Internacao (dtSaida ASC)  ;

CREATE INDEX fk_Internacao_Procedimento1_idx ON /**/Internacao (procRealizado ASC)  ;

CREATE INDEX fk_Internacao_Procedimento2_idx ON /**/Internacao (procedimento ASC)  ;

CREATE INDEX fk_Internacao_Procedimento3_idx ON /**/Internacao (procSolicitado ASC)  ;














-- -----------------------------------------------------
-- Table `mydb`.`Parto`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Parto ;

CREATE TABLE IF NOT EXISTS /**/Parto (
  idParto INT NOT NULL,
  idMae INT NULL,
  idPai INT NULL,
  idPessoa INT NULL,
  horaNasc VARCHAR(45) NULL,
  escolaridadeMae INT NULL,
  ocupacaoMae INT NULL,
  tpParto INT NULL,
  tpApresent INT NULL,
  trabPartIndu INT NULL,
  cesParto INT NULL,
  tpNascAssi INT NULL,
  tpRobson VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  internacao INT NULL,
  PRIMARY KEY (idParto),
  CONSTRAINT fk_Nascimento_Pessoa1
    FOREIGN KEY (idMae)
    REFERENCES /**/Pessoa (idPessoa)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Nascimento_Pessoa2
    FOREIGN KEY (idPai)
    REFERENCES /**/Pessoa (idPessoa)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Nascimento_Pessoa3
    FOREIGN KEY (idPessoa)
    REFERENCES /**/Pessoa (idPessoa)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Nascimento_Escolaridade1
    FOREIGN KEY (escolaridadeMae)
    REFERENCES /**/Escolaridade (idEscolaridade)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Parto_Ocupacao1
    FOREIGN KEY (ocupacaoMae)
    REFERENCES /**/Ocupacao (idOcupacao)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Parto_Tipo_Parto1
    FOREIGN KEY (tpParto)
    REFERENCES /**/Tipo_Parto (idTipoParto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Parto_Tipo_Apresentacao_RN1
    FOREIGN KEY (tpApresent)
    REFERENCES /**/Tipo_Apresentacao_RN (idTipoApresentacao)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Parto_Trabalho_Parto_Induzido1
    FOREIGN KEY (trabPartIndu)
    REFERENCES /**/Trabalho_Parto_Induzido (idTrabalho)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Parto_Cesaria_Antes_Trabalho_Parto1
    FOREIGN KEY (cesParto)
    REFERENCES /**/Cesaria_Antes_Trabalho_Parto (idCesariaParto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Parto_Nascimento_Assistido1
    FOREIGN KEY (tpNascAssi)
    REFERENCES /**/Nascimento_Assistido (idNascAssis)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Parto_Internacao1
    FOREIGN KEY (internacao)
    REFERENCES /**/Internacao (idInternacao)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Nascimento_Pessoa1_idx ON /**/Parto (idMae ASC)  ;

CREATE INDEX fk_Nascimento_Pessoa2_idx ON /**/Parto (idPai ASC)  ;

CREATE INDEX fk_Nascimento_Pessoa3_idx ON /**/Parto (idPessoa ASC)  ;

CREATE INDEX fk_Nascimento_Escolaridade1_idx ON /**/Parto (escolaridadeMae ASC)  ;

CREATE INDEX fk_Parto_Ocupacao1_idx ON /**/Parto (ocupacaoMae ASC)  ;

CREATE INDEX fk_Parto_Tipo_Parto1_idx ON /**/Parto (tpParto ASC)  ;

CREATE INDEX fk_Parto_Tipo_Apresentacao_RN1_idx ON /**/Parto (tpApresent ASC)  ;

CREATE INDEX fk_Parto_Trabalho_Parto_Induzido1_idx ON /**/Parto (trabPartIndu ASC)  ;

CREATE INDEX fk_Parto_Cesaria_Antes_Trabalho_Parto1_idx ON /**/Parto (cesParto ASC)  ;

CREATE INDEX fk_Parto_Nascimento_Assistido1_idx ON /**/Parto (tpNascAssi ASC)  ;

CREATE INDEX fk_Parto_Internacao1_idx ON /**/Parto (internacao ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`Gestacao`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Gestacao ;

CREATE TABLE IF NOT EXISTS /**/Gestacao (
  idGestacao INT NOT NULL,
  qtdFilhoMort INT NULL,
  semGestac INT NULL,
  dtUltiMenst INT NULL,
  mesPrenatal VARCHAR(45) NULL,
  qtdConsulta INT NULL,
  altoRisco VARCHAR(45) NULL,
  tpGravidez VARCHAR(45) NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  idMae INT NULL,
  idAtendimento INT NULL,
  idParto INT NULL,
  PRIMARY KEY (idGestacao),
  CONSTRAINT fk_Gestacao_Pessoa1
    FOREIGN KEY (idMae)
    REFERENCES /**/Pessoa (idPessoa)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  -- CONSTRAINT fk_Gestacao_Atendimento1
  --   FOREIGN KEY (idAtendimento)
  --   REFERENCES /**/Atendimento (idAtendimento)
  --   ON DELETE NO ACTION
  --   ON UPDATE NO ACTION,
  CONSTRAINT fk_Gestacao_Parto1
    FOREIGN KEY (idParto)
    REFERENCES /**/Parto (idParto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Gestacao_Pessoa1_idx ON /**/Gestacao (idMae ASC)  ;

-- CREATE INDEX fk_Gestacao_Atendimento1_idx ON /**/Gestacao (idAtendimento ASC)  ;

CREATE INDEX fk_Gestacao_Parto1_idx ON /**/Gestacao (idParto ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`NascidoVivo`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/NascidoVivo ;

CREATE TABLE IF NOT EXISTS /**/NascidoVivo (
  idNascidoVivo INT NOT NULL,
  numeroDn INT NULL,
  nomeRn VARCHAR(45) NULL,
  pesoRn DOUBLE PRECISION NULL,
  altoRisco VARCHAR(45) NULL,
  apgar1 INT NULL,
  apgar5 INT NULL,
  idParto INT NOT NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idNascidoVivo),
  CONSTRAINT fk_NascidoVivo_Parto1
    FOREIGN KEY (idParto)
    REFERENCES /**/Parto (idParto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_NascidoVivo_Parto1_idx ON /**/NascidoVivo (idParto ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`Obito`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Obito ;

CREATE TABLE IF NOT EXISTS /**/Obito (
  idObito INT NOT NULL, /* SIM */
  numeroDo INT NULL, /* SIM */
  causaBas VARCHAR(45) NULL, /* SIM */
  causaMorte VARCHAR(45) NULL, /* SIM */
  idPessoa INT NOT NULL,
  dtObito INT NOT NULL, /* SIM */
  horaObito VARCHAR(45) NULL, /* SIM */
  tpObito INT NOT NULL, /* SIM */
  obitoGrav INT NOT NULL, /* SIM */
  obitoPuerp INT NOT NULL, /* SIM */
  locOcor INT NOT NULL, /* SIM */
  obitoDurante INT NOT NULL, /* SIM */
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idObito),
  CONSTRAINT fk_Obito_Pessoa1
    FOREIGN KEY (idPessoa)
    REFERENCES /**/Pessoa (idPessoa)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Obito_Data1
    FOREIGN KEY (dtObito)
    REFERENCES /**/Data (idData)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Obito_Tipo_Obito1
    FOREIGN KEY (tpObito)
    REFERENCES /**/Tipo_Obito (idTpObito)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Obito_Obito_na_Gravidez1
    FOREIGN KEY (obitoGrav)
    REFERENCES /**/Obito_na_Gravidez (idObitoGravidez)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Obito_Obito_no_Puerperio1
    FOREIGN KEY (obitoPuerp)
    REFERENCES /**/Obito_no_Puerperio (idObitoPuerperio)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Obito_Localizacao1
    FOREIGN KEY (locOcor)
    REFERENCES /**/Localizacao (idLocalizacao)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Obito_Atendimento1
    FOREIGN KEY (obitoDurante)
    REFERENCES /**/Atendimento (idAtendimento)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Obito_Pessoa1_idx ON /**/Obito (idPessoa ASC)  ;

CREATE INDEX fk_Obito_Data1_idx ON /**/Obito (dtObito ASC)  ;

CREATE INDEX fk_Obito_Tipo_Obito1_idx ON /**/Obito (tpObito ASC)  ;

CREATE INDEX fk_Obito_Obito_na_Gravidez1_idx ON /**/Obito (obitoGrav ASC)  ;

CREATE INDEX fk_Obito_Obito_no_Puerperio1_idx ON /**/Obito (obitoPuerp ASC)  ;

CREATE INDEX fk_Obito_Localizacao1_idx ON /**/Obito (locOcor ASC)  ;

CREATE INDEX fk_Obito_Atendimento1_idx ON /**/Obito (obitoDurante ASC)  ;

-- -----------------------------------------------------
-- Table `mydb`.`Natimorto`
-- -----------------------------------------------------
DROP TABLE IF EXISTS /**/Natimorto ;

CREATE TABLE IF NOT EXISTS /**/Natimorto (
  idNatimorto INT NOT NULL,
  numeroDo INT NULL,
  altoRisco VARCHAR(45) NULL,
  obitoParto INT NOT NULL,
  idObito INT NOT NULL,
  idParto INT NOT NULL,
  dtRegistro TIMESTAMP(0) NULL,
  loteId VARCHAR(40),
  PRIMARY KEY (idNatimorto),
  CONSTRAINT fk_Natimorto_Obito_Parto1
    FOREIGN KEY (obitoParto)
    REFERENCES /**/Obito_Parto (idObitoParto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Natimorto_Obito1
    FOREIGN KEY (idObito)
    REFERENCES /**/Obito (idObito)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Natimorto_Parto1
    FOREIGN KEY (idParto)
    REFERENCES /**/Parto (idParto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
;

CREATE INDEX fk_Natimorto_Obito_Parto1_idx ON /**/Natimorto (obitoParto ASC)  ;

CREATE INDEX fk_Natimorto_Obito1_idx ON /**/Natimorto (idObito ASC)  ;

CREATE INDEX fk_Natimorto_Parto1_idx ON /**/Natimorto (idParto ASC)  ;
