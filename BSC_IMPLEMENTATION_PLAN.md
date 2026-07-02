# Balanced Scorecard Implementation Plan and Prompt Pack (COMPLETED & VERIFIED)

> [!NOTE]
> All prompts (0 through 6) have been fully implemented, modularized, verified, and successfully pushed to GitHub. This document remains as the historical execution plan and specification record.

## Reference Files

- Backend foundation prompt: `C:\Users\sghd70204\.codex\attachments\4123a50b-ee48-4fd5-bceb-cd3e496bbf3c\pasted-text.txt`
- Interactive HTML reference: `D:\Projects\PMS_Dashboard\SGH-Hub-BSC-Demo.html`
- Strategy Map reference: `\\sghfslogix\UserData\sghd70204\Downloads\ChatGPT Image Jun 30, 2026, 01_02_33 PM (1).png`
- Perspective Summary reference: `\\sghfslogix\UserData\sghd70204\Downloads\ChatGPT Image Jun 30, 2026, 01_02_34 PM (2).png`
- Finance workbook: `\\sghfslogix\UserData\sghd70204\Downloads\Finance_Managerial_Corporate_Dummy_Data.xlsx`
- Finance worksheet: `Finance KPI Data`

Reference images and HTML define layout direction only. They are not a source for KPI names, calculations, authorization, or hardcoded team data.

## Global Rules

- Employee dashboards must remain visually and functionally unchanged.
- BSC is available only for Managerial and Corporate contexts.
- Preserve unrelated working-tree changes.
- Use existing project conventions before adding abstractions or dependencies.
- Do not hardcode team-specific KPIs in shared BSC logic.
- Do not claim completion without actual test/build output.
- Do not add a generic Balanced Scorecard sidebar link.
- Finance navigation is allowed only after populated Finance routes are verified.

---

## Prompt 0 - Architecture Audit Only

```text
You are working in the PMS Dashboard repository.

We are introducing a Balanced Scorecard experience for Managerial and Corporate performance levels only.

Important scope:
- Employee dashboards must remain visually and functionally unchanged.
- Managerial and Corporate will receive a Balanced Scorecard workspace.
- This workspace will have two views: Strategy Map and Perspective Summary.
- Do not write code or modify files in this step.

Inspect the real project structure, models, team JSON configs, KPI calculation service, dashboard APIs, frontend pages, hooks, existing filters, route/query-state patterns, exports, and authorization scope logic.

Answer:

1. Where should BSC metadata live: team JSON, database-backed team_kpi_config fields, or a hybrid? Choose one canonical source of truth and reject duplicated metadata.

2. How should each Managerial/Corporate KPI declare exactly one perspective from:
- Financial
- Customer
- Internal Process
- Learning & Growth

3. What metadata is required per perspective? Cover key/label, focus text, strategic objective, display order, optional icon key, and optional strategy-map links.

4. Which endpoints and services can be reused, and is one dedicated read-only BSC endpoint required?

5. How will People discovery and employee_ids filtering remain scoped to team, performance_level, branch where applicable, and existing RBAC permissions?

6. How will team, single-person, and multi-person scorecards be calculated without averaging raw achievement percentages? Preserve higher_better, lower_better, capping, contribution, N/A, partial-data, and weight-coverage semantics.

7. Which backend, migration, config, frontend, test, and documentation files should change?

Return:
- Evidence-backed current-state findings with file references.
- One architecture decision.
- Proposed config/data contract.
- Proposed canonical API request and response.
- Aggregation and authorization rules.
- Changed-file plan.
- Risks and backward-compatibility concerns.
- Acceptance criteria for Prompt 1.

Stop after the audit. Make no changes.
```

Acceptance gate: one metadata source, aggregation path, authorization path, and canonical API contract are selected with no unresolved architecture choice.

---

## Prompt 1 - Backend and Config Foundation

```text
Implement the backend and configuration foundation for the Balanced Scorecard workspace.

Preconditions:
- Read and follow the accepted Prompt 0 audit.
- Read the complete source prompt at:
  C:\Users\sghd70204\.codex\attachments\4123a50b-ee48-4fd5-bceb-cd3e496bbf3c\pasted-text.txt
- If the audit is missing or unresolved, stop without coding.

Implement the attached Prompt 1 exactly, with these locked rules:
- BSC is enabled only for Managerial and Corporate.
- Employee config and Employee API behavior remain backward compatible.
- Use Prompt 0's metadata source of truth; do not duplicate metadata.
- Support exactly Financial, Customer, Internal Process, and Learning & Growth.
- Keep all BSC behavior configuration-driven.
- Add or extend the smallest read-only canonical BSC API selected by Prompt 0.
- Reuse existing scoring semantics for direction, capping, and contribution.
- Never average raw achievement values for aggregate scores.
- Keep raw achievement, effective achievement, weighted contribution, perspective score, and total score distinct.
- Preserve Not Configured, No Data, and partial weight coverage without silently converting them to zero.
- Scope every employee_id to authorized team, performance_level, and branch/context.
- Reuse an existing safe People endpoint or add one only if Prompt 0 requires it.

Run focused tests covering:
- Employee compatibility.
- Managerial/Corporate perspective config.
- team, single-person, and multi-person aggregation.
- lower_better and capping.
- N/A, No Data, and partial coverage.
- team/level/branch/employee authorization.
- Managerial-only versus Corporate-only access.

Run the relevant backend suite and report exact commands and output. Update documentation only after verification. Do not start frontend work.
```

