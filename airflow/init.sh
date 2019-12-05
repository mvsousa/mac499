#!/usr/bin/env bash
airflow initdb

export FERNET_KEY=$(python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)")
airflow connections -a --conn_id fs_default --conn_type fs
airflow connections -a --conn_id etl_ftp --conn_type ftp --conn_host ftp_server --conn_port 21 --conn_login admin --conn_password admin
airflow connections -a --conn_id etl_stage_extract --conn_type postgres --conn_host 1_extract --conn_port 5432 --conn_login postgres
airflow connections -a --conn_id etl_stage_clean --conn_type postgres --conn_host 2_clean --conn_port 5432 --conn_login postgres
airflow connections -a --conn_id etl_stage_conform --conn_type postgres --conn_host 3_conform --conn_port 5432 --conn_login postgres
airflow connections -a --conn_id etl_stage_final --conn_type postgres --conn_host 4_final --conn_port 5432 --conn_login postgres
airflow scheduler &
airflow webserver
