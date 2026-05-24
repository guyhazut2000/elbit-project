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

- [ ] Task 1: Install Docker Desktop
- [ ] Task 2: Run `hello-world` container
- [ ] Task 3: Understand `docker-compose.yml` structure
- [ ] Task 4: Write full `docker-compose.yml` (Zookeeper, Kafka, ES, Kibana, Airflow)
- [ ] Task 5: `docker compose up -d` — all services healthy

---

## Phase 2 — Kafka ([02-kafka.md](docs/02-kafka.md))

- [ ] Task 1: Verify Kafka is running
- [ ] Task 2: Create topic `news-raw`
- [ ] Task 3: Send test message via CLI
- [ ] Task 4: Read message back via CLI
- [ ] Task 5: Write `producer/producer.py`
- [ ] Task 6: Test producer — messages in topic

---

## Phase 3 — Airflow ([03-airflow.md](docs/03-airflow.md))

- [ ] Task 1: Open Airflow UI at http://localhost:8080
- [ ] Task 2: Understand DAG file structure
- [ ] Task 3: Test DAG prints "hello"
- [ ] Task 4: Production DAG runs producer every 10 minutes
- [ ] Task 5: Monitor DAG runs in UI
- [ ] Task 6: Configure retries / failure handling

---

## Phase 4 — Elasticsearch & Kibana ([04-elasticsearch.md](docs/04-elasticsearch.md))

- [ ] Task 1: Verify Elasticsearch is running
- [ ] Task 2: Create index `news`
- [ ] Task 3: Insert test document via curl
- [ ] Task 4: Write `consumer/consumer.py`
- [ ] Task 5: Kibana dashboard (bar, pie, table)

---

## Phase 5 — Linux scripts ([05-linux-scripts.md](docs/05-linux-scripts.md))

- [ ] Task 1: `scripts/health_check.sh`
- [ ] Task 2: `scripts/restart_pipeline.sh`
- [ ] Task 3: `scripts/logs.sh`
- [ ] Task 4: `chmod +x` on scripts
- [ ] Task 5: Cron job example documented/tested

---

## Phase 6 — Integration ([06-putting-it-together.md](docs/06-putting-it-together.md))

- [ ] Full end-to-end test (NewsAPI → Kibana)
- [ ] Complete pipeline checklist signed off
- [ ] README polished for GitHub
- [ ] Interview talking points written
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
|      |       |                             |
|      |       |                             |