Acceptance gate: the canonical endpoint is tested, RBAC scope is enforced, calculation semantics are verified, and Employee compatibility passes.

---

## Prompt 2 - BSC Header, Filters, Routing, and URL State

```text
Implement the Balanced Scorecard frontend entry point for Managerial and Corporate dashboards only.

Preconditions:
- Prompt 1 is complete and its canonical API contract is verified.
- Do not change backend contracts in this prompt.

WHEN TO SHOW BSC

- Managerial or Corporate plus configured team: render BalancedScorecardWorkspace.
- Employee: render the existing dashboard unchanged.
- Managerial or Corporate without BSC config: retain the existing dashboard and show a non-blocking "Balanced Scorecard is not configured for this context yet" message.
- Do not show broken empty cards.

URL STATE

Use URL query parameters as the only source for:
- performance_level
- branch
- month
- year
- repeated employee_ids
- bsc_view

Do not duplicate these values in local state or Zustand.

Defaults:
- Managerial -> perspective_summary
- Corporate -> strategy_map

TOP TOOLBAR

Build:
[ Performance Level ] [ Branch ] [ Month ] [ People ] [ View ]

- Performance Level offers Managerial and Corporate only and respects access. Lock or omit it when only one level is available.
- Branch and Month reuse current behavior. History ends at selected month/year.
- People is a searchable keyboard-accessible multi-select, searches name and ID, uses scoped backend options, supports all/one/many, and persists employee_ids in URL.
- View switches between strategy_map and perspective_summary and persists bsc_view.
- Remove Export Excel from the top BSC toolbar only. Leave Employee export unchanged.
- Local exports will be implemented in later prompts.

COMPONENTS

Create the smallest project-consistent shell:
- BalancedScorecardWorkspace
- BalancedScorecardToolbar
- PeopleMultiSelect
- StrategyMapView entry
- PerspectiveSummaryView entry

Do not implement full cards, charts, rosters, or fake data yet. Implement loading, no-config, unauthorized, request-error, and empty-data states.

Verify Employee regression, Managerial/Corporate defaults, URL round-tripping, People scope, keyboard controls, responsive toolbar, and frontend production build. Report actual output and stop.
```

Acceptance gate: Employee is unchanged, Managerial/Corporate enter the BSC shell, all toolbar state round-trips through the URL, and no fake view data exists.

---

## Required Finance Data Gate - After Prompt 2

Complete this gate before Prompt 3 so the UI is evaluated with real Finance sandbox data rather than Inbound or empty responses.

```text
Create a local frontend Finance sandbox fixture from:
\\sghfslogix\UserData\sghd70204\Downloads\Finance_Managerial_Corporate_Dummy_Data.xlsx

Read only the Finance KPI Data worksheet.

Requirements:
- Normalize worksheet rows into src/data/finance/finance-kpi-data.json.
- Add one frontend adapter/repository that exposes the same canonical BSC response consumed by the BSC hook.
- Do not import raw JSON directly in JSX.
- Do not add a backend importer, database rows, or migrations for dummy data.
- Map exactly:
  - Account Manager -> Managerial
  - Assistant Finance Manager -> Managerial
  - Finance Manager -> Corporate
- Provide real /team/finance context.
- Render headings Finance · Managerial and Finance · Corporate.
- Do not route Finance through Inbound, Sales, Pharmacy, or another team.
- Do not add navigation yet.

Verify JSON row count against the worksheet, position mappings, sample KPI values, and populated Finance Managerial/Corporate responses. Stop before adding sidebar navigation.
```

Acceptance gate: both Finance contexts return populated canonical data with correct positions and no "No performance records available" fallback.

---

## Prompt 3 - Strategy Map View

