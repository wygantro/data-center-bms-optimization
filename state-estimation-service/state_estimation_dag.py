# dags/state_estimator_dag.py

from datetime import datetime, timedelta
import logging
import requests

from airflow import DAG
from airflow.operators.python import PythonOperator

STATE_ESTIMATOR_URL = "http://state-estimator-service:8000/estimate"

default_args = {
    "owner": "rl-platform",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=2),
}

def call_state_estimator(**context):
    payload = {
        "run_id": context["run_id"],
        "logical_date": context["logical_date"].isoformat(),
        "source": "airflow",
        "estimation_type": "state_prediction",
        "horizon_minutes": 10,
    }

    response = requests.post(
        STATE_ESTIMATOR_URL,
        json=payload,
        timeout=30,
    )

    response.raise_for_status()

    result = response.json()

    required_fields = ["estimated_state", "confidence", "timestamp"]
    missing = [field for field in required_fields if field not in result]

    if missing:
        raise ValueError(f"State estimator response missing fields: {missing}")

    logging.info("State estimate received: %s", result)

    return result

with DAG(
    dag_id="rl_state_estimator_every_10_minutes",
    description="Calls RL state estimator service every 10 minutes",
    default_args=default_args,
    schedule="*/10 * * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["reinforcement-learning", "state-estimation", "ml"],
) as dag:

    estimate_state = PythonOperator(
        task_id="call_state_estimator",
        python_callable=call_state_estimator,
    )