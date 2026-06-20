# PMS Dashboard - Performance Management System

## Current System Status (Updated: June 20, 2026 - Production Ready)

### ✅ Completed Features

#### Backend (Python/FastAPI)
- **Database**: Production PostgreSQL database integrated via SQLAlchemy async ORM, with schema management through Alembic migrations.
- **Compliance & Security**:
  - JWT Authentication and Role-Based Access Control (RBAC) supporting Admin, Manager, Executive, Viewer.
  - Multi-tenant/Team-scoped write restrictions and account lockouts (15 minutes after 5 consecutive login failures).
  - Entity-wide **Soft Delete & Restore** (respects `is_active` flags by default) for Employees, Teams, Users, and Corrective Actions.
  - **Data Versioning History**: Tracks changes to performance records, enabling as-of-date queries and delta calculations.
  - **Complete Audit Trail**: Records exact changes (`old_values` and `new_values`) for all updates/deletes in an `audit_log` table.
- **Caching & Query Optimization**:
  - Thread-safe in-memory LRU session cache.
  - Central Redis caching layer with transparent `1.0s` connection timeout and database fallback.
  - Eager relationship loading (`joinedload`) to prevent N+1 queries.
- **Multi-Team KPI Engine** (8 Teams Supported):
  - **Legacy Teams**: Inbound, Outbound, Sales, Pre-Approvals Offshore, Inbound UAE (existing weights)
  - **New Teams (June 2026)**: 
    - **Pharmacy** (5 KPIs, Uncapped): WaitingTime, Leakage (inverse) + TenderCompliance, ATV, Prescription (direct) - each 20%
    - **Coding** (3 KPIs, Capped): QualityErrors (20%), Rejection (50%), TAT (30%) - all inverse
    - **CSR** (3 KPIs, Capped): Rejection (40%, inverse) + Queries (30%, direct) + AttendedCR (30%, direct)
  - **Configurable via JSON**: Each team has `/config/teams/{team}.json` defining KPIs, weights, directions (higher_better/lower_better), capping rules
  - **Dynamic Factory Pattern**: `CleanerFactory` auto-loads team-specific data cleaners
  - **Achievement Calculation**:
    - Direct KPIs: achievement = (actual/target) × 100
    - Inverse KPIs: achievement = (target/actual) × 100
    - Zero-division protection: actual=0 for inverse KPIs returns 100%
  - **Capping Logic**:
    - Pharmacy: Uncapped (scores can exceed 100%)
    - Coding/CSR: Capped at 100% (individual achievements and final score)

#### Frontend (React/TypeScript)
- **Employee Profile Page**:
  - KPI Breakdown with progress bars and color fallbacks.
  - Stats cards: Personal Peak, 6M Avg, Consecutive A's.
  - Performance trend chart mapping months.
- **Team Dashboard**:
  - Roster view with sortable employees and comparison averages.
  - Region filters (All, EGY, UAE).
  - Dark/Light mode theme switcher.
  - Multi-team selector (8 teams supported)

#### Monitoring & Alerts
- **System Health Probes**: Public `/api/health` checking PostgreSQL and Redis connection statuses and query response times.
- **Sliding Error Alerts**: Captures exceptions in the middleware, logs them, and triggers Slack notifications if error rates exceed 1% in a 5-minute sliding window.
- **Structured JSON Logging**: Thread-safe `request_id` context injection, writing stdout logs and daily rotating JSON log files.

---

## Team Configuration System

### Supported Teams (8 Total)

#### Legacy Teams (5)
1. **Inbound** - Traditional call center metrics
2. **Outbound** - Outbound call operations
3. **Sales** - Sales team performance (OPCensus, OPRevenue, IPCensus, IPRevenue, Activity)
4. **Pre-Approvals Offshore** - Pre-approval processing
5. **Inbound UAE** - UAE-specific inbound operations

