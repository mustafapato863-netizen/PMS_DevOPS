# PMS Dashboard — DevOps Platform Repository

This repository hosts all infrastructure-as-code, docker container definitions, proxy setups, database scripts, monitoring configurations, and operational runbooks for the PMS Dashboard platform.

The active application now includes a modular Balanced Scorecard workspace for Managerial and Corporate levels. The older standalone HTML reference and session checklist files have been removed from the live docs flow.

---

## 1. Repository Structure

```
PMS-DevOps/
├── .env.example              - Environment configuration template.
├── README.md                 - This operations overview guide.
│
├── compose/                  - Docker Compose files for all environments.
│   ├── docker-compose.dev.yml
│   ├── docker-compose.staging.yml
│   └── docker-compose.prod.yml
│
├── docker/                   - Target Dockerfiles.
│   ├── Dockerfile.backend
│   └── Dockerfile.frontend
│
├── nginx/                    - Proxy configurations.
│   ├── nginx.conf
│   └── sites/
│       └── pms.conf
│
├── monitoring/               - Telemetry configurations.
│   ├── prometheus/
│   │   └── prometheus.yml
│   ├── grafana/
│   │   ├── dashboards/
│   │   └── provisioning/
│   └── loki/
│       └── loki-config.yml
│
├── scripts/                  - Operational automation scripts.
│   ├── deploy.sh
│   ├── migrate.sh
│   ├── backup-db.sh
│   ├── restore-db.sh
│   ├── health-check.sh
│   └── rollback.sh
│
├── deployment/               - Cloud and self-hosted deploy guides.
│   ├── railway.md
│   ├── vercel.md
│   ├── self-hosted-vps.md
│   ├── environment-variables.md
│   └── production-checklist.md
│
├── backups/                  - Logical database sql backup target.
│   └── .gitkeep
│
├── restore/                  - Database sql restoration files target.
│   └── .gitkeep
│
└── docs/                     - System architecture and incident runbooks.
    ├── GIT_WORKFLOW.md
    ├── INFRASTRUCTURE_RUNBOOK.md
    ├── INCIDENT_RESPONSE.md
    └── RELEASE_PROCESS.md
```

---

## 2. Integration with Application Repositories

The PMS Dashboard employs a multi-repository approach:
- **`PMS-Frontend`**: Contains the React single-page portal. Deployed on **Vercel CDN edges** for global file delivery.
- **`PMS-Backend`**: Contains the FastAPI API logic and database migrations. Deployed on **Railway** container runtimes.
- **`PMS-DevOps`** (This Repository): Houses all common orchestration configurations, local developer setups, backups, monitoring alerts, and deployment scripts.

---

## 3. Deployment Runbooks

### A. Local Development Compose
To quickly spin up database, cache, and backend APIs for local coding:
```bash
docker compose -f compose/docker-compose.dev.yml up -d
```

### B. Production Deployment (Self-Hosted VPS)
To deploy the entire stack (including Nginx proxy, prometheus, and grafana) to a production node:
```bash
# Clone DevOps repository, configure .env, then run:
./scripts/deploy.sh
```

### C. Backup, Migrations, and Restores
- **Backup DB:** `./scripts/backup-db.sh`
- **Restore DB:** `./scripts/restore-db.sh backups/pms_backup_latest.sql`
- **Migrations:** `./scripts/migrate.sh`
- **Rollback:** `./scripts/rollback.sh`

### Balanced Scorecard Notes
- BSC implementation lives in the React frontend, not in this repository.
- The old demo/reference artifacts were retired after the modular workspace landed in the main app.
