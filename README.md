# PMS Dashboard

| Metadata | Value |
| :--- | :--- |
| **Current Version** | `v0.8.2-stable` |
| **Project Status** | `Ready for Infrastructure Hardening` |
| **Last Updated** | June 2026 |
| **Last Verified** | June 2026 |

Performance management dashboard for tracking employee KPIs across multiple operational teams. The application combines a FastAPI API, a React frontend, PostgreSQL persistence, Redis caching, Excel ingestion, and Socket.IO notifications.

## Features

- Executive, team, employee, planning, settings, and team-management views
- JWT authentication and role-aware UI/API access
- Employee performance history, KPI breakdowns, trends, and recommendations
- Team rosters, grade distributions, comparisons, targets, and KPI weights
- Excel upload and team-specific data cleaning
- Corrective actions, manager notes, audit history, soft delete, and restore
- Configurable KPI definitions for nine teams, with config-driven onboarding for new teams
- PostgreSQL repositories, Alembic migrations, Redis caching, and health checks
- DB-backed user administration under Settings > Users
- Real-time notifications over Socket.IO with Admin/global delivery and Manager/Agent scoping

## Supported Teams

Team definitions live in `Backend/config/teams/`.

| Team | Region | KPIs | Scoring |
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

## Tech Stack

**Backend:** Python 3.11+, FastAPI, Pydantic, SQLAlchemy, Alembic, PostgreSQL, Redis, Pandas, and python-socketio.

**Frontend:** React 19, TypeScript, Vite 8, React Router, TanStack Query, Zustand, Recharts, Tailwind CSS, Zod, and Socket.IO Client.

## KPI Scoring Model

The PMS scoring engine separates KPI Achievement from KPI Contribution.

- **KPI Achievement** represents real employee performance and may exceed 100%.
- **KPI Contribution** is the capped amount used in the final score calculation. It can never exceed the KPI's configured weight.
- **Final Performance Score** is the sum of all KPI contributions and is capped at 100%.

For every KPI:

```text
Direct KPI Achievement = (actual / target) * 100
Inverse KPI Achievement = (target / actual) * 100
Effective Achievement = min(KPI Achievement, 100)
KPI Contribution = Effective Achievement * KPI Weight
```

*Example:* If a KPI has a weight of 10% and the employee achieves 150% performance, the contribution is capped at 10% (not 15%). The final score is the sum of all contributions, capped at 100%.

This scoring model applies consistently across all supported teams.

## Dashboard Data & Month Behavior

### Dashboard Month Filter
- Dashboards default to the **latest available month** containing performance data.
- **All Months** remains available as an explicit user selection in the dropdown.
- When **All Months** is selected, metrics (scores, averages, grade distributions) are aggregated across all selected months.
- *Headcount Interpretation:* When Month = All, the headcount represents repeated monthly records (e.g. 1 agent active for 5 months = 5 records). To avoid confusion, the "Total Agents" card defaults to the headcount of the latest month only and shows a warning footnote (e.g., "Current headcount based on May") explaining this context.

### Dashboard Data Path
- **DB-First Architecture:** Performance reads on the dashboard are read-path database first. The dashboard queries the PostgreSQL database via SQLAlchemy models, utilizing local JSON repository files purely as a fallback when database records are unavailable.
- **QueryOptimizer** [Implemented / Not Primary Path]: An optimized database query pipeline leveraging Redis caching is implemented and tested, but is not used as the primary path in active routes to avoid potential schema incompatibilities.

## Security & User Access Control
- **User Suspension & Session Security:** Suspended or disabled users (`is_active = false` in the database) immediately lose active API access. The backend verifies the user's active status on every authenticated request; the frontend localStorage session token alone is not sufficient authority to access routes.
- **Application-level RBAC:** Scoped role access (Admin, Manager, Executive, Viewer) is enforced in the API routes. 
- **Database Row Level Security (RLS)** [Planned]: Policies restricting manager views to their assigned teams are planned for future deployment (not yet active in migrations).

