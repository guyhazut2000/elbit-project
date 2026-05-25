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
