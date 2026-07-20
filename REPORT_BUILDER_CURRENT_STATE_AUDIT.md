# PMS Report Builder — Current-State Audit

**Audit date:** 18 July 2026<br>
**Scope:** Read-only inspection of the current repository and the June 2026 Egypt dashboard PDF<br>
**Application changes:** None<br>
**Database changes:** None

> The PDF was used only to identify the visible June 2026 views and sections. The requested repository path `docs/reporting/PMS_Egypt_June_Report_No_Sidebar.pdf` is not present in the working tree; the attached file at `\\sghfslogix\UserData\SGHD70204\Downloads\PMS_Egypt_June_Report_No_Sidebar.pdf` was inspected instead. No metric below is asserted from the screenshots alone. Data and calculation claims are traced to repository code.

## 1. Executive audit summary

The repository already contains a substantial reporting platform rather than a blank export feature. It has persisted system/user templates, editable drafts, versioned optimistic saves, block/layout registries, scope-aware page resolution, PDF generation, generated-report snapshots, Insights integration, Planning integration, and corrective-action integration. The current story builder can already create a template-derived Step 3 and has real-data providers for score summaries, trends, grades, KPI contributions, people rankings, actions, insights and plans.

The implementation is not yet a single canonical reporting pipeline. There are three materially different calculation/view paths:

1. Dashboard pages calculate much of the presentation model in React from `/api/performance`, static team configuration, JSON weights and local fallbacks.
2. Insights builds a more controlled backend analysis workspace from SQL plus the rich JSON evidence mirror and management BSC records.
3. Reporting has both a legacy `ReportService` and the newer `ReportStoryService`; the latter independently recalculates summaries, KPI aggregation, people risk and score movement.

This produces avoidable semantic drift. Confirmed examples include fixed “Last 6 Months” labels when only one or two periods exist, different grade/status rules, zero-target handling that changes between components, report placeholders that carry numeric zero while displaying `N/A`, and “Impact” in the Executive action card actually being a count of action-note mentions.

The most important conclusion is: **the next phase should consolidate report view models around persisted `PerformanceRecord`/`KPIValue` evidence and `InsightsService`, not copy React dashboard calculations into the PDF layer.** Most management-report blocks can be completed without schema changes. Structured management decisions, confirmed-cause approval, dedicated feedback sessions and retention-grade immutable history are the capabilities most likely to need persistence or explicit business rules.

## 2. Current reporting architecture

### Runtime layers

| Layer | Current implementation | Audit assessment |
|---|---|---|
| Dashboard UI | `ExecutiveView`, `TeamDashboardView`, `MarketingDashboardView` and their child components | Rich visual components, but substantial client-side calculation and hardcoded fallback logic |
| Performance API | `Backend/api/routers/performance.py` | Applies authenticated team scope, then delegates record lookup to `DashboardRecordService` |
| Evidence resolver | `Backend/services/dashboard_record_service.py` | SQL determines available record keys; rich JSON records are returned when matched; `list_analysis_records()` can preserve SQL-only rows |
| Insights API | `Backend/api/routers/insights.py` → `InsightsService.generate_workspace()` | Strongest existing deterministic analysis layer; includes data-quality warnings and direction-aware KPI analysis |
| Planning API | `Backend/api/routers/planning.py` → `PlanningService` → `PlanningRepository` | Persisted objectives, KPIs, actions, milestones, notes and expected/actual impact |
| Actions API | legacy employee/action routers → `CorrectiveActionService` → `ActionRepository` | Real persistence exists, but the legacy write contract exposes only a small subset of the `Action` model |
| Legacy reports | `Backend/services/report_service.py` | Separate preview/generate/template route family and duplicated report assembly |
| Story reports | `Backend/services/report_story_service.py` | Current editable block/page architecture; resolves real data and persists immutable-style snapshots |
| Report rendering | `Backend/services/report_pdf_renderer.py` | Server-side PDF renderer over resolved block data; dashboard React components are not reused directly |
| Report UI | `ReportBuilderView`, Steps 1–5, `reportBuilderStore`, `BlockRenderer` | Supports template → generated pages → edit → validate → export |

### Sources of truth currently in use

