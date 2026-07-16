# PMS Dashboard System Audit Report

Audit and hardening date: 2026-07-16

## Scope and boundary

The audit covered the root DevOps repository and the nested Backend and Frontend repositories. It reviewed tracked data, Git history indicators, manifests and lockfiles, environment handling, Docker Compose, Nginx, authentication, CORS, WebSockets, uploads, error responses, migrations, tests, frontend imports, types, and production build configuration.

The implementation used small compatibility-preserving changes. It did not redesign the UI, change KPI calculations, change database schemas, remove API routes, weaken tests, or merge directly to `main`. The protected reference remains the three `Safe Version` commits on `main`; hardening is isolated on `codex/comprehensive-hardening`.

## Executive summary

- Current tracked employee, performance, action, upload, and user JSON data was removed from the Backend and Frontend trees. Backend local copies remain ignored for private runtime compatibility.
- Production now fails fast when required private runtime JSON is missing instead of silently creating empty operational data. Development and tests can still initialize empty stores.
- CORS now uses an explicit configured allowlist for HTTP and Socket.IO and rejects wildcard origins.
- Legacy unauthenticated API access is restricted to pytest or explicit development/test environments. Production cannot enable it through the compatibility flag alone.
- Uploads now have application and Nginx size limits, safe basenames, extension checks, workbook signature checks, empty-file rejection, and bounded reads.
- Internal exception details are no longer returned in generic 5xx responses.
- Redis authentication and credential-bearing URLs are configured in all Compose environments. Production Grafana no longer has a default administrator password.
- Frontend fallback production data was removed, authentication context boundaries were clarified, dead code was reduced, TypeScript contracts were corrected, and React hook/compiler violations were resolved.
- Frontend audited dependencies were updated to patched compatible versions. `npm audit` changed from three high-severity findings to zero findings.
- Backend changed from 312 passed / 26 failed to 347 passed / 0 failed. Frontend changed from 154 ESLint errors and 185 TypeScript errors to zero.

## Critical findings

### SEC-01: Sensitive data remains retrievable from Git history

Status: **manual action still required**.

The current trees no longer track the production-like JSON files, but earlier commits still contain employee identity, performance, action, upload, and environment data. Removing files in a new commit does not remove historical objects.

Required action:

1. Rotate every credential that may have appeared in any historical `.env` or configuration file.
2. Agree a maintenance window and rewrite all affected repository histories with an approved tool.
3. Force-push rewritten branches and tags.
4. Require fresh clones and invalidate old forks, caches, artifacts, and backups where possible.
5. Run a dedicated history scanner such as Gitleaks or TruffleHog before making a repository public.

History rewriting was intentionally not automated because it is destructive, invalidates the `Safe Version` commit references, and requires coordination with every clone and deployment.

## Security issues fixed

### SEC-02: Sensitive runtime JSON tracked and bundled

Status: **fixed in the current branch**.

Removed from Backend tracking:

- `data/corrective_actions.json`
- `data/employees.json`
- `data/kpi_weights.json`
- `data/manager_notes.json`
- `data/performance_records.json`
- `data/targets.json`
- `data/team_actions.json`
- `data/uploads.json`
- `data/users.json`

Removed from Frontend:

- `src/data/all_months_performance.json`

The Frontend no longer bundles a sensitive fallback dataset. Backend private runtime files are ignored and documented in `Backend/data/README.md`.

### SEC-03: Wildcard credentialed CORS

Status: **fixed**.

`CORS_ORIGINS` is parsed as an explicit allowlist and used consistently by FastAPI and Socket.IO. `*` is rejected rather than combined with credentials.

### SEC-04: Production legacy authentication bypass

Status: **fixed**.

The compatibility bypass is allowed only under pytest, or when `APP_ENV` is explicitly `development`/`test` and `ALLOW_LEGACY_API_ACCESS=1`. Invalid-token responses no longer expose token parsing details.

### SEC-05: Unsafe upload handling

Status: **fixed**.

Upload processing now enforces `MAX_UPLOAD_BYTES`, reads in bounded chunks, rejects empty/oversized files, sanitizes path components, checks allowed extensions, and validates ZIP/OLE workbook signatures. Nginx enforces the matching 25 MB request limit. Expected validation failures retain their 400/413 statuses.

### SEC-06: Internal exception disclosure

Status: **fixed for audited generic 5xx paths**.

Audited routers and middleware return stable public messages while server logs retain diagnostic context. Intentional 4xx validation messages remain unchanged.

### SEC-07: Redis and Grafana unsafe defaults

Status: **fixed**.

Dev, staging, and production Redis use `requirepass`, authenticated health checks, and credential-bearing application URLs. Production Grafana requires an explicit password and has no hard-coded fallback. Persistent named volumes were added and obsolete Compose `version` keys were removed.

