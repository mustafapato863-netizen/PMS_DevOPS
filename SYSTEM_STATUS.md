# PMS Dashboard System Status

**Last verified:** June 21, 2026

**Lifecycle:** Active development

**Overall status:** Functional development build with unresolved backend test and frontend lint failures

This document is a point-in-time engineering health snapshot. Setup, architecture, and API reference material live in `README.md` and `README_PROJECT_STRUCTURE.md`.

## Verification Summary

The following checks were run locally on June 21, 2026:

| Check | Result | Details |
| --- | --- | --- |
| Backend test suite | Failing | 223 passed, 14 failed, 27 errors, 21 warnings in 36.33s |
| Frontend production build | Passing | Vite transformed 3,124 modules and completed successfully |
| Frontend lint | Failing | 153 errors and 3 warnings |
| Documentation diff check | Passing | No whitespace errors in the updated documentation |

Commands used:

```powershell
cd Backend
python -m pytest tests -q

cd ..\Frontend
npm run build
npm run lint
```

These results describe the current local workspace, including uncommitted changes. They are not a production readiness or SLA statement.

## Working Capabilities

- FastAPI and Socket.IO backend application
- React 19 and Vite frontend with authenticated routes
- PostgreSQL persistence and Alembic migrations
- Redis caching and service health reporting
- JWT authentication and role-based access controls
- Employee, performance, planning, settings, upload, and team-management APIs
- Employee notes, corrective actions, soft deletion, restore, auditing, and versioning
- Excel processing through shared and team-specific cleaners
- Eight JSON-configured teams across EGY and UAE
- Configurable direct/inverse KPI calculations, weights, grade thresholds, and capping rules
- Frontend production bundle generation

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

The source of truth is `Backend/config/teams/`. Pharmacy, Coding, and CSR have focused coverage in `Backend/tests/test_three_teams.py`.

## Known Issues

### Backend Tests

The current backend run has 14 assertion/mock failures in `Backend/tests/test_api_routers.py`. The failures cover employee and performance router behavior, error handling, and response schema expectations. The test expectations and mocks need to be reconciled with the current router and service contracts.

Another 27 tests in `Backend/tests/test_integration_stage_4_7.py` fail during setup. These repository and workflow tests use SQLite, while the mapped schema includes PostgreSQL-specific types such as `JSONB`. The test database strategy needs either compatible type variants or a PostgreSQL-backed integration environment.

### Frontend Lint

ESLint reports 153 errors and 3 warnings. The recurring categories are:

- Explicit `any` types
- Unused imports, variables, and parameters
- State updates performed synchronously inside React effects
- Fast Refresh export-boundary violations
- Hook dependency warnings
- Smaller style rules such as `prefer-const` and empty blocks

The production build still succeeds, so these are quality-gate failures rather than TypeScript build failures.

## Current Priorities

1. Align router tests with the active employee and performance API contracts.
2. Choose a consistent integration-test database strategy for PostgreSQL-specific models.
3. Reduce frontend lint failures, starting with React effect issues and unsafe `any` usage.
4. Run the complete backend suite and frontend checks in CI to prevent status drift.
5. Add deployment-level smoke testing for the Compose stack and frontend-to-backend connectivity.

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