- SQL: `teams`, `employees`, `performance_records`, `kpi_values`, `actions`, planning tables, report tables and upload logs.
- Static applied employee configuration: `Backend/config/teams/*.json`, loaded by `Backend/config/loader.py`.
- Legacy JSON repositories: `Backend/data/performance_records.json`, `kpi_weights.json`, `targets.json`, `team_actions.json` and related files.
- Management configuration uses separate SQL models (`ManagementKPIConfig`, history and snapshots) and `ManagementBSCService`, correctly separated from employee configuration.

The hybrid SQL/JSON evidence resolver is intentional compatibility code, but it is also the main architectural risk. `InsightsService` calls `DashboardRecordService.list_analysis_records()` and includes management BSC analysis records. Both report services currently call `list_records()` instead, so SQL-only evidence and management records can be omitted from report data even when Insights can see them.

## 3. Current data flow

### Dashboard flow

`React page` → hook (`usePerformanceData`, `useMarketingData`, `useInsightsWorkspace`, `useActionStore`) → API → router scope check → service/repository → SQL and/or JSON evidence → React aggregation and formatting.

The generic dashboards download a broad `/api/performance` dataset and then filter/aggregate it in the browser. `usePerformanceData.ts`, `types.ts`, `kpiScore.ts`, `teamKpiAnalysis.ts` and the marketing analytics modules all contain business calculations.

### Story-report flow

`Step 1 scope` → `Step 2 system/user template` → `POST /api/reports/story/drafts` → template pages expanded per authorized team with primary-period data → persisted `ReportDraft.definition_json` → `GET .../pages/{page_id}` → `ReportStoryService._resolve_provider()` → generic `BlockRenderer` → validate → resolve all pages again → PDF → `GeneratedReport` snapshots.

The generated row stores the final definition, system narrative, management commentary, resolved data, validation output, PDF bytes and an integrity identifier. It is therefore suitable as an evidence snapshot, subject to the deletion caveat in section 10.

### Configuration and calculation flow

- Employee imports calculate and persist `score`, `grade`, KPI actual/target/achievement/weight/contribution.
- Dashboard React code frequently recomputes values from raw fields and JSON weights.
- Insights uses persisted KPI values when present, enriching labels/direction/unit from the applied config, but it does not filter persisted KPI keys out when they are absent from the current visible config.
- Story reports average persisted KPI rows and independently derive lost points and contribution movement.

## 4. PDF page-to-frontend-component mapping

| PDF page/view | Producing page | Visible sections and producing components |
|---|---|---|
| 1 — Executive Overview | `Frontend/src/pages/ExecutiveView.tsx` | Four cards: `KpiCard`; grade distribution/risk table: `ExecutivePerformancePanel`; actions summary: `ActionsSummaryCard`; team table: `TeamSummaryTable` |
| 2 — Pre-Approvals IP Offshore | `Frontend/src/pages/TeamDashboardView.tsx` | Summary/KPI cards: `TeamKpiSection`; grade/trend: `TeamChartsSection`; top/bottom: `TeamRosterSection`; development/actions: inline section in `TeamDashboardView`; summary/analysis: `TeamPerformanceIntelligence` and `TeamPerformanceAnalysis` |
| 3 — Inbound | `TeamDashboardView.tsx` | Same generic team components; call-centre analysis additionally comes from `buildTeamKpiAnalysis(... includeNoShow: true)` and Insights operational analysis |
| 4 — Outbound | `TeamDashboardView.tsx` | Same generic team components; includes synthetic No Show and AHT analysis (`includeNoShow`, `includeAht`) |
| 5 — Marketing Overview | `MarketingDashboardView.tsx` → `MarketingOverview.tsx` | Overview cards, position cards, position comparison, grade distribution, attention list, score trend and insights are generated from `buildMarketingInsights()` |
| 6 — Media Buyer | `MarketingDashboardView.tsx` → `MarketingPositionDetail.tsx` | KPI cards: `PerformanceKpiCard`; charts: `TeamChartsSection`; locally ranked top/bottom; performance analysis from marketing position analysis helpers |
| 7 — Graphic Designer | `MarketingPositionDetail.tsx` | Same position-detail component with position-filtered config and records |
| 8 — Social Media Specialist | `MarketingPositionDetail.tsx` | Same position-detail component; one-record top and bottom duplication follows the local ranking logic |

The PDF pages are therefore screenshots of two dashboard families: the generic team dashboard and the separate marketing position dashboard. The Report Builder currently renders normalized report block data, not these React trees.

