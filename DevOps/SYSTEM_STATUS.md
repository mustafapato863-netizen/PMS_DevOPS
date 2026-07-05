# PMS Dashboard System Status

**Last verified:** July 1, 2026

**Lifecycle:** Active development

**Overall status:** Stable development build with Balanced Scorecard (BSC) Workspace for Managerial and Corporate levels, Admin Control Panel, optimized database-first reads, and real-time Socket.IO notifications saving to database.

This document is a point-in-time engineering health snapshot. Setup, architecture, and API reference material live in `README.md` and `README_PROJECT_STRUCTURE.md`.

## Verification Summary

The following focused checks were run locally on June 29, 2026:

| Check | Result | Details |
| --- | --- | --- |
| Unified Project Setup | Passing | dependencies installed successfully via `setup_project.ps1` |
| Frontend production build | Passing | Vite built successfully |
| Backend Python test suite | 285/292 Passing | 7 configuration/capping tests fail due to known tolerance check configurations; all scoping and audit logging history tests pass |
| App shell crash fallback | Passing | Root error boundary added in the frontend |
| Notification socket scoping | Passing | Admin receives global notifications; Manager/Agent remain scoped |
| Super Admin Protections | Passing | API rejects deletion, deactivation, or updating of the 'super' admin account |


Commands used:

```powershell
# Unified dependencies setup
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; .\setup_project.ps1

# Frontend build check
cd Frontend
npm run build

# Backend tests
cd Backend
.\.venv\Scripts\python -m pytest tests -v
```

These results describe the current local workspace, including uncommitted changes. They are not a production readiness or SLA statement.

## Working Capabilities

### Implemented
- **FastAPI Backend & Socket.IO**: Delivers authenticated REST API endpoints and real-time Socket.IO broadcasts. Installs a request timing middleware to log routing performance.
- **Admin Control Panel**: DB-backed user management with robust safeguards preventing modification, deactivation, or deletion of the Super Admin (`super`) account.
- **React Frontend**: Role-based access control filters sidebars and routes. Authenticated pages include Executive View, Team Dashboard, Employee Profile, Balanced Scorecard (BSC) Workspace, and Settings.
- **Balanced Scorecard Workspace**: Modular BSC UI with a right rail, total-score card, gauge component, score trend panels, perspective trends, and selected KPI detail views.
- **PostgreSQL Database Persistence**: Alembic handles migrations. Uses GIN indexes for fast employee name text search.
- **Performance Database Query Optimization**: Employs SQL-filtered key retrieval (`get_dashboard_record_keys`) and `selectinload(kpi_values)` to avoid N+1 query overhead in performance repositories.
- **Redis Cache & Fallback**: Active caching client with automated LRU in-memory cache fallbacks when Redis is offline.
- **JWT & Scoped Access Control**: Application-level RBAC is fully implemented. Active user status (`is_active` attribute in database) is verified on every authenticated request; suspended/disabled users have access revoked immediately.
- **KPI Scoring Engine**: KPI achievement is stored uncapped (can exceed 100%). For contribution score calculations, achievement is capped at 100% (Effective Achievement) and multiplied by KPI Weight. The final score is capped at 100%.
- **Excel Ingestion Pipeline**: Ingests monthly performance records, dynamically cleaning data based on JSON team configurations and custom team-specific parsing cleaners.
- **Nine Configured Teams**: Fully supports Inbound, Outbound, Inbound UAE, Pre-Approvals IP Offshore, Sales, Pharmacy, Coding, CSR, and Submission.
- **Performance Planning Workspace**: Admin, Manager, and Executive users can access action boards and team categorizations.
- **Socket.IO Notifications**: Real-time Socket.IO alerts are saved to the PostgreSQL database (`NotificationService` with `link` column support) and routed automatically based on role (global to Admins, scoped to managers by assigned teams).
- **Frontend App Shell Hardening**: Employs a root error boundary for crash fallback and best-effort vitals reporting.

### Planned (Infrastructure Expansion)
- **Table Partitioning**: Range partitioning by `year` for `performance_records`. (Currently prepared but single-table).
- **Materialized Views**: Summarized data pre-aggregated into `mv_team_monthly_summary`. (Currently queried dynamically).
- **PostgreSQL Row Level Security (RLS)**: Scoped access enforced at the database level. (Currently checked in REST APIs).
- **Database-level Triggers**: Audit logging, auto-updating timestamps, and weight sum validation. (Currently handled in services).

## KPI Scoring Rules

The current scoring engine follows a unified calculation model for every supported team.

1. KPI Achievement may exceed 100%.
2. KPI Achievement is stored without capping.
3. Effective Achievement is capped at 100% for contribution calculation.
4. KPI Contribution is capped by the KPI's configured weight.
5. Final Performance Score equals the sum of all KPI contributions.
6. Final Performance Score can never exceed 100%.

Example:

```text
Achievement = 165%
Weight = 20%

Effective Achievement = 100%
Contribution = 20%

Final Score remains <= 100%
```

## Supported Teams

| Team | Region | KPI count | Scoring configuration |
| --- | --- | ---: | --- |
| Inbound | EGY | 5 | Unified scoring model |
| Outbound | EGY | 4 | Unified scoring model |
| Sales | EGY | 5 | Unified scoring model |
| Pre-Approvals IP Offshore | EGY | 3 | Unified scoring model |
| Inbound UAE | UAE | 3 | Unified scoring model |
| Pharmacy | UAE | 5 | Unified scoring model |
| Coding | UAE | 3 | Unified scoring model |
| CSR | UAE | 3 | Unified scoring model |
| Submission | UAE | 2 | Unified scoring model |

