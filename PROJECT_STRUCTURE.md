# PMS Dashboard - Project Structure

## Directory Layout

```
PMS_Dashboard/
├── Backend/                          # FastAPI Python backend
│   ├── api/
│   │   ├── routers/
│   │   │   ├── employee.py          # Employee profile endpoints
│   │   │   ├── performance.py       # Performance data endpoints
│   │   │   ├── team.py              # Team actions
│   │   │   ├── settings.py          # KPI weights/targets settings
│   │   │   ├── upload.py            # File upload endpoints
│   │   │   └── users_and_actions.py # User management & actions
│   │   └── dependencies.py          # Request validation, serialization
│   ├── config/
│   │   └── settings.py              # Configuration
│   ├── data/
│   │   ├── performance_records.json # 694 employee records (main database)
│   │   ├── kpi_weights.json         # Team-specific KPI weights
│   │   ├── employees.json           # Employee directory
│   │   ├── corrective_actions.json  # Manager actions history
│   │   └── users.json               # User accounts & roles
│   ├── repositories/                # Data access layer
│   │   ├── base.py
│   │   ├── json_repos.py            # JSON file repositories
│   │   └── __init__.py
│   ├── services/                    # Business logic layer
│   │   ├── kpi_service.py           # ⭐ CRITICAL: KPI calculation engine
│   │   │                             # - Calculate performance scores
│   │   │                             # - Assign grades (A-E)
│   │   │                             # - Compute achievements per KPI
│   │   ├── seeding_service.py       # Database initialization
│   │   ├── team_registry.py         # Team-to-KPI mappings, column names
│   │   ├── analysis_service.py      # Analysis & insights
│   │   ├── planning_service.py      # Planning categories & thresholds
│   │   └── insights_service.py      # Generate insights
│   ├── processors/
│   │   └── excel_processor.py       # Excel file parsing
│   ├── models/
│   │   └── schemas.py               # Pydantic models
│   ├── Data_Cleaning_Teams/         # Team-specific cleaning logic
│   │   ├── inbound.py
│   │   ├── outbound.py
│   │   ├── sales.py
│   │   ├── coding.py
│   │   ├── csr.py
│   │   ├── pharmacy.py
│   │   ├── preapprovals_offshore.py
│   │   └── inbound_UAE.py
│   ├── exports/
│   │   └── report_exporter.py       # Report generation
│   ├── app.py                       # FastAPI application entry point
│   ├── main.py                      # Alternative entry point
│   ├── requirements.txt             # Python dependencies
│   ├── pyproject.toml               # Project configuration
│   ├── Dockerfile                   # Container configuration
│   ├── reseed_clean.py              # Database reseeding script
│   ├── reseed_clean.py              # Main reseeding logic
│   └── scripts/
│       ├── reseed_all.py            # Reseed all data
│       └── scratch/                 # Development/debugging scripts
│           ├── scratch_inspect_*.py # Various inspection scripts
│           └── verify_records.py    # Record verification
│
├── Frontend/                         # React/TypeScript frontend
│   ├── src/
│   │   ├── pages/                   # Page-level components
│   │   │   ├── ExecutiveView.tsx    # Executive summary dashboard
│   │   │   ├── TeamDashboardView.tsx # Team performance view
│   │   │   ├── EmployeeProfileView.tsx # ⭐ CRITICAL: Employee detail page
│   │   │   │                          # - Displays score, grade, KPI breakdown
│   │   │   │                          # - Score trend chart
│   │   │   │                          # - Stats cards (Peak, 6M Avg, Consecutive A's)
│   │   │   ├── PlanningView.tsx      # Planning & actions
│   │   │   ├── SettingsView.tsx      # Configuration & uploads
│   │   │   └── LoginView.tsx         # Authentication
│   │   │
│   │   ├── components/
│   │   │   ├── common/
│   │   │   │   ├── Sidebar.tsx
│   │   │   │   └── Header.tsx
│   │   │   ├── employee/
│   │   │   │   ├── KpiBreakdownPanel.tsx  # ⭐ CRITICAL: KPI display & progress bars
│   │   │   │   │                          # - calculateCappedScore() function
│   │   │   │   │                          # - KpiBar with progress bar visualization
│   │   │   │   │                          # - Performance circle score
│   │   │   │   ├── EmployeeStatsSummary.tsx
│   │   │   │   ├── ScoreTrendChart.tsx
│   │   │   │   └── ActionTimeline.tsx
│   │   │   ├── team/
│   │   │   │   ├── TeamRosterSection.tsx
│   │   │   │   └── EmployeeActionModal.tsx
│   │   │   └── charts/
│   │   │       └── PlayerRadarChart.tsx
│   │   │
│   │   ├── context/                 # React Context providers
│   │   │   ├── AuthContext.tsx      # Authentication state
│   │   │   ├── RoleContext.tsx      # User role management
│   │   │   └── ThemeContext.tsx     # Dark/light theme
│   │   │
│   │   ├── hooks/                   # Custom React hooks
│   │   │   ├── usePerformanceData.ts # Fetch & process performance data
│   │   │   ├── useMonthParam.ts      # URL month parameter
│   │   │   ├── useLocationParam.ts   # URL location parameter
│   │   │   ├── useActionStore.ts     # Local action storage
│   │   │   └── useAuthRedirect.ts    # Auth redirects
│   │   │
│   │   ├── services/                # Business logic (frontend)
│   │   │   └── employeeAnalytics.ts # ⭐ CRITICAL: Analytics calculations
│   │   │                             # - calculateConsecutiveGrades()
│   │   │                             # - calculatePeakMonth()
│   │   │                             # - calculatePercentile()
│   │   │                             # - calculateStability()
│   │   │
│   │   ├── types.ts                 # ⭐ CRITICAL: Type definitions & helpers
│   │   │                             # - AgentRecord interface
│   │   │                             # - getActualValue() - extracts KPI actual values
│   │   │                             # - getTargetValue() - extracts targets
│   │   │                             # - getKPIsForAgent() - builds KPI array
│   │   │                             # - getGradeClass() - grade calculation
│   │   │
│   │   ├── teamRegistry.ts          # ⭐ CRITICAL: KPI configurations per team
│   │   │                             # Maps:
│   │   │                             #   - Team name → KPI definitions
│   │   │                             #   - KPI keys → achievement/target field names
│   │   │                             #   - Column names from raw_data to KPI values
│   │   │
│   │   ├── config.ts                # API configuration & endpoints
│   │   ├── App.tsx                  # Root component
│   │   └── main.tsx                 # React entry point
│   │
│   ├── dist/                        # Build output (production)
│   ├── node_modules/                # Dependencies
│   ├── package.json                 # NPM dependencies
│   ├── vite.config.ts               # Vite configuration
│   ├── tailwind.config.ts           # Tailwind CSS config
│   └── tsconfig.json                # TypeScript configuration
│
└── README.md                        # This documentation

```