## 5. Frontend-component-to-API mapping

| Component/hook | API(s) | Use |
|---|---|---|
| `ExecutiveView` / `useAllTeamsSummary` | `GET /api/performance`, `GET /api/settings/weights` | Workforce, score, grade and team aggregation |
| `ActionsSummaryCard` / `useActionStore` | `GET /api/corrective-actions` | Action counts, employee counts, action types and root-cause-note mention counts |
| `TeamDashboardView` / `useTeamData` | `GET /api/performance`, `GET /api/settings/weights`, `GET /api/config/teams/{team}` | Team summary, KPI cards, grades, trend and roster |
| `TeamPerformanceAnalysis` | `GET /api/insights/workspace` | Canonical insight narratives for the selected team/period |
| Team development/action section | `GET/POST /api/team-actions`; `GET /api/corrective-actions` | Free-text team key action and employee corrective-action summary |
| Action modal/store | `POST /api/employee/{employee_id}/corrective-actions`; `DELETE .../{action_id}` | Legacy create/update/deactivate contract |
| `MarketingOverview` / `MarketingPositionDetail` | `GET /api/config/teams/Marketing?performance_level=Employee`, `GET /api/performance?team=Marketing&performance_level=Employee` | Position-scoped configuration and records; most analysis is client-side |
| Report Step 2 | `GET /api/reports/story/templates`, `POST /api/reports/story/drafts` | Select template and automatically create Step 3 pages |
| Report Step 3 | `GET /api/reports/story/registry`, `GET/PUT /api/reports/story/drafts/{id}`, `GET .../pages/{page}` | Edit definitions and resolve real data per page |
| Report Steps 4–5 | `POST .../validate`, `POST .../generate` | Validation and PDF snapshot generation |
| Planning page/hooks | `/api/planning/options`, `/api/planning`, `/api/planning/{id}` and item/note endpoints | Persisted plan execution data |

## 6. API-to-service mapping

| API | Service path | Authorization behavior |
|---|---|---|
| `GET /api/performance` | `DashboardRecordService.list_records()` | Authenticated scope and team filter applied in router |
| `GET /api/config/teams*` | `config.loader` directly | No authentication dependency on these read endpoints |
| `GET /api/settings/weights` | `JSONKPIWeightsRepository` directly | No authentication dependency on read endpoint |
| `GET /api/corrective-actions` | `CorrectiveActionService.list_all()` | Role check only; no team/level scope filtering |
| Employee corrective-action writes | `CorrectiveActionService.save/deactivate()` | Admin/Manager role check; no explicit target-team scope validation in the route/service |
| `GET/POST /api/team-actions` | `JSONTeamActionsRepository` directly | GET is unauthenticated/unscoped; POST requires `create_actions`, but does not validate team assignment |
| `GET /api/insights/workspace` | `InsightsService.generate_workspace()` | Authenticated scope, role and team/level filters |
| `/api/planning*` | `PlanningService` → `PlanningRepository` | Permission plus service scope validation |
| `/api/reports/story*` | `ReportStoryService` → report/action/planning repositories and Insights | Permission checks, ownership checks and report-scope revalidation |
| Legacy `/api/reports/*` | `ReportService` | Permission and scope checks, but separate collection/rendering path |

## 7. Service-to-database-model mapping

| Service/capability | Models or persisted source |
|---|---|
| Performance score/grade/status | `PerformanceRecord`; employee and team identity from `Employee` and `Team` |
| KPI actual/target/weight/contribution | `KPIValue`; applied configuration originates from `TeamKPIConfig` and/or static team JSON; management uses `ManagementKPIConfig` and snapshots/history |
| Dashboard rich evidence | Legacy `performance_records.json`, joined to SQL keys by `DashboardRecordService` |
| Corrective actions | `Action`; legacy UI exposes only action type/text/root-cause note/month/year |
| Quantified performance plans | `PerformancePlan`, `PlanObjective`, `PlanKPI`, `PlanMilestone`, `PlanNote`, `PlanInsightLink`, plus linked `Action` |
| Report templates | `ReportTemplate.definition_json`, versioned by `template_key` + `version` |
| Editable reports | `ReportDraft` with scope, periods, definition, commentary, validation and optimistic `version` |
| Generated history | `GeneratedReport` with PDF bytes and definition/narrative/data/validation snapshots |
| Legacy saved templates | `SavedReportTemplate`, separate from `ReportTemplate` |
| Upload/data-quality evidence | `UploadLog` |
| Team key action | `Backend/data/team_actions.json`; no SQL model and no year in the key/schema |

