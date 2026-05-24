# Phase 0: Project overview

## What and Why

You already build web apps with Next.js — you know APIs, databases, and deployments. **Data engineering** is the discipline of moving and transforming data reliably at scale: ingest from many sources, buffer spikes, process in streams or batches, and make data queryable for analytics.

This project is a **real-time news intelligence pipeline**: every 10 minutes you pull headlines, queue them, analyze sentiment, store them for search, and visualize trends in Kibana. You will learn industry-standard tools (Docker, Kafka, Airflow, Elasticsearch) by using them together — not in isolation.

Think of it like upgrading from a single Next.js API route that fetches news on page load to a **factory** that runs 24/7 whether anyone visits your site or not.

---

## Architecture (ASCII)

```
                         REAL-TIME NEWS INTELLIGENCE PIPELINE
 =============================================================================

   +-------------+     +------------------+     +------------------+
   |   NewsAPI   |     |     Apache       |     |     Apache       |
   |  (external) |     |     Airflow      |     |      Kafka       |
   |  REST API   |     |   scheduler      |     |  message queue   |
   +------+------+     +--------+---------+     +--------+---------+
          |                      |                        |
          |    every 10 min      |   runs producer.py     |
          |                      v                        |
          |             +--------+---------+              |
          +------------>|  producer/       |---publish--->|
                        |  producer.py     |   topic:     |
                        +------------------+  news-raw     |
                                                   |        |
                                                   | consume|
                                                   v        |
                        +------------------+     +----------+--------+
                        |  consumer/       |<----|  Kafka broker     |
                        |  consumer.py     |     |  (+ Zookeeper)    |
                        |  sentiment + ES  |     +-------------------+
                        +--------+---------+
                                 |
                                 | index documents
                                 v
                        +------------------+     +------------------+
                        | Elasticsearch    |<----|     Kibana       |
                        |  index: news     |     |   dashboards     |
                        +------------------+     +------------------+

   All boxed services run in Docker via docker-compose.yml on your laptop.
```

**Data flow in one sentence:** Airflow triggers the producer → producer fetches NewsAPI and sends JSON to Kafka → consumer reads Kafka, scores sentiment, writes to Elasticsearch → Kibana charts the results.

---

## Technology stack

| Tool | What it does | Why we use it here |
|------|----------------|---------------------|
| **NewsAPI** | HTTP API for headlines | Real external data source (like production) |
| **Docker** | Runs apps in isolated containers | Same stack on any machine; no "works on my PC" |
| **docker-compose** | Starts many containers with one command | One file defines Kafka + ES + Airflow + … |
| **Apache Kafka** | Distributed log / message queue | Decouples fetch from processing; handles bursts |
| **Apache Airflow** | Workflow scheduler with UI | Cron on steroids: retries, logs, dependencies |
| **Python** | Producer & consumer scripts | Standard language for data scripts and ML libs |
| **Elasticsearch** | Search & analytics engine | Fast filters, aggregations, full-text on headlines |
| **Kibana** | UI for Elasticsearch | Live charts without building a custom dashboard |
| **Bash scripts** | Automate health checks & restarts | What ops teams use on Linux servers |

---

## Prerequisites checklist

Install and verify **before** Phase 1.

- [ ] **Git** — `git --version`
- [ ] **Docker Desktop** (Windows/Mac) or Docker Engine + Compose (Linux) — `docker --version` and `docker compose version`
- [ ] **Python 3.10+** — `python --version`
- [ ] **Code editor** (Cursor / VS Code)
- [ ] **NewsAPI key** — register at https://newsapi.org/ (free developer tier)
- [ ] **~8 GB RAM** free for Docker (check Docker Desktop → Settings → Resources)
- [ ] **Terminal** — Git Bash or WSL on Windows recommended for scripts in Phase 5

Optional but helpful:

- [ ] Postman or `curl` for testing HTTP
- [ ] Basic understanding of JSON and environment variables (you have this from Next.js)

---

## Estimated time per phase

| Phase | Doc | Focus | Rough time |
|-------|-----|--------|------------|
| 0 | This file | Read & install | 1–2 hours |
| 1 | 01-docker.md | Infrastructure up | 3–5 hours |
| 2 | 02-kafka.md | Producer + Kafka CLI | 4–6 hours |
| 3 | 03-airflow.md | Scheduling | 3–5 hours |
| 4 | 04-elasticsearch.md | Consumer + Kibana | 5–8 hours |
| 5 | 05-linux-scripts.md | Ops scripts | 2–3 hours |
| 6 | 06-putting-it-together.md | E2E + portfolio | 2–4 hours |

**Total:** ~20–33 hours spread over 2–4 weeks is normal for a first pipeline.

---

## How to use these docs

### Read order

1. `00-overview.md` (you are here)
2. `01-docker.md` → `02-kafka.md` → `03-airflow.md` → `04-elasticsearch.md` → `05-linux-scripts.md` → `06-putting-it-together.md`

Do **not** skip Docker — everything else runs inside it.

### How to track progress

1. Open [PROGRESS.md](../PROGRESS.md) in a second tab.
2. After each task with ✅, check the box when your **Checkpoint** commands succeed.
3. If stuck >30 minutes, read [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) for that phase's tool.

### Rules for you as the learner

- Type commands yourself; don't only read.
- When code is shown, create the file in the repo path indicated.
- Every `.env` secret stays out of Git (add `.env` to `.gitignore`).

---

## Task ✅ — Create your environment file

**Explanation:** Central place for secrets and config (like `.env.local` in Next.js).

**Code/command:**

```bash
# From repo root news-pipeline/
cd news-pipeline

# Create .env (never commit this file)
cat > .env << 'EOF'
NEWS_API_KEY=replace_with_your_key_from_newsapi_org
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
KAFKA_TOPIC=news-raw
ELASTICSEARCH_URL=http://localhost:9200
ELASTICSEARCH_INDEX=news
EOF
```

Add to `.gitignore`:

```gitignore
.env
.venv/
__pycache__/
*.pyc
```

**Expected result:** File `.env` exists locally; Git ignores it.

### Checkpoint

```bash
# Should print your key (careful sharing screen)
grep NEWS_API_KEY .env
```

---

## Task ✅ — Initialize Git (optional but recommended)

**Explanation:** Portfolio projects live on GitHub.

**Code/command:**

```bash
git init
git add README.md docs/ PROGRESS.md TROUBLESHOOTING.md docker-compose.yml
git commit -m "chore: initial news pipeline course structure"
```

**Expected result:** Clean first commit without `.env`.

### Checkpoint

```bash
git status   # .env should NOT appear in staged files
```

---

## How this connects to the project

This document is your map. Every later phase adds one box in the architecture diagram until NewsAPI headlines appear as sentiment charts in Kibana — the story you will tell in interviews and on your README.
