# PMS Dashboard System Status

**Last verified:** June 23, 2026

**Lifecycle:** Active development

**Overall status:** Functional development build with targeted config-driven onboarding improvements, DB-backed user management in progress, global Admin notifications, and focused backend/frontend checks passing

This document is a point-in-time engineering health snapshot. Setup, architecture, and API reference material live in `README.md` and `README_PROJECT_STRUCTURE.md`.

## Verification Summary

The following focused checks were run locally on June 23, 2026:

| Check | Result | Details |
| --- | --- | --- |
| Frontend production build | Passing | Vite built successfully |
| Backend Python compile check | Passing | `python -m py_compile Backend/config/socket_config.py` |
| App shell crash fallback | Passing | Root error boundary added in the frontend |
| Notification socket scoping | Passing | Admin receives global notifications; Manager/Agent remain scoped |

Commands used:

```powershell
cd ..\Frontend
npm run build
cd Backend
python -m py_compile Backend/config/socket_config.py
```

These results describe the current local workspace, including uncommitted changes. They are not a production readiness or SLA statement.

## Working Capabilities

- FastAPI and Socket.IO backend application
- React 19 and Vite frontend with authenticated routes
- PostgreSQL persistence and Alembic migrations
- Redis caching and service health reporting
- JWT authentication and role-based access controls
- Employee, performance, planning, settings, upload, team-management, and DB-backed user admin APIs
- Employee notes, corrective actions, soft deletion, restore, auditing, and versioning
- Excel processing through shared and team-specific cleaners
- Nine JSON-configured teams across EGY and UAE
- Configurable direct/inverse KPI calculations, weights, grade thresholds, and capping rules
- Frontend production bundle generation
- Socket.IO notifications with explicit Admin global delivery plus scoped Manager/Agent access
- Root error boundary and best-effort vitals reporting in the frontend shell

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
- The full backend regression suite was not re-run after the latest documentation-only update.

## Current Priorities

1. Keep the user admin flow aligned with the live PostgreSQL `users` table.
2. Reduce frontend lint failures, starting with React effect issues and unsafe `any` usage.
3. Add deployment-level smoke testing for the Compose stack and frontend-to-backend connectivity.
4. Keep onboarding docs aligned with the config-first team creation flow.

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
