# Self-Hosted VPS Deployment Guide

This guide documents the procedures for deploying the PMS Dashboard stack on a self-hosted Virtual Private Server (VPS) using Docker Compose and Nginx.

---

## 1. Deployment Model & Architecture

A self-hosted deployment runs all tiers (Database, Cache, API, Reverse Proxy, and Telemetry Monitoring) on a single Virtual Private Server (VPS) or server cluster.

```
                  Web Client Request (Port 80 / 443)
                                 |
                                 v
                            [Nginx Proxy]
                                 |
           +---------------------+---------------------+
           |                                           |
           v (Port 80)                                 v (Port 7860)
  [Static React Files]                          [FastAPI Backend]
                                                       |
                                            +----------+----------+
                                            |                     |
                                            v                     v
                                      [PostgreSQL]             [Redis]
```

---

## 2. Prerequisites
- A VPS running Ubuntu 20.04/22.04 LTS (minimum 2 Core CPU, 4GB RAM).
- Docker and Docker Compose installed:
  - Docker v20.10+
  - Docker Compose v2.0+
- A domain name pointing to the VPS public IP address.
- Port 80 and 443 open on the network firewall.

---

## 3. Provisioning Steps

1. **Clone the DevOps Workspace:**
   ```bash
   git clone https://github.com/PMS-Dashboard/PMS-DevOps.git /opt/pms-devops
   cd /opt/pms-devops
   ```

2. **Configure Environment variables:**
   Create a `.env` file from the template and edit it:
   ```bash
   cp .env.example .env
   nano .env # Set database passwords, JWT secrets, and ports
   ```

3. **Establish Scripts Permissions:**
   ```bash
   chmod +x scripts/*.sh
   ```

4. **Run Ingestion and Compilation Deployments:**
   ```bash
   ./scripts/deploy.sh
   ```

5. **Verify Stack Container health checks:**
   ```bash
   docker compose -f compose/docker-compose.prod.yml ps
   ```

---

## 4. Backups and Logging Maintenance
- Backups are stored under `/opt/pms-devops/backups/`. Add `scripts/backup-db.sh` to a daily cron tab scheduler to automate snapshots.
- Logger rotated trace files reside under the backend's `/app/logs/` directories inside the container.
