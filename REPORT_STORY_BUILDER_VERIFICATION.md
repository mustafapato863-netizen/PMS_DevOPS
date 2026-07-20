# Monthly Performance Review Story Builder - Verification

Verification date: 18 July 2026

## Scope verified

- Persistent, versioned report templates; editable drafts; and immutable generated-report snapshots are separate database concepts.
- The five-stage workflow is Scope, Template, Build Report, Review, and Export PDF.
- Six seeded system templates share the canonical block and layout registries.
- The Offshore Monthly Performance Review expands its 17-page base story by repeating department detail pages only for authorized departments. A two-department fixture produced 26 pages.
- Primary and comparison periods remain explicit. Missing comparison evidence is reported rather than silently substituted.
- The active-page endpoint resolves only the requested page and revalidates scope and block permissions.
- PDF generation is vector based, uses a 960 x 540 point 16:9 page, and stores a SHA-256 integrity hash with the immutable generation snapshot.

## Automated verification

### Backend focused regression

Command:

```powershell
.\.venv\Scripts\python.exe -m pytest -q -p no:cacheprovider tests/test_report_story_service.py tests/test_report_service.py tests/test_migration_graph.py
```

Result: **17 passed**.

This includes evidence for template idempotency, dynamic page expansion, period data refresh, optimistic version conflicts, zero-target handling, consecutive-month rules, contribution reconciliation, PDF dimensions, generated snapshot immutability, authorization revalidation, quantified root causes/actions, feedback reuse, and management-commentary preservation.

### Backend full regression

Command:

```powershell
.\.venv\Scripts\python.exe -m pytest -q -p no:cacheprovider tests
```

Result: **410 passed, 56 warnings**. The warnings are existing Starlette, Pydantic, JWT test-key, and naive-UTC deprecations; there were no test failures.

### Frontend verification

Commands:

```powershell
npx tsc --noEmit
npm run lint
npm test
npm run build
```

Results:

- TypeScript: passed.
- ESLint: passed.
- Vitest: **22 files, 79 tests passed**.
- Vite production build: passed; **3,277 modules transformed**.

### API contract

FastAPI OpenAPI generation succeeded and exposes **11 `/api/reports/story` paths**, covering templates, drafts, active-page data, validation, narrative regeneration, generation, generated-report duplication, generated-report deletion, and registry discovery.

### Migration verification

- `alembic heads`: **`f9a3d6c8b271 (head)`**.
- PostgreSQL offline upgrade SQL from `e3b8c1d4f920` to `f9a3d6c8b271`: generated successfully.
- PostgreSQL offline downgrade SQL from `f9a3d6c8b271` to `e3b8c1d4f920`: generated successfully.
- The full historical migration chain cannot be applied to a temporary SQLite database because the older unchanged revision `975c072657f1` uses `ALTER COLUMN`, which SQLite does not support. The application database target is PostgreSQL, and this limitation predates the story-builder migration.

### PDF verification

- Automated assertions verified `/MediaBox [0 0 960 540]`, page count, immutable stored bytes, and SHA-256 integrity.
- Representative cover, executive-summary, and lowest-KPI/lost-points pages were rendered to PNG with Poppler and visually inspected.
- No clipping, overlap, unreadable labels, or screenshot-based content was found.
- The dedicated renderer and story service contain no non-ASCII typography characters that would cause unsupported-font substitution.

## Transaction and permission evidence

- Draft updates require the expected version and reject stale saves.
- Scope authorization is checked when creating a draft and again during page resolution/generation.
- Generated reports are created from validated snapshots and are not rewritten when their source draft changes.
- Existing transaction rollback tests remain green in the full backend suite.
- Admin-only organization template visibility and block-specific action permissions are enforced by the canonical permission service.

## Manual deployment checks

The following are deployment checks, not code failures:

1. Run the migration against the designated PostgreSQL staging database after confirming the target and backup policy.
2. Generate one report with a production-like authorized user and compare the rendered evidence with the source records.
3. Confirm browser download headers and PDF opening behavior behind the deployed reverse proxy.

## Result

The requested PDF-first Monthly Performance Review Story Builder is implemented and passes the repository's focused, frontend, and full backend automated verification boundaries. No introduced regression was detected.

## Follow-up UI reliability verification

The report-scope navigation and project loading experience were hardened after implementation:

- New-report route reset now completes before the scope initialization effect, preventing the report name or periods from being erased by an initialization race.
- Scope initialization writes the report name, primary period, and valid earlier comparison period as one state update.
- Next validates every required field, displays an actionable message beside the invalid control, and focuses that control instead of failing silently.
- Shared accessible loading skeletons now replace blank route fallbacks and full-page spinners across lazy routes, Reports, Insights, Planning, Report Builder, Employee Profile, Team Management, onboarding, and embedded report/plan panels.
- Follow-up frontend verification: TypeScript passed, ESLint passed, **26 Vitest files / 88 tests passed**, and the Vite production build passed with **3,278 modules transformed**.

## Local PostgreSQL activation

The configured local PostgreSQL database `PMS_Sys` was found at revision `e3b8c1d4f920`, which caused `UndefinedTable: report_templates` and missing `generated_reports` column failures. Revision `f9a3d6c8b271` was applied transactionally after verifying the target database and capturing the existing generated-report count.

- Alembic current after upgrade: `f9a3d6c8b271`.
- Existing generated reports: **0 before / 0 after**.
- `report_templates` and `report_drafts`: present.
- Required generated-report snapshot columns: present.
- System-template seeding: **6 templates**, unchanged after a second call.
- Live authenticated `GET /api/reports/story/templates`: **HTTP 200**, 6 templates on two consecutive calls.
- Live authenticated legacy `GET /api/reports`: **HTTP 200**.
