# PMS Dashboard Project Structure

This guide maps the current repository and explains where the main application responsibilities live. For installation and everyday commands, see [README.md](README.md).

## Architecture

```text
React + TypeScript frontend
        |
        | HTTP / Socket.IO
        v
FastAPI API and middleware
        |
        +-- services and processors
        +-- repositories
        +-- SQLAlchemy models
        |
        +-- PostgreSQL
        +-- Redis
        +-- JSON seed/fallback data
```

The backend entry point is `Backend/app.py`. It mounts the API below `/api`, installs authentication, error-handling, and CORS middleware, seeds database data and permissions during startup, and wraps FastAPI with the Socket.IO ASGI application.

The frontend entry point is `Frontend/src/main.tsx`; routes and application providers are composed in `Frontend/src/App.tsx`.

## Repository Layout

```text
PMS_Dashboard/
|-- Backend/
|   |-- api/
|   |   |-- middleware/          # Authentication, RBAC, error handling
|   |   `-- routers/             # FastAPI route modules
|   |-- config/
|   |   |-- teams/               # JSON KPI definitions used for team onboarding
|   |   |-- database.py          # SQLAlchemy engine and sessions
|   |   |-- loader.py            # Team configuration loading/validation
|   |   |-- logging_config.py    # Structured logging
|   |   `-- socket_config.py     # Socket.IO server
|   |-- Data_Cleaning_Teams/     # Team-specific Excel cleaners
|   |-- data_cleaning/           # Shared cleaning base, mappings, factory
|   |-- data/                     # JSON seed/fallback application data
|   |-- exports/                  # Report export support
|   |-- migrations/              # Alembic environment and revisions
|   |-- models/                  # ORM models and API schemas
|   |-- processors/              # Excel processing orchestration
|   |-- repositories/            # Database and JSON data access
|   |-- scripts/                 # JSON-to-database migration scripts
|   |-- services/                # Application and domain logic
|   |-- tests/                   # Backend unit and integration tests
|   |-- app.py                   # FastAPI/Socket.IO application
|   |-- alembic.ini              # Migration configuration
|   |-- Dockerfile               # Backend container image
|   `-- requirements.txt         # Pinned backend dependencies
|-- Database/                    # SQL schema reference documents (pms_scheme.sql)
|-- Frontend/
|   |-- public/                  # Static public assets
|   |-- src/
|   |   |-- components/          # Common, chart, employee, team UI
|   |   |-- constants/           # Shared constants
|   |   |-- context/             # Auth, role, and theme providers
|   |   |-- data/                # Bundled frontend data
|   |   |-- hooks/               # Query, URL, store, and socket hooks
|   |   |-- lib/                 # API client and query client
|   |   |-- pages/               # Route-level views
|   |   |-- schemas/             # Zod validation schemas
|   |   |-- services/            # Frontend analytics helpers
|   |   |-- store/               # Zustand state
|   |   |-- App.tsx              # Providers, guards, and routes
|   |   |-- config.ts            # API and Socket.IO URLs
|   |   `-- main.tsx             # Browser entry point
|   |-- package.json             # Scripts and dependencies
|   `-- vite.config.ts           # Vite configuration
|-- DATABASE_SCHEMA.md           # Database schema and relationships reference
|-- docker-compose.yml           # PostgreSQL, Redis, backend
|-- README.md                    # Setup and feature overview
|-- README_PROJECT_STRUCTURE.md  # This guide

```

Generated logs, caches, virtual environments, package installations, and build outputs are omitted from the map.

## Backend Modules

### API Layer

`Backend/api/routers/__init__.py` assembles the route modules:

| Module | Responsibility |
| --- | --- |
| `auth.py` | Login and logout |
| `performance.py` | Performance queries, planning, insights, and exports |
| `employee.py` | Employee CRUD, search, restore, notes, and actions |
| `team.py` | Team actions |
| `settings.py` | KPI weights and targets |
| `upload.py` | PMS workbook uploads |
| `config.py` | Team configuration discovery |
| `team_management.py` | Team CRUD, validation, and onboarding |
| `bulk_operations.py` | Bulk records, KPI updates, and employee deletion |
| `health.py` | Database/cache health reporting |
| `vitals.py` | Frontend web-vitals ingestion |
| `users_and_actions.py` | DB-backed users and corrective actions |

### Service and Data Layers

- `services/` contains authentication, employee, performance, KPI, planning, learning, insights, caching, auditing, versioning, onboarding, health, and notification logic.
- `repositories/` isolates SQLAlchemy and JSON access from the service layer.
- `models/models.py` and `models/team_models.py` define persistence models; `models/schemas.py` defines request and response schemas.
- `migrations/versions/` contains the Alembic revision history.
- `data/` supplies seed or fallback JSON records. Treat these files as application data, not test fixtures.

### KPI and Excel Pipeline

```text
Excel workbook
  -> ExcelProcessor
  -> CleanerFactory
  -> team-specific cleaner
  -> normalized KPI values
  -> KPIService calculation and grading
  -> repository/database storage
