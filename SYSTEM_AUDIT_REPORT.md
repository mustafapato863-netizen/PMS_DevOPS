# PMS Dashboard System Audit Report

Audit date: 2026-07-16

## Scope and safety boundary

This audit covered the root DevOps repository and the nested Frontend and Backend repositories. It reviewed tracked files, manifests and lockfiles, environment handling, Docker Compose files, migrations, tests, runtime data, imports, logging, authentication, uploads, and current validation commands.

The cleanup deliberately did not change business logic, calculations, UI, API contracts, database schema or behavior, permissions, routing, or user workflows. Existing user changes in all three repositories were preserved.

## Executive summary

- The highest risk is production-like employee, performance, upload, and corrective-action data tracked in Git. Some of these files are active runtime compatibility sources, so automatic removal would change behavior.
- No high-confidence private key, AWS key, GitHub token, OpenAI key, or Slack token pattern was found in the currently tracked code scan. This was a pattern scan, not a substitute for a dedicated history scanner.
- A `.env` path exists in Backend Git history. Current local environment files are ignored, but any credential that was ever committed must be treated as exposed and rotated.
- CORS, legacy authentication bypass, upload memory limits, raw exception responses, Redis authentication, and a production Grafana fallback require a dedicated security-hardening phase because changing them can affect compatibility or deployment.
- Frontend production build and its two existing tests pass. Full lint and TypeScript checks already fail.
- Backend collects 338 retained tests. The full suite has the same 26 failures before and after cleanup; 312 tests pass.
- No dependency was removed. Static import tracing did not prove any direct manifest dependency unused.

## Critical findings

### SEC-01: Production-like personal and performance data is tracked in Git

Evidence, without exposing values:

| Repository | Tracked source | Record count | Sensitive field categories |
| --- | --- | ---: | --- |
| Backend | `data/performance_records.json` | 785 | employee identifiers, employee names, upload identifiers |
| Backend | `data/employees.json` | 195 | identifiers, names |
| Backend | `data/corrective_actions.json` | 5 | employee identity, manager notes, actions, creator identity |
| Backend | `data/team_actions.json` | 1 | team identifiers and action content |
| Backend | `data/uploads.json` | 1 | filename and upload identifier |
| Frontend | `src/data/all_months_performance.json` | 56 | nested employee identity and performance data |

Risk: anyone with repository or history access can retrieve these records. The frontend fallback is bundled into production assets. Backend JSON files are still referenced by legacy repositories, migration scripts, and learning behavior.

Action required: move required fixtures to anonymized synthetic data, make the database/private object storage the only production source, remove tracked sensitive data, purge Git history, and rotate any related credentials. This was intentionally not automated because deleting these sources would change current runtime and fallback behavior.

### SEC-02: Environment file exists in Git history

Backend history contains a tracked `.env` path. Current local `.env` files are ignored and secret values were not printed or copied into this report.

Action required: rotate every credential that may have appeared in that file, then use an approved history-rewrite procedure and coordinate a fresh clone for all consumers.

## High-risk findings

### SEC-03: Wildcard CORS is combined with credentials

`Backend/app.py:86` configures `allow_origins=["*"]`, `allow_credentials=True`, and wildcard methods and headers. A `CORS_ORIGINS` setting exists in environment examples but is not used by this middleware.

Recommended follow-up: parse an explicit origin allowlist from configuration and pass it through all deployment environments. This was not changed because an incomplete allowlist could break existing clients.

### SEC-04: Environment-controlled unauthenticated compatibility bypass

`Backend/api/middleware/auth_middleware.py:34` permits broad employee, performance, team, and upload paths without a bearer token when `ALLOW_LEGACY_API_ACCESS=1`. The resulting identity and role can be supplied through request headers.

Recommended follow-up: remove the production bypass or hard-disable it outside an explicit test environment. It was retained because it is a documented compatibility path and removing it changes authorization behavior.

### SEC-05: Uploads are read fully into memory without a size limit

`Backend/api/routers/upload.py:61` validates only the filename extension and `Backend/api/routers/upload.py:72` reads the whole upload. This permits memory exhaustion and does not validate the file signature before processing.

Recommended follow-up: enforce reverse-proxy and application limits, stream to a bounded temporary file, validate ZIP/OLE signatures, and reject malformed workbooks before processing. This requires an agreed API limit and was therefore not applied in cleanup.

### SEC-06: Internal exception text is returned to clients

Multiple routes interpolate `str(e)` into `StandardResponse.message`, including `Backend/api/routers/upload.py:125`, `Backend/api/routers/upload.py:171`, and user-management routes. This can disclose database, filesystem, parser, or infrastructure details.

Recommended follow-up: return stable public error codes/messages and retain detailed context only in structured server logs. Response text was not changed because it is part of the current API contract.

### SEC-07: Redis production password variable is not enforced

`DevOps/compose/docker-compose.prod.yml` defines a Redis password environment variable, but the Redis service command does not require authentication. A leaked or reachable Redis endpoint would allow unauthorized cache access.

