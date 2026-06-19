# 📊 PMS Dashboard — Project Documentation

> **Saudi German Hospital · Performance Management System**
>
> An end-to-end analytics dashboard that ingests raw PMS Excel data, cleanses it, computes weighted KPIs per team using custom rule-based scoring engines, and visualizes outcomes across a 3-page premium React/Vite/TailwindCSS manager workspace.

---

## Table of Contents

1. [Quick Start & Setup](#-quick-start--setup)
2. [Project Architecture](#-project-architecture)
3. [Dashboard Pages](#-dashboard-pages)
4. [Routing Map](#-routing-map)
5. [Grading & Status System](#-grading--status-system)
6. [Backend — Python / FastAPI (Clean Architecture)](#-backend--python--fastapi-clean-architecture)
7. [Frontend — React / Vite / TailwindCSS](#-frontend--react--vite--tailwindcss)
8. [Frontend Team Onboarding Flow](#-frontend-team-onboarding-flow)
9. [Role-Based Access Control (RBAC)](#-role-based-access-control-rbac)
10. [API Reference](#-api-reference)
11. [Excel Sheet Processing & Mapping](#-excel-sheet-processing--mapping)
12. [KPI Weights & Targets Engines](#-kpi-weights--targets-engines)
13. [Folder Structure](#-folder-structure)

---

## 🚀 Quick Start & Setup

### Prerequisites

| Component | Minimum Version | Verification Command |
|---|---|---|
| **Python** | 3.10+ | `python --version` |
| **Node.js** | 18+ | `node --version` |
| **pip packages** | pandas, numpy, fastapi, uvicorn, pydantic | `pip list` |

### Running the Services

1. **Spin up the Backend (FastAPI)**:
   ```bash
   cd Backend
   uvicorn app:app --reload --port 8000
   # OR: python app.py
   ```
   > Upon startup, the backend automatically seeds itself from the Excel file configured in `Backend/config/settings.py`.

2. **Spin up the Frontend (Vite)**:
   ```bash
   cd FrontEnd
   npm install   # First time only
   npm run dev
   ```

### Ports & URLs

| Service | URL |
|---|---|
| **Frontend Dashboard** | http://localhost:5173 (or 5174 if port busy) |
| **Backend API** | http://127.0.0.1:8000 |
| **Swagger / OpenAPI Docs** | http://127.0.0.1:8000/docs |

---

## 🏗 Project Architecture

```
                          ┌─────────────────────────────────────┐
                          │          CLIENT (React + Vite)       │
                          │        http://localhost:5173         │
                          │                                      │
                          │  /executive  →  Executive Summary    │
                          │  /team/:id   →  Team Dashboard       │
                          │  /employee/:id → Employee Profile    │
                          └──────────────────┬──────────────────┘
                                             │
                                             │ REST API  (X-User-Role header)
                                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         FASTAPI BACKEND  :8000                          │
├─────────────────────────────────────────────────────────────────────────┤
│  api/routes.py        Endpoints, CORS, role auth, upload handling       │
│  services/*           KPI scoring, root cause, trends, planning         │
│  repositories/*       JSON file-based persistence layer                 │
│  processors/*         Excel ingestion & column cleaning                 │
│  exports/*            CSV / Excel report generation                     │
│  data/*.json          Local JSON "databases"                            │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📱 Dashboard Pages

### Page 1 — Executive Summary (`/executive`)

**Audience:** Senior management — high-level cross-team view

| Component | Description |
|---|---|
| **4 KPI Cards** | Total Agents · Avg Performance Score · % Class A&B (≥80%) · % Class D&E (<70%) |
| **Team Summary Table** | Clickable rows per team — shows agent count, avg score, and A/B/C/D/E class breakdown |
| **Grade Distribution Bar Chart** | All teams combined — class A through E with counts |
| **Actions Summary Card** | This-month corrective actions: total count, breakdown by type (Training/Reward/PIP/Monitor/Coaching), top root causes, pending offline sync list |
| **Month Selector** | Dropdown synced to URL params — updates all components simultaneously |

---

### Page 2 — Team Dashboard (`/team/:teamId`)

**Audience:** Team managers — deep dive into one team's performance

Available team routes:
- `/team/all` — All agents across all teams
- `/team/inbound` — Inbound team
- `/team/outbound` — Outbound team
- `/team/inbound-uae` — Inbound UAE team
- `/team/pre-approvals` — Pre-Approvals IP Offshore team
- `/team/sales` — Sales team
- `/team/pharmacy` — Pharmacy team
- `/team/csr` — CSR team
- `/team/coding` — Coding team

| Component | Description |
|---|---|
| **Team Header** | Team name · Back button · Month selector · Export Excel button (Manager/Admin only) |
| **4 KPI Cards** | Avg Score · % Class A&B · % Class D&E · Total Agents (team-filtered) |
| **Employee Table** | 8 columns with sort, search, and pagination (15 rows/page) — see below |
| **Grade Distribution Pie Chart** | Team-level class breakdown |
| **Score Trend Line Chart** | Average score over the last 6 months |
| **Employee Action Modal** | 5 action types (Training/Reward/PIP/Monitor/Coaching) with root cause notes |

**Employee Table Columns:**

| Column | Logic |
|---|---|
| **EMPLOYEE** | Name (clickable → `/employee/:id`) + employee ID |
| **TEAM** | Team name |
| **SCORE** | Color-coded badge: green ≥90%, blue 80–90%, amber 70–80%, red <70% |
| **GRADE** | A/B/C/D/E badge (auto-computed from score) |
| **TREND** | ↑ +X% if improved >2% · ↓ −X% if declined >2% · → Stable otherwise |
| **STATUS** | Meet (≥80%) · Average (70–80%) · Below (<70%) |
| **ROOT CAUSE** | Auto-detected from KPI thresholds + editable leader note preview |
| **ACTIONS** | Latest recorded action + "Add Action" link |

---

### Page 3 — Employee Profile (`/employee/:id`)

**Audience:** Team leaders — 360° view of individual agent

| Component | Description |
|---|---|
| **Profile Card** | Name · ID · Team · Score · Grade badge · Status badge · Add Action button |
| **KPI Breakdown Panel** | Circular score gauge + 3 progress bars: Attendance vs 90% · Booking vs 90% · AHT vs 4 min |
| **Score Trend Chart** | Line chart over all available months with 80% target reference line |
| **Root Cause Analysis** | Auto-detected issue + per-KPI comparison table + leader note field |
| **Action History Timeline** | Chronological list of all corrective actions (merged: localStorage + backend) with sync indicators, color-coded by action type |
| **Add Action Button** | Opens action modal (same as Team Dashboard) |

---

## 🗺 Routing Map

| Route | Page | Notes |
|---|---|---|
| `/` | → `/executive` | Redirect |
| `/executive` | Executive Summary | All roles |
| `/team/all` | All Teams Dashboard | All roles |
| `/team/inbound` | Inbound Team | All roles |
| `/team/outbound` | Outbound Team | All roles |
| `/team/inbound-uae` | Inbound UAE Team | All roles |
| `/team/pre-approvals` | Pre-Approvals Team | All roles |
| `/team/sales` | Sales Team | All roles |
| `/team/pharmacy` | Pharmacy Team | All roles |
| `/team/csr` | CSR Team | All roles |
| `/team/coding` | Coding Team | All roles |
| `/employee/:id` | Employee Profile | All roles |
| `/operational` | → `/team/all` | Legacy redirect |
| `/planning` | Performance Planning Kanban | Manager, Admin, Executive |
| `/settings` | KPI Settings | Admin only |

---

## 🎓 Grading & Status System

### Grade Classes (Score → Class)

| Class | Score Range | Meaning |
|---|---|---|
| **A — Excellent** | ≥ 90% (Can exceed 100%) | Top performer |
| **B — Meets Expectations** | 80% – 89.9% | On track |
| **C — Average** | 70% – 79.9% | Needs monitoring |
| **D — Below Average** | 60% – 69.9% | Intervention recommended |
| **E — Unsatisfactory** | < 60% | Immediate action required |

### Performance Status (Score → Status)

| Status | Threshold | Display |
|---|---|---|
| **Meet** | Score ≥ 80% | Blue badge |
| **Average** | 70% ≤ Score < 80% | Amber badge |
| **Below** | Score < 70% | Red badge |

### Auto Root Cause Detection

Triggered automatically when computing each agent's row:

```
Attend Rate < 75%  →  "Attend ↓ (main issue)"
Booking Rate < 75% →  "Booking ↓"
AHT > 5 min        →  "AHT ↑ (slow)"
All within targets  →  "All metrics good"
```

---

## 🐍 Backend — Python / FastAPI (Clean Architecture)

The backend follows a **Clean Architecture** pattern with strict separation between presentation, domain logic, and persistence.

### Directory Breakdown

| Directory | Responsibility |
|---|---|
| **`api/`** | REST endpoints, CORS setup, role authentication via `X-User-Role` header |
| **`config/`** | App settings, file paths, environment parameters |
| **`models/`** | Pydantic schemas: `Employee`, `PerformanceRecord`, `CorrectiveAction`, etc. |
| **`processors/`** | Excel ingestion — parses 4 sheets, cleans columns, normalizes headers |
| **`repositories/`** | JSON file-based data access layer — lightweight, schema-less persistence |
| **`services/`** | Domain core (see below) |
| **`exports/`** | CSV/Excel report generation |
| **`data/`** | Physical JSON "databases" for employees, records, actions, weights, targets |

### Services

| Service | Role |
|---|---|
| `kpi_service.py` | Weighted KPI scoring engine + grade assignment |
| `analysis_service.py` | Root cause analysis, outlier detection, action suggestions |
| `trend_service.py` | Month-over-Month performance trajectory |
| `planning_service.py` | Employee category classification (SIP, PI, Promotion, etc.) |
| `insights_service.py` | Executive text summary generation |
| `learning_service.py` | Historical action analysis for AI-style recommendations |

---

## ⚛ Frontend — React / Vite / TailwindCSS

Built with **React 19 + TypeScript**, **Vite 8**, **TailwindCSS v4**, **Recharts v3**, and **Framer Motion v12**.

### Hook Architecture

| Hook | Purpose |
|---|---|
| `usePerformanceData(month, location)` | Core data fetcher — API-first, JSON fallback |
| `useAllTeamsSummary(month)` | Per-team KPI aggregation for Executive Summary |
| `useTeamData(teamName, month)` | Team-filtered rows with computed grade/status/root cause |
| `useCRMData(month, location)` | Legacy CRM format for OperationalView |
| `useActionStore()` | Backend-primary corrective actions + localStorage offline fallback |
| `useMonthParam(default)` | URL search param synced month selector |

### Action Persistence Strategy

Actions are saved backend-first:

```
1. POST /api/employee/:id/corrective-actions  →  if OK, mark synced = true
2. Always cache to localStorage (key: "pms_actions_v2")
3. If backend unavailable → saved locally only (synced = false)
4. UI shows WifiOff icon on unsynced actions in timeline
```

---

## 🧭 Frontend Team Onboarding Flow

This section documents the exact frontend file order to change when a new team must appear in the dashboard with its own values, route, KPIs, and employee details.

### Current Team Slugs

| Slug | Display Name | Backend Team Name | Region Group |
|---|---|---|---|
| `all` | All Teams | `null` / all agents | General |
| `inbound` | Inbound | `Inbound` | Offshore EGY |
| `outbound` | Outbound | `Outbound` | Offshore EGY |
| `pre-approvals` | Pre-Approvals | `Pre-Approvals IP Offshore` | Offshore EGY |
| `inbound-uae` | Inbound | `Inbound UAE` | UAE Region |
| `sales` | Sales | `Sales` | UAE Region |
| `pharmacy` | Pharmacy | `Pharmacy` | UAE Region |
| `csr` | CSR | `CSR` | UAE Region |
| `coding` | Coding | `Coding` | UAE Region |

### File Change Order for a New Team

| Order | File | What to Change | Key Lines |
|---:|---|---|---|
| 1 | `FrontEnd/src/types.ts` | Add the new team's display name, slug, and exact backend team name to `TEAM_ID_MAP`, `TEAM_NAME_MAP`, and `TEAM_DB_NAME_MAP`. Add any new KPI fields to `AgentRecord.actual`, `AgentRecord.achievement`, `KPIConfig`, `getKPIsForAgent`, grade/status/root-cause helpers, and team-specific KPI mapping. | `types.ts:141`, `types.ts:304` |
| 2 | `FrontEnd/src/components/common/Sidebar.tsx` | Add the new team under `egyItems` or `uaeItems` so it appears in navigation. Use route `/team/<slug>`. | `Sidebar.tsx:33`, `Sidebar.tsx:36`, `Sidebar.tsx:38` |
| 3 | `FrontEnd/src/pages/TeamDashboardView.tsx` | Confirm the URL slug resolves to the backend team name through `TEAM_DB_NAME_MAP`. Add region detection, header colors, icons, export filename behavior, and team-specific insight bullets if needed. | `TeamDashboardView.tsx:59`, `TeamDashboardView.tsx:79`, `TeamDashboardView.tsx:903`, `TeamDashboardView.tsx:1211` |
| 4 | `FrontEnd/src/hooks/usePerformanceData.ts` | Ensure `useTeamData()` filters by the exact backend `identity.team`. Ensure `useAllTeamsSummary()` creates the correct `teamId` fallback and class counts. Normalize score values if backend returns decimals or percentages. | `usePerformanceData.ts:201`, `usePerformanceData.ts:625`, `usePerformanceData.ts:746` |
| 5 | `FrontEnd/src/components/team/TeamKpiSection.tsx` | Add the new team-specific KPI cards, targets, badges, trend deltas, and volume labels. Use the same `SecondaryKpiCard` pattern as Sales, Pharmacy, CSR, and Pre-Approvals. | `TeamKpiSection.tsx:129`, `TeamKpiSection.tsx:231`, `TeamKpiSection.tsx:406`, `TeamKpiSection.tsx:466`, `TeamKpiSection.tsx:528` |
| 6 | `FrontEnd/src/pages/EmployeeProfileView.tsx` | Add weight key mapping and actual-volume formatting for the new team's KPIs. Add profile-only panels if the team needs extra totals, territory, or benchmark fields. | `EmployeeProfileView.tsx:33`, `EmployeeProfileView.tsx:55`, `EmployeeProfileView.tsx:159` |
| 7 | `FrontEnd/src/components/employee/KpiBreakdownPanel.tsx` | Confirm the KPI breakdown can read the new KPIs from `getKPIsForAgent()` and show the correct weights, bars, targets, and issue labels. | `KpiBreakdownPanel.tsx:89`, `KpiBreakdownPanel.tsx:111` |
| 8 | `FrontEnd/src/services/employeeAnalytics.ts` | Update employee analytics only if the new team needs custom archetype, stability, ranking, or root-cause narrative logic. | `employeeAnalytics.ts:5`, `employeeAnalytics.ts:23`, `employeeAnalytics.ts:93`, `employeeAnalytics.ts:121` |
| 9 | `FrontEnd/src/App.tsx` | Usually no change is required because the dynamic route `/team/:teamId` already supports all teams. Only edit this file if the new team needs a separate page instead of the reusable Team Dashboard. | `App.tsx:43` |

### Values That Must Be Available for the New Team

For the new team to appear correctly across the frontend, the backend/API or fallback JSON should provide:

| Value | Used By | Notes |
|---|---|---|
| `identity.team` | Team filter, employee table, profile | Must exactly match `TEAM_DB_NAME_MAP[slug]`. |
| `identity.employee_id` | Employee table links, action store, profile | Must be unique per employee/month. |
| `identity.month` | Month selector, trends, actions | Must match the month options from `usePerformanceData()`. |
| `evaluation.score` | Score, grade, status, sorting | Frontend normalizes small decimals where needed. |
| `evaluation.grade` | Grade labels and badges | Can be backend text; frontend also computes A/B/C/D/E. |
| `evaluation.root_cause` | Auto root cause | Used for non-A/B agents. |
| `evaluation.manager_notes` | Leader note preview | Used in team table and employee profile. |
| `evaluation.corrective_action` | Latest action preview | Used in team table. |
| `evaluation.suggested_action` | Action suggestions | Used in employee profile. |
| `actual.*` | KPI cards, charts, root cause | Example: `booking_rate`, `attend_rate`, `abandon_rate`, `reachability_rate`, `submission_rate`, `rejection_rate`. |
| `achievement.*` | KPI bars, radar, analytics | Example: Sales `op_revenue_ach`, `op_census_ach`, `activity_ach`. |
| `raw_data.*` | Volume labels and target fallbacks | Example: `A.OPCensus`, `T.OPRevenue`, `Team`, `Out Team`. |
| `geo.bookings` / `geo.attended` | Branch filters and call-center volumes | Required for Dubai/Sharjah/Ajman/Clinics filtering. |
| `calls.*` | AHT, abandon, booking conversion | Required for Inbound/Outbound/Inbound UAE. |

### Reviewed Updated Files

| File | Review Summary |
|---|---|
| `FrontEnd/src/components/common/Sidebar.tsx` | Navigation now includes UAE teams: Sales, Pharmacy, CSR, and Coding. |
| `FrontEnd/src/components/team/TeamKpiSection.tsx` | Team KPI cards now support Sales, Pharmacy, CSR, and Coding-specific metrics and targets. |
| `FrontEnd/src/hooks/usePerformanceData.ts` | Core data hook filters teams, computes class counts, and normalizes score values. Region fallback now recognizes all UAE teams. |
| `FrontEnd/src/pages/EmployeeProfileView.tsx` | Employee profile now supports richer comparison, analytics, KPI volumes, and team-specific panels. |
| `FrontEnd/src/components/employee/KpiBreakdownPanel.tsx` | KPI breakdown now uses dynamic KPI definitions and optional team weights. Includes Coding KPIs. |
| `FrontEnd/src/pages/TeamDashboardView.tsx` | Central team page resolves team slugs, computes team metrics, renders insights, and handles export. Added Coding icon/name/region. |
| `FrontEnd/src/services/employeeAnalytics.ts` | Employee analytics now include ranking, percentile, stability, archetype, peak month, and narrative helpers. |
| `FrontEnd/src/types.ts` | Shared types now include team slug maps and reusable KPI helpers for all supported teams. Added Coding mappings. |
| `FrontEnd/src/hooks/useKpiDeltas.ts` | Added Coding delta, on-target, and trend-good computations. |
| `FrontEnd/src/hooks/useTeamMetrics.ts` | Spreads `computeCodingMetrics` into TeamMetrics. |
| `FrontEnd/src/hooks/teamMetrics/computeCodingMetrics.ts` | New — 3 Coding KPIs computed from raw_data with fuzzy key matching. |
| `FrontEnd/src/components/team/CodingKpiGrid.tsx` | New — 3-card KPI grid for Coding (Quality Errors Rate, Rejection Rate, TAT). |
| `FrontEnd/src/utils/teamTheme.ts` | Added emerald/teal Coding theme with `Code` icon. |
| `BackEnd/Data_Cleaning_Teams/coding.py` | New — Coding Excel processor with fuzzy column matching and 3-KPI engine. |
| `BackEnd/processors/excel_processor.py` | Added `process_sheet_coding` method. |
| `BackEnd/services/kpi_service.py` | Added Coding weights (20/50/30), targets, and calculation branch. |
| `BackEnd/services/seeding_service.py` | Added Coding sheet loading, region mapping, and record creation. |
| `BackEnd/models/schemas.py` | Added `quality_errors_ach`, `coding_rejection_ach`, `coding_tat_ach` to AchievementMetrics. |
| `BackEnd/api/dependencies.py` | Region fallback and serialization now include Coding as UAE. |

---

## 🔐 Role-Based Access Control (RBAC)

The `X-User-Role` header controls access at both the API and UI levels.

| Role | Dashboard Access | Actions | Export | Settings | Upload |
|---|---|---|---|---|---|
| **Admin** | All pages | ✅ | ✅ | ✅ | ✅ |
| **Manager** | All pages | ✅ | ✅ | ❌ | ❌ |
| **Executive** | Dashboard + Planning | ❌ | ❌ | ❌ | ❌ |
| **Viewer** | Dashboard only (read-only) | ❌ | ❌ | ❌ | ❌ |

> The Export Excel button on the Team Dashboard is hidden for **Viewer** and **Executive** roles.

---

## 📡 API Reference

All requests should include: `X-User-Role: <Role>` (defaults to `Viewer`).

### Core Endpoints

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/` | — | Health check |
| `GET` | `/api/performance?month=X&team=Y` | — | All performance records (filterable) |
| `GET` | `/api/employee/{id}` | — | Full employee profile + action history |
| `POST` | `/api/employee/{id}/corrective-actions` | Manager+ | Save corrective action |
| `POST` | `/api/employee/{id}/notes` | Manager+ | Save manager notes |
| `GET` | `/api/employee/{id}/recommendations?month=X` | — | AI-style historical recommendation |
| `GET` | `/api/planning?month=X` | Manager+ | Employee category lists |
| `GET` | `/api/insights?month=X` | Manager+ | Executive text summaries |
| `GET` | `/api/reports/export?month=X&team=Y&format=excel` | Manager+ | Download Excel/CSV report |
| `POST` | `/api/uploads/pms` | Admin | Upload new PMS Excel file |
| `GET` | `/api/uploads` | Admin | Upload history |
| `GET` | `/api/settings/weights` | — | Current KPI weights |
| `POST` | `/api/settings/weights` | Admin | Update KPI weights |
| `GET` | `/api/settings/targets` | — | Current KPI targets |
| `POST` | `/api/settings/targets` | Admin | Update KPI targets + recalculate all scores |

---

## 🔄 Excel Sheet Processing & Mapping

The pipeline parses `PMS_Trend_All.xlsx` across 7 sheets:

| Sheet | Module | Key Columns |
|---|---|---|
| **Inbound** | `process_sheet_inbound` | InboundCalls, AHT, Dubai/Sharjah/Ajman/Clinics Booking & Attend, Attend%Ach%, Booking%Ach%, QualityTargetAch%, AHTAch%, UTZ%Ach%, AbandonRate%Ach% |
| **Outbound** | `process_sheet_outbound` | AttendC.RAch%, BookingC.RAch%, QualityAch%, Reachability%Ach% |
| **Inbound UAE** | `process_sheet_inbound_uae` | AttendC.RAch%, BookingC.RAch%, AbandonRateAch% |
| **Pre-Approvals IP Offshore** | `process_sheet_preapprovals` | SubmittedClaims, IPInitialRejection%, Error%, NumberApprovalwithin48hrs |
| **Sales** | `sales.py` | OPCensusAch%, OPRevenueAch%, IPCensusAch%, IPRevenueAch%, ActivityAch% |
| **Pharmacy** | `process_sheet_pharmacy` | WaitingTimeAch%, LeakageAch%, TenderComplianceAch%, ATVAch%, NoofPrescriptionAch% |
| **CSR** | `process_sheet_csr` | CSRRejection%, CSRQueries%, AttendedC.R% |
| **Coding** | `process_sheet_coding` | QualityErrorsAch%, RejectionAch%, TATAch% |

---

## ⚖ KPI Weights & Targets Engines

Scores are computed by `KPIService` and normalized to **0–100**. The frontend grade classification maps:

| Frontend Grade | Score Range |
|---|---|
| **A — Excellent** | ≥ 90% (Supports uncapped scores >100%) |
| **B — Meets Expectations** | 80–89.9% |
| **C — Average** | 70–79.9% |
| **D — Below Average** | 60–69.9% |
| **E — Unsatisfactory** | < 60% |

> Note: Backend KPI weight thresholds may differ per team — the frontend displays the computed `score` field returned by the API.

### Weight Definitions per Team

**Inbound (5 KPIs — UTZ/Abandon swappable)**
- Attend Conversion: **70%**
- Booking Conversion: **10%**
- Quality Score: **5%**
- AHT: **5%**
- UTZ or Abandon Rate: **10%** *(auto-swap if UTZ is empty)*

**Outbound (4 KPIs)**
- Attend Conversion: **70%**
- Booking Conversion: **10%**
- Quality: **10%**
- Reachability: **10%**

**Inbound UAE (3 KPIs)**
- Attend Conversion: **70%**
- Booking Conversion: **20%**
- Abandon Rate: **10%**

**Pre-Approvals IP Offshore (dynamic)**
- If submitted claims > 0: Rejection **50%** · Initial Error **20%** · Submission on time **30%**
- If submitted claims = 0: Rejection **60%** · Initial Error **0%** · Submission on time **40%**

**Sales (5 KPIs — dynamically uncapped >100% scores for overachievers)**
- IP Revenue: **45%**
- IP Census: **25%**
- OP Revenue: **10%**
- OP Census: **10%**
- Activity Score: **10%**

**Pharmacy (5 KPIs)**
- Waiting Time: **20%**
- Leakage: **20%**
- Tender Item Compliance: **20%**
- ATV: **20%**
- Prescription Contribution: **20%**

**CSR (3 KPIs)**
- CSR Rejection: **40%**
- CSR Queries: **30%**
- Attended C.R: **30%**

**Coding (3 KPIs)**
- Quality Errors Rate: **20%**
- Rejection Rate: **50%**
- TAT: **30%**

---

## 📁 Folder Structure

```
PMS_Dashboard/
├── Backend/
│   ├── api/
│   │   └── routes.py                     # All API endpoints & role authorization
│   ├── config/
│   │   └── settings.py                   # File paths, environment settings
│   ├── data/                             # JSON flat-file databases
│   │   ├── employees.json
│   │   ├── performance_records.json
│   │   ├── corrective_actions.json
│   │   ├── manager_notes.json
│   │   ├── kpi_weights.json
│   │   ├── targets.json
│   │   └── uploads.json
│   ├── exports/
│   │   └── report_exporter.py            # CSV/Excel export generation
│   ├── models/
│   │   └── schemas.py                    # Pydantic entity models
│   ├── processors/
│   │   └── excel_processor.py            # Multi-sheet Excel ingestion pipeline
│   ├── repositories/
│   │   ├── base.py                       # Abstract repository interfaces
│   │   └── json_repos.py                 # JSON file-backed implementations
│   ├── services/
│   │   ├── kpi_service.py                # Weighted scoring engine
│   │   ├── analysis_service.py           # Root cause & outlier detection
│   │   ├── trend_service.py              # Month-over-Month trends
│   │   ├── planning_service.py           # Employee category classifier
│   │   ├── insights_service.py           # Executive summary generator
│   │   └── learning_service.py           # Historical action recommender
│   ├── app.py                            # FastAPI app setup + startup seeder
│   └── main.py                           # Legacy CLI orchestrator
│
└── FrontEnd/
    ├── index.html
    ├── vite.config.ts
    ├── package.json
    └── src/
        ├── App.tsx                        # Router setup with all page routes
        ├── main.tsx                       # React DOM entry point
        ├── index.css                      # Global styles, grade badges, status colors
        ├── types.ts                       # TypeScript interfaces + utility functions
        │
        ├── context/
        │   └── RoleContext.tsx            # Role state (Admin/Manager/Executive/Viewer)
        │
        ├── data/
        │   └── all_months_performance.json # Local fallback dataset
        │
        ├── hooks/
        │   ├── usePerformanceData.ts      # Core API hook + KPI aggregators
        │   ├── useActionStore.ts          # Corrective action persistence (backend + localStorage)
        │   └── useMonthParam.ts           # URL-synced month selector
        │
        ├── pages/
        │   ├── ExecutiveView.tsx          # Page 1: Cross-team executive summary
        │   ├── TeamDashboardView.tsx      # Page 2: Per-team employee table + charts
        │   ├── EmployeeProfileView.tsx    # Page 3: Individual 360° profile
        │   ├── PlanningView.tsx           # Performance planning Kanban
        │   ├── OperationalView.tsx        # Legacy roster view (redirected)
        │   └── SettingsView.tsx           # KPI weights & targets (Admin only)
        │
        └── components/
            ├── common/
            │   ├── Sidebar.tsx            # Navigation: Executive · Teams · Planning
            │   ├── Header.tsx             # Global filter bar + role selector
            │   ├── FileUpload.tsx         # Drag-and-drop Excel upload modal
            │   ├── RoleSelector.tsx       # Role switcher for testing
            │   ├── EmployeeTable.tsx      # Legacy agent grid (OperationalView)
            │   ├── CorrectiveActionWorkspace.tsx
            │   ├── KanbanBoard.tsx
            │   ├── KpiCard.tsx
            │   ├── StatCard.tsx
            │   ├── ActionCard.tsx
            │   └── SkeletonLoader.tsx
            │
            ├── executive/
            │   ├── TeamSummaryTable.tsx   # Clickable team rows → /team/:id
            │   ├── GradeDistributionChart.tsx # Bar chart: class A–E counts
            │   └── ActionsSummaryCard.tsx # Monthly actions breakdown + root causes
            │
            ├── team/
            │   ├── TeamHeader.tsx            # Header, filters, export button
            │   ├── TeamKpiSection.tsx        # Team-specific KPI cards and targets
            │   ├── TeamChartsSection.tsx     # Grade distribution + score trend
            │   ├── TeamRosterSection.tsx     # Employee roster, search, pagination
            │   └── EmployeeActionModal.tsx   # Action modal (5 types + root cause note)
            │
            ├── employee/
            │   ├── ScoreTrendChart.tsx    # Line chart over all months
            │   ├── KpiBreakdownPanel.tsx  # Gauge + progress bars vs targets
            │   └── ActionTimeline.tsx     # Merged local + backend action history
            │
            └── charts/                   # Legacy chart components
                ├── ConversionFunnel.tsx
                ├── KpiTargetChart.tsx
                ├── GrowthTrendChart.tsx
                ├── LocationProfitabilityChart.tsx
                ├── LocationBarChart.tsx
                ├── CumulativeAreaChart.tsx
                ├── ValueLeakageChart.tsx
                ├── ExecutiveInsights.tsx
                ├── AgentRanking.tsx
                └── OutlierAlerts.tsx
```

---

> **Last Updated:** June 2026 · Built by the SGH Data Analytics Team
