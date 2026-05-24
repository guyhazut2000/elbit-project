# Phase 3: Apache Airflow

## What and Why

**Airflow** orchestrates workflows as code. You define a **DAG** (Directed Acyclic Graph): tasks and dependencies. A **scheduler** runs tasks on a **schedule_interval** (like cron: `*/10 * * * *` = every 10 minutes).

**Analogy:** A smart cron job with a **control panel**. Classic cron runs a script and emails you if it fails; Airflow shows history, retries, logs per task, and lets you pause the whole pipeline from a UI.

**Why for this project:** You want news fetched **every 10 minutes automatically**, not only when you remember to run `producer.py`.

### Key concepts

| Term | Meaning |
|------|---------|
| **DAG** | Workflow definition (Python file in `dags/`) |
| **Task** | One step (operator instance) |
| **Operator** | Template for work (`BashOperator`, `PythonOperator`, …) |
| **schedule_interval** | When the DAG runs (`timedelta`, cron, or `@daily`) |
| **XCom** | Small data passed between tasks (optional) |

---

## Task 1 ✅ — Access Airflow UI

**Explanation:** Web UI at port 8080 (from docker-compose).

**Code/command:**

1. Ensure stack is up: `docker compose up -d`
2. Open browser: http://localhost:8080
3. Login: username `admin`, password `admin`

**Expected result:** Airflow home page with DAGs list (may be empty).

### Checkpoint

You see **DAGs** menu and no login errors.

---

## Task 2 ✅ — Understand DAG file structure

**Explanation:** Airflow scans `dags/*.py` and imports objects that define a `DAG`.

**Code/command:** Read this annotated template (do not run yet as final DAG):

```python
# dags/example_structure.py — LEARNING TEMPLATE ONLY
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

# Default args applied to all tasks in the DAG
default_args = {
    "owner": "news-pipeline",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

# DAG context manager — Airflow registers this DAG
with DAG(
    dag_id="example_structure",           # unique ID in UI
    default_args=default_args,
    description="Shows minimal DAG structure",
    schedule_interval=None,               # None = trigger manually only
    start_date=datetime(2026, 1, 1),      # required; no runs before this
    catchup=False,                        # don't backfill old intervals
    tags=["learning"],
) as dag:
    hello = BashOperator(
        task_id="say_hello",              # unique within DAG
        bash_command='echo "hello from Airflow"',
    )
```

**Expected result:** You can point to `dag_id`, `task_id`, `schedule_interval`, and `default_args`.

### Checkpoint

Explain in one sentence: "What is the difference between a DAG and a task?"  
**Answer:** DAG is the whole workflow; a task is one step inside it.

---

## Task 3 ✅ — Write a simple test DAG

**Explanation:** Confirm your `dags/` folder is mounted and parsed.

**Code/command:** Create `dags/hello_dag.py`:

```python
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
```

Wait ~30 seconds or trigger refresh in UI.

**Expected result:** `hello_dag` appears in UI (may be paused).

**Run it:** Toggle ON → click play ▶ → **Trigger DAG**.

**Expected result:** Task turns green (success).

### Checkpoint

```bash
docker compose logs airflow-scheduler --tail 20 | grep hello_dag
```

No import errors; mentions `hello_dag`.

---

## Task 4 ✅ — Production DAG (producer every 10 minutes)

**Explanation:** Run `producer.py` on schedule. We use `BashOperator` with the venv Python on the **host** path mounted into the container — simplest for learning. Alternative: install deps in custom Airflow image (advanced).

**Code/command:** Create `dags/news_fetch_dag.py`:

```python
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

# Every 10 minutes: cron */10 * * * *
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
    run_producer = BashOperator(
        task_id="run_producer",
        # Path inside container (./producer is mounted at /opt/airflow/producer)
        bash_command="""
        set -e
        pip install -q requests kafka-python python-dotenv 2>/dev/null || true
        cd /opt/airflow
        export $(grep -v '^#' /opt/airflow/producer/.env 2>/dev/null | xargs) || true
        python /opt/airflow/producer/producer.py
        """,
        env={
            "NEWS_API_KEY": "{{ var.value.get('NEWS_API_KEY', '') }}",
            "KAFKA_BOOTSTRAP_SERVERS": "kafka:29092",
            "KAFKA_TOPIC": "news-raw",
        },
    )
```

**Important for Kafka from inside Airflow container:** use bootstrap `kafka:29092` (Docker network), not `localhost:9092`.

**Set Airflow variable (recommended):**

1. UI → **Admin** → **Variables** → Add  
   - Key: `NEWS_API_KEY`  
   - Value: your API key  

Or copy `.env` into `producer/.env` and adjust the bash script to `source` it.

**Simpler local approach:** hardcode env in `docker-compose.yml` for `airflow-scheduler` and `airflow-webserver`:

```yaml
environment:
  NEWS_API_KEY: your_key_here
  KAFKA_BOOTSTRAP_SERVERS: kafka:29092
  KAFKA_TOPIC: news-raw
```

Then simplify `bash_command` to:

```python
bash_command="python /opt/airflow/producer/producer.py",
```

**Expected result:** DAG scheduled every 10 minutes; task runs producer.

### Checkpoint

After trigger or schedule wait:

```bash
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic news-raw \
  --timeout-ms 3000 \
  --max-messages 1
```

New messages appear after DAG success.

---

## Task 5 ✅ — Monitor DAG runs in the UI

**Explanation:** Learn the observability Airflow gives you.

**Code/command:**

1. Open **DAGs** → `news_fetch_dag`
2. Click **Grid** or **Graph** view
3. Click a green square → **Log** for `run_producer`

**Expected result:** Log shows `Fetched N articles` and `Published N messages`.

### Checkpoint

Last run status = **success** (green). Duration is reasonable (< 2 min).

---

## Task 6 ✅ — Handle failures and retries

**Explanation:** Networks fail; Airflow can retry without you waking up.

**Code/command:**

1. In `default_args`, we already set `retries: 2` and `retry_delay: 3 minutes`.
2. **Test failure:** Temporarily set invalid API key in Variables → trigger DAG → task fails → fix key → clear failed task → retry.

**Clear and retry:**

- UI → failed run → **Clear** task → **Trigger DAG** again

Optional: add `on_failure_callback` later (Slack/email) — not required for course.

**Expected result:** Failed run shows red; after fix, retry succeeds.

### Checkpoint

```bash
docker compose logs airflow-scheduler --tail 50 | grep -i retry
```

After forced failure, logs mention retry attempts.

---

## How this connects to the project

Airflow is the **heartbeat** of ingestion. It replaces "run producer when I remember" with a reliable 10-minute rhythm. Phase 4's consumer can run continuously (separate process) while Airflow keeps filling Kafka.