---

## Critical Data Flow

### 🔴 Score Calculation Pipeline

```
Employee Profile Page Load
    ↓
1. Fetch from Backend: /api/employee/{id}/
    ↓
2. Data arrives: BackendProfile with performance_history
    ↓
3. Frontend: calculateCappedScore(agent, teamWeights)
    ├─ For each KPI:
    │   ├─ Get actual via getActualValue()
    │   ├─ Get target via getTargetValue()
    │   ├─ Calculate achievement ratio = actual / target
    │   ├─ NO per-KPI capping (can exceed 100%)
    │   └─ Contribution = achievement × weight
    │
    ├─ Raw Total = SUM(contributions)
    ├─ Final Score = MIN(rawTotal, 100)
    └─ Returns: 0-100 capped score
    ↓
4. Display Score: 53.6% (with 1 decimal)
5. Calculate Grade: A/B/C/D/E based on score
6. Show KPI Breakdown:
    ├─ KpiBar for each KPI
    ├─ Progress bar width = (actual / target) × 100
    └─ Color based on achievement status
```

### 📊 KPI Value Extraction

```
Sales KPI: OP Census
    ↓
Raw Data Fields:
├─ A.OPCensus = 1,078 (actual)
├─ T.OPCensus = 1,351.83 (target)
└─ OPCensusAch% = 0.7974 (achievement ratio = 79.74%)
    ↓
Frontend getActualValue() for Sales KPIs:
├─ Looks for: OPCensusAch%, OPCensusAch, or [kpi.achievementKeys]
├─ Finds: 0.7974 (decimal form, already = 79.74%)
└─ Returns: 0.7974 as-is
    ↓
KpiBreakdownPanel:
├─ Displays: formatVal(0.7974) = 79.7% ✓
├─ Display format: (value × 100).toFixed(1)% 
└─ Progress bar width: (0.7974 / 1.0) × 100 = 79.7%
```

