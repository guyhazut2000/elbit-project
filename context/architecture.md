# Architecture

```
NewsAPI → Airflow (*/10 min) → producer.py → Kafka (news-raw)
                                              → consumer.py → Elasticsearch (news) → Kibana
```

| Component | Port (host) | Role |
|-----------|-------------|------|
| Kafka | 9092 | Message queue |
| Airflow | 8080 | Scheduler + UI |
| Elasticsearch | 9200 | Document store |
| Kibana | 5601 | Dashboards |

**Config:** `.env` on host; Airflow containers use `kafka:29092` for Kafka.

**Full detail:** `docs/00-overview.md` and `docs/01-docker.md`.
