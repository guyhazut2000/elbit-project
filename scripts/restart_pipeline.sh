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
