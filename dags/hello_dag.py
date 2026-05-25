"""hello_dag.py — minimal DAG to verify Airflow setup."""
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    "owner": "news-pipeline",
    "retries": 0,
}

with DAG(
    dag_id="hello_dag",
    default_args=default_args,
    description="Prints hello for testing",
    schedule_interval=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["test"],
) as dag:
    BashOperator(
        task_id="print_hello",
        bash_command='echo "hello"',
    )