## 8. Existing reusable components

### Safe to reuse as presentation components after receiving canonical view models

- `KpiCard` and `PerformanceKpiCard` for metric presentation.
- `TeamChartsSection` chart styling, after replacing the fixed period label with data-derived text.
- `TeamRosterSection` table/performer presentation, not its local business derivations.
- `ExecutivePerformancePanel` visual composition for grade/risk display, after backend view-model alignment.
- `ActionsSummaryCard` visual layout, after replacing text-mined “Impact” with an accurately named count or a real impact measure.
- `TeamPerformanceAnalysis` and `TeamPerformanceIntelligence` narrative/card patterns.
- `MarketingOverview` and `MarketingPositionDetail` layouts, but not their independent calculation functions.
- Report `BlockRenderer`, thumbnails, library, layouts and Step 3 editing controls.

Directly mounting interactive dashboard components inside server PDF generation would couple browser state, responsive layouts and client calculations to the export. The safe reuse boundary is **design tokens and normalized view models**, not the entire interactive React page.

## 9. Existing reusable backend services

- `DashboardRecordService.list_analysis_records()` is the safest employee evidence resolver because it retains SQL-only rows.
- `ManagementBSCService.list_analysis_records()` is the canonical management/corporate evidence path.
- `InsightsService.generate_workspace()` already handles explicit periods, previous available periods, weighted drivers, zero targets, direction, operational No Show/AHT diagnostics and data-quality coverage.
- `ReportStoryService` provides scope expansion, permission pruning, draft lifecycle, provider resolution, validation, snapshots and generation.
- `PlanningService` and `PlanningRepository` provide quantified baseline/target/current/impact, accountable owner, due dates, milestones, notes and closure requirements.
- `CorrectiveActionService` and `ActionRepository` provide persisted action history, but require a richer contract for management reporting.
- `ReportRepository` provides versioned templates, optimistic draft updates and generated-report persistence.
- `config.loader.resolve_team_config()` is the correct static employee-config resolver; report/insight providers should use it to validate visibility, not invent KPI lists.

## 10. Existing persisted reporting capabilities

| Capability | State | Evidence |
|---|---|---|
| System and user story templates | Already supported | `ReportTemplate`, version-aware seeding in `ReportStoryService.ensure_system_templates()` |
| Full and Compact system stories | Already supported | `report_system_templates.py` Full v2 and Compact v1 |
| Reuse template to build Step 3 | Already supported | Step 2 creates a draft; service expands one team page per authorized team with current-period data |
| Editable pages/blocks/commentary | Already supported | `ReportDraft.definition_json`, `management_commentary_json`, frontend store and Step 3 |
| Saved legacy report configuration | Already supported | `SavedReportTemplate` and `/api/reports/saved-templates` |
| Generated evidence snapshot | Already supported | final definition, narrative, data, validation and PDF stored on `GeneratedReport` |
| Immutable generated-report history | Partially supported | Generated drafts cannot be edited and snapshots have integrity IDs, but `DELETE /api/reports/story/generated/{id}` physically deletes the row and no retention/audit-delete policy is enforced |

There are two persisted template architectures (`ReportTemplate` and `SavedReportTemplate`) and two generation services. They should be converged through compatibility, not expanded further.

## 11. Missing report blocks and capability classification

### Required management capabilities

