# Master progress checklist

Copy this file or check boxes in GitHub / your editor as you complete each task.

**Legend:** `[ ]` not started · `[~]` in progress · `[x]` done

---

## Phase 0 — Overview & setup

- [ ] Read [docs/00-overview.md](docs/00-overview.md) fully
- [ ] Install Docker Desktop
- [ ] Install Python 3.10+
- [ ] Create NewsAPI account and copy API key
- [ ] Clone/create `news-pipeline` repo locally
- [ ] Create `.env` file (you will add keys in later phases)

---

## Phase 1 — Docker ([01-docker.md](docs/01-docker.md))

- [x] Task 1: Install Docker Desktop
- [x] Task 2: Run `hello-world` container
- [x] Task 3: Understand `docker-compose.yml` structure
- [x] Task 4: Write full `docker-compose.yml` (Zookeeper, Kafka, ES, Kibana, Airflow)
- [x] Task 5: `docker compose up -d` — all services healthy

---

## Phase 2 — Kafka ([02-kafka.md](docs/02-kafka.md))

- [x] Task 1: Verify Kafka is running
- [x] Task 2: Create topic `news-raw`
- [x] Task 3: Send test message via CLI
- [x] Task 4: Read message back via CLI
- [x] Task 5: Write `producer/producer.py`
- [x] Task 6: Test producer — messages in topic

---

## Phase 3 — Airflow ([03-airflow.md](docs/03-airflow.md))

- [x] Task 1: Open Airflow UI at http://localhost:8080
- [x] Task 2: Understand DAG file structure
- [x] Task 3: Test DAG prints "hello"
- [x] Task 4: Production DAG runs producer every 10 minutes
- [x] Task 5: Monitor DAG runs in UI
- [x] Task 6: Configure retries / failure handling

---

## Phase 4 — Elasticsearch & Kibana ([04-elasticsearch.md](docs/04-elasticsearch.md))

- [x] Task 1: Verify Elasticsearch is running
- [x] Task 2: Create index `news`
- [x] Task 3: Insert test document via curl
- [x] Task 4: Write `consumer/consumer.py`
- [~] Task 5: Kibana dashboard (bar, pie, table) — build UI per `kibana/README.md`

---

## Phase 5 — Linux scripts ([05-linux-scripts.md](docs/05-linux-scripts.md))

- [x] Task 1: `scripts/health_check.sh`
- [x] Task 2: `scripts/restart_pipeline.sh`
- [x] Task 3: `scripts/logs.sh`
- [x] Task 4: `chmod +x` on scripts
- [x] Task 5: Cron job example documented/tested

---

## Phase 6 — Integration ([06-putting-it-together.md](docs/06-putting-it-together.md))

- [x] Full end-to-end test (NewsAPI → Elasticsearch; Kibana UI manual)
- [x] Complete pipeline checklist signed off (`scripts/e2e_check.sh`)
- [x] README polished for GitHub
- [x] Interview talking points written (`docs/INTERVIEW.md`)
- [ ] (Optional) Next steps picked (see doc)

---

## Portfolio extras (optional)

- [ ] Add architecture diagram image to README
- [ ] Record 2-minute demo GIF
- [ ] Deploy nothing to cloud OR add CI that runs `health_check.sh`
- [ ] Add unit tests for sentiment function
- [ ] Pin all image versions in `docker-compose.yml`

---

## Notes

| Date | Phase | What I learned / blocked on |
|------|-------|-----------------------------|
| 2026-05-24 | 1 | Stack up; first `up` needed manual `docker pull postgres:15` |
| 2026-05-24 | 2 | Producer OK; bumped kafka-python for Python 3.12 |
| 2026-05-25 | 4 | Consumer + ES index; 51 docs; fixed Windows print encoding |
| 2026-05-25 | 6 | e2e_check.sh, README, INTERVIEW.md; pipeline verified |

---

## Pipeline checklist (Phase 6)

- [x] `docker compose ps` — kafka, elasticsearch, kibana, airflow-* running
- [x] `./scripts/health_check.sh` exits 0
- [x] Topic `news-raw` exists
- [x] Index `news` exists with documents
- [x] `hello_dag` and `news_fetch_dag` visible in Airflow
- [x] `news_fetch_dag` succeeds on schedule or trigger
- [x] `consumer.py` runs without errors
- [~] Kibana dashboard shows sentiment pie + articles (manual UI)
- [x] `.env` not committed to Git
- [x] [TROUBLESHOOTING.md](TROUBLESHOOTING.md) available
