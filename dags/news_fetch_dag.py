"""
news_fetch_dag.py — every 10 minutes, run producer to push news to Kafka.
"""
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    "owner": "news-pipeline",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=3),
    "email_on_failure": False,
}

with DAG(
    dag_id="news_fetch_dag",
    default_args=default_args,
    description="Fetch NewsAPI and publish to Kafka",
    schedule_interval="*/10 * * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["news", "kafka"],
) as dag:
    BashOperator(
        task_id="run_producer",
        bash_command="python /opt/airflow/producer/producer.py",
    )
