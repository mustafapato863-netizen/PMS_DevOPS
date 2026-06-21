# PMS Dashboard

Performance management dashboard for tracking employee KPIs across multiple operational teams. The application combines a FastAPI API, a React frontend, PostgreSQL persistence, Redis caching, Excel ingestion, and Socket.IO notifications.

## Features

- Executive, team, employee, planning, settings, and team-management views
- JWT authentication and role-aware UI/API access
- Employee performance history, KPI breakdowns, trends, and recommendations
- Team rosters, grade distributions, comparisons, targets, and KPI weights
- Excel upload and team-specific data cleaning
- Corrective actions, manager notes, audit history, soft delete, and restore
- Configurable KPI definitions for eight teams
- PostgreSQL repositories, Alembic migrations, Redis caching, and health checks
- Real-time notifications over Socket.IO

## Supported Teams

Team definitions live in `Backend/config/teams/`.

| Team | Region | KPIs | Scoring |
| --- | --- | ---: | --- |
| Inbound | EGY | 5 | Config-driven |
| Outbound | EGY | 4 | Config-driven |
| Sales | EGY | 5 | Config-driven |
| Pre-Approvals IP Offshore | EGY | 3 | Config-driven |
| Inbound UAE | UAE | 3 | Config-driven |
| Pharmacy | UAE | 5 | Uncapped |
| Coding | UAE | 3 | Capped at 100% |
| CSR | UAE | 3 | Capped at 100% |

For a direct KPI, achievement is `(actual / target) * 100`. For an inverse KPI, where lower is better, it is `(target / actual) * 100`. KPI weights, directions, grade thresholds, source columns, and capping behavior are declared in each team's JSON file.

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

## Common Commands

```powershell
# Backend tests
cd Backend
pytest tests -v

# Three-team KPI tests
pytest tests/test_three_teams.py -v

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
| Uploads | `/api/uploads` | list, upload PMS workbook, delete upload |
| Configuration | `/api/config/teams` | list and read team definitions |
| Team management | `/api/team-management` | CRUD, validation, onboarding, statistics |
| Bulk operations | `/api/bulk` | performance records, KPI config, employee deletion |
| Web vitals | `/api/vitals` | frontend telemetry ingestion |

Interactive endpoint schemas are available in Swagger UI at `/docs` while the backend is running.

## Adding a Team

1. Add a validated JSON definition to `Backend/config/teams/`.
2. Add the team cleaner to `Backend/Data_Cleaning_Teams/`.
3. Register the cleaner in `Backend/data_cleaning/cleaner_factory.py`.
4. Add focused configuration, calculation, cleaner, and integration tests.
5. Run the backend suite and verify the team through the configuration API.

## Documentation

- [Project structure](README_PROJECT_STRUCTURE.md)
- [Three-team KPI calculation guide](THREE_TEAMS_KPI_CALCULATION_GUIDE.md)
- [System status](SYSTEM_STATUS.md)
- [Backend notes](Backend/README.md)