### 📝 Team Registry Mapping

```typescript
// teamRegistry.ts
Sales: {
  OPCensus: {
    key: 'OPCensus',
    label: 'OP Census',
    weight: 0.10,
    color: '#3B82F6',
    achievementKeys: ['OPCensusAch%', 'OPCensusAch'],
    actualKeys: ['A.OPCensus'],
    targetKeys: ['T.OPCensus'],
    defaultTarget: 1.0,
    volumeKeyActual: 'A.OPCensus',
    volumeKeyTarget: 'T.OPCensus',
    volumeUnit: 'Census'
  },
  // ... more KPIs
}
```

---

## Key Functions Reference

### Backend (kpi_service.py)

```python
def calculate_performance(team: str, row: Dict) -> Tuple[float, str, Dict, Dict]:
    """
    Main scoring function - called per employee record.
    
    Args:
        team: Team name (Sales, Inbound, CSR, etc.)
        row: Raw data dictionary
        
    Returns:
        (score: 0-100, grade: A-E, achievements: dict, weights: dict)
    """
```

### Frontend (types.ts)

```typescript
function getActualValue(agent, raw_data, kpi): number
    // Extracts actual KPI value from raw_data or achievement object
    // For Sales KPIs: returns achievement ratio (e.g., 0.7974)
    // For Call Center KPIs: returns rate value (e.g., 0.65)

function getTargetValue(raw_data, keys, fallback): number
    // Extracts target value from raw_data

function getKPIsForAgent(agent): KPIConfig[]
    // Builds array of KPI configs with actual/target values
    
function getGradeClass(score): GradeClass
    // Returns letter grade: A/B/C/D/E

function getStatusFromScore(score): 'Exceeds' | 'Meets' | 'Below'
    // Returns performance status
```

### Frontend (EmployeeProfileView.tsx)

```typescript
function calculateCappedScore(agent, teamWeights): number
    // Wrapper function - delegates to KpiBreakdownPanel
    
function safeCalculateCappedScore(agent): number
    // Safe version with fallback to backend evaluation.score
    // Handles weights loading race condition
    
const trendData = useMemo(() => {
    // Calculates trend line data for ScoreTrendChart
    // Uses backend performance_history or local rows
    // Returns array of {month, score, benchmarkScore, isPeak}
})

const analytics = useMemo(() => {
    // Calculates stats cards:
    // - rank, percentile, stability
    // - consecutiveGrades (consecutive A's from end)
    // - peakMonth (best month)
    // - gradeDistribution (A/B/C/D/E count)
    // - avgLast6 (6-month average)
})
```

### Frontend (employeeAnalytics.ts)

```typescript
function calculateConsecutiveGrades(history, targetGrade, teamWeights, calculateCappedScoreFn): number
    // Counts consecutive target grades from end of history going backward
    // Recalculates grades from capped scores

function calculatePeakMonth(history, teamWeights, calculateCappedScoreFn): {month, score, grade}
    // Finds best performing month

function calculatePercentile(rank, total): number
    // Calculates percentile ranking

function calculateStability(history): 'Stable' | 'Improving' | 'Declining' | 'Volatile'
    // Analyzes score trend stability
```

---

## Data Mutations & Updates

### When is performance_records.json updated?

1. **Upload Excel File** (Settings → PMS Upload)
   - Triggers `reseed_all.py` or direct seeding
   - Recalculates all 694 records
   - Applies `kpi_service.calculate_performance()` per record

2. **Manual Reseed** (Backend command)
   ```bash
   python reseed_clean.py
   # Clears performance_records.json
   # Re-reads from Excel source
   # Recalculates all scores with current formula
   ```

3. **Never automatically from Frontend**
   - Frontend is read-only for performance data
   - Only updates corrective_actions.json (local action history)