| Capability | Classification | Current evidence and gap |
|---|---|---|
| June versus May comparison | **Already supported** | Story drafts persist explicit primary/comparison periods. Insights instead chooses the previous available explicit period; the UI must label which rule is in use. |
| Overall PMS Score movement explanation | **Already supported** | `ReportStoryService._movement()` produces an evidence-based explanation and warns when comparison is unavailable. |
| Contribution-based reconciliation | **Partially supported** | Contribution deltas are summed and a residual is shown. It does not yet decompose matched-population, joiner/leaver, configuration-version and missing-data effects. |
| Lowest KPIs by weighted lost points | **Already supported** | `_kpis()` calculates `weight - contribution` and sorts by lost points. |
| Lowest employees in selected month | **Already supported** | `_people(lowest=True)` and `lowest_employees`/`bottom_performers` providers. |
| Below target for three consecutive valid months | **Partially supported** | `_consecutive_low()` requires the three preceding calendar periods and excludes incomplete histories; it does not select the last three valid comparable periods or validate configuration continuity. |
| Root-cause evidence | **Partially supported** | Corrective-action notes, evaluation root cause and config issues are returned, but evidence quality and source confirmation are weak. |
| Confirmed versus likely causes | **Partially supported** | Labels exist, but “confirmed” means a free-text action note exists; no approver, confirmation status or timestamp is persisted. |
| Process versus staff issues | **Partially supported** | `_issue_category()` is keyword based. Worse, `process_issues` and `staff_issues` both use the unfiltered `root_causes` provider and therefore currently return the same rows. |
| Quantified action plans | **Partially supported** | Fully available when an `Action` is linked to a `PerformancePlan`; most legacy corrective actions lack this link. |
| Baseline, target, projected impact, owner, due date | **Partially supported** | Schema already supports all fields via `PerformancePlan`/`Action`; legacy action API/UI does not capture them. No schema change is required to expose existing fields. |
| Feedback-session status | **Partially supported** | Report service infers sessions from action-type words and due/status fields. There is no dedicated session record or attendance/outcome evidence. |
| Management decisions | **Missing and persistence may be required** | `decisions_required` generates prompts and commentary stores free text; there is no structured decision, approver, status or decision date. |
| Next-month review commitments | **Partially supported** | Plan milestones and review-period `PlanNote`s can represent follow-up, but no report-level commitment/acceptance workflow exists. |
| Saved report templates | **Already supported** | Both story and legacy template persistence exist. |
| Template automatically builds Step 3 | **Already supported** | Confirmed in Step 2 and `create_draft()`. |
| Immutable generated history | **Partially supported** | Snapshot/integrity support exists; physical delete and absent retention policy prevent a true immutable audit ledger. |

### Block-level gaps

| Missing or incomplete block | Classification | Next technical need |
|---|---|---|
| Exact score-change bridge (KPI + population + config + residual) | **Missing but existing data is sufficient** for an initial matched-cohort bridge | New backend query/service over persisted scores/contributions and explicit periods; configuration-version rule must be agreed |
| Applied-configuration audit block | **Missing but existing data is sufficient** | Compare persisted KPI keys/weights with resolved applied config and upload/config history |
| Confirmed root-cause register | **Missing and persistence may be required** | Structured cause, classification, evidence reference, confirmer and timestamp |
| Process issue register vs staff issue register | **Missing but existing data is sufficient** for provisional categorization | Fix provider filtering; business-approved category taxonomy is still required |
| Quantified action portfolio | **Partially supported** | Query linked actions/plans and surface validation warnings; enrich legacy action write contract |
| Feedback sessions register | **Missing and persistence may be required** | Dedicated session schedule/completion/outcome if inferred actions are not acceptable |
| Management decision log | **Missing and persistence may be required** | Structured decision/owner/date/status; commentary alone is not sufficient |
| Next-month commitments | **Blocked by unclear business rules** | Decide whether commitments are milestones, notes, actions or a separate approved decision object |
| True milestone overview | **Partially supported** | Current `milestones` provider returns plan-level rows rather than `PlanMilestone` rows; fix query only |
| Plan execution/status summary | **Partially supported** | Current Full template uses `performance_status` beside feedback, not a plan execution summary |
| Data-quality configuration coverage | **Partially supported** | `missing_configuration`, `invalid_targets` and general data-quality blocks currently collapse mainly to zero-target rows |

## 12. Confirmed bugs and inconsistencies

