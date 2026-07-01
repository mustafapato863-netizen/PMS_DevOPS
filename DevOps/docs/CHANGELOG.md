# Changelog

All notable changes to the PMS Dashboard project are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and adheres to Semantic Versioning.

---

## [v2.1.0] — 2026-06-29

### Added
- **Level-Scoped Team Access Control:** Extended user authorization and scopes to be granularly matched by both `team_id` and `performance_level`.
- **Granular Assignment API:** Created GET, POST, DELETE endpoints at `/api/users/{user_id}/assignments` to manage level-specific team access.
- **Granular Assignments Editor:** Implemented a new, modern UI component in `SettingsView.tsx` allowing Admin to add/remove specific level assignments.
- **Config Discovery Endpoint:** Introduced `/api/config/teams/available-levels` to resolve configured and database-present performance levels.
- **Integration Test Suite:** Added `tests/test_performance_level_scoping.py` covering schema constraints, scope resolution, auth filters, and user assignment management.

### Changed
- **Header & Sidebar Updates:** Restricted visible teams and level filter options based on the user's explicit team-level assignments.
- **Middlewares Hardening:** Fixed DB connection leak in `AuthMiddleware` by safely resolving overridden test sessions during pytest runs.

---

## [v2.0.1] — 2026-06-29

### Added
- **Unified Setup Script:** Introduced `setup_project.ps1` at the root directory to automate Python virtual environment setup and Frontend npm installs.
- **Dependency Hardening:** Added missing backend packages to `requirements.txt` (`python-dotenv`, `pyjwt`, `bcrypt`, `redis`) and testing dependencies (`pytest`, `pytest-asyncio`, `hypothesis`, `httpx`).

### Fixed
- **Sidebar Icon Reference:** Resolved an uncaught `ReferenceError` for the undefined `BriefcaseBusiness` icon by replacing it with the standard `Briefcase` icon in `Sidebar.tsx`.
- **Dynamic Header Month Filter:** Linked the top navigation month selector to the dynamic `usePerformanceData` store to only show months containing actual performance records.

---

## [v2.0.0] — 2026-06-25 (Current)

### Added
- **Production Hardening Specifications:** Created production Docker Compose configs (`docker-compose.prod.yml`) isolating database/Redis services.
- **Orchestrator Probes:** Added `/api/health/liveness` and `/api/health/readiness` endpoints to facilitate monitoring and deployments.
- **Configurable Database Pooling:** Exposed SQLAlchemy pool metrics (`DATABASE_POOL_SIZE`, `DATABASE_MAX_OVERFLOW`, `DATABASE_POOL_RECYCLE`) to environment variables.
- **Configurable Logging Levels:** Log level variables can now be overridden via `LOG_LEVEL`.
- **Comprehensive Guide Workspace:** Generated architectural deep-dives inside `docs/` detailing Security, Deployment, KPIScoringEngine, and NotificationArchitecture.

### Changed
- **Metadata Alignment:** Standardized version markers, status summaries, and check timestamps across all root guides.

---

## [v1.5.0] — 2026-06-15

### Added
- **Active User Session Controls:** Integrated middleware check in `AuthMiddleware` verifying user active status (`is_active`) on every REST request, immediately revoking access for suspended users.
- **Scoped Notification Rooms:** Implemented room joining logic in python-socketio to scope notifications (e.g. Admin global streams vs Manager scoped teams).
- **Audit Logging and Restore Utilities:** Added database auditing on row mutations and soft delete / restore controls for employee entities.

### Changed
- **Dashboard All Months Headcount Fix:** The "Total Agents" card aggregation now queries the latest available month headcount rather than summing repeating employee records across multiple months, with warning notes appended.

---

## [v1.0.0] — 2026-05-10

### Added
- **Unified KPI Scoring Engine:** Created scoring calculator separating raw achievement from weight-capped contribution points.
- **Config-Driven Onboarding:** Moved team definitions to JSON configuration files under `config/teams/`, enabling onboarding of new teams without database schema migrations.
- **Role-Based Access Control (RBAC):** Added role checks (Admin, Manager, Executive, Viewer) at the FastAPI route middleware and React routing components.

### Changed
- **DB-First Performance Reads:** Migrated the dashboard read paths to query PostgreSQL database tables first, using local JSON repositories strictly as fallback data.

---

## [v0.5.0] — 2026-04-01

### Added
- **Ingestion Pipeline:** Created Excel workbook parser with support for custom cleaning rules.
- **Core Database Entities:** Deployed database tables (`employees`, `performance_records`, `kpi_values`, `upload_log`, `users`).
- **Initial Dashboards:** Developed React page components for Team view, Executive dashboard, and Employee details.

---

## [v0.1.0] — 2026-02-15

### Added
- **Initial Scaffold:** Initial setup of backend FastAPI scaffolding, SQLAlchemy ORM mappings, Vite React framework, and Tailwind CSS.
