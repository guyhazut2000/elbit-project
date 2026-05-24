# Troubleshooting — top 10 beginner issues

Use this when something fails during the news pipeline course. Each item: **symptom → cause → fix**.

---

## 1. `docker compose up` fails with "port is already allocated"

**Symptom:** Error like `Bind for 0.0.0.0:8080 failed: port is already allocated`.

**Cause:** Another app (old Airflow, another project, IIS, local dev server) uses the same port.

**Fix:**

```bash
# Windows (PowerShell) — find what uses port 8080
netstat -ano | findstr :8080

# Stop the process or change the host port in docker-compose.yml, e.g.:
# ports:
#   - "8081:8080"   # host:container
```

Restart: `docker compose down` then `docker compose up -d`.

---

## 2. Docker Desktop says "WSL 2 required" or engine won't start

**Symptom:** Docker stuck on "Starting..." or WSL errors on Windows.

**Cause:** WSL 2 not installed or not default.

**Fix:**

1. Run in PowerShell (Admin): `wsl --install`
2. Reboot
3. Docker Desktop → Settings → General → use WSL 2 based engine
4. Settings → Resources → give Docker at least **6–8 GB RAM**

---

## 3. Kafka container exits immediately / "InconsistentClusterIdException"

**Symptom:** Kafka restarts in a loop after you changed versions or wiped volumes partially.

**Cause:** Old data volume incompatible with new Kafka image.

**Fix:**

```bash
docker compose down -v   # WARNING: deletes all Docker volumes for this project
docker compose up -d
```

Recreate topic `news-raw` (see [docs/02-kafka.md](docs/02-kafka.md)).

---

## 4. Cannot connect to Kafka from host (`localhost:9092` connection refused)

**Symptom:** `producer.py` or `kafka-console-producer` fails on `localhost:9092`.

**Cause:** Wrong advertised listener — Kafka inside Docker advertises an internal hostname your PC cannot resolve.

**Fix:** In `docker-compose.yml`, ensure Kafka has something like:

```yaml
KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:29092,PLAINTEXT_HOST://0.0.0.0:9092
```

Use **`localhost:9092`** from your machine; use **`kafka:29092`** from other containers.

---

## 5. Elasticsearch yellow/red — "max virtual memory areas"

**Symptom:** ES logs: `max virtual memory areas vm.max_map_count [65530] is too low`.

**Cause:** Linux kernel limit (common on WSL).

**Fix (WSL / Linux):**

```bash
sudo sysctl -w vm.max_map_count=262144
```

Make permanent: add `vm.max_map_count=262144` to `/etc/sysctl.conf`.

On Docker Desktop for Mac/Windows, this is usually handled automatically; if not, check Docker Desktop docs for your version.

---

## 6. Airflow UI loads but DAGs don't appear

**Symptom:** Empty DAG list or "DAG not found".

**Cause:** DAG folder not mounted, syntax error in `.py` file, or scheduler not parsing.

**Fix:**

```bash
# Check scheduler logs
docker compose logs airflow-scheduler --tail 100

# Fix Python syntax in dags/*.py
# Ensure volume mount in compose matches your ./dags folder
```

Unpause DAG in UI (toggle). New files can take ~30–60 seconds to show.

---

## 7. NewsAPI returns 401 or 429

**Symptom:** `{"status":"error","code":"apiKeyInvalid"}` or rate limit.

**Cause:** Missing/wrong key or free tier limits (100 requests/day on developer plan).

**Fix:**

- Put key in `.env`: `NEWS_API_KEY=your_key_here`
- Load in Python with `os.getenv("NEWS_API_KEY")`
- Space Airflow runs (10 min schedule is fine); avoid manual spam during testing
- For heavy testing, mock JSON locally instead of calling API every time

---

## 8. `consumer.py` runs but nothing in Elasticsearch

**Symptom:** Kafka has messages; `curl localhost:9200/news/_search` is empty.

**Cause:** Wrong index name, ES not ready, or consumer not committing offsets / crashing silently.

**Fix:**

```bash
# ES health
curl http://localhost:9200/_cluster/health?pretty

# Consumer logs
docker compose logs -f   # or run consumer in foreground with print/debug

# Manual index test
curl -X POST "http://localhost:9200/news/_doc" -H "Content-Type: application/json" -d '{"title":"test"}'
```

Match index name exactly: `news`.

---

## 9. Kibana shows "Unable to connect to Elasticsearch"

**Symptom:** Kibana setup screen or red ES status.

**Cause:** Wrong `ELASTICSEARCH_HOSTS` or ES still starting.

**Fix:**

- Wait 1–2 minutes after `docker compose up`
- In compose, Kibana should point to `http://elasticsearch:9200` (service name, not localhost, from inside Docker network)
- From browser use http://localhost:5601

---

## 10. Python `ModuleNotFoundError` (kafka, elasticsearch, etc.)

**Symptom:** Import errors when running `producer.py` or `consumer.py` on host.

**Cause:** Dependencies not installed in current venv.

**Fix:**

```bash
cd news-pipeline
python -m venv .venv
# Windows
.venv\Scripts\activate
# Mac/Linux
source .venv/bin/activate

pip install -r requirements.txt
```

If you run scripts **inside** Airflow container, install packages in the image or use `PythonVirtualenvOperator` — see [docs/03-airflow.md](docs/03-airflow.md).

---

## Still stuck?

1. Run `docker compose ps` — all services should be `running` or `healthy`.
2. Run `scripts/health_check.sh` (after Phase 5).
3. Collect logs: `docker compose logs --tail=50 > debug.txt`
4. Search the exact error string in the doc for that phase.

---

## How this connects to the project

A production pipeline fails in predictable places: ports, listeners, memory, API keys, and path mismatches. Fixing these locally teaches you the same debugging flow you'd use on call in a data engineering job.