1. **KPIs can appear outside the visible applied configuration.** `InsightsService._configured_kpi_values()` enriches persisted values but does not filter persisted keys against resolved config. `ReportStoryService._kpis()` and frontend `getKPIsForAgent()` also consume every persisted KPI row. Team analysis additionally injects operational No Show and AHT. Operational diagnostics are legitimate, but the UI/report must explicitly label them as non-weighted diagnostic metrics.
2. **Zero targets have conflicting outcomes.** Insights suppresses achievement and emits data-quality warnings; marketing explains the ambiguity; `teamKpiAnalysis` makes `targetMet` false and achievement zero; `calculateWeightedKpiScore()` uses a `0.0001` denominator and can award a capped full contribution for a higher-is-better KPI; dynamic KPI cards may mark a positive actual against zero as on target.
3. **Grade/status semantics conflict.** The generic frontend thresholds are A 95/B 90/C 80/D 70, while marketing uses resolved team thresholds and maps B and C to “Meets”. Other client helpers use 95/85/75/60 planning thresholds. Backend import comments describe older thresholds while executable assignment differs. Report `_is_below()` prioritizes stored status/grade and only falls back to score `<70` when both are absent.
4. **“Last 6 Months” is a fixed label.** `TeamChartsSection.tsx` always renders it even when the data has one or two points, as seen on the marketing pages. The report trend provider correctly returns up to six available periods but the dashboard title remains inaccurate.
5. **Root-cause “Impact” is a count.** `ActionsSummaryCard` counts regex mentions in `root_cause_note` and displays `{count}x` under “Impact”. It is frequency, not score or employee impact.
6. **Corrective actions are structurally sparse through the legacy UI.** The model has owner/due/priority/KPI/evidence/completion fields, but `CorrectiveActionService.save()` only accepts month, action string, root-cause note, year and id.
7. **Placeholder zeros can enter report charts.** `score_comparison` uses `previous_score or 0` and `average_score or 0` while the display string says `N/A`; summary movement also defaults missing change to a positive tone.
8. **Rounding and movement semantics differ.** Some components use absolute score-point deltas, some relative percent changes, and some call weighted contribution points `%`. A 1-point score move and a 1% relative move can therefore receive the same visual suffix.
9. **Duplicate calculation logic is extensive.** KPI/score/grade/status/trend logic exists in `usePerformanceData.ts`, `types.ts`, `kpiScore.ts`, `teamKpiAnalysis.ts`, marketing analytics, `InsightsService`, `ReportService` and `ReportStoryService`.
10. **Milestone block is semantically wrong.** The `milestones` provider serializes plans (name/team/status/owner/due) instead of `PlanMilestone` rows.
11. **Process/staff issue blocks are not separated.** Both registry entries route to identical unfiltered root-cause rows.
12. **Team key actions are weakly identified.** `team_actions.json` keys by team and month without year, so a later year can collide; this data is not integrated into the story report.
13. **Top and bottom can contain the same employee.** With one measured employee, marketing local ranking renders that employee in both groups, visible on Social Media Specialist.
14. **Report and Insights evidence coverage differs.** Insights uses `list_analysis_records()` plus management records; report services use `list_records()`, which can omit SQL-only and management evidence.
15. **The data-quality registry overstates distinct behavior.** Several distinct block names resolve to the same zero-target-centric provider output.

## 13. Items requiring frontend changes only

- Make trend titles data-derived: “Available trend — 2 periods” or “June 2026 only”.
- Rename action root-cause “Impact” to “Action mentions” until real impact is supplied.
- Label synthetic No Show/AHT as “Operational diagnostic — weight 0/not scored”.
- Never render a numeric zero when the API state is `N/A`/missing.
- Standardize suffixes: score change `%`, percentage-point wording in narrative, relative movement explicitly labeled.
- Prevent the same person appearing in both top and bottom for populations too small to form distinct groups.
- Reuse backend-supplied grade/status instead of reclassifying where canonical values exist.
- Display report block provenance, period rule and warning state in the builder.

These changes are safe only if they do not conceal the backend inconsistencies listed above.

## 14. Items requiring backend changes without schema changes

- Make story reports use `list_analysis_records()` and, where allowed, management BSC analysis records.
- Filter report/Insight scored KPIs by the effective visible configuration; retain extra metrics only as explicitly non-scored diagnostics.
- Create one canonical score/KPI view-model service used by Insights and reports.
- Implement a matched-cohort contribution bridge with residual categories.
- Fix process/staff root-cause filtering and milestone serialization.
- Expose existing `Action` and `PerformancePlan` fields through a richer service contract.
- Enforce team/level scope on corrective-action list and writes.
- Add year to team-action lookup behavior or retire this JSON feature in favor of Planning/Actions; adding year to JSON shape does not require a DB migration.
- Make all report providers return explicit `state`, `value: null` and warnings for unavailable data.
- Unify template APIs behind `ReportTemplate` while maintaining compatibility reads for legacy saved templates.

## 15. Items that may require database changes

No migration should be designed until the business decisions in section 21 are answered. Likely persistence candidates are:

