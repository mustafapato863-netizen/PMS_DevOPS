# Report Builder Phase 1 Verification

## Environment and safety

- Branch: `codex/reporting-phase-1` in root, Backend and Frontend repositories.
- No migration command was run.
- No production data was modified.
- Tests used in-memory/disposable databases and temporary JSON paths.

## Commands and results

### Backend focused reporting and authorization

```powershell
$env:PYTHONPATH='.'
pytest -q -p no:cacheprovider tests/test_reporting_evidence_service.py tests/test_report_story_service.py tests/test_corrective_action_scope.py tests/test_team_action_year_compatibility.py tests/test_rbac.py
```

Result: **42 passed**, 8 warnings.

### Backend Insights regression

```powershell
pytest -q -p no:cacheprovider tests/test_insights_service.py
```

Result: **10 passed**.

### Full backend suite

```powershell
pytest -q -p no:cacheprovider
```

Result: **431 passed**, 56 warnings, 0 failed. The warnings are existing FastAPI/Starlette, Pydantic, JWT test-key, and datetime deprecations.

Audit baseline before Phase 1: **416 passed**, 56 warnings. Final count increased because focused Phase 1 tests were added.

### Frontend tests

```powershell
npm run test -- --run
```

Result: **29 test files passed; 96 tests passed**.

### Frontend lint

```powershell
npm run lint
```

Result: **passed**, 0 errors.

### Frontend production build

```powershell
npm run build
```

Result: **passed**; Vite transformed 3,279 modules and produced the production bundle.

### OpenAPI validation

```powershell
$env:PYTHONPATH='.'
python -c "from app import app; schema=app.other_asgi_app.openapi(); ..."
```

Result: OpenAPI **3.1.0**, **90 paths**, **111 operations**. Redis was unavailable and the existing application fallback was used; schema generation succeeded.

## Test evidence added

- Immediate calendar previous period and year boundary.
- Missing adjacent comparison state.
- Zero-target configuration review with null calculations.
- Real zero versus missing evidence.
- Stale KPI exclusion and mismatch warning.
- Weight-zero diagnostic labeling/no lost points.
- Persisted historical grade/status authority.
- Distinct Top/Bottom populations.
- Data-derived trend titles.
- Matched bridge reconciliation within 0.2 score points with separate joiner/leaver counts.
- Process/Staff provider separation.
- Real milestone serialization.
- Corrective-action employee scope allow/deny.
- Team-action year collision prevention and legacy fallback.
- Story service regression updated to assert provisional root causes and non-quantified action semantics.

## Authorization evidence

Focused tests demonstrate an assigned Manager may target an employee in the authorized team/level and is rejected with `PermissionError` outside it. Existing RBAC tests pass. Router enforcement is server-side for list, write, deactivate, and team actions.

## Score reconciliation evidence

The fixture contains a matched employee, one joiner and one leaver. The assertion verifies:

`reported score-point change = KPI movements + joiner + leaver + scope mix + configuration mismatch + missing evidence + residual`

within the contract tolerance.

## Zero-target evidence

The focused contract test verifies `state=configuration_requires_review` and null `target`, `achievement`, and `lost_points`. Insights tests verify no target percentage is reported and analysis coverage does not count the invalid KPI.

## Known remaining gaps / Phase 2

- Persisted confirmed root-cause evidence, feedback sessions, management decisions and next-month commitments require business/persistence work outside this phase.
- React threshold fallback remains only for legacy payloads that lack a backend-derived grade; canonical records should always supply one.
- Report/PDF visual redesign, new templates, Step 3 redesign, PPTX, scheduling and AI narratives remain out of scope.
- Existing deprecation warnings were not changed because they are unrelated to Phase 1.

## Final boundary

Verification stops after canonical reporting evidence, correctness, authorization, compatibility changes, and documentation. Phase 2 was not started.