### SEC-08: Vulnerable frontend dependency versions

Status: **fixed**.

`react-router-dom`, Vite, and affected transitive packages were updated within the existing stack. No new dependency or replacement framework was introduced. `npm audit --audit-level=moderate` reports zero vulnerabilities.

## Architecture and cleanup findings

### Applied

- Removed unreachable legacy `Frontend/src/pages/OperationalView.tsx` after confirming it had no import or route consumer.
- Consolidated Balanced Scorecard response types around `useBalancedScorecard` instead of parallel `any` contracts.
- Separated Auth context/hook definitions from the Provider to preserve React Fast Refresh correctly.
- Moved non-component gauge and manager snapshot helpers out of component modules.
- Removed an unused KPI card implementation and unused KPI-key mapper.
- Removed sensitive Frontend fallback behavior; API failure now produces an explicit empty state.
- Retained the canonical router -> service -> repository direction for new upload validation by placing file validation in `services/upload_security.py`.

### Intentionally retained

- Twenty-five additional statically unreachable Frontend files remain because static reachability alone does not prove product obsolescence.
- The older `hooks/api/usePerformanceData.ts` compatibility surface remains because removing it was not proven safe.
- Backend private JSON compatibility repositories remain for local/private runtime consumers. This is not a completed database-only migration.
- Existing router-owned orchestration was not broadly rewritten; doing so would exceed the safe, behavior-preserving boundary.
- All canonical Backend tests and both Frontend summary tests were retained.

## Test-suite findings

Earlier safe cleanup removed three unsafe diagnostic functions from two root-level Backend files because they directly opened the configured database, printed records, swallowed exceptions, and had no assertions:

- `test_integration.py::test_user_repository`
- `test_integration.py::test_team_repository`
- `test_team_service.py::test_team_service`

Hardening removed no additional test. It added focused coverage for CORS, authentication boundaries, private runtime data, and upload security.

| Validation | Before | After |
| --- | ---: | ---: |
| Backend full pytest | 312 passed, 26 failed | 347 passed, 0 failed |
| Frontend ESLint | 154 errors, 5 warnings | 0 errors, 0 warnings |
| Frontend TypeScript | 185 errors | 0 errors |
| Frontend Node tests | 2 passed | 2 passed |
| npm audit | 3 high findings | 0 findings |

## Dependency audit

| Area | Before | After | Removed |
| --- | ---: | ---: | ---: |
| Frontend direct runtime dependencies | 15 | 15 | 0 |
| Frontend direct development dependencies | 12 | 12 | 0 |
| Backend requirements entries | 22 | 22 | 0 |

No package was removed without proof. Patched versions were applied only where the audit identified active vulnerabilities. `pip check` reports no broken Python requirements.

## Verification evidence

| Command/check | Result |
| --- | --- |
| Backend `python -m pytest -q` | 347 passed, 57 warnings |
| Backend focused security tests | included in full green suite |
| Backend source `compileall` | passed |
| Backend `pip check` | no broken requirements |
| Alembic heads | one head: `c1a8f6d2e4b7` |
| OpenAPI generation | 66 paths, 77 operations |
| Frontend `npx tsc -b --noEmit` | passed |
| Frontend `npm run lint` | passed, no findings |
| Frontend `npm run build` | passed, 3,237 modules transformed |
| Frontend `npm run test:summary` | 2 passed |
| Frontend `npm audit --audit-level=moderate` | 0 vulnerabilities |
| Dev/staging/prod `docker compose ... config --quiet` | all passed |

OpenAPI generation used the ASGI wrapper's FastAPI application without running application lifespan/database seed operations. Redis was unavailable locally and the documented in-memory fallback was used.

## Remaining risks and manual review

1. Git history rewrite and credential rotation remain mandatory before public exposure.
2. Complete the private JSON to database/object-storage migration before removing legacy JSON repositories.
3. Add Gitleaks/TruffleHog, pip-audit, and a SAST scanner to CI; they were not installed locally.
4. Migrate Pydantic v1 validators/config and `datetime.utcnow()` before future major dependency upgrades.
5. Review the remaining statically unreachable Frontend files with product ownership.
6. Move legacy router-owned persistence/orchestration into existing services in separate contract-tested phases.

## Final status

- Requested hardening implemented: **Yes**
- Acceptance criteria satisfied for the safe automated scope: **Yes**
- Introduced regressions: **No evidence; all available suites pass**
- Frozen prerequisite regressions: **No**
- Rollback/atomicity verification passed: **Yes, through retained full-suite coverage**
- Required artifacts generated: **Yes**
- Safe to review and merge after branch review: **Yes**
- Safe to make repository public without history rewrite/rotation: **No**