Recommended follow-up: configure `requirepass` or ACLs, use a credential-bearing `REDIS_URL`, restrict network exposure, and update health checks safely.

### SEC-08: Production Grafana has an insecure password fallback

`DevOps/compose/docker-compose.prod.yml` permits a hard-coded fallback for the Grafana administrator password.

Recommended follow-up: require the variable with no default and source it from a secret manager. This was retained to avoid changing existing deployment startup behavior during a cleanup-only phase.

### DEP-01: Three high-severity npm audit records

`npm audit --omit=dev` reported high-severity findings affecting the currently locked versions of `react-router`, direct dependency `react-router-dom`, and direct development dependency `vite`. Fixes are reported as available.

No version was changed because the task forbids upgrades unless clearly necessary and requires behavior preservation. Apply patched versions in a dedicated dependency update with route, build, and Windows dev-server regression testing.

## Medium-risk findings

### QUAL-01: Backend regression suite is not green

Baseline and final result: 26 failed, 312 passed. Failure groups:

- Authentication and middleware: 2 failures in `tests/test_auth.py`.
- Batch and bulk API behavior: 4 failures across `tests/test_batch.py` and `tests/test_bulk_api.py`.
- KPI/config calculations: 3 failures across `tests/test_kpi_contribution_capping.py` and `tests/test_performance_levels.py`.
- RBAC endpoints: 5 failures in `tests/test_rbac.py`.
- Re-submission calculations: 8 failures in `tests/test_re_submission_team.py`.
- User administration routing: 4 failures in `tests/test_user_admin_routing.py`.

Representative evidence shows contract drift rather than cleanup regressions: an active-user test receives `User account is disabled`, a batch test expects an older validation string, and KPI tests use column names no longer accepted by the current config.

### QUAL-02: Frontend static validation is not green

- ESLint: 159 findings, comprising 154 errors and 5 warnings, both before and after cleanup.
- TypeScript project check: 185 compiler errors. Common groups include missing achievement fields in shared types, duplicate incompatible `Team` types, outdated Zod signatures, and unused declarations.
- Vite build still succeeds because the build does not perform a complete TypeScript project check.

Recommended follow-up: establish a clean type-check script and fix errors by domain without weakening rules.

### ARCH-01: Routers contain persistence and business orchestration

Several routes query SQLAlchemy sessions directly or coordinate repositories and recalculation loops. Examples include `Backend/api/routers/users_and_actions.py` and `Backend/api/routers/upload.py`. This conflicts with the documented router -> service -> repository direction and makes transaction ownership harder to verify.

Recommended follow-up: move logic into existing canonical services in small, behavior-preserving phases with API contract tests. No architectural refactor was made in this cleanup.

### ARCH-02: Parallel JSON and database compatibility paths remain

Database-backed repositories coexist with `Backend/repositories/json_repos.py`; corrective-action JSON is also consumed by migration and learning code. This creates multiple potential sources of truth.

Recommended follow-up: complete a measured migration, compare record counts, freeze writes to legacy JSON, and remove compatibility paths only after production verification.

### OPS-01: Python dependency vulnerability scan is incomplete

`pip check` passed, but `pip-audit`, `gitleaks`, `trufflehog`, and `semgrep` were not installed. Pattern scans and compatibility checks cannot prove absence of vulnerabilities.

Recommended follow-up: add pinned CI jobs for dependency and secret scanning with an approved exception process.

### OPS-02: Deprecated runtime patterns

Tests emit Pydantic v1-style validator/config warnings and `datetime.utcnow()` deprecation warnings. These are compatibility risks for future major upgrades, not current cleanup candidates.

## Low-risk findings

### CLEAN-01: Stale generated lint output was tracked

`Frontend/lint_output.txt` and `Frontend/lint_output_utf8.txt` were command output artifacts with no runtime references. They were removed and `lint_output*.txt` was added to the frontend ignore file.

### CLEAN-02: Three unsafe diagnostic tests were collected as tests

The root-level Backend files `test_integration.py` and `test_team_service.py` contained three test functions that connected to `SessionLocal`, printed database records, used no assertions, and swallowed exceptions. They were removed. Real repository and service coverage remains under `Backend/tests`.

### CLEAN-03: Compiled Python bytecode was tracked

Sixteen `Backend/**/__pycache__/*.pyc` files were tracked even though the existing Backend ignore file already excludes bytecode. They were removed from the working tree so the source files, not interpreter-specific Python 3.13 artifacts, remain authoritative.

### OPS-03: Obsolete Compose schema keys

All three Compose files validate, but Docker reports that the top-level `version` key is obsolete. It was left unchanged because the DevOps files already contain user changes and removal has no runtime benefit.

## Dependency audit

### Counts

