#!/bin/bash
# ==============================================================================
# Database Migrations Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Switch directory context to Backend where alembic.ini is situated
cd "${SCRIPT_DIR}/../Backend"

# Load environment configurations
if [ -f .env ]; then
  source .env
fi

echo "[INFO] Executing database migrations to the latest head revision..."

# Run alembic upgrade head
if alembic upgrade head; then
  echo "[SUCCESS] Schema migrations applied successfully."
else
  echo "[ERROR] Schema migrations failed to execute."
  exit 1
fi
