# Real-Time News Intelligence Pipeline

Ingests headlines from NewsAPI on a schedule, streams them through Kafka, enriches with sentiment analysis, and visualizes trends in Kibana.

## Architecture

```
NewsAPI → Airflow (every 10 min) → producer.py → Kafka (news-raw)
                                              → consumer.py → Elasticsearch (news) → Kibana
```

## Stack

Docker · Zookeeper · Kafka · Airflow · Python · Elasticsearch · Kibana

## Quick start

1. Copy `.env.example` to `.env` and set `NEWS_API_KEY` ([NewsAPI](https://newsapi.org/))
2. Start infrastructure:

   ```bash
   cd news-pipeline
   docker compose up -d
   bash scripts/health_check.sh
   ```

3. Python dependencies (host):

   ```bash
   python -m venv .venv
   # Windows: .venv\Scripts\activate
   # Mac/Linux: source .venv/bin/activate
   pip install -r requirements.txt
   ```

4. Kafka topic and Elasticsearch index (first time):

   ```bash
   docker exec kafka kafka-topics --bootstrap-server localhost:9092 --create --if-not-exists --topic news-raw --partitions 1 --replication-factor 1
   bash scripts/setup_news_index.sh
   ```

5. **Terminal A** — run the consumer (leave running):

   ```bash
   python consumer/consumer.py
   ```

6. **Airflow** — http://localhost:8080 (`admin` / `admin`): enable `news_fetch_dag`, or run once manually:

   ```bash
   python producer/producer.py
   ```

7. **Kibana** — http://localhost:5601 — build dashboard per [kibana/README.md](kibana/README.md)

8. Verify end-to-end:

   ```bash
   bash scripts/e2e_check.sh
   ```

## Project structure

| Path | Purpose |
|------|---------|
| `docs/` | Step-by-step course (start at `00-overview.md`) |
| `docker-compose.yml` | All infrastructure services |
| `dags/` | Airflow DAG definitions |
| `producer/` | NewsAPI → Kafka |
| `consumer/` | Kafka → sentiment → Elasticsearch |
| `scripts/` | Health, E2E, restart, logs |
| `kibana/` | Dashboard setup guide |

## What I learned

- Decoupling ingest and processing with a message queue
- Docker networking (`localhost:9092` vs `kafka:29092`)
- Orchestration with Airflow (retries, schedule, observability)
- Operational scripts for health and E2E checks

## Interview prep

See [docs/INTERVIEW.md](docs/INTERVIEW.md).

## Course & troubleshooting

- Progress: [PROGRESS.md](PROGRESS.md)
- Full walkthrough: [docs/00-overview.md](docs/00-overview.md) → [06-putting-it-together.md](docs/06-putting-it-together.md)
- Fixes: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Agents: [AGENTS.md](AGENTS.md), [context/](context/)

## License

MIT — use for learning and portfolio.
