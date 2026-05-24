#!/usr/bin/env bash
# health_check.sh — verify Docker Compose services for news-pipeline are running.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

echo "=== News Pipeline Health Check ==="
echo "Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

SERVICES=(zookeeper kafka elasticsearch kibana airflow-webserver airflow-scheduler postgres)

if ! docker compose ps >/dev/null 2>&1; then
  echo "ERROR: docker compose not available or not in news-pipeline directory"
  exit 1
fi

FAILED=0
for svc in "${SERVICES[@]}"; do
  if docker compose ps --status running 2>/dev/null | grep -q "${svc}"; then
    echo "[OK]   ${svc}"
  elif docker compose ps | grep "${svc}" | grep -qE "running|Up"; then
    echo "[OK]   ${svc}"
  else
    echo "[FAIL] ${svc} — not running"
    FAILED=1
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
