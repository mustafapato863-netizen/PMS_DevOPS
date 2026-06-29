#!/bin/bash
# ==============================================================================
# Database Backup Script
# ==============================================================================
set -euo pipefail

# Resolve script directory path context
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Load environment configurations if .env exists
if [ -f ../.env ]; then
  source ../.env
fi

DB_USER=${POSTGRES_USER:-postgres}
DB_NAME=${POSTGRES_DB:-PMS_Sys}
DB_HOST=${POSTGRES_HOST:-localhost}
DB_PORT=${POSTGRES_PORT:-5432}
BACKUP_DIR="../backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/pms_backup_${DB_NAME}_${TIMESTAMP}.sql"

echo "[INFO] Starting database backup for database: ${DB_NAME}..."
mkdir -p "${BACKUP_DIR}"

# Execute pg_dump (expects PGPASSWORD env variable to be set to bypass interactive prompt)
if pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -F p -f "${BACKUP_FILE}"; then
  echo "[SUCCESS] Database backup saved to: ${BACKUP_FILE}"
else
  echo "[ERROR] Database backup execution failed."
  exit 1
fi
