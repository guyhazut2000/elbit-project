# Phase 6: Putting it all together

## What and Why

You have learned each component in isolation. This phase wires **habit and verification**: start the stack, schedule ingestion, run the consumer, confirm data in Kibana, and package the story for GitHub and interviews.

**Analogy:** You've practiced each instrument; now play the song start to finish without stopping.

---

## Full end-to-end test

Follow in order. Total time: ~30–45 minutes (excluding 10-minute Airflow waits).

### Step 1 — Start infrastructure

**Code/command:**

```bash
cd news-pipeline
docker compose up -d
./scripts/health_check.sh
```

**Expected result:** All checks passed.

### Checkpoint

```bash
curl -s http://localhost:9200/_cluster/health | grep -o '"status":"[^"]*"'
```

---

### Step 2 — Ensure Kafka topic and ES index exist

**Code/command:**

```bash
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --create --if-not-exists --topic news-raw --partitions 1 --replication-factor 1

curl -X PUT "http://localhost:9200/news" -H "Content-Type: application/json" -d '{"mappings":{"properties":{"title":{"type":"text"},"url":{"type":"keyword"},"source":{"type":"keyword"},"publishedAt":{"type":"date"},"fetchedAt":{"type":"date"},"sentiment":{"type":"keyword"},"sentiment_score":{"type":"float"}}}}' 2>/dev/null || true
```

**Expected result:** Topic and index ready (index create may say already exists — OK).

### Checkpoint

```bash
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | grep news-raw
curl -s http://localhost:9200/news
```

---

### Step 3 — Start consumer (Terminal A)

**Code/command:**

```bash
source .venv/bin/activate   # or Windows equivalent
python consumer/consumer.py
```

**Expected result:** `Listening on topic 'news-raw'...`

---

### Step 4 — Enable Airflow DAG (or manual producer)

**Option A — Airflow:** UI → enable `news_fetch_dag` → Trigger DAG  
**Option B — Manual:**

```bash
python producer/producer.py
```

**Expected result:** Consumer terminal prints `Indexed: ...` lines.

### Checkpoint

```bash
curl -s "http://localhost:9200/news/_count"
```

Count > 0.

---

### Step 5 — Verify Kibana

1. Open http://localhost:5601  
2. Open dashboard **News Intelligence** (from Phase 4)  
3. Refresh time range to **Last 24 hours**

**Expected result:** Charts and table show your articles.

### Checkpoint

Take a screenshot for your README (optional but strong for portfolio).

---

## Complete working pipeline checklist

Mark in [PROGRESS.md](../PROGRESS.md) when true:

- [ ] `docker compose ps` — kafka, elasticsearch, kibana, airflow-* running
- [ ] `./scripts/health_check.sh` exits 0
- [ ] Topic `news-raw` exists
- [ ] Index `news` exists with documents
- [ ] `hello_dag` and `news_fetch_dag` visible in Airflow
- [ ] `news_fetch_dag` succeeds on schedule or trigger
- [ ] `consumer.py` running without errors
- [ ] Kibana dashboard shows sentiment pie + articles
- [ ] `.env` not committed to Git
- [ ] [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) bookmarked

---

## How to write a good README for GitHub

Use this template in your root `README.md` (customize after you finish):

```markdown
# Real-Time News Intelligence Pipeline

Ingests headlines from NewsAPI on a schedule, streams them through Kafka,
enriches with sentiment analysis, and visualizes trends in Kibana.

## Architecture

[Insert your ASCII diagram or screenshot]

## Stack

Docker · Kafka · Airflow · Python · Elasticsearch · Kibana

## Quick start

1. Copy `.env.example` to `.env` and add `NEWS_API_KEY`
2. `docker compose up -d`
3. `pip install -r requirements.txt`
4. `python consumer/consumer.py` (separate terminal)
5. Enable `news_fetch_dag` in Airflow at http://localhost:8080
6. Open Kibana at http://localhost:5601

## What I learned

- Decoupling ingest and processing with a message queue
- Operational concerns: retries, health checks, listener config

## License

MIT
```

Also add `.env.example`:

```bash
NEWS_API_KEY=
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
KAFKA_TOPIC=news-raw
ELASTICSEARCH_URL=http://localhost:9200
ELASTICSEARCH_INDEX=news
```

---

## What to say in a job interview

**30-second pitch:**  
"I built a news analytics pipeline that fetches headlines every 10 minutes with Airflow, buffers them in Kafka, and processes them with a Python consumer that does sentiment analysis and indexes into Elasticsearch. I monitor everything with Kibana and wrote Bash scripts for health checks."

**If they ask "why Kafka?":**  
"To decouple the producer from the consumer. If Elasticsearch is slow or down, messages stay in the queue instead of losing fetches or blocking the scheduler."

**If they ask "why Airflow instead of cron?":**  
"Retries, dependency graphs, centralized logs, and a UI to see historical runs — important when a pipeline has more than one step."

**If they ask "what would you improve?":**  
"Mention: schema registry for Kafka, dead-letter topic, Prometheus/Grafana metrics, idempotent consumer with exactly-once semantics, Terraform for cloud deploy, Confluent or MSK instead of single broker."

**If they ask "hardest bug?":**  
Prepare one real story from [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) — e.g. Kafka `advertised.listeners` or ES memory.

---

## Next steps to level up the project

Pick 1–2 for portfolio depth:

| Enhancement | Skill demonstrated |
|-------------|-------------------|
| **Dead-letter topic** `news-dlq` for failed messages | Error handling |
| **Great Expectations** or pydantic validation on payloads | Data quality |
| **Terraform** on AWS (MSK + OpenSearch + MWAA) | Cloud DE |
| **dbt** or batch export to Snowflake/BigQuery | Warehouse modeling |
| **Prometheus + Grafana** for lag and throughput | Observability |
| **GitHub Actions** run `health_check.sh` on push | CI/CD |
| **Replace TextBlob** with Hugging Face model | ML integration |
| **Single Dockerfile** for producer+consumer | Container best practices |

---

## Task ✅ — Final reflection (5 minutes)

**Explanation:** Solidify learning.

**Code/command:** In [PROGRESS.md](../PROGRESS.md), fill the Notes table with one row per phase.

**Expected result:** Written record of blockers and wins.

### Checkpoint

You can draw the architecture from memory on a whiteboard in under 2 minutes.

---

## How this connects to the project

This document is the **graduation**: proof the system works as a whole. Your README and interview answers turn the same architecture diagram from Phase 0 into a story employers recognize — batch + streaming patterns, orchestration, queue, and analytics store.