## Upload & Data Quality Rules
- **Employee Code Format:** For *Inbound*, *Outbound*, and *Pre-Approvals IP Offshore* teams, employee codes must use SGHD-prefixed HR identifiers (e.g., `SGHD70170`). 
- **Upload Normalization & Validation** [Planned]: Automatic rejection or normalization of non-SGHD employee codes for these specific teams is planned. Prevention of duplicate employee/month/team records is also planned as a data-quality hardening feature.

## Quick Start

### Docker Compose

Docker Compose starts PostgreSQL, Redis, and the backend API:

```bash
docker compose -f DevOps/compose/docker-compose.dev.yml up --build
```

- API: `http://localhost:7860`
- Swagger UI: `http://localhost:7860/docs`
- Health check: `http://localhost:7860/api/health`
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`

The frontend is not included in the compose setup; run it separately as described below. The credentials in Compose are development defaults and should be replaced outside local development.

### Local Development

#### Unified Setup (Recommended)
You can set up both backend and frontend dependencies automatically by running the unified setup script from the root directory:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; .\setup_project.ps1
```

#### Manual Setup

**Start the backend:**

```powershell
cd Backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
alembic upgrade head
uvicorn app:app --reload --port 8000
```

Configure the backend with environment variables as needed:

```dotenv
DATABASE_URL=postgresql://postgres:password123@localhost:5432/PMS_Sys
REDIS_URL=redis://localhost:6379/0
JWT_SECRET=replace-with-a-secure-secret
```

**In another terminal, start the frontend:**

```powershell
cd Frontend
npm install
npm run dev
```

The frontend defaults to `http://localhost:8000` for API and Socket.IO connections. Override this with `VITE_API_BASE_URL` and `VITE_SOCKET_URL`.

The frontend app shell now includes a root error boundary, and web-vitals reporting is best-effort so a missing `/api/vitals` endpoint does not break the UI.

## Common Commands

```powershell
# Backend tests
cd Backend
pytest tests -v

# Three-team KPI tests
pytest tests/test_three_teams.py -v

# Submission team tests
pytest tests/test_submission_team.py -v

# Frontend checks and production build
cd ..\Frontend
npm run lint
npm run build
```

## API Overview

All API routes are mounted under `/api`.

| Area | Base path | Examples |
| --- | --- | --- |
| Authentication | `/api/auth` | `POST /login`, `POST /logout` |
| Health | `/api/health` | `GET /api/health` |
| Performance | `/api/performance` | records, employee/team/grade/status queries, planning, insights, export |
| Employees | `/api/employee` | list, search, create, update, soft delete, restore, notes, actions |
| Team actions | `/api/team-actions` | list and create team actions |
| Settings | `/api/settings` | KPI weights and targets |
| Users | `/api/users` | DB-backed user management and login |
| Uploads | `/api/uploads` | list, upload PMS workbook, delete upload |
| Configuration | `/api/config/teams` | list and read team definitions |
| Team management | `/api/team-management` | CRUD, validation, onboarding, statistics |
| Bulk operations | `/api/bulk` | performance records, KPI config, employee deletion |
| Web vitals | `/api/vitals` | frontend telemetry ingestion |

Interactive endpoint schemas are available in Swagger UI at `/docs` while the backend is running.

## Adding a Team

1. Add a validated JSON definition to `Backend/config/teams/`.
2. Add the team cleaner to `Backend/Data_Cleaning_Teams/` if the Excel layout is unique.
3. Register the cleaner in `Backend/data_cleaning/cleaner_factory.py` only when auto-discovery does not pick it up.
4. Verify the team through `/api/config/teams`, `/api/team-management/teams`, and `/api/settings/weights`.
5. Add focused configuration, calculation, cleaner, and integration tests.
6. Run the focused backend tests and frontend build before merge.

## Documentation Index

