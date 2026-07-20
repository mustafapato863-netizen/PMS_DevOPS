# Report Builder Phase 1 Implementation

## Scope

Phase 1 establishes canonical reporting evidence and correctness. It does not redesign the Report Builder, add persistence models, migrate data, or change PDF styling.

## Canonical architecture

`ReportingEvidenceService` is the reporting interpretation layer over already-authorized analysis records. Record collection and authorization remain in the existing services. The flow is:

`ReportStoryService -> InsightsService authorized analysis union -> DashboardRecordService.list_analysis_records + ManagementBSCService.list_analysis_records -> ReportingEvidenceService -> report block contracts`

The service returns normalized summary, KPI evidence, grade distribution, employee rankings, adjacent-period comparison, score movement reconciliation, trend metadata, and data-quality warnings. `ReportStoryService` delegates these meanings instead of recalculating them independently.

## Existing services reused

- `DashboardRecordService.list_analysis_records()` for employee evidence, including SQL-only records.
- `ManagementBSCService.list_analysis_records()` through the existing Insights authorized union.
- `InsightsService` for direction-aware analytical narratives and authorized scope composition.
- `ActionRepository`, `CorrectiveActionService`, `PlanningRepository`, and existing authorization helpers.
- Persisted performance score, grade, status, KPI actual, target, weight and contribution values.
- `ReportTemplate` remains canonical; `SavedReportTemplate` remains compatibility-only.

## KPI inclusion rules

- A scored KPI must match the effective configuration by configured key or label and have a positive applied/configured weight.
- Persisted unknown/stale KPI evidence remains stored but is excluded from scored interpretation and emits an applied-configuration mismatch warning.
- Configured weight-zero metrics are diagnostics: `included_in_score=false`, `weight=0`, no weighted contribution/lost points, and the exact label **Operational diagnostic — not included in PMS score**.
- No Show and AHT are produced only from real operational fields. No Show target remains 20% and lower is better.

## Zero-target and unavailable rules

- Missing or zero target returns `state=configuration_requires_review`.
- Achievement, meaningful target value, weighted contribution interpretation, lost points, and projected impact are null.
- Real numeric zero actual values remain zero when a valid non-zero target exists.
- Comparison unavailable, missing, invalid configuration, and real zero are separate states; report comparison providers no longer use zero placeholders.

## Grade and status

- Persisted historical grade/status are authoritative.
- When absent, the backend reporting layer derives them from the effective team/level/position configuration.
- React now honors persisted A-E grades for every team. Its threshold fallback is compatibility-only for legacy records missing a backend grade.

## Previous-period rule

Comparison is always the immediately preceding calendar month, including December across a year boundary. Missing adjacent data returns `comparison_state=unavailable`; neither Insights nor Story jumps to an older available month.

## Movement semantics and reconciliation

The contract separates:

- current/previous overall score;
- total score-point change;
- matched/current-only/previous-only employees;
- KPI contribution score-point movements;
- joiner, leaver, population/scope mix, configuration mismatch, missing evidence, and residual effects;
- reconciliation state and a documented 0.2 score-point rounding tolerance.

Headline averages use all authorized valid records. Attribution uses matched employees where possible. Any unreconciled amount remains explicit rather than being fabricated as KPI movement. Percentage-valued KPI changes expose absolute change, percentage-point change, and relative percentage change separately.

## Trend and population behavior

Trend contracts include available periods, count, requested range, actual range, state and a data-derived title. Top and bottom rankings come from one canonical ordering; top employees are excluded from bottom, so a one-person population appears only once.

## Root causes, milestones and actions

- Rule-derived Process/Staff classifications are `confidence=likely`; data/configuration issues are separate.
- Process and Staff block registry providers are distinct filters.
- Milestone blocks serialize real `PlanMilestone` rows, including plan, owner, dates, status and overdue state.
- Mention counts are labeled **Action mentions**, not impact.
- Coaching/monitoring records are not quantified plans, projected impacts, or completed interventions unless baseline, target, owner, due date and measurement criteria exist. Completion additionally requires closure evidence.

## Authorization and compatibility

- Corrective-action lists are filtered by team/performance-level authorization.
- Create/update/deactivate validates the target employee scope server-side.
- Team-action reads and writes require the existing action permissions plus team authorization.
- Admin behavior remains unrestricted; Executive access was not broadened.
- Team-action JSON keys are now `team + year + month`. Reads accept an optional year and fall back to a legacy yearless record only when no year-specific row exists. New year-specific saves never overwrite another year.

## No schema change

No migration or new persistence model was created or applied. Existing JSON and database contracts are preserved with additive optional fields.

## Phase boundary

No Step 3 redesign, new report templates, feedback/decision/commitment persistence, PDF redesign, scheduling, AI narrative generation, PPTX export, or Phase 2 work is included.