#### New Teams (3) - Added June 2026
6. **Pharmacy**
   - **5 KPIs** (equal weights: 20% each)
   - Inverse: WaitingTime, Leakage
   - Direct: TenderCompliance, ATV, Prescription
   - **Uncapped**: Scores can exceed 100%
   - Grade Thresholds: A≥95, B≥85, C≥75, D≥65

7. **Coding**
   - **3 KPIs**: QualityErrors (20%), Rejection (50%), TAT (30%)
   - All inverse (lower is better)
   - **Capped at 100%**: Individual achievements and final score
   - Grade Thresholds: A≥95, B≥85, C≥75, D≥65

8. **CSR** (Customer Service Representatives)
   - **3 KPIs**: Rejection (40%), Queries (30%), AttendedCR (30%)
   - Mixed: Rejection (inverse) + Queries, AttendedCR (direct)
   - **Capped at 100%**
   - Grade Thresholds: A≥95, B≥85, C≥75, D≥65

### Configuration Files
Each team has a JSON configuration at `Backend/config/teams/{team_name}.json`:

```json
{
  "team": "Pharmacy",
  "db_name": "Pharmacy",
  "region": "UAE",
  "employee_id_col": "EmployeeID",
  "employee_name_col": "EmployeeName",
  "grade_thresholds": {"A": 95, "B": 85, "C": 75, "D": 65},
  "kpis": [
    {
      "key": "WaitingTime",
      "label": "Waiting Time",
      "weight": 0.20,
      "direction": "lower_better",
      "unit": "min",
      "color": "#EF4444",
      "actual_col": "A.TotalAvgWaitingTime",
      "target_col": "T.TotalWaitingTime",
      "capping": "uncapped"
    }
    // ... 4 more KPIs
  ]
}
```

### Data Processing Architecture

```
Excel Upload
    ↓
CleanerFactory.get_process_function(team_name)
    ↓
Team-Specific Cleaner (pharmacy.py / coding.py / csr.py)
    ↓
KPI Achievement Calculation
    - Direct: achievement = (actual/target) × 100
    - Inverse: achievement = (target/actual) × 100
    ↓
Apply Capping Rules
    - Pharmacy: No capping
    - Coding/CSR: Cap at 100%
    ↓
Weighted Score: Σ(achievement × weight)
    ↓
Grade Assignment (A/B/C/D/E)
    ↓
Store in Database
```

---

## Performance Score Calculation

### Legacy Teams (e.g., Sales)
```
For each KPI:
1. Achievement% = (Actual / Target) × 100 (Uncapped per KPI)
2. Contribution = Achievement% × Weight
3. Raw Total = SUM(all contributions)
4. Final Score = MIN(Raw Total, 100%) (Capped at end)
```

**Example: Sales Team (May)**
| KPI | Actual | Target | Achievement | Weight | Contribution |
|-----|--------|--------|-------------|--------|--------------|
| OP Census | 1,078 | 1,351.83 | 79.7% | 10% | 7.97% |
| OP Revenue | 463,399 | 670,736 | 69.1% | 10% | 6.91% |
| IP Census | 21 | 45.91 | 45.7% | 25% | 11.43% |
| IP Revenue | 117,705 | 287,458 | 40.9% | 45% | 18.43% |
| Activity | 313 | 327 | 89.0% | 10% | 8.90% |
| **TOTAL** | | | | | **53.64%** → Grade E |

### New Teams (Pharmacy, Coding, CSR)

#### Pharmacy Example (Uncapped)
```
KPI Achievements:
- WaitingTime (inverse): 76.92% (4.0 target / 5.2 actual × 100)
- Leakage (inverse): 120% (3.0 target / 2.5 actual × 100) ← Exceeds 100%!
- TenderCompliance: 94% (94/100 × 100)
- ATV: 107.14% (150/140 × 100) ← Exceeds 100%!
- Prescription: 94.44% (85/90 × 100)

Performance Score = (76.92 + 120 + 94 + 107.14 + 94.44) × 0.20
                  = 98.5% (NO CAPPING) → Grade A
```