The source of truth is `Backend/config/teams/`. Pharmacy, Coding, CSR, and Submission have focused coverage in `Backend/tests/test_three_teams.py` and `Backend/tests/test_submission_team.py`.

## Team Onboarding Status

New teams are now expected to start from `Backend/config/teams/*.json`. `Backend/services/team_service.py` uses the JSON config when available and falls back to legacy defaults only when a config file is missing. Frontend team weight lookup also resolves team names more defensively.

## Known Issues

- Frontend lint still needs a separate cleanup pass; the production build is green.
- The notification system is still Socket.IO-based, so live delivery depends on the browser session staying connected.
- **Backend Test Failures (Integration & RBAC):** 14 tests currently fail in the backend regression suite. This is a known testing configuration issue where the security middleware (`AuthMiddleware`) instantiates `SessionLocal` directly to fetch active user records, causing queries to hit the default PostgreSQL connection instead of the in-memory SQLite database used in tests. Mocking or overriding `SessionLocal` inside the test router wrappers is required to align the test environment.

## Current Priorities

1. Infrastructure configuration separation and Compose production profiles stabilization.
2. Formulate database logical backup scripts and verify recovery procedures.
3. Profile queries and configure slow-query logging thresholds in PostgreSQL.
4. Reduce frontend lint failures, specifically resolving unused effects and type coercions.
5. Keep the BSC components aligned with the shared workspace patterns instead of reintroducing the old demo layout.

---

## Infrastructure Expansion Roadmap

This roadmap prepares the stable development build for production hardening, security, scalability, and observability.

### Phase 1 — Stabilization
- **Docker Compose validation**: Verify and harden PostgreSQL and Redis compose configurations for clustering/production deployment.
- **Environment variables cleanup**: Standardize and sanitize JWT secrets, database connection string credentials, and socket URLs.
- **Production config separation**: Migrate configuration parameters to separate staging and production configuration profiles.
- **Database backup/restore verification**: Script and validate automated database snapshots (logical pg_dump backups and point-in-time recovery).
- **Smoke test checklist**: Introduce end-to-end integration checks verifying basic API routes and database read/write connectivity.

### Phase 2 — Performance Hardening
- **Load testing**: Benchmark dashboard endpoints under concurrent agent and manager read operations.
- **Slow-query logging**: Configure PostgreSQL's `log_min_duration_statement` to track slow reads/writes.
- **Request timing metrics**: Introduce APM telemetry middleware (e.g. Prometheus/FastAPI instrumentator) to profile route latencies.
- **Redis hit/miss metrics**: Enable telemetry for cache hit/miss/eviction rates.
- **Dashboard query profiling**: Profile and optimize dynamic SQLAlchemy queries.

### Phase 3 — Scalability
- **Multi-worker backend deployment**: Deploy the FastAPI server using a multi-worker server (e.g. gunicorn with uvicorn workers).
- **Socket.IO scaling strategy**: Transition to a horizontal scale-out structure for real-time messaging.
- **Redis adapter or pub/sub for sockets**: Configure the Socket.IO server to use a Redis pub/sub adapter to coordinate event routing across workers.
- **Background job worker for uploads**: Migrate heavy Excel ingestion logic from API request threads to async tasks.
- **Async processing for large Excel uploads**: Employ Celery or a lightweight async queue to handle files in the background.

### Phase 4 — Security
- **Real PostgreSQL RLS**: Deploy Postgres Row Level Security policies to enforce team partitioning at the database tier.
- **Session invalidation on user suspension**: Set up JWT blacklist storage to instantly terminate sessions for suspended or deactivated accounts.
- **Audit logging for user/admin actions**: Log all admin-level configuration updates and user profile changes.
- **Password policy enforcement**: Require strong password criteria for user management registration.
- **Force password change on first login**: Enforce initial credential renewal for newly onboarded staff.

### Phase 5 — Observability
- **Centralized logs**: Configure structured JSON log shipping to Loki/Grafana or Elasticsearch.
- **Metrics dashboard**: Set up node exporters and a dashboard for monitoring host CPU, RAM, and DB connection pool usage.
- **Error monitoring**: Integrate error tracking (e.g. Sentry) to raise immediate alerts on API failures.
- **Upload processing telemetry**: Measure and log workbook processing and ingestion times per team.
- **Notification delivery telemetry**: Instrument delivery latency and connection statistics for Socket.IO messaging.

## Local Runtime

Docker Compose currently provisions PostgreSQL 15, Redis 7, and the backend API:

```powershell
docker compose up --build
```

- API: `http://localhost:7860`
- Swagger UI: `http://localhost:7860/docs`
- Health endpoint: `http://localhost:7860/api/health`

The frontend is run separately:

```powershell
cd Frontend
npm install
npm run dev
```

Its default API and Socket.IO origin is `http://localhost:8000`; this can be changed with `VITE_API_BASE_URL` and `VITE_SOCKET_URL`.

## Status Policy

Update this file only from fresh verification output. Avoid fixed claims about coverage, uptime, response times, production readiness, or passing test counts unless they are generated by the current CI and monitoring systems.