| Area | Before | After | Removed |
| --- | ---: | ---: | ---: |
| Frontend direct dependencies | 15 | 15 | 0 |
| Frontend direct dev dependencies | 12 | 12 | 0 |
| Backend requirements entries | 22 | 22 | 0 |

Static usage found imports or configuration use for every frontend direct dependency. Backend requirements include runtime servers, database drivers, migration tools, and pytest plugins that cannot be judged solely by application imports. No package met the proof threshold for removal.

The local frontend `node_modules` contains ignored extraneous packages, but this is workspace installation state rather than a tracked manifest issue. A clean `npm ci` environment should be used in CI.

## Duplicate and dead-code audit

- SHA-256 comparison found no exact duplicate tracked files larger than 100 bytes in Frontend or Backend.
- The two Dockerfiles differ only slightly, but both are needed for distinct nested-repository and DevOps build contexts, so they were retained.
- A TypeScript import graph from `src/main.tsx` found 26 configured source files not reachable from the current application entry point. These include older chart components, `OperationalView.tsx`, older API hooks, and balanced-scorecard helpers.
- Unreachable-by-static-import is not sufficient proof of obsolescence because files may be development entry points, barrel exports, or staged features. All 26 were retained for manual product-owner review.
- `src/hooks/usePerformanceData.ts` and the older `src/hooks/api/usePerformanceData.ts` represent overlapping data-access generations. The latter was retained because removing a compatibility API surface was outside the safe boundary.

## Test-suite audit

### Removed

- `Backend/test_integration.py::test_user_repository`
- `Backend/test_integration.py::test_team_repository`
- `Backend/test_team_service.py::test_team_service`

Reason: no assertions, direct production-configured database access, sensitive console output, and swallowed failures.

### Retained

All 338 tests under `Backend/tests` were retained, including authentication, RBAC, uploads, migrations, KPI calculations, rollback/atomicity, soft deletion, corrective actions, BSC, repositories, services, and regression coverage. Frontend summary tests were retained.

### Counts

| Collection | Before | After |
| --- | ---: | ---: |
| All Backend pytest tests | 341 | 338 |
| Canonical `Backend/tests` suite | 338 | 338 |
| Frontend Node tests | 2 | 2 |

## Security improvements applied

- Removed three debug prints that exposed JWT decode exception details.
- Removed two direct traceback prints from upload routes.
- Redacted Redis connection logging so it no longer includes the configured URL or connection exception text.
- Added ignore coverage for generated lint result files.
- Removed 16 tracked Python bytecode artifacts already covered by Backend ignore rules.

No user-facing error text, authentication decision, permission, route, database write, or upload processing behavior was changed.

## Validation evidence

| Command or check | Result |
| --- | --- |
| `npm run test:summary` | 2 passed |
| `npm run build` | passed, 3,237 modules transformed |
| `npm run lint` | baseline/final unchanged: 154 errors, 5 warnings |
| `npx tsc -b --noEmit` | 185 existing errors |
| `python -m pytest --collect-only -q -p no:cacheprovider` | 338 tests after cleanup |
| `python -m pytest -q -p no:cacheprovider tests --tb=no` | baseline/final unchanged: 312 passed, 26 failed |
| Focused upload/cache tests | 11 passed |
| Atomicity and rollback tests | 2 passed |
| `python -m compileall -q ...` | passed |
| OpenAPI generation | 66 paths, 77 operations |
| `python -m pip check` | passed |
| `python -m alembic heads` | one head: `c1a8f6d2e4b7` |
| Alembic history traversal | passed |
| Dev/staging/prod `docker compose ... config --quiet` | all passed, obsolete-version warnings only |
| `npm audit --omit=dev` | 3 high records |
| Current tracked token/key pattern scan | no matching high-confidence token/key patterns |

The application server was not started with its lifespan because startup seeding can write to the configured database. OpenAPI import and Compose validation provided non-destructive startup/configuration checks. No migration upgrade or destructive database command was run.

## Items intentionally kept

- Tracked runtime/fallback data, pending a safe data migration and history purge.
- CORS behavior, pending a confirmed production allowlist.
- Legacy unauthenticated compatibility, pending a coordinated authorization change.
- Existing raw API error messages, because they are response-contract behavior.
- Upload behavior, pending an agreed file-size policy and proxy configuration.
- Redis/Grafana production behavior, pending a deployment security change.
- All direct dependencies, because none was proven unused.
- The 26 statically unreachable frontend files, because static reachability alone is insufficient deletion proof.
- Parallel JSON compatibility repositories and migration scripts.
- Existing frontend, backend, and DevOps user changes unrelated to this audit.

## Recommended order of follow-up

1. Incident-style data and Git-history cleanup with credential rotation.
2. Restore a green backend regression baseline and frontend type/lint baseline.
3. Harden CORS, legacy access, Redis, Grafana, error responses, and upload limits behind explicit deployment tests.
4. Patch audited npm vulnerabilities in a dedicated dependency change.
5. Complete JSON-to-database migration and then remove confirmed dead compatibility code.
