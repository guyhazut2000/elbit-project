# Real-Time News Intelligence Pipeline

A hands-on data engineering project: fetch news, queue it, analyze sentiment, search and visualize — built step by step with Docker, Kafka, Airflow, Elasticsearch, and Kibana.

## Architecture

```
NewsAPI → Airflow (scheduler) → Kafka (queue) → Python Consumer → Elasticsearch → Kibana
```

## Quick start

1. Clone this repo and open it in your editor.
2. Read [docs/00-overview.md](docs/00-overview.md) for prerequisites and reading order.
3. Track progress in [PROGRESS.md](PROGRESS.md).
4. When something breaks, check [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

**Cursor / AI:** See [AGENTS.md](AGENTS.md) and [context/](context/) for agent rules and trunk-based Git workflow.

## Project structure

| Path | Purpose |
|------|---------|
| `docs/` | Step-by-step course (start at `00-overview.md`) |
| `docker-compose.yml` | All infrastructure services (filled in Phase 1) |
| `dags/` | Airflow DAG definitions |
| `producer/` | Fetches NewsAPI and publishes to Kafka |
| `consumer/` | Reads Kafka, sentiment analysis, writes Elasticsearch |
| `scripts/` | Health checks, restarts, log helpers |
| `kibana/` | Saved objects / dashboard notes (optional exports) |

## Prerequisites (summary)

- Docker Desktop
- Python 3.10+
- Free [NewsAPI](https://newsapi.org/) key
- ~8 GB RAM free for Docker
- Git

Full checklist: [docs/00-overview.md](docs/00-overview.md).

## Documentation map

| Phase | Doc | Topic |
|-------|-----|--------|
| 0 | [00-overview](docs/00-overview.md) | Architecture, stack, plan |
| 1 | [01-docker](docs/01-docker.md) | Docker & docker-compose |
| 2 | [02-kafka](docs/02-kafka.md) | Kafka & producer |
| 3 | [03-airflow](docs/03-airflow.md) | Scheduling |
| 4 | [04-elasticsearch](docs/04-elasticsearch.md) | Storage & Kibana |
| 5 | [05-linux-scripts](docs/05-linux-scripts.md) | Ops scripts |
| 6 | [06-putting-it-together](docs/06-putting-it-together.md) | E2E & portfolio |

## License

MIT — use for learning and portfolio.
