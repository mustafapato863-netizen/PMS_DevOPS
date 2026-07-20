# PDF-first Monthly Performance Review Story Builder Audit

## Current implementation

- Reports already has a five-step React workflow, scoped report options, preview/generation APIs, persisted generated files, private saved configurations, PDF/PPTX exporters, and permission middleware.
- Authoritative performance data is already exposed through `DashboardRecordService`; KPI direction, target, weight, achievement, contribution, root-cause, employee history, and score are carried by existing PMS records.
- Existing Actions and Planning models contain ownership, due dates, KPI linkage, status, completion notes, evidence, baselines/targets, and milestones that reports can summarize without duplicating action-plan storage.
- There is no separate feedback-session table or backend workflow. Coaching, feedback, PIP, monitoring, review notes, and follow-up evidence currently live in corrective Actions and Planning. The report must derive feedback status from those records and explicitly label unavailable scheduling fields rather than create a competing subsystem.

## What works and should be reused

- Router -> service -> repository -> database structure.
- `view_reports`/`export_data` permissions, authenticated scope, team and performance-level filtering.
- Existing score and KPI calculations; reports must consume them and never recalculate final PMS scores.
- Existing Insights language/rules where available, Planning plans/milestones, corrective Actions, upload logs, React Query, Zustand, Recharts, Lucide, theme variables, and the installed PDF/PPTX capabilities.
- Existing Reports list/download behavior and compatibility endpoints.

## Step 3 problems

- Selecting a template currently creates browser-only slides from the template name; no draft is persisted or hydrated.
- The browser invents historical score points, target achievement, comparison badges, and narrative statements.
- The existing PowerPoint builder emits fake KPI and sample table values.
- Blocks, layouts, settings, and exporters recognize inconsistent string sets with no authoritative registry.
- The full PMS navigation and permanent columns leave too little canvas space.
- Thumbnails are generic grey bars, the settings panel is frequently empty, and layout compatibility is not enforced.
- Auto-save is a spinner label only; there is no debounce, concurrency check, conflict state, or unload warning.

## Missing persistence and contracts

- Missing versioned reusable Report Template entity.
- Missing monthly Report Draft with independent system analysis and management commentary.
- Generated Report lacks final definition, narrative/data snapshots, template version, validation, and integrity ID.
- Missing typed finite page/block/layout definition and per-page normalized block-data response.
- Missing comparison, three-consecutive-month, lowest-KPI, root-cause confidence, action quantification, and feedback-status report contracts.

## Duplicate or unsafe logic

- Story structure is duplicated between template cards and the Zustand store.
- Block metadata is duplicated in Content Library, renderer, settings, and exporters.
- The current builder treats an end period as a comparison period while the legacy backend interprets it as a report range.
- Saved templates persist monthly scope and period in the same object as reusable structure.
- Generated narrative and management commentary are not separated.

## High-confidence restructuring

1. Preserve compatibility endpoints but add versioned templates, drafts, and immutable generated snapshots.
2. Keep finite block/layout registries in backend code. Persist only safe references and typed configuration.
3. Seed six system templates idempotently, including a dynamic Offshore Monthly Review whose department-detail page group expands from the selected authorized teams.
4. Create one authorized report context for primary/comparison/history data and reuse it across all blocks on the active page.
5. Rank low KPIs by weighted lost points, then achievement/target gap/deterioration/weight—never raw actual values across mixed units.
6. Identify consecutive low performers only across three chronologically consecutive valid months.
7. Distinguish confirmed root causes (recorded action/root-cause evidence), likely factors (measured patterns), and data issues.
8. Separate process/staff actions using existing Action/Plan types and warn when owner, due date, baseline, target, unit, assumptions, or evidence is missing.
9. Derive feedback-session status from existing coaching/feedback/PIP actions; do not add a duplicate feedback table.
10. Implement Presentation PDF first from the same normalized page contract used by Build and Review. Keep the definition export-neutral; PowerPoint remains deferred compatibility output.
11. Use debounced optimistic draft saving and lazy active-page hydration.

## Overengineering risks and deferrals

- No free positioning, resizers, shapes, animation, layers, collaboration, approvals, scheduling, email, public sharing, custom formulas, or SQL.
- No generic CMS/page-builder engine and no database-defined executable renderers.
- No unsupported causal attribution or guaranteed projected impact. Contribution reconciliation is marked estimated whenever source values cannot exactly reconcile.
- No new feedback subsystem. Missing feedback scheduling fields remain visible as data gaps.
- Presentation PDF is the primary new renderer. A4 Document PDF and richer PowerPoint rendering are deferred until the shared contract is proven.

## Recommended implementation sequence

1. Persistence, typed definitions, registries, migration, and system-template seed.
2. Authorized primary/comparison/history context and PMS-specific block providers.
3. Draft/template APIs, optimistic auto-save, validation, narratives, and immutable PDF generation.
4. Focused builder shell, hydrated pages, real thumbnails, modal library, contextual settings, Review, and Export.
5. Focused domain/integration tests, migration/API checks, full frontend/backend regression, and rendered PDF inspection.
