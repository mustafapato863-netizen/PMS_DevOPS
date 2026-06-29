#!/bin/bash
# ==============================================================================
# Production Deployment Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

# Load env configurations
if [ -f .env ]; then
  source .env
fi

ENV_NAME=${ENVIRONMENT:-production}
echo "[INFO] Commencing containerized deployment for environment: ${ENV_NAME}..."

# Ensure we pull the latest images or build them
# Build and run containers via compose/docker-compose.prod.yml
if docker compose -f compose/docker-compose.prod.yml up -d --build; then
  echo "[SUCCESS] Production services compiled and started in background."
  
  # Trigger post-deployment health check
  echo "[INFO] Triggering post-deployment sanity checks..."
  "./scripts/health-check.sh"
else
  echo "[ERROR] Container deployment failed."
  exit 1
fi