### Root Reference Guides
- [Project Layout & Structure Summary](DevOps/README_PROJECT_STRUCTURE.md)
- [Database Entity Schema & Relationships](DevOps/DATABASE_SCHEMA.md)
- [System Status & Verification Checks](DevOps/SYSTEM_STATUS.md)
- [New Team Onboarding Flow](NEW_TEAM_ONBOARDING.md)
- [Three-Team KPI Calculation Guide](THREE_TEAMS_KPI_CALCULATION_GUIDE.md)
- [Backend Development Notes](Backend/README.md)

### Architectural Deep-Dives
- [System Architecture](DevOps/docs/Architecture.md) — Multi-tier dataflow, ORM access patterns, and fallback logic.
- [Backend Portal Rules](DevOps/docs/Backend.md) — FastAPI configurations, authentication, dependency injection, and data seeding.
- [Frontend Portal Design](DevOps/docs/Frontend.md) — Routes, role-based sidebars, Zustand stores, hooks, and error containment.
- [Infrastructure Specifications](DevOps/docs/Infrastructure.md) — Composite index mappings, Redis cache schemas, and local run configurations.
- [Security Enforcement Matrix](DevOps/docs/Security.md) — JWT lifecycle rules, user deactivation checks, and RBAC tables.
- [Production Deployment Specs](DevOps/docs/Deployment.md) — Gunicorn/Nginx settings, automated backups, and metric reporting.
- [Excel Upload Ingestion Pipeline](DevOps/docs/UploadPipeline.md) — Excel cleaners, transaction scopes, audits, and rollback logic.
- [Dashboard Visual Workflow](DevOps/docs/DashboardFlow.md) — Aggregation scripts, month filters, and headcount warnings.
- [Real-Time Notification Architecture](DevOps/docs/NotificationArchitecture.md) — Socket.IO rooms, reconnection events, and scale-out plans.
- [KPI Scoring engine Formulas](DevOps/docs/KPIScoringEngine.md) — Target/actual equations, weight capping rules, and grading scripts.
- [API Reference Guide](DevOps/docs/API_REFERENCE.md) — Detailed specifications for all REST endpoints, requests, responses, and validations.
- [Troubleshooting & Runbook](DevOps/docs/TROUBLESHOOTING.md) — Diagnosis and resolution runbooks for common system issues.
- [Changelog History](DevOps/docs/CHANGELOG.md) — Semantic version records of major milestones and development iterations.
- [Performance Optimization Guide](DevOps/docs/PERFORMANCE.md) — Index configurations, server-side caching, slow-query roadmaps, and load benchmarks.
- [Frontend Bootstrapping Flow](DevOps/docs/BOOTSTRAP_FLOW.md) — Sequence charts of initialization gates, profiles mapping, and WebSocket setup.
- [Database Schema ERD](DevOps/docs/DATABASE_ERD.md) — Mermaid ER diagram mapping entities, keys, and relational cardinality.
- [Request Execution Lifecycle](DevOps/docs/REQUEST_LIFECYCLE.md) — Sequence charts tracing client queries through middlewares, cache, and database layers.
- [Architecture Decision Records (ADRs)](DevOps/docs/ADR.md) — Design logs ADR-001 through ADR-007.
- [Project Milestones Roadmap](DevOps/docs/Roadmap.md) — Completed milestones, active tasks, and upcoming goals.
- [Git Workflow Branching Strategy](DevOps/docs/GIT_WORKFLOW.md) — Multi-repository layout structure, release candidate promotions, and tag conventions.
- [Infrastructure Operations Runbook](DevOps/docs/INFRASTRUCTURE_RUNBOOK.md) — Common command scripts, database maintenance, and cache flushes.
- [Incident Response SOPs](DevOps/docs/INCIDENT_RESPONSE.md) — Severity classifications and emergency playbooks.
- [Release Process Guidelines](DevOps/docs/RELEASE_PROCESS.md) — Branch freezes, QA verification checks, and semantic tags.

---

## Infrastructure Hardening Roadmap

For a detailed visual gantt chart and concrete phase items, see the [Roadmap](DevOps/docs/Roadmap.md) guide.