- Structured root-cause confirmation and evidence approval.
- Dedicated feedback-session scheduling, attendance, outcome and follow-up.
- Management decision records with owner, approver, date, status and linked evidence.
- Report-level next-month commitments if Planning milestones/notes are not accepted as the canonical representation.
- Generated-report retention/deletion audit if regulatory immutability is required.

Baseline/target/owner/due/evidence/completion do **not** inherently require new columns; the existing Planning/Action models already contain them.

## 16. Items that should reuse Insights, Planning, corrective actions, or feedback functionality

- KPI drivers, severity, zero-target warnings, previous-period validity and data coverage should reuse `InsightsService.generate_workspace()`.
- Overall movement should reconcile `PerformanceRecord.score` with persisted `KPIValue.contribution`, then expose Insights as explanation, not independently recalculate the score.
- Action baselines, targets, owners, due dates, expected/actual impact and review cadence should reuse `PerformancePlan`, `PlanKPI`, `PlanMilestone` and linked `Action`.
- Employee interventions and closure evidence should reuse `Action`; the API must stop discarding fields already present on the model.
- Feedback can temporarily reuse coaching/PIP/training actions only if the product explicitly accepts inference. Otherwise it needs dedicated persistence.
- Management commentary should remain separate from deterministic system analysis, as the current draft model already does.

## 17. Security and authorization risks

1. `GET /api/corrective-actions` returns all employee actions to Admin, Manager and Executive roles without team/level filtering. The client then filters after receiving the data.
2. Corrective-action save/delete checks role but does not explicitly verify the employee’s team is within the manager’s assigned scope.
3. `GET /api/team-actions` is unauthenticated and unscoped. POST checks `create_actions` but not access to the supplied team id.
4. `GET /api/config/teams*` and settings weight/target reads have no permission dependency. Configuration may not be confidential, but this should be an explicit policy.
5. `ReportStoryService` correctly revalidates report scope, block permissions and ownership; this should remain the reference pattern.
6. Generated-report download is owner/Admin scoped, but generated reports can be physically deleted. If reports are governance evidence, delete must become archive/audited retention.
7. Current scope helpers treat `Executive` as self-only for performance records despite an aggregated-analytics permission. This is a functional/role-policy inconsistency requiring clarification, not a reason to broaden access automatically.

## 18. Risks of overengineering

- Building a second analytics engine inside the report renderer would worsen drift.
- Reusing complete responsive React pages in PDF would introduce browser/runtime coupling and duplicate state.
- Adding a grid engine is unnecessary; the existing block/layout registry is sufficient.
- Creating new action, planning or insight tables before using current models would duplicate architecture.
- Adding AI-generated narratives is unnecessary for the audited requirements; deterministic evidence and manager commentary already exist.
- Migrating all JSON compatibility data at once is outside the report phase. The report layer should first consume the canonical resolver consistently.
- A new chart/table/state/export library is unnecessary.

## 19. Recommended phased implementation plan

### Phase 1 — Canonical evidence and correctness

1. Define a shared backend reporting view model over `list_analysis_records()`, management BSC records and resolved applied configuration.
2. Standardize nulls, units, directions, grade/status and movement semantics.
3. Fix zero-target, hidden KPI, milestone, process/staff and placeholder-zero defects.
4. Add focused contract tests comparing dashboard/Insights/report figures for June 2026 fixture data.

### Phase 2 — Management analysis blocks

1. Implement matched-cohort score-change reconciliation and residual categories.
2. Complete weighted-lost-points, three-valid-period risk and applied-config audit blocks.
3. Make root-cause evidence explicit about confirmed, likely and data-quality sources.
4. Improve team and executive summaries using the same backend view models.

### Phase 3 — Execution evidence

1. Expand action API/UI to use existing owner/due/baseline/target/impact/evidence fields.
2. Wire real milestones, plan progress and closure evidence into blocks.
3. Decide and implement feedback/decision/commitment persistence only where current models are insufficient.

### Phase 4 — Governance and convergence

1. Converge legacy and story template/report routes behind the story architecture with compatibility reads.
2. Enforce team/level authorization on all action and team-action paths.
3. Adopt archive/retention/audit semantics for generated reports if immutable history is required.
4. Remove obsolete client calculation fallbacks only after parity tests pass.

## 20. Exact files likely to be changed in the next phase

### Backend