```

Shared cleaning behavior lives in `Backend/data_cleaning/`. Individual cleaners live in `Backend/Data_Cleaning_Teams/`. The cleaner factory maps configured team names to their processing functions.

Each file in `Backend/config/teams/` declares:

- Team name and region
- Employee ID and name source columns
- Grade thresholds
- KPI keys, labels, weights, units, and colors
- Actual and target source columns
- KPI metadata including configuration properties (KPI direction, weight, keys). Runtime scoring follows the unified scoring model:
  - KPI Achievement preserves the employee's real performance and may exceed 100%.
  - Effective Achievement is capped at 100% for contribution calculation.
  - KPI Contribution is calculated from Effective Achievement and KPI Weight.
  - A KPI Contribution can never exceed its configured weight share.
  - Final Performance Score is the sum of all KPI contributions and can never exceed 100%.

New team onboarding stays config-first:

1. Add the team JSON config.
2. Add a cleaner only if the workbook shape differs.
3. Let `Backend/services/team_service.py` build the database payload from config when available.
4. Verify discovery through the config and team-management APIs.

## Frontend Modules

The authenticated route tree in `Frontend/src/App.tsx` includes:

| Route | View | Access |
| --- | --- | --- |
| `/executive` | Executive summary | Authenticated users |
| `/team/:teamId` | Team dashboard | Authenticated users |
| `/employee/:employeeId` | Employee profile | Authenticated users |
| `/planning` | Planning workspace | Admin, Manager, Executive |
| `/team-management` | Team administration | Admin |
| `/settings` | Settings | Authenticated users |
| `/api/users` | User management | Admin only |

Unauthenticated users are redirected to `/login`. `/operational` redirects to `/team/all`.

Data access is centered on `src/lib/apiClient.ts`, TanStack Query hooks under `src/hooks/api/`, and the central URLs in `src/config.ts`. Socket hooks handle real-time updates and notifications, with Admin sessions subscribing to the global notification stream and Manager/Agent sessions staying scoped to assigned access.

## Configuration

Common backend environment variables:

| Variable | Purpose |
| --- | --- |
| `DATABASE_URL` | PostgreSQL SQLAlchemy connection URL |
| `REDIS_URL` | Redis connection URL |
| `JWT_SECRET` | Token signing secret |
| `JWT_ALGORITHM` | Token algorithm |
| `JWT_EXPIRE_MINUTES` | Token lifetime |
| `PMS_DATA_DIR` | Runtime data directory |
| `PMS_DEFAULT_FILE_PATH` | Default workbook path |
| `PORT` | Container API port |

Frontend build-time variables:

| Variable | Purpose | Default |
| --- | --- | --- |
| `VITE_API_BASE_URL` | Backend HTTP origin | `http://localhost:8000` |
| `VITE_SOCKET_URL` | Socket.IO origin | `http://localhost:8000` |

`VITE_API_URL` remains a fallback alias for the HTTP origin.

## Tests and Validation

Backend tests are under `Backend/tests/`, with additional root-level backend test scripts. The suite covers routers, authentication/RBAC, repositories, services, caching, monitoring, bulk operations, soft deletion, versioning, and the four newer KPI teams (Coding, CSR, Pharmacy, and Submission).

```powershell
cd Backend
pytest tests -v
pytest tests/test_three_teams.py -v
pytest tests/test_submission_team.py -v
```

Frontend validation uses the scripts declared in `Frontend/package.json`:

```powershell
cd Frontend
npm run lint
npm run build
```

Avoid recording fixed passing-test counts or performance/SLA claims in this document; those values should come from the current CI run and monitoring environment.

The authenticated app shell is wrapped in a root error boundary so a page crash falls back to a safe screen instead of taking down the whole UI. Browser vitals reporting in `Frontend/src/main.tsx` is best-effort and ignores a missing `/api/vitals` endpoint.
