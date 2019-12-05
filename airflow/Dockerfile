FROM puckel/docker-airflow:latest

COPY ./init.sh /
COPY config/airflow.cfg /usr/local/airflow/airflow.cfg
RUN mkdir /usr/local/airflow/dags/
RUN mkdir /usr/local/airflow/plugins/
RUN mkdir /usr/local/airflow/from/
RUN mkdir /usr/local/airflow/stagging/
RUN mkdir /usr/local/airflow/parsed/
COPY ./dags/* /usr/local/airflow/dags/
EXPOSE 8080
EXPOSE 5555

ENTRYPOINT ["/init.sh"]
