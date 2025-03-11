FROM apache/airflow:2.10.5 as builder

ADD requirements.txt .
RUN pip install apache-airflow==2.10.5 -r requirements.txt
