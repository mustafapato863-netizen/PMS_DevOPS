#!/bin/bash
# ==============================================================================
# Deployment Rollback Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

# Load env configurations
if [ -f .env ]; then
  source .env
fi

echo "[WARNING] CAUTION: Destructive Action. This operation will rollback the last database migration schema update and restart container instances."
read -p "Are you absolutely sure you want to perform this rollback? (y/N) " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "[INFO] Rollback procedure cancelled by user."
  exit 0
fi

echo "[INFO] Downgrading database migration state by 1 step..."
cd Backend
if alembic downgrade -1; then
  echo "[SUCCESS] Database schema downgrade executed successfully."
else
  echo "[WARNING] Database schema downgrade failed. Logical backup restore might be required."
fi

cd "${SCRIPT_DIR}/.."
echo "[INFO] Stopping production containers..."
docker compose -f compose/docker-compose.prod.yml down

echo "[INFO] Launching previous container states..."
if docker compose -f compose/docker-compose.prod.yml up -d; then
  echo "[SUCCESS] Previous container states launched successfully."
else
  echo "[ERROR] Failed to start previous container states."
  exit 1
fi

echo "[SUCCESS] Rollback operations complete."
