# Report Builder Phase 2 Implementation

## Scope

Phase 2 adds six management-analysis blocks on top of the Phase 1 canonical reporting evidence layer. It does not introduce a second reporting service, database migration, state manager, chart library, or persistence model.

## New management blocks

| Block type | Purpose | Registry category |
|---|---|---|
| `overall_score_movement_bridge` | Reconciles adjacent-month overall score movement | Drivers and Insights |
| `lowest_kpis_weighted_impact` | Ranks valid KPIs by weighted lost points | Drivers and Insights |
| `lowest_employees_current_period` | Shows current-period employee risk with canonical classifications | People |
| `three_month_consecutive_low_performers` | Identifies repeated risk across three exact calendar months | People |
| `applied_configuration_audit` | Discloses data/configuration limitations without repairing data | Data Quality |
| `root_cause_evidence_matrix` | Separates cause category and evidence confidence | Drivers and Insights |

All six blocks are registered in the existing `BLOCK_REGISTRY`, use existing layouts, accept the existing block settings (including `row_limit` and scope override), and are available to system and saved user templates.

## Canonical provider contracts

`ReportingEvidenceService.build()` produces every Phase 2 payload once for an authorized record scope. `ReportStoryService` only selects the registered payload and validates it through the Pydantic contracts in `models/report_definitions.py`. React and the PDF renderer format the returned values but do not recalculate scores, KPI achievement, weighted loss, classifications, or evidence confidence.

The service is dictionary/object neutral so the same evidence layer supports employee records and managerial/corporate analysis dictionaries. Managerial and corporate rows use their period-applied persisted KPI metadata before employee YAML configuration.

## Overall score bridge

- Comparison is the immediately preceding calendar month only.
- Headline scores use all authorized valid current and previous records.
- Matched employees provide KPI contribution movement where comparable.
- Joiner, leaver, scope mix, applied-configuration change, missing/incomparable evidence, and residual are separate addends.
- Team movements are descriptive matched-cohort segmentations and are not added a second time to the mathematical bridge.
- The bridge is `reconciled` inside the configured `0.2` point tolerance; otherwise it is `partial` with a visible residual and warning.
- Narrative uses contribution language and does not assert unsupported causality.

## KPI ranking method

KPI rows are aggregated by team, position, and KPI identity. The default order is:

1. highest weighted lost points;
2. lowest valid achievement;
3. largest valid target gap;
4. largest deterioration in contribution;
5. highest applied weight.

Zero/missing targets, invalid directions, stale persisted KPIs, and zero-weight diagnostics are excluded from scored ranking and returned under `configuration_issues_excluded` or the configuration audit. A real numeric zero remains a valid actual when the target is valid.

## Three-month repeated-risk rule

The service constructs exactly `primary - 2`, `primary - 1`, and `primary`. An employee is classified only when all three calendar months contain a valid score and the canonical grade/status is below threshold in every month. Missing middle months go to `insufficient_history`. Applied KPI signatures are compared across the sequence; changes remain visible through `changed_configuration_disclosed` and a warning.

## Applied configuration audit

The diagnostic block reports stale persisted KPIs, configured-but-missing evidence, weight mismatch, duplicates, zero/missing targets, invalid direction, missing unit, diagnostic metrics, missing grade/status, missing configuration version, and changed compared-period signatures. Every issue includes scope, period, expected/actual state, analysis effect, correction, and whether ranking or reconciliation is blocked. The provider never repairs data.

## Root-cause evidence rules

- `Confirmed`: a persisted root-cause note has an explicit persisted evidence reference.
- `Likely`: derived from persisted action notes, evaluation patterns, or deterministic keyword classification.
- `Data / Configuration Issue`: objective output of the applied-configuration audit.
- `Unclassified / Requires Review`: performance evidence exists but confirmation evidence does not.

Classification supports Process, Staff, Both, Data / Configuration, and Requires Review. Counts are labeled `Evidence mentions` or `Linked action records`; they are never presented as score impact. Corrective-action evidence is omitted when the user lacks `view_actions`, and the authorization boundary is disclosed in the block.

## Template version update

`offshore_monthly_performance_review` Version 3 is seeded alongside Versions 1 and 2. The template creates the management story in this order: cover, executive summary, movement, risk concentration, lowest KPIs, one authorized team/position deep dive per team with current-period data, lowest employees, repeated risk, root causes, actions/planning, configuration warnings, and decisions/next steps.

Latest-version selection exposes Version 3 for new drafts. Existing drafts, generated reports, Version 1/2 system rows, and user-owned templates remain unchanged.

## Builder and PDF behavior

- Builder renderers show a compact movement bridge and management tables with units, confidence, evidence labels, configuration exclusions, and insufficient-history disclosure.
- The PDF uses the identical resolved `slide_data` snapshot as preview.
- PDF output remains 960 x 540 (16:9), limits management tables to at most 10 visible rows, wraps long management cells, and displays row-count/exclusion notes.
- Context caching reuses authorized records for blocks/pages with the same effective scope during validation and generation.
- System Analysis and Management Commentary remain separate snapshots.

## Known limitations / Phase 3 boundary

- Some managerial/corporate analysis rows do not expose a persisted configuration-version identifier. Phase 2 compares effective KPI signatures and emits an audit issue instead of inventing a version.
- Feedback sessions, management decisions, root-cause confirmation workflows, and next-month commitments do not have new persistence in this phase.
- Action notes without an evidence reference remain Likely even if wording sounds definitive.
- PDF tables intentionally show a bounded management summary; full evidence remains in the immutable normalized snapshot.
- No PPTX implementation or schema migration is included.
