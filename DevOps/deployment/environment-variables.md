# Environment Variables Directory

This document details all configurations, secrets, database parameters, and environment flags used by the PMS Dashboard services.

---

## 1. Backend Service Configuration Variables

The following properties configure the FastAPI application server, database mappings, and logging outputs:

| Variable | Type | Default | Purpose |
| :--- | :--- | :--- | :--- |
| `PORT` | Integer | `7860` | Network port mapped inside containers. |
| `DATABASE_URL` | Connection URL | N/A | PostgreSQL connection string (`postgresql://user:pass@host:5432/db`). |
| `DATABASE_POOL_SIZE` | Integer | `20` | Maximum persistent database connections. |
| `DATABASE_MAX_OVERFLOW`| Integer | `10` | Temporary database connection overflow headroom. |
| `DATABASE_POOL_RECYCLE`| Integer | `1800` | Bumps stale database connections after specified seconds. |
| `REDIS_URL` | Connection URL | N/A | Redis caching instance string (`redis://:pass@host:6379/0`). |
| `JWT_SECRET` | String | N/A | Encryption key used to sign session cookies and JWTs. |
| `JWT_ALGORITHM` | String | `HS256` | Encryption token hashing format. |
| `JWT_EXPIRE_MINUTES` | Integer | `1440` | Token validity lifespan (default 24 hours). |
| `PMS_DATA_DIR` | Directory Path | `/app/data` | Container storage path preserving uploaded sheets. |
| `PMS_DEFAULT_FILE_PATH`| File Path | `/app/data/PMS_Trend_All.xlsx` | Default seed workbook fallback file path. |
| `LOG_LEVEL` | Enum String | `INFO` | Structured logging volume filters (DEBUG/INFO/WARNING/ERROR). |

---

## 2. Frontend Web Portal Variables

Vercel builds static assets and injects the following variables into index bundles:

| Variable | Type | Default | Purpose |
| :--- | :--- | :--- | :--- |
| `VITE_API_BASE_URL` | Endpoint URL | `http://localhost:8000` | Base API target URL for HTTP requests. |
| `VITE_SOCKET_URL` | Endpoint URL | `http://localhost:8000` | Base URL target for WebSocket connections. |

---

## 3. Monitoring & Operations Variables

Variables mapping ports and credentials for monitoring tools:

| Variable | Type | Default | Purpose |
| :--- | :--- | :--- | :--- |
| `PROMETHEUS_PORT` | Integer | `9090` | Host port exposing Prometheus dashboards. |
| `GRAFANA_PORT` | Integer | `3000` | Host port exposing Grafana analytical widgets. |
| GF_SECURITY_ADMIN_USER | String | `admin` | Initial Grafana dashboard administrator user ID. |
| GF_SECURITY_ADMIN_PASSWORD | String | `adminpassword` | Initial Grafana dashboard administrator password. |
| `ENVIRONMENT` | String | `production` | Deploy profile configuration identifier (production/staging/dev). |
| `APP_VERSION` | String | `2.0.0` | Containerized build version tag tracker. |