#### Coding Example (Capped)
```
KPI Achievements (before capping):
- QualityErrors (inverse): 60% (3/5 × 100)
- Rejection (inverse): 25% (2/8 × 100)
- TAT (inverse): 83.33% (20/24 × 100)

Each capped at 100%: [60%, 25%, 83.33%]
Performance Score = 60×0.20 + 25×0.50 + 83.33×0.30 = 49.5%
Final Score = MIN(49.5%, 100%) = 49.5% → Grade E
```

#### CSR Example (Mixed KPIs, Capped)
```
KPI Achievements (before capping):
- Rejection (inverse): 41.67% (5/12 × 100)
- Queries (direct): 112.5% (450/400 × 100) → Capped to 100%
- AttendedCR (direct): 105.56% (95/90 × 100) → Capped to 100%

After capping: [41.67%, 100%, 100%]
Performance Score = 41.67×0.40 + 100×0.30 + 100×0.30 = 76.67%
Final Score = 76.67% → Grade C
```

### Key Differences
| Aspect | Legacy Teams | Pharmacy | Coding/CSR |
|--------|-------------|----------|------------|
| **Individual Achievement Cap** | None | None | 100% |
| **Final Score Cap** | 100% | None | 100% |
| **Can Exceed 100%** | No | Yes | No |
| **KPI Types** | Direct only | Mixed | Mixed |

---

## API Endpoints

### Authentication
- `POST /api/auth/login` - Authenticate and obtain JWT token
- `POST /api/auth/logout` - Clear session cache

### Health & Monitoring
- `GET /api/health` - Check service database and cache status (returns 503 if DB down)

### Employee & Performance
- `GET /api/employee/{id}/` - Fetch profile and scores history
- `GET /api/performance?month=<month>&team=<team>` - Get team performance roster
- `GET /api/team/{team_id}/kpis` - Get team KPI configuration and definitions

### Configuration
- `GET /api/settings/weights` - Get active weights configuration (legacy)
- `GET /api/config/teams` - List all available team configurations
- `GET /api/config/teams/{team_name}` - Get specific team configuration JSON

### Admin & Bulk Endpoints (RBAC Protected)
- `POST /api/bulk/performance/records` - Batch insert records in 1,000 chunks
- `POST /api/upload/excel/{team_name}` - Upload Excel file for specific team
- `PATCH /api/bulk/teams/{team_id}/kpi-config` - Bulk update weights (validates sum = 1.0)
- `DELETE /api/bulk/employees` - Bulk soft-delete employees (limit 100/call)

---

## Running the Project

The entire production stack (App + Postgres DB + Redis Cache) can be launched locally using Docker Compose.

### Docker Compose (Recommended)
```bash
# Start all services with health checks
docker compose up --build

# Run backend migrations
docker compose exec web alembic upgrade head

# Run tests
docker compose exec web pytest tests/
```
- **App**: http://localhost:7860
- **Health Check**: http://localhost:7860/api/health
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

### Manual Development Setup

#### 1. Backend
```bash
cd Backend
pip install -r requirements.txt

# Set environment variables in .env
# DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/pms_db
# REDIS_URL=redis://localhost:6379

# Run migrations
alembic upgrade head

# Run tests
pytest tests/test_three_teams.py -v  # 92 tests for new teams
pytest tests/ -v                      # All tests

# Start server
uvicorn app:app --reload --port 8000
```

#### 2. Frontend
```bash
cd Frontend
npm install
npm run dev
```

---

## Testing & Quality Assurance

### Test Coverage

#### Backend Tests
- **Total Tests**: 267 tests (175 legacy + 92 new teams)
- **Pass Rate**: 100% ✅
- **Execution Time**: ~3.5 seconds

#### New Teams Test Suite (92 tests)
1. **Configuration Loading** (29 tests)
   - Valid config loading for Pharmacy, Coding, CSR
   - Error handling: missing fields, invalid weights, bad thresholds
   - Weight validation with 0.001 tolerance
   - Grade threshold ordering

