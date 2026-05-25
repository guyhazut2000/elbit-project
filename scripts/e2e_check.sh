#!/usr/bin/env bash
# e2e_check.sh — verify the full news pipeline (infra + data path).
# Run from repo root after: docker compose up -d, consumer running, Airflow DAG on.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

FAILED=0

fail() {
  echo "[FAIL] $*"
  FAILED=1
}

ok() {
  echo "[OK]   $*"
}

echo "=== News Pipeline E2E Check ==="
echo "Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

echo "--- Infrastructure (health_check) ---"
if bash "${SCRIPT_DIR}/health_check.sh"; then
  ok "health_check.sh"
else
  fail "health_check.sh"
fi

echo ""
echo "--- Kafka topic news-raw ---"
if docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null | grep -qx "news-raw"; then
  ok "topic news-raw exists"
else
  fail "topic news-raw missing"
fi

echo ""
echo "--- Elasticsearch index news ---"
COUNT=$(curl -sf "http://localhost:9200/news/_count" | grep -o '"count":[0-9]*' | head -1 | cut -d: -f2 || echo "0")
if [[ -n "${COUNT}" && "${COUNT}" -gt 0 ]]; then
  ok "index news has ${COUNT} documents"
else
  fail "index news empty — run consumer/consumer.py and producer"
fi

if curl -sf "http://localhost:9200/news/_search" -H "Content-Type: application/json" \
  -d '{"size":0,"aggs":{"s":{"terms":{"field":"sentiment","size":3}}}}' \
  | grep -q '"buckets"'; then
  ok "sentiment aggregation on news index"
else
  fail "sentiment field missing or no aggregations"
fi

echo ""
echo "--- Airflow DAGs ---"
if MSYS_NO_PATHCONV=1 docker exec airflow-scheduler airflow dags list 2>/dev/null | grep -q "news_fetch_dag"; then
  ok "news_fetch_dag registered"
else
  fail "news_fetch_dag not found"
fi

if MSYS_NO_PATHCONV=1 docker exec airflow-scheduler airflow dags list 2>/dev/null | grep -q "hello_dag"; then
  ok "hello_dag registered"
else
  fail "hello_dag not found"
fi

echo ""
echo "--- Kafka consumer lag (news-consumer-group) ---"
LAG=$(docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 \
  --describe --group news-consumer-group 2>/dev/null | awk '/news-raw/ {print $6}' | head -1 || echo "")
if [[ -n "${LAG}" && "${LAG}" =~ ^[0-9]+$ ]]; then
  if [[ "${LAG}" -eq 0 ]]; then
    ok "consumer group lag is 0"
  else
    echo "[WARN] consumer lag is ${LAG} — ensure consumer/consumer.py is running"
  fi
else
  echo "[WARN] consumer group not found — start consumer/consumer.py"
fi

echo ""
echo "--- Manual checks ---"
echo "  - Consumer: python consumer/consumer.py (separate terminal)"
echo "  - Kibana:   http://localhost:5601 — dashboard per kibana/README.md"
echo "  - Airflow:  http://localhost:8080 — news_fetch_dag enabled"

if [[ "${FAILED}" -eq 0 ]]; then
  echo ""
  echo "E2E automated checks passed."
  exit 0
else
  echo ""
  echo "E2E automated checks failed."
  exit 1
fi