### When are weights updated?

1. **Settings Page** (Settings → KPI Weights)
   - User updates team KPI weights
   - Saved to `kpi_weights.json`
   - Frontend fetches via `GET /api/settings/weights`
   - Does NOT retrigger performance calculation
   - Must manually reseed to recalculate scores with new weights

---

## Configuration Files

### kpi_weights.json
```json
{
  "data": [
    {
      "team": "Sales",
      "weights": {
        "OPCensus": 0.10,
        "OPRevenue": 0.10,
        "IPCensus": 0.25,
        "IPRevenue": 0.45,
        "Activity": 0.10
      }
    }
  ]
}
```

### teamRegistry.ts (Frontend hardcoded)
Defines KPI configs per team:
- Label, unit, color, achievement/target key names
- Weight percentages
- Default targets
- Volume display fields

**Note**: Weights can be overridden from `kpi_weights.json` API

---

## Performance Metrics

### Build Time
- Frontend: ~700ms (Vite)
- Bundle size: ~1MB gzipped

### API Response Times
- `/api/employee/{id}/` - ~50-100ms (includes 5 months history)
- `/api/performance?month=All` - ~200ms (694 records)

### Database Size
- performance_records.json: ~6MB
- All JSON files combined: ~10MB

---

## Known Bugs & Limitations

### ❌ No Known Critical Bugs (As of TASK 14)

### ⚠️ Trade-offs & Limitations

1. **Uncapped Per-KPI Contributions**
   - Allows one high-performing KPI to contribute > its weight%
   - Final score still capped at 100%
   - Example: 180% Activity (10% weight) = 18% contribution

2. **Score Calculation Race Condition** (FIXED)
   - When teamWeights not loaded yet, uses backend evaluation.score
   - May cause minor display inconsistency on first load
   - Resolved by TASK 14 changes

3. **No Real-time Updates**
   - Performance data changes require manual reseed
   - Not for live streaming leaderboards

4. **JSON Database Scalability**
   - Currently: 694 employees
   - Each record: ~5-10KB JSON
   - Total: ~6MB
   - Performance fine for current scale; would need DB for 10K+ records

---

## Development Workflow

### Adding New KPI to Team
1. Update `Backend/services/team_registry.py` (column mappings)
2. Update `Frontend/src/teamRegistry.ts` (display config)
3. Update `Backend/data/kpi_weights.json` (add weight)
4. Reseed: `python reseed_clean.py`
5. Test in Employee Profile page

### Changing Score Calculation Logic
1. Edit `Backend/services/kpi_service.py` → `calculate_performance()`
2. Reseed database: `python reseed_clean.py`
3. Frontend automatically uses new scores (no deploy needed)

### Updating KPI Thresholds
1. Edit `Frontend/src/types.ts` → `getGradeClass()`
2. Edit `Backend/services/planning_service.py` (if using backend thresholds)
3. No database update needed
4. Rebuild frontend: `npm run build`

---

## Recent Changes (TASK 15 - Current Session)

### Bug Fixed: TeamRosterSection null score crash
**Files Modified**:
- `Frontend/src/components/team/TeamRosterSection.tsx`

**Changes**:
1. Line 12: Updated `scoreBg()` function signature to accept `null` and default to 0
2. Line 30: Added null check in `TrendCell` component
3. Line 153: Added null coalescing in score display: `(row.score || 0).toFixed(1)`

**Impact**: 
- Eliminates React crash when rendering employee roster
- Gracefully handles records with missing score values
- Team roster now displays correctly with fallback values

---

## Testing Checklist

- [x] Employee profile loads without React hooks error (Fixed TASK 15)
- [ ] KPI progress bars display (Sales: 79.7%, 40.9%, etc.)
- [ ] Score circle and text match (53.6%)
- [ ] Grade calculation correct (E for 53.6%)
- [ ] Stats cards display correctly
- [ ] Performance trend shows all months
- [ ] Consecutive A's = 0 (May is E, not A)
- [ ] Personal Peak = 100% (Jan-Apr best)
- [ ] Hover tooltips work
- [ ] Comparison modes switch correctly
- [ ] Region filter works (EGY/UAE)
- [ ] Month selector works (All/Jan-Dec)

