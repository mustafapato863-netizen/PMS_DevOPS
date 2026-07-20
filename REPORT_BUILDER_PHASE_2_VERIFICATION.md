# Report Builder Phase 2 Verification

## Validation baseline and results

The focused Phase 1 reporting baseline before Phase 2 changes was:

- `python -m pytest tests/test_reporting_evidence_service.py tests/test_report_story_service.py -q`
- Result: **26 passed**.

Final focused verification:

- Same command after Phase 2.
- Result: **37 passed**.

Final regression verification:

| Command | Result |
|---|---|
| `python -m pytest -q` | **442 passed**, 57 existing deprecation/environment warnings |
| `npm test` | **30 files passed, 99 tests passed** |
| `npm run lint` | Passed, no lint errors |
| `npm run build` | Passed, Vite production build generated |
| OpenAPI schema inspection | **90 paths**, including **18 `/api/reports` paths** |

The OpenAPI inspection logged Redis fallback and existing Pydantic configuration warnings; schema generation succeeded and report API paths were unchanged.

## Tests added or extended

- Exact/partial score bridge reconciliation and joiner/leaver separation.
- Weighted lost-points ordering.
- Zero-target and diagnostic exclusion.
- Current-period lowest-employee ordering.
- Exact three-calendar-month qualification and missing-middle-month exclusion.
- Applied-configuration continuity disclosure.
- Configuration audit issue detection without repair.
- Confirmed root cause requiring persisted evidence.
- Likely process/staff/both classification and data/configuration grouping.
- Frequency labels not being represented as score impact.
- Managerial dictionary records using period-applied KPI metadata.
- Version 3 system-template seeding while preserving Versions 1/2 and a user-owned template.
- Complete Phase 2 block population in the generated Step 3 story.
- Action-evidence authorization boundary.
- Preview/PDF normalized-data equality and immutable Version 3 snapshot.
- Compact frontend movement, KPI exclusion, and insufficient-history states.

## Acceptance evidence

### Movement reconciliation

Focused tests sum KPI contributions, joiner, leaver, scope, configuration, missing-evidence, and residual addends and assert the result matches the headline score-point movement within the canonical tolerance. Non-zero residual produces `partial`; an exact bridge produces `reconciled`.

### Three-month sequence

The test sequence April 2026, May 2026, June 2026 qualifies. A March/May/June sequence is rejected and returned as insufficient history. A changed applied KPI weight returns `changed_configuration_disclosed` with a warning.

### Zero-target and diagnostic evidence

Zero-target rows have no achievement or lost points and are returned in the configuration exclusion/audit output. Zero-weight diagnostics carry the operational-diagnostic label and do not enter PMS lost-points ranking.

### Permission evidence

A Viewer can resolve performance/root-cause reporting evidence without `view_actions`; the corrective-action repository is not loaded and the normalized output includes an explicit authorization-boundary row. Admin/Manager action evidence remains available through existing permissions.

### Template and user-template evidence

System seeding stores Versions 2 and 3 for the canonical monthly review and returns only Version 3 for new drafts. A private user template remains Version 1 with its original definition. No overwrite or archive occurs.

### Preview/PDF identity

The Version 3 generation test resolves the movement page in preview, generates the PDF, then asserts the generated report's immutable `data_snapshot_json` contains the identical normalized block data. It also verifies 12 pages for a one-team story and a 960 x 540 media box.

### Visual PDF evidence

A six-page verification PDF was generated from canonical Phase 2 evidence and rendered with Poppler at 110 DPI. `pdfinfo` reported **6 pages** and **960 x 540 pt**. All six management blocks were visually inspected for page bounds, headers/footers, table limits, labels, units, residual visibility, wrapped text, and overlap. No clipping outside page bounds or overlapping blocks was observed. Temporary visual-verification artifacts were kept under `tmp/pdfs/phase2_verification` only during validation.

## Database and transaction boundary

- No Phase 2 migration or schema change was created.
- No production database data was modified during verification.
- Reporting tests use an in-memory SQLite database and immutable generated-report snapshots.
- Rollback/count restoration is not applicable to Phase 2 because it adds no database-mutating workflow beyond the already-tested template/draft/report transactions.

## Remaining Phase 3 items

- Dedicated persisted feedback-session workflow/status.
- Structured management decisions and next-month commitments.
- Explicit root-cause confirmation workflow.
- Persisted configuration-version identifiers where source contracts do not currently expose them.
- Any future PPTX output.

Phase 3 was not started.
