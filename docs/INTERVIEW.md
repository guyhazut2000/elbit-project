# Interview talking points

## 30-second pitch

I built a news analytics pipeline that fetches headlines every 10 minutes with Airflow, buffers them in Kafka, and processes them with a Python consumer that does sentiment analysis and indexes into Elasticsearch. I monitor the stack with health scripts and visualize trends in Kibana.

## Why Kafka?

To decouple the producer from the consumer. If Elasticsearch is slow or down, messages stay in the queue instead of losing fetches or blocking the scheduler.

## Why Airflow instead of cron?

Retries, centralized logs, a UI for run history, and pausing the whole workflow — important when a pipeline has more than one step.

## What would you improve?

- Schema registry for Kafka payloads
- Dead-letter topic for failed messages
- Prometheus/Grafana for lag and throughput
- Idempotent / exactly-once consumer semantics
- Terraform for cloud deploy (MSK, OpenSearch, MWAA)

## Hardest bugs (from this project)

- **Kafka from Docker:** `advertised.listeners` must expose `localhost:9092` for host and `kafka:29092` for containers.
- **Airflow + Python 3.8:** `list[dict]` type hints need `from __future__ import annotations`.
- **Windows consumer:** Unicode arrows in `print()` broke the console; use ASCII `->`.
- **First `docker compose up`:** `postgres:15` image needed an explicit `docker pull`.

## Architecture (whiteboard)

```
NewsAPI -> Airflow (*/10 min) -> producer -> Kafka (news-raw)
                                         -> consumer -> Elasticsearch (news) -> Kibana
```
