# Phase 5: Linux scripts for operations

## What and Why

Data pipelines run on **Linux servers** in the cloud. Engineers automate health checks, restarts, and log tailing with **shell scripts** (Bash). Even on Windows, you use Git Bash or WSL to run the same scripts you'll use in production.

**Analogy:** Scripts are the **pit crew** for your race car (Docker stack): quick checks before a demo, restart after a crash, grab logs when something smells wrong.

**Why for this project:** After Phase 4, you have 7+ containers. Scripts save you from memorizing long `docker compose` commands.

---

## Task 1 ✅ — Write health_check.sh

**Explanation:** Exit code 0 = all critical services running; non-zero = something down.

**Code/command:** Create `scripts/health_check.sh`:

```bash
#!/usr/bin/env bash
# health_check.sh — verify Docker Compose services for news-pipeline are running.
set -euo pipefail

# Move to repo root (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

echo "=== News Pipeline Health Check ==="
echo "Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# List of compose service names we expect
SERVICES=(zookeeper kafka elasticsearch kibana airflow-webserver airflow-scheduler postgres)

# docker compose ps --format requires compose v2
if ! docker compose ps >/dev/null 2>&1; then
  echo "ERROR: docker compose not available or not in news-pipeline directory"
  exit 1
fi

FAILED=0
for svc in "${SERVICES[@]}"; do
  # Check if service container is running (may match partial name)
  STATE=$(docker compose ps --status running --services 2>/dev/null | grep -x "${svc}" || true)
  if [[ -z "${STATE}" ]]; then
    # Fallback: look for running line containing service name
    if docker compose ps | grep -E "^${svc}\s" | grep -q "running\|Up"; then
      echo "[OK]   ${svc}"
    else
      echo "[FAIL] ${svc} — not running"
      FAILED=1
    fi
  else
    echo "[OK]   ${svc}"
  fi
done

echo ""
echo "--- HTTP endpoints ---"

check_url() {
  local name="$1"
  local url="$2"
  if curl -sf --max-time 5 "${url}" >/dev/null; then
    echo "[OK]   ${name} (${url})"
  else
    echo "[FAIL] ${name} (${url})"
    FAILED=1
  fi
}

check_url "Elasticsearch" "http://localhost:9200"
check_url "Kibana" "http://localhost:5601/api/status"
check_url "Airflow" "http://localhost:8080/health"

echo ""
if [[ "${FAILED}" -eq 0 ]]; then
  echo "All checks passed."
  exit 0
else
  echo "One or more checks failed."
  exit 1
fi
```

**Expected result:** File saved under `scripts/`.

### Checkpoint

(Run after Task 4 chmod)

```bash
./scripts/health_check.sh
echo "exit code: $?"
```

Exit code `0` when stack is up.

---

## Task 2 ✅ — Write restart_pipeline.sh

**Explanation:** Clean restart without deleting volumes (data preserved).

**Code/command:** Create `scripts/restart_pipeline.sh`:

```bash
#!/usr/bin/env bash
# restart_pipeline.sh — stop and start the full docker compose stack.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

echo "Stopping news-pipeline stack..."
docker compose down

echo "Starting news-pipeline stack..."
docker compose up -d

echo "Waiting 30s for services to warm up..."
sleep 30

echo "Running health check..."
"${SCRIPT_DIR}/health_check.sh"
```

**Expected result:** One command restarts everything and runs health check.

### Checkpoint

```bash
./scripts/restart_pipeline.sh
```

Ends with `All checks passed.` (or lists what failed).

---

## Task 3 ✅ — Write logs.sh

**Explanation:** Quick view of last 50 lines per service without opening Docker Desktop.

**Code/command:** Create `scripts/logs.sh`:

```bash
#!/usr/bin/env bash
# logs.sh — print last 50 log lines for each main service.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

SERVICES=(kafka elasticsearch kibana airflow-webserver airflow-scheduler)

LINES=50

for svc in "${SERVICES[@]}"; do
  echo ""
  echo "========== ${svc} (last ${LINES} lines) =========="
  docker compose logs --tail="${LINES}" "${svc}" 2>/dev/null || echo "(service ${svc} not found)"
done

echo ""
echo "Done."
```

**Expected result:** Scrollable log snapshot in terminal.

### Checkpoint

```bash
./scripts/logs.sh | head -40
```

Shows `========== kafka` section with log lines.

---

## Task 4 ✅ — Make scripts executable

**Explanation:** Unix requires execute permission to run `./script.sh`.

**Code/command:**

```bash
chmod +x scripts/health_check.sh
chmod +x scripts/restart_pipeline.sh
chmod +x scripts/logs.sh
```

On Windows Git Bash, `chmod` works; in PowerShell you can also run: `bash scripts/health_check.sh`.

**Expected result:** Scripts run without `bash` prefix.

### Checkpoint

```bash
ls -l scripts/*.sh
```

Shows `-rwxr-xr-x` or similar (x = executable).

---

## Task 5 ✅ — Cron job example

**Explanation:** On a Linux server, cron runs scripts on a schedule (like Airflow, but lighter).

**Code/command:**

Example: run health check every hour and append to a log file.

```bash
# Edit crontab (Linux server or WSL)
crontab -e
```

Add this line (adjust path to your clone):

```cron
# Every hour at minute 0 — health check news pipeline
0 * * * * /home/YOUR_USER/news-pipeline/scripts/health_check.sh >> /home/YOUR_USER/news-pipeline/logs/health.log 2>&1
```

**On Windows:** use **Task Scheduler** instead of cron, or run health check manually before demos.

**Expected result:** You understand where cron fits: simple host checks vs Airflow for complex DAGs.

### Checkpoint

```bash
# List crontab (after you add an entry)
crontab -l
```

Shows your health check line (Linux/WSL only).

---

## How this connects to the project

These scripts are what you'd put in a repo's `scripts/` folder for teammates and CI. Phase 6's end-to-end checklist can start with `./scripts/health_check.sh` before you trigger Airflow.
