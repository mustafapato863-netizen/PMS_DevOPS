# PMS Dashboard

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

## KPI Scoring Model

The PMS scoring engine separates KPI Achievement from KPI Contribution.

KPI Achievement represents real employee performance and may exceed 100%.

KPI Contribution is the capped amount used in the final score calculation.

For every KPI:

```text
Direct KPI Achievement = (actual / target) * 100
Inverse KPI Achievement = (target / actual) * 100
Effective Achievement = min(KPI Achievement, 100)
KPI Contribution = Effective Achievement * KPI Weight
```

The Final Performance Score is the sum of all KPI contributions.

Because each KPI contribution is capped by its configured weight, the Final Performance Score can never exceed 100%.

This scoring model applies consistently across all supported teams.

## Tech Stack

**Backend:** Python 3.11+, FastAPI, Pydantic, SQLAlchemy, Alembic, PostgreSQL, Redis, Pandas, and python-socketio.

**Frontend:** React 19, TypeScript, Vite 8, React Router, TanStack Query, Zustand, Recharts, Tailwind CSS, Zod, and Socket.IO Client.

## Quick Start

### Docker Compose

Docker Compose starts PostgreSQL, Redis, and the backend API:

```bash
docker compose up --build
```

- API: `http://localhost:7860`
- Swagger UI: `http://localhost:7860/docs`
- Health check: `http://localhost:7860/api/health`
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`

The frontend is not included in `docker-compose.yml`; run it separately as described below. The credentials in Compose are development defaults and should be replaced outside local development.

### Local Development

Start the backend:

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

In another terminal, start the frontend:

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

## Documentation

- [Project structure](README_PROJECT_STRUCTURE.md)
- [Database schema and relationships](DATABASE_SCHEMA.md)
- [System status](SYSTEM_STATUS.md)
- [New team onboarding](NEW_TEAM_ONBOARDING.md)
- [Three-team KPI calculation guide](THREE_TEAMS_KPI_CALCULATION_GUIDE.md)
- [Backend notes](Backend/README.md)
