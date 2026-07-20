# Report Story Builder Architecture

## Boundary

This implementation restructures the existing Reports workflow into a PDF-first monthly story builder. It does not add a general presentation editor, a second Insights engine, a second Planning system, or a second corrective-action/feedback system.

## Canonical flow

`reports router -> ReportStoryService -> existing repositories/services -> database`

- `ReportTemplate` stores versioned reusable structure only.
- `ReportDraft` stores the editable period/scope definition, generated system narratives, and separately keyed management commentary.
- `GeneratedReport` stores the immutable definition, narrative, data and validation snapshots together with the generated PDF bytes and integrity identifier.
- `BLOCK_REGISTRY` is the sole block metadata/provider/permission registry.
- `LAYOUT_REGISTRY` is the sole fixed-slot layout registry.
- `ReportStoryService` is the only hydration, validation and generation orchestrator.
- `presentation_pdf.py` is a dedicated 16:9 vector renderer consuming the same block-data contracts as Build and Review.

## Reused sources of truth

- `DashboardRecordService` and existing scope filters for authorized PMS records.
- Stored evaluation score, grade, status and KPI values; no KPI formula is recalculated outside existing normalized fields.
- `PlanningRepository` for baselines, quantified targets, expected/actual impact and milestones.
- `ActionRepository` for corrective actions, owners, due dates, evidence and completion notes.
- Existing coaching/feedback/PIP/training corrective actions for feedback-session status. No feedback table was duplicated because the repository contains no separate persisted feedback-session domain.
- Existing upload logs for data-quality evidence.
- Existing RBAC permission matrix and team/team-level scope checks.

## Data contracts

Templates and drafts contain ordered pages, governed layouts, fixed slots, PMS block types and block settings. They never contain monthly KPI values. Active page data is resolved lazily through one page endpoint and is returned as `ready`, `no_data`, `incomplete_configuration`, `permission_denied`, or `source_unavailable` with explicit warnings.

System analysis is deterministic and stored by block ID. Management commentary is stored in a separate map and is never modified by narrative regeneration.

## Analysis rules

- Primary and comparison periods are explicit; comparison must precede primary. Missing comparison data is disclosed and never silently replaced.
- Score movement compares average final PMS scores and reconciles KPI contribution changes. A residual above 0.2 percentage points is labelled estimated and attributed only to possible population/configuration/target/missing-data changes.
- Lowest KPIs rank by weighted lost points, then achievement, then weight. Raw actual values are never compared across unlike units.
- Lower-is-better achievement uses `target / actual`; zero or missing targets remain unquantified and produce validation warnings.
- Consecutive low performers require the primary month and the two immediately preceding calendar months, with canonical stored below-target status/grade in all three. Missing or non-consecutive months do not qualify.
- Recorded corrective-action root causes are confirmed. Measured patterns are likely factors requiring confirmation. Missing/zero targets are data issues.
- Process/staff classification uses deterministic business-language mapping and returns `Both` or `Requires confirmation` when evidence is mixed/insufficient.
- Projected impact is shown only when already stored on a linked performance plan and is labelled non-guaranteed with its assumption source.

## PDF method

Presentation PDF uses a fixed 960 x 540 MediaBox (16:9), vector text, vector cards, vector bars and tables. It does not capture dashboard screenshots. Every page carries scope, explicit periods, confidentiality, page number and branding. The generated file and serialized snapshot are hashed together for historical integrity.

## Deferred by scope

- Document PDF (A4) renderer.
- PowerPoint renderer on the new story contract.
- Scheduling, email delivery, public sharing, real-time collaboration and approval workflow.
- A standalone feedback-session domain, unless the product later introduces one outside Reports.
