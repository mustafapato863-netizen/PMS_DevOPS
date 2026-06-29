# Incident Response Guide

This document outlines the standard operating procedures (SOPs) for classifying, diagnosing, and resolving critical system incidents on the PMS Dashboard platform.

---

## 1. Severity Classifications

| Severity | Priority | Description | Target Resolution |
| :--- | :--- | :--- | :--- |
| **Severity 1 (P0)** | Critical | Platform is completely inaccessible. Core database connection failure, Redis connection crash loops, or frontend assets unresolvable. | < 1 hour |
| **Severity 2 (P1)** | High | API routes return 500/503 errors. Ingestion pipeline fails, auth session validation blocks users, or scorecard calculations are corrupted. | < 4 hours |
| **Severity 3 (P2)** | Medium | Non-blocking feature failure. Real-time notifications fail to dispatch, settings updates fail to cache, or minor UI loading lag. | < 24 hours |

---

## 2. Emergency Recovery Playbooks

### Playbook A: Server Inaccessible (HTTP 500 / 503)
1. Log into the VPS server.
2. Check active containers: `docker ps`.
3. Inspect system error logs:
   ```bash
   docker compose -f compose/docker-compose.prod.yml logs -f web
   ```
4. If PostgreSQL is offline, check connections and volumes:
   ```bash
   docker compose -f compose/docker-compose.prod.yml logs -f db
   ```
5. If data corruption has occurred, stop stack, restore last validated SQL backup, and restart:
   ```bash
   ./scripts/restore-db.sh backups/pms_backup_latest.sql
   ```

### Playbook B: Infinite WebSocket Reconnection Loop
1. Open Nginx reverse proxy logs:
   ```bash
   docker compose -f compose/docker-compose.prod.yml logs -f nginx
   ```
2. Verify if requests to `/socket.io/` return HTTP 400 or HTTP 403.
3. Ensure CORS settings in `socket_config.py` allow the frontend domain.
4. Restart the WebSocket handler:
   ```bash
   docker compose -f compose/docker-compose.prod.yml restart web
   ```
