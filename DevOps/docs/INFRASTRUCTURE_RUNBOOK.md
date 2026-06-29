# Infrastructure Runbook

This document describes the procedures for maintaining the PMS Dashboard server infrastructure, database storage, cache nodes, logging rotations, and container setups.

---

## 1. Common Service Control Operations

Commands are executed from the repository root directory on the host VPS:

### Start the Application Stack
```bash
docker compose -f compose/docker-compose.prod.yml up -d
```

### Stop the Application Stack
This stops containers but preserves all persistent volume data:
```bash
docker compose -f compose/docker-compose.prod.yml down
```

### Restart a Specific Service
To restart the FastAPI backend container after a configuration adjust:
```bash
docker compose -f compose/docker-compose.prod.yml restart web
```

### View Live Log Streams
```bash
docker compose -f compose/docker-compose.prod.yml logs -f web
```

---

## 2. Database Maintenance & Ingestions

### Schema Migrations Rollout
When updating databases to the latest version:
```bash
./scripts/migrate.sh
```

### Logical Database Backups
Automated backups run daily at 02:00 AM. To run a manual logical backup:
```bash
./scripts/backup-db.sh
```
*Backups are saved as SQL files under `backups/`.*

### Database Restoration
To restore a snapshot:
```bash
./scripts/restore-db.sh backups/pms_backup_PMS_Sys_20260625_120000.sql
```

---

## 3. Redis Cache Administration

If cache inconsistencies occur:

### Purging All Caches
To flush Redis records completely:
```bash
docker exec -it pms_redis_cache_prod redis-cli FLUSHALL
```

### Inspecting Cache Keys
```bash
docker exec -it pms_redis_cache_prod redis-cli KEYS "*"
```
