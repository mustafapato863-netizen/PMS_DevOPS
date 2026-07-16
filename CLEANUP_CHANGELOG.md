# PMS Dashboard Cleanup Changelog

Cleanup and hardening date: 2026-07-16

## Boundary

Changes were made on `codex/comprehensive-hardening` in the root, Backend, and Frontend repositories. `main` retains the previously pushed `Safe Version` reference. No automatic merge or history rewrite was performed.

## Phase 1: Safe audit cleanup

### Removed

- `Frontend/lint_output.txt`
- `Frontend/lint_output_utf8.txt`
- `Backend/test_integration.py`
- `Backend/test_team_service.py`
- Sixteen tracked Backend `__pycache__/*.pyc` artifacts

The two test files contained three collected diagnostic functions with no assertions, direct configured-database access, sensitive prints, and swallowed exceptions. Canonical repository, service, API, rollback, and integration tests were retained.

### Changed

- Added ignore coverage for generated lint output.
- Removed JWT decode exception prints, upload tracebacks, and Redis URL/error details from logs.

## Phase 2: Sensitive data and runtime safety

### Removed from tracking

- `Backend/data/corrective_actions.json`
- `Backend/data/employees.json`
- `Backend/data/kpi_weights.json`
- `Backend/data/manager_notes.json`
- `Backend/data/performance_records.json`
- `Backend/data/targets.json`
- `Backend/data/team_actions.json`
- `Backend/data/uploads.json`
- `Backend/data/users.json`
- `Frontend/src/data/all_months_performance.json`

Local Backend copies remain ignored for private runtime compatibility. `Backend/data/README.md` documents provisioning. Production fails fast for missing required private data; development/test may initialize empty stores.

## Phase 3: Security hardening

### Backend

- Added explicit `APP_ENV`, `CORS_ORIGINS`, and `MAX_UPLOAD_BYTES` configuration.
- Applied the CORS allowlist to HTTP and Socket.IO and rejected wildcard origins.
- Restricted legacy unauthenticated access to explicit development/test contexts.
- Preserved dependency overrides while obtaining authentication database sessions in tests.
- Replaced token and generic server error disclosure with stable public messages.
- Added `services/upload_security.py` for bounded reads, basename handling, extension/signature validation, and size/empty-file rejection.
- Applied upload security to performance uploads and BSC template uploads.

### DevOps

- Added Redis passwords, authenticated URLs, and authenticated health checks in dev, staging, and production.
- Required the production Grafana administrator password with no fallback.
- Added named persistent volumes.
- Removed obsolete Compose schema versions.
- Added Nginx `client_max_body_size 25m`.
- Updated `.env.example` without adding secret values.

## Phase 4: Frontend integrity and simplification

### Removed

- `Frontend/src/pages/OperationalView.tsx`

Reason: import and route tracing proved the legacy page unreachable and duplicated the current operational workflow.

### Consolidated or simplified

- Replaced the sensitive data fallback with API-only loading and an empty state.
- Centralized Balanced Scorecard API response types.
- Split Auth context/hook definitions from the Provider.
- Moved gauge-tone and manager-snapshot helpers out of component modules.
- Removed unused KPI card and KPI-key implementations.
- Corrected shared team, location, onboarding, chart, employee history, notification, and socket types.
- Removed render-time ref access, static component creation, state-in-effect violations, unsafe `any` usage, and obsolete React Query state values.
- Preserved current UI layout and user-facing calculations.

## Phase 5: Dependency remediation

- Updated `react-router-dom` to `^7.18.1`.
- Updated Vite to `^8.1.4`.
- Updated affected lockfile transitive packages with `npm audit fix`.
- Dependencies removed: none.
- Dependencies added: none.
- Direct dependency count remained 15 runtime + 12 development.
- `npm audit` improved from three high-severity findings to zero.

## Tests

### Added

- `Backend/tests/test_auth_hardening.py`
- `Backend/tests/test_cors_hardening.py`
- `Backend/tests/test_runtime_data_security.py`
- `Backend/tests/test_upload_security.py`

### Updated

- Corrected stale expectations/fixtures in batch, performance-level, upload, and Balanced Scorecard tests to match canonical current behavior.
- Reused the canonical KPI row-key resolver so production calculation and tests use the same aliases.

### Removed

No canonical test was removed during hardening. The only removed tests were the three unsafe diagnostics listed in Phase 1.

## Verification by group

| Group | Verification |
| --- | --- |
| Sensitive data/runtime | runtime-data tests, Frontend build, tracked-file inspection |
| CORS/auth | focused hardening tests, full Backend suite |
| Uploads | router tests, signature/size/path tests, full Backend suite |
| Error handling | router tests and OpenAPI generation |
| DevOps | dev/staging/prod Compose config validation |
| Frontend types/hooks | TypeScript and ESLint after each batch |
| Dependencies | production build, summary tests, npm audit |

## Final verification

- Backend full suite: `347 passed, 0 failed`.
- Backend source compile: passed.
- Backend requirements compatibility: passed.
- Alembic: one head, `c1a8f6d2e4b7`.
- OpenAPI: 66 paths, 77 operations.
- Frontend TypeScript: passed.
- Frontend ESLint: passed with zero warnings.
- Frontend production build: passed.
- Frontend summary tests: 2/2 passed.
- Frontend npm audit: zero vulnerabilities.
- Docker Compose dev/staging/prod: all passed.

## Removal totals

- Phase 1 removed files/artifacts: 20.
- Hardening removed sensitive/dead source files: 11.
- Total removed tracked files/artifacts across both phases: 31.
- Test functions removed: 3 unsafe diagnostics.
- Canonical tests removed: 0.
- Dependencies removed: 0.

## Remaining manual actions

- Rotate historical credentials and rewrite Git history before public exposure.
- Complete database/object-storage migration for private JSON compatibility data.
- Add dedicated secret, Python dependency, and SAST scanning to CI.
- Review the remaining statically unreachable Frontend files with product ownership.
- Address Pydantic and timezone deprecations in a separately tested compatibility phase.
