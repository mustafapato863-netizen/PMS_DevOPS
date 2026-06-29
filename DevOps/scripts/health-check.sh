#!/bin/bash
# ==============================================================================
# Health Check Verification Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

# Load env configurations
if [ -f .env ]; then
  source .env
fi

APP_PORT=${PORT:-7860}
HOST="http://localhost:${APP_PORT}"
ENDPOINT="${HOST}/api/health/readiness"

echo "[INFO] Querying system readiness check endpoint: ${ENDPOINT}..."

# Wait and query for up to 30 seconds (6 attempts with 5s sleep)
for i in {1..6}; do
  # Use curl with silent output and HTTP status assertion
  if curl -s -f "${ENDPOINT}" > /dev/null; then
    echo "[SUCCESS] System is healthy and ready to receive traffic."
    exit 0
  else
    echo "[INFO] Service is bootstrapping. Retrying in 5 seconds (attempt $i/6)..."
    sleep 5
  fi
done

echo "[ERROR] Readiness check failed. Service returned unhealthy state or is unreachable."
exit 1