2. **Achievement Calculation** (6 tests)
   - Direct KPI calculations (actual/target)
   - Inverse KPI calculations (target/actual)
   - Capping logic verification
   - Zero division prevention

3. **Cleaner Factory** (22 tests)
   - Correct cleaner selection per team
   - Error handling for unknown teams
   - Case insensitivity support
   - Function signature validation
   - Multi-call consistency

4. **Property-Based Tests** (23 tests) - Using Hypothesis
   - **1,000+ total iterations** across all properties
   - Property 1: Direct KPI Achievement Correctness (100 iterations)
   - Property 2: Inverse KPI Achievement Correctness (300 iterations)
   - Property 3: Pharmacy Uncapped Scoring (100 iterations)
   - Property 4: Coding/CSR Capped Scoring (200 iterations)
   - Property 5: Grade Assignment Consistency (100 iterations)
   - Property 6: Weight Sum Validation (verified for all teams)
   - Property 7: Configuration Round-Trip (200 iterations)
   - Property 8: Zero Division Prevention (100 iterations)
   - CSR Mixed KPI Calculation (100 iterations)

5. **Integration Tests** (3 tests)
   - Complete Pharmacy workflow (config → cleaner → calculation → grade)
   - Complete Coding workflow
   - Complete CSR workflow

6. **Percentage Parsing** (5 tests)
   - String with % symbol ("95%")
   - Decimal fraction (0.95)
   - Integer (95)
   - NaN handling
   - Comma-separated values ("1,234")

7. **Round-Trip Consistency** (3 tests)
   - JSON serialization/deserialization
   - Numeric precision preservation (weights within 1e-6)
   - Multi-iteration stability

### Running Tests
```bash
# Run all tests
pytest tests/ -v

# Run specific test suite
pytest tests/test_three_teams.py -v

# Run with coverage report
pytest tests/ --cov=. --cov-report=html

# Run property tests with detailed output
pytest tests/test_three_teams.py -v -s --hypothesis-show-statistics
```

---

## Verification Metrics
- **Backend Tests**: 267/267 passing (100%)
- **Property Tests**: 1,000+ iterations executed
- **Test Execution**: ~3.5s total
- **Log Files**: `Backend/logs/pms_app.log` (daily rotating JSON)
- **Code Coverage**: >85% for new team implementation

---

## Team Configuration Management

### Adding a New Team

1. **Create Configuration File**: `Backend/config/teams/new_team.json`
```json
{
  "team": "NewTeam",
  "db_name": "NewTeam",
  "region": "UAE",
  "employee_id_col": "EmployeeID",
  "employee_name_col": "EmployeeName",
  "grade_thresholds": {"A": 95, "B": 85, "C": 75, "D": 65},
  "kpis": [
    {
      "key": "KPI1",
      "label": "First KPI",
      "weight": 0.50,
      "direction": "higher_better",  // or "lower_better"
      "unit": "%",
      "color": "#10B981",
      "actual_col": "A.KPI1",
      "target_col": "T.KPI1",
      "capping": "uncapped"  // or "capped_at_100"
    }
  ]
}
```

2. **Create Data Cleaner**: `Backend/Data_Cleaning_Teams/new_team.py`
```python
def process_new_team(file_path: str, sheet_name: str = None):
    # Load Excel file
    # Clean and standardize data
    # Calculate KPI achievements
    # Apply capping rules
    # Return processed DataFrame
    pass
```

3. **Register in Factory**: Add to `Backend/data_cleaning/cleaner_factory.py`
```python
cleaner_modules = {
    # ...
    'new_team': {'class': None, 'function': 'process_new_team'},
}
```

4. **Validate Configuration**:
```bash
python -c "from config.loader import load_team_config; config = load_team_config('NewTeam'); print('✅ Valid')"
```

5. **Run Tests**:
```bash
pytest tests/test_three_teams.py -v
```

---