```text
Implement the Strategy Map view inside the new Balanced Scorecard workspace.

This view is only for Managerial and Corporate contexts.

Use these references as layout direction, not hardcoded content:
- D:\Projects\PMS_Dashboard\SGH-Hub-BSC-Demo.html
- \\sghfslogix\UserData\sghd70204\Downloads\ChatGPT Image Jun 30, 2026, 01_02_33 PM (1).png

GOAL

Show how performance perspectives connect through cause and effect.

The map must explain:
Learning & Growth -> Internal Process -> Customer -> Financial

Use configured strategy_map_links when available. Use this standard relationship only as a safe fallback.

LAYOUT

Use a bright professional SaaS design: white/subtle neutral surface, soft pastel perspective cards, thin colored borders, readable connectors, high-contrast text, and restrained shadows. Do not use a black background or dark diagram canvas.

Place a central compact node: Vision & Strategy.

Render Financial, Customer, Internal Process, and Learning & Growth around it. Each card shows:
- configured icon
- perspective label
- focus text
- score or N/A
- trend versus last month when available
- primary KPI driver
- weighted contribution such as 23 of 45
- Excellent, Good, Needs Attention, or Not Configured badge

INTERACTION

- Cards are keyboard-accessible and clickable.
- Selection updates selected_perspective URL state and KPI table context.
- Hover/focus on a configured connector or card shows a concise explanatory tooltip.
- Do not invent causal claims beyond configured links or generic perspective labels.

N/A STATES

- Keep perspectives without KPIs visible.
- Show Not Configured or No KPIs defined yet.
- Never show a fake score.

RESPONSIVE

- Desktop: connected visual diagram.
- Tablet: compact two-by-two layout with simplified connectors.
- Mobile: vertical Learning & Growth -> Internal Process -> Customer -> Financial sequence.
- Do not shrink into unreadable nodes or cause page overflow.

CONSTRAINTS

- No team-specific hardcoding or Pharmacy-only labels.
- Reuse the canonical BSC response.
- Do not recalculate business scores.
- Do not modify Employee view.
- Respect reduced motion and communicate relationships in accessible text as well as connectors.

Run the frontend production build and report real output.
```

Acceptance gate: the Strategy Map is configuration-driven, accessible, responsive, populated by canonical Finance data, and does not alter Employee routes.

---

## Prompt 4 - Perspective Summary and Dynamic Roster

```text
Implement the Perspective Summary view inside the Balanced Scorecard workspace.

This view is only for Managerial and Corporate contexts.

Use these references as visual direction:
- D:\Projects\PMS_Dashboard\SGH-Hub-BSC-Demo.html
- \\sghfslogix\UserData\sghd70204\Downloads\ChatGPT Image Jun 30, 2026, 01_02_34 PM (2).png

TOP SUMMARY CARDS

Render the four configured perspective cards. Each card shows:
- icon and label
- focus statement
- perspective score/index
- trend versus previous month
- target reference when available
- weighted contribution such as 23 of 45
- one high-impact KPI driver
- Excellent, Good, Needs Attention, or Not Configured status

Do not treat N/A as zero.

SELECTED PERSPECTIVE

- Cards are keyboard-accessible and interactive.
- Clicking updates selected_perspective URL state.
- Selection filters/highlights KPI Performance Details and updates the roster.
- Default to the configured perspective with the largest weighted performance gap.
- Ignore Not Configured perspectives and do not choose from raw percentage alone.

PERSPECTIVE CONTRIBUTOR ROSTER

For All People or multiple selected people, render "[Selected Perspective] Contributor Roster" with:
- Employee
- Perspective Score
- Weighted Contribution
- up to three dynamically selected highest-weight relevant KPI columns
- Trend
- Status

Rules:
- No hardcoded KPI columns.
- Default sorting surfaces largest direction-aware business risk/performance gap first.
- Provide Needs Attention, Top Contributors, and All People modes.
- Include search and a local Export current view menu.

When one person is selected, replace the one-row roster with Selected Person Perspective Breakdown showing:
- perspective score
- key KPI performance
- trend
- weighted contribution
- key risk/opportunity

DATA AND SECURITY

- Use the canonical BSC response.
- Respect team, branch, month/year, people, performance_level, and RBAC scope.
- Never leak Corporate people into Managerial scope or vice versa.

RESPONSIVE

- Desktop: four-card grid and roster below.
- Tablet: two-by-two grid.
- Mobile: stacked/horizontal cards and roster transformed into readable data cards/list.

Run the frontend production build and report real output.
```

Acceptance gate: Perspective Summary correctly handles team/one/many People scopes, weighted-gap default selection, dynamic roster columns, RBAC, and responsive states.

---

## Prompt 5 - KPI Table and Selected KPI Trend/Table View