- `Backend/services/dashboard_record_service.py`
- `Backend/services/insights_service.py`
- `Backend/services/report_story_service.py`
- `Backend/services/report_registry.py`
- `Backend/services/report_service.py` (compatibility/convergence only)
- `Backend/services/corrective_action_service.py`
- `Backend/services/planning_service.py`
- `Backend/repositories/action_repository.py`
- `Backend/repositories/planning_repository.py`
- `Backend/repositories/report_repository.py`
- `Backend/api/routers/reports.py`
- `Backend/api/routers/users_and_actions.py`
- `Backend/api/routers/employee.py`
- `Backend/api/routers/team.py`
- `Backend/models/report_definitions.py`
- `Backend/models/planning_schemas.py`
- `Backend/tests/test_report_story_service.py`
- `Backend/tests/test_report_service.py`
- `Backend/tests/test_corrective_action_service.py`
- `Backend/tests/test_planning_workspace.py`
- New focused report-view-model tests, if a shared service is introduced

### Frontend

- `Frontend/src/hooks/usePerformanceData.ts`
- `Frontend/src/types.ts`
- `Frontend/src/utils/kpiScore.ts`
- `Frontend/src/features/team/teamKpiAnalysis.ts`
- `Frontend/src/features/marketing/marketingAnalytics.ts`
- `Frontend/src/features/marketing/marketingPositionAnalysis.ts`
- `Frontend/src/hooks/useActionStore.ts`
- `Frontend/src/components/team/TeamChartsSection.tsx`
- `Frontend/src/components/executive/ActionsSummaryCard.tsx`
- `Frontend/src/components/marketing/MarketingPositionDetail.tsx`
- `Frontend/src/components/reports/builder/BlockRenderer.tsx`
- `Frontend/src/components/reports/builder/Step2Template.tsx`
- `Frontend/src/components/reports/builder/Step3Builder.tsx`
- `Frontend/src/hooks/api/useReports.ts`
- Relevant Vitest files beside these components/hooks

`Backend/models/models.py` and an Alembic migration should be included only after a business decision confirms new persistence.

## 21. Questions requiring a business decision before implementation

1. Does “June versus May” always mean the immediately preceding calendar month, or the previous available valid/config-compatible period?
2. Should score-change reconciliation use all records or a matched employee cohort, and how should joiners/leavers be presented?
3. Are operational diagnostics such as No Show and zero-weight AHT allowed in analysis when they do not affect the PMS score? What label is mandatory?
4. Is a zero target ever valid? If yes, what is the achievement rule for each direction and unit?
5. Which grade thresholds and status mapping are authoritative: global, team-configured, or stored-at-upload values?
6. What makes a root cause “confirmed”, and who is allowed to confirm it?
7. Is process/staff classification manager-selected, rule-derived, or both with approval?
8. Must every corrective action be quantified, or are non-quantified coaching notes permitted but excluded from management impact totals?
9. Can feedback sessions be represented as action types, or must attendance/outcome be separately recorded?
10. Are management decisions and next-month commitments formal records requiring owners/status/audit, or is signed commentary sufficient?
11. Must generated reports be legally immutable, and if so what retention/deletion policy applies?
12. Should Executive users see organization aggregates, assigned teams, or self-only data? Current permission names and scope behavior disagree.
13. Which of `ReportTemplate` and legacy `SavedReportTemplate` is the long-term canonical template concept?

## Validation baseline

All validation was read-only with respect to the application database. Backend tests inspected for this audit use temporary in-memory SQLite databases.

| Command | Result |
|---|---|
| `python -m pytest tests/test_report_story_service.py tests/test_report_service.py -q -p no:cacheprovider` from `Backend` | **22 passed** |
| `python -m pytest -q -p no:cacheprovider` from `Backend` | **416 passed, 56 warnings** |
| `npm run test -- --run` from `Frontend` | **29 files passed, 96 tests passed** |
| `npm run lint` from `Frontend` | **Passed** |

The initial focused pytest invocation from the repository root failed collection because `Backend` was not on the Python import path; rerunning the identical nodes from the canonical `Backend` working directory passed. This is a command-context issue, not an application-test failure. A production build was intentionally not run because this phase is a read-only audit and build output would create/modify artifacts.

### Audit boundary

The audit stops at current-state analysis and this document. No application code, database row, migration, dependency, UI, report template, report data or PDF generation behavior was changed.
