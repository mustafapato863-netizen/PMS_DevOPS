#!/bin/bash
# ==============================================================================
# Database Restore Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Load environment configs
if [ -f ../.env ]; then
  source ../.env
fi

DB_USER=${POSTGRES_USER:-postgres}
DB_NAME=${POSTGRES_DB:-PMS_Sys}
DB_HOST=${POSTGRES_HOST:-localhost}
DB_PORT=${POSTGRES_PORT:-5432}

# Require backup path parameter
if [ -z "${1:-}" ]; then
  echo "[ERROR] Missing target backup file parameter. Usage: ./restore-db.sh <backup_file_path>"
  exit 1
fi
BACKUP_FILE="$1"

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "[ERROR] Backup file does not exist at: ${BACKUP_FILE}"
  exit 1
fi

echo "[WARNING] CAUTION: Destructive Action. This operation will overwrite all data inside database '${DB_NAME}'."
read -p "Are you absolutely sure you want to run the database restore? (y/N) " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "[INFO] Restoration execution aborted by user."
  exit 0
fi

echo "[INFO] Restoring database '${DB_NAME}' from: ${BACKUP_FILE}..."

# Execute psql to restore schema/data (expects PGPASSWORD env variable to be set)
if psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${BACKUP_FILE}"; then
  echo "[SUCCESS] Database restored successfully."
else
  echo "[ERROR] Database restoration execution failed."
  exit 1
fi