```text
Refine KPI drill-down behavior for Managerial and Corporate Balanced Scorecard views only.

Do not change Employee KPI behavior unless an existing component is reused without visual or functional regression.

KPI PERFORMANCE DETAILS

Render a central table with:
- Perspective
- KPI
- Weight
- Target
- Actual
- Score/Achievement
- Weighted Contribution
- Performance Status

Requirements:
- Clicking a row selects selected_kpi in URL state and visibly marks the row.
- Perspective selection filters/highlights relevant rows.
- Provide All Perspectives to restore the full table.
- Add local Export KPI Table.

REMOVE STATIC KPI TREND TILES

Remove the wide strip of multiple static KPI trend cards. Do not replace it with another static grid.

SELECTED KPI TREND ANALYSIS

Below the table render one dynamic panel with:
[ KPI selector ] [ Time Range ] [ Trend View ] [ Table View ] [ More / Export ]

Selection rules:
- Use the clicked KPI.
- Otherwise choose the highest-risk KPI in the selected perspective.
- If no KPI applies, show a clean empty state.
- Revalidate selected_kpi after filters change and replace only when it leaves the current authorized dataset.

Trend View:
- show actual score/value using canonical display semantics
- target line when configured
- monthly points
- direction-aware status
- selected-month highlight
- trailing range ending at dashboard month/year

Table View columns:
Month | Actual | Target | Variance | MoM Change | Status

Variance must be direction-aware. For lower_better, lower actual is favorable. Reuse backend scoring/status where available and keep N/A honest.

Show compact insights:
- Latest Score
- versus Last Month
- versus 6M Average
- Months at/above target, phrased correctly for direction
- Best Month

EXPORT

Local menu options:
- Export KPI history as Excel
- Export KPI history as CSV
- Export current trend table

Do not restore export to the top header.

TESTS

Add practical coverage for row selection, trend/table toggle, lower_better variance, N/A, selected-month range ending, selected-KPI validity after filters, and authorization scope.

Run relevant tests and frontend production build. Report actual output.
```

Acceptance gate: KPI selection drives one direction-aware trend/table panel, URL state remains valid across filters, exports are scoped, and tests/build pass.

---

## Prompt 6 - Final Integration, Permissions, Responsive, Navigation, and Documentation

```text
Perform final integration QA for the Managerial and Corporate Balanced Scorecard workspace. Do not add unrelated features.

VERIFY SCOPE

Employee:
- remains visually and functionally unchanged
- never unexpectedly renders BSC
- keeps existing filters, export, and workflows

Managerial and Corporate:
- render BSC only when configured
- provide Strategy Map and Perspective Summary
- preserve filters, selected perspective/KPI, and view in URL state
- respect team, branch, month/year, People, and performance_level

Security:
- People discovery is scoped to authorized team and level
- Managerial-only cannot access Corporate data and vice versa
- All People means all authorized people in current context
- exports use the exact current scope

Data quality:
- N/A never silently becomes zero
- lower_better remains correct
- cards/table/trends use the same canonical source
- scoring and contribution reuse backend semantics

Responsive:
- desktop map is readable
- tablet map remains usable
- mobile map becomes vertical flow
- summary cards and roster remain readable
- no sideways page overflow

FINANCE NAVIGATION - ONLY NOW

After both Finance routes are visibly populated and verified:
- add Finance under Managerial and Corporate hierarchies
- do not expose Finance under Employee or All
- do not add a generic BSC sidebar link
- Managerial Finance link opens Perspective Summary
- Corporate Finance link opens Strategy Map
- headings must be Finance · Managerial and Finance · Corporate

TESTS

Run:
- targeted BSC backend tests
- authorization/scoping tests
- existing KPI scoring tests
- frontend build
- frontend lint
- relevant component tests
- browser verification for Strategy Map, Perspective Summary, selected KPI trend, KPI table, Finance Managerial, Finance Corporate, one Employee route, and one mobile/tablet viewport

Separate new failures from known pre-existing failures. Do not claim a check passed unless actual output confirms it.

DOCUMENTATION

Document:
- BSC is Managerial/Corporate only
- Strategy Map and Perspective Summary behavior
- perspective configuration metadata
- scoped People behavior
- URL-state contract
- local export behavior
- no-config fallback
- Finance fixture is frontend sandbox data, not production ingestion

FINAL REPORT

Return:
1. Changed files and purpose.
2. API/data contract summary.
3. Exact test/build/browser results.
4. Incomplete items clearly labeled.
5. Screenshots or concise walkthrough for Strategy Map, Perspective Summary, selected KPI Trend View, KPI Table View, and one mobile/tablet state.

Target composition:

Finance · Managerial or Finance · Corporate
[ Level ] [ Branch ] [ Month/Year ] [ All People ] [ View ]

Balanced Scorecard
|- Strategy Map
|  `- Vision & Strategy plus four connected perspectives
`- Perspective Summary
   `- four cards plus selected-perspective contributor roster

KPI Performance Details
`- click KPI row -> one dynamic KPI Trend Analysis
   |- Trend View
   `- Table View
```

Acceptance gate: backend and frontend checks are evidenced, Employee regression is clean, Finance and both views work end to end, navigation points only to populated routes, and documentation matches the implementation.

