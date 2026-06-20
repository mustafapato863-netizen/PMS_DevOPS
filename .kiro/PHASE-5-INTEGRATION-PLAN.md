# Phase 5 Integration Plan — Database to System (Detailed Roadmap)

**Status**: ✅ Database created and configured  
**Objective**: Integrate database with existing system for Phase 5 continuation  
**Scope**: Convert JSON-based services to database-driven services  
**Estimated Duration**: 4-6 hours  
**Success Metric**: All services working with database, zero errors

---

## Current State Assessment

### ✅ What's Ready
- Database created: `PMS_Sys`
- Connection configured: `.env` updated with `DATABASE_URL`
- Models defined: 6 SQLAlchemy models in `models/models.py`
- Async support: `asyncpg` driver installed
- ORM configured: SQLAlchemy 2.0+ with connection pooling

### ⚠️ What Needs Integration
- Services still using JSON files (`team_service.py`)
- API routers expecting JSON responses
- Team onboarding service needs database persistence
- No repository layer (direct ORM access)
- Migration scripts not yet created

---

## Phase 5 Integration Roadmap

### **Stage 1: Database Initialization** (30 min)
**Goal**: Create database schema and seed initial data

#### 1.1 Create Alembic Migration
```bash
cd Backend
alembic init migrations
alembic revision --autogenerate -m "Initial schema creation"
```

**Files to create/modify**:
- `Backend/migrations/env.py` (auto-generated)
- `Backend/migrations/alembic.ini` (auto-generated)
- `Backend/migrations/versions/001_initial.py` (auto-generated)

**Tasks**:
- [ ] Generate migration script
- [ ] Review auto-generated schema
- [ ] Apply migration: `alembic upgrade head`
- [ ] Verify tables created in database
- [ ] Test connection with `psql`

#### 1.2 Verify Schema
```sql
-- In psql:
\dt                          -- List all tables
\d teams                     -- Describe teams table
SELECT count(*) FROM teams;  -- Should return 0
```

**Verification Checklist**:
- [ ] 6 tables created (teams, team_kpi_config, employees, performance_records, kpi_values, upload_log)
- [ ] Primary keys defined
- [ ] Foreign keys set up
- [ ] Indexes created
- [ ] Timestamps set to NOW()

---

### **Stage 2: Repository Layer** (90 min)
**Goal**: Create abstraction layer between services and database

#### 2.1 Create Base Repository
**File**: `Backend/repositories/base_repository.py`

```python
from typing import Generic, TypeVar, Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import select

T = TypeVar('T')

class BaseRepository(Generic[T]):
    """Generic repository for CRUD operations"""
    
    def __init__(self, db: Session, model: type):
        self.db = db
        self.model = model
    
    def create(self, obj_in: dict) -> T:
        """Create new record"""
        db_obj = self.model(**obj_in)
        self.db.add(db_obj)
        self.db.commit()
        self.db.refresh(db_obj)
        return db_obj
    
    def get_by_id(self, id: any) -> Optional[T]:
        """Get record by ID"""
        return self.db.query(self.model).filter(self.model.id == id).first()
    
    def get_all(self, skip: int = 0, limit: int = 100) -> List[T]:
        """Get all records with pagination"""
        return self.db.query(self.model).offset(skip).limit(limit).all()
    
    def update(self, id: any, obj_in: dict) -> Optional[T]:
        """Update record"""
        db_obj = self.get_by_id(id)
        if db_obj:
            for key, value in obj_in.items():
                setattr(db_obj, key, value)
            self.db.commit()
            self.db.refresh(db_obj)
        return db_obj
    
    def delete(self, id: any) -> bool:
        """Delete record"""
        db_obj = self.get_by_id(id)
        if db_obj:
            self.db.delete(db_obj)
            self.db.commit()
            return True
        return False
```

**Tasks**:
- [ ] Create `Backend/repositories/` directory
- [ ] Create `base_repository.py` with CRUD methods
- [ ] Create `__init__.py` in repositories

#### 2.2 Create Specific Repositories
**Files**:
- `Backend/repositories/team_repository.py`
- `Backend/repositories/employee_repository.py`
- `Backend/repositories/performance_repository.py`

**Team Repository** (`team_repository.py`):
```python
from repositories.base_repository import BaseRepository
from models.models import Team

class TeamRepository(BaseRepository[Team]):
    def get_by_name(self, name: str):
        return self.db.query(Team).filter(Team.name == name).first()
    
    def get_active_teams(self):
        return self.db.query(Team).filter(Team.is_active == True).all()
    
    def count_by_region(self, region: str):
        return self.db.query(Team).filter(Team.region == region).count()
```

**Employee Repository** (`employee_repository.py`):
```python
from repositories.base_repository import BaseRepository
from models.models import Employee

class EmployeeRepository(BaseRepository[Employee]):
    def get_by_employee_id(self, employee_id: str):
        return self.db.query(Employee).filter(Employee.employee_id == employee_id).first()
    
    def get_by_team(self, team_id):
        return self.db.query(Employee).filter(Employee.team_id == team_id).all()
    
    def get_active_by_team(self, team_id):
        return self.db.query(Employee).filter(
            (Employee.team_id == team_id) & 
            (Employee.is_active == True)
        ).all()
```

**Performance Repository** (`performance_repository.py`):
```python
from repositories.base_repository import BaseRepository
from models.models import PerformanceRecord

class PerformanceRepository(BaseRepository[PerformanceRecord]):
    def get_by_employee_month(self, employee_id, month: str, year: int):
        return self.db.query(PerformanceRecord).filter(
            (PerformanceRecord.employee_id == employee_id) &
            (PerformanceRecord.month == month) &
            (PerformanceRecord.year == year)
        ).first()
    
    def get_monthly_records(self, team_id, month: str, year: int):
        return self.db.query(PerformanceRecord).filter(
            (PerformanceRecord.team_id == team_id) &
            (PerformanceRecord.month == month) &
            (PerformanceRecord.year == year)
        ).all()
```

**Tasks**:
- [ ] Create team repository with custom queries
- [ ] Create employee repository with team filtering
- [ ] Create performance repository with monthly queries
- [ ] Create `__init__.py` in repositories with exports

---

### **Stage 3: Update Services** (120 min)
**Goal**: Replace JSON-based logic with database queries

#### 3.1 Update TeamService
**File**: `Backend/services/team_service.py`

**Before** (JSON-based):
```python
def get_all_teams():
    teams_config = load_teams_config()  # Read from JSON file
    return list(teams_config.values())
```

**After** (Database-based):
```python
from repositories.team_repository import TeamRepository
from config.database import SessionLocal

def get_all_teams():
    db = SessionLocal()
    repo = TeamRepository(db, Team)
    teams = repo.get_active_teams()
    db.close()
    return teams
```

**Methods to update**:
- [ ] `get_all_teams()` → Query from `teams` table
- [ ] `get_team(name)` → Use `team_repository.get_by_name()`
- [ ] `create_team(request)` → Insert into `teams` + `team_kpi_config`
- [ ] `update_team(name, request)` → Update `teams` record
- [ ] `delete_team(name)` → Soft delete (set `is_active=False`)
- [ ] `validate_team()` → Check database constraints
- [ ] Remove `_save_team_config()` — No longer needed

**Key Changes**:
- Remove file I/O operations
- Use `SessionLocal()` for DB sessions
- Return ORM models (FastAPI converts to Pydantic schemas)
- Add transaction handling for multi-table operations

**Tasks**:
- [ ] Add database imports
- [ ] Replace JSON loading with repository calls
- [ ] Update create_team to insert KPI config
- [ ] Update update_team for multi-field updates
- [ ] Remove JSON file operations
- [ ] Test each method

#### 3.2 Update PerformanceService (if exists)
Similar pattern:
- [ ] Replace JSON queries with database queries
- [ ] Use `PerformanceRepository` for record retrieval
- [ ] Add transaction support for bulk inserts

#### 3.3 Update EmployeeService (if exists)
- [ ] Use `EmployeeRepository` for queries
- [ ] Add team relationship queries
- [ ] Support filtering by team

**Tasks Summary**:
- [ ] Update all service methods to use repositories
- [ ] Add error handling for database operations
- [ ] Add logging for database operations
- [ ] Test each service method

---

### **Stage 4: Update API Routers** (60 min)
**Goal**: Ensure routers work with database-backed services

#### 4.1 Team Management Router
**File**: `Backend/api/routers/team_management.py`

**Status**: Already compatible! But verify:
- [ ] Endpoints call updated services
- [ ] Response schemas match database models
- [ ] Error handling works with DB errors

**Checklist**:
```python
@router.get("/teams")
async def list_teams(db: Session = Depends(get_db)):
    # Now calls: TeamService.get_all_teams() which uses db
    teams = TeamService.get_all_teams()
    return TeamListResponse(teams=teams)
```

#### 4.2 Employee Router
**File**: `Backend/api/routers/employee.py`

- [ ] `GET /api/employees` → Query all from database
- [ ] `GET /api/employees/{id}` → Query by ID from database
- [ ] `POST /api/employees` → Insert into database
- [ ] `PUT /api/employees/{id}` → Update database record

#### 4.3 Performance Router
**File**: `Backend/api/routers/performance.py`

- [ ] `GET /api/performance/records` → Query from database
- [ ] `GET /api/performance/{emp_id}/{month}` → Database query
- [ ] `POST /api/performance/records` → Insert bulk records

**Tasks Summary**:
- [ ] Verify all routers use updated services
- [ ] Test all endpoints with database backend
- [ ] Check response formats match Pydantic schemas

---

### **Stage 5: Team Onboarding Persistence** (45 min)
**Goal**: Persist onboarding state to database

#### 5.1 Create OnboardingState Model
**Already exists** in `models/models.py` (to be added):

```python
class OnboardingState(Base):
    __tablename__ = "onboarding_states"
    
    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    team_id = Column(UUID, ForeignKey("teams.id"), unique=True)
    current_step = Column(Integer, default=0)
    status = Column(String(20), default="pending")  # pending, in_progress, completed
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    last_error = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
```

#### 5.2 Create OnboardingRepository
**File**: `Backend/repositories/onboarding_repository.py`

```python
class OnboardingRepository(BaseRepository[OnboardingState]):
    def get_by_team(self, team_id):
        return self.db.query(OnboardingState).filter(
            OnboardingState.team_id == team_id
        ).first()
    
    def get_or_create(self, team_id):
        state = self.get_by_team(team_id)
        if not state:
            state = OnboardingState(team_id=team_id)
            self.db.add(state)
            self.db.commit()
        return state
    
    def update_step(self, team_id, step: int, status: str):
        state = self.get_by_team(team_id)
        if state:
            state.current_step = step
            state.status = status
            state.updated_at = func.now()
            self.db.commit()
        return state
```

#### 5.3 Update TeamOnboardingService
**File**: `Backend/services/team_onboarding_service.py`

**Changes**:
- [ ] Persist state to database after each step
- [ ] Recover from database on failure
- [ ] Track `started_at`, `completed_at`, `last_error`
- [ ] Query status from database instead of memory

**Example**:
```python
async def _execute_workflow(team_name: str, steps):
    db = SessionLocal()
    repo = OnboardingRepository(db, OnboardingState)
    state = repo.get_or_create(team_id)
    
    state.status = "in_progress"
    state.started_at = datetime.now()
    db.commit()
    
    for step in steps:
        try:
            # Execute step
            state.current_step = step.step_number
            db.commit()
        except Exception as e:
            state.status = "failed"
            state.last_error = str(e)
            db.commit()
    
    state.status = "completed"
    state.completed_at = datetime.now()
    db.commit()
    
    db.close()
```

**Tasks**:
- [ ] Add OnboardingState model (if not already there)
- [ ] Create OnboardingRepository
- [ ] Update TeamOnboardingService to persist state
- [ ] Test recovery after restart

---

### **Stage 6: Data Migration** (30 min)
**Goal**: Load existing JSON data into database

#### 6.1 Create Migration Script
**File**: `Backend/scripts/migrate_json_to_db.py`

```python
import json
import uuid
from pathlib import Path
from config.database import SessionLocal
from models.models import Team, TeamKPIConfig, Employee

def migrate_teams():
    """Load teams from JSON configs to database"""
    db = SessionLocal()
    config_dir = Path("config/teams")
    
    for json_file in config_dir.glob("*.json"):
        with open(json_file) as f:
            config = json.load(f)
        
        team = Team(
            id=uuid.uuid4(),
            name=config['name'],
            db_name=config.get('db_name', config['name']),
            region=config.get('region', 'UAE'),
            is_active=config.get('is_active', True)
        )
        db.add(team)
        db.flush()
        
        # Add KPIs
        for kpi_key, weight in config.get('kpi_weights', {}).items():
            kpi = TeamKPIConfig(
                team_id=team.id,
                kpi_key=kpi_key,
                kpi_label=kpi_key.title(),
                weight=weight
            )
            db.add(kpi)
    
    db.commit()
    db.close()
    print("✓ Teams migrated to database")

if __name__ == "__main__":
    migrate_teams()
```

**Tasks**:
- [ ] Create `Backend/scripts/` directory
- [ ] Create migration script
- [ ] Test script with dry-run
- [ ] Execute migration
- [ ] Verify data in database: `SELECT * FROM teams;`

#### 6.2 Verify Migration
```bash
cd Backend
python scripts/migrate_json_to_db.py

# Verify
python -c "
from config.database import SessionLocal
from models.models import Team
db = SessionLocal()
teams = db.query(Team).all()
for team in teams:
    print(f'Team: {team.name} (ID: {team.id})')
db.close()
"
```

**Verification Checklist**:
- [ ] All teams imported
- [ ] All KPI configs created
- [ ] No duplicate records
- [ ] All relationships correct

---

### **Stage 7: Testing & Verification** (60 min)
**Goal**: Ensure all systems work with database

#### 7.1 Unit Tests
**File**: `Backend/tests/test_repositories.py`

```python
import pytest
from config.database import SessionLocal
from repositories.team_repository import TeamRepository
from models.models import Team

def test_create_team():
    db = SessionLocal()
    repo = TeamRepository(db, Team)
    
    team = repo.create({
        'name': 'test_team',
        'db_name': 'test_db',
        'region': 'UAE'
    })
    
    assert team.name == 'test_team'
    assert team.is_active == True
    
    db.close()

def test_get_by_name():
    db = SessionLocal()
    repo = TeamRepository(db, Team)
    
    team = repo.get_by_name('inbound')
    assert team is not None
    
    db.close()
```

**Tests to create**:
- [ ] Repository CRUD operations
- [ ] Service layer queries
- [ ] API endpoint responses
- [ ] Team onboarding persistence
- [ ] Error handling

#### 7.2 Integration Tests
```bash
# Test endpoints manually
curl http://localhost:8000/api/team-management/teams
curl -X POST http://localhost:8000/api/team-management/teams \
  -H "Content-Type: application/json" \
  -d '{"name":"test","display_name":"Test"}'
```

**Manual Testing**:
- [ ] GET /api/team-management/teams
- [ ] POST /api/team-management/teams (create)
- [ ] GET /api/team-management/teams/{name}
- [ ] PUT /api/team-management/teams/{name}
- [ ] DELETE /api/team-management/teams/{name}
- [ ] POST /api/team-management/teams/{name}/onboard

#### 7.3 Database Validation
```bash
# Connect to database and verify
psql -U postgres -d PMS_Sys -c "
SELECT * FROM teams;
SELECT COUNT(*) FROM team_kpi_config;
SELECT COUNT(*) FROM employees;
SELECT COUNT(*) FROM performance_records;
"
```

**Verification**:
- [ ] Data exists in all tables
- [ ] Foreign keys working
- [ ] Soft deletes working
- [ ] Timestamps updating

---

### **Stage 8: Error Handling & Logging** (45 min)
**Goal**: Robust error handling and monitoring

#### 8.1 Add Database Error Handling

```python
# In services
try:
    team = repo.get_by_name(name)
    if not team:
        raise HTTPException(404, "Team not found")
except SQLAlchemyError as e:
    logger.error(f"Database error: {e}")
    raise HTTPException(500, "Database error")
except Exception as e:
    logger.error(f"Unexpected error: {e}")
    raise HTTPException(500, "Internal server error")
```

**Tasks**:
- [ ] Add try-except blocks to all repository calls
- [ ] Log database errors appropriately
- [ ] Return meaningful error messages
- [ ] Handle connection failures gracefully

#### 8.2 Add Logging

```python
import logging

logger = logging.getLogger(__name__)

def get_team(name: str):
    logger.info(f"Fetching team: {name}")
    try:
        team = repo.get_by_name(name)
        logger.info(f"Team found: {team.id}")
        return team
    except Exception as e:
        logger.error(f"Failed to fetch team: {e}")
        raise
```

**Tasks**:
- [ ] Add logging to all database operations
- [ ] Log successful operations
- [ ] Log errors with full context
- [ ] Set up log levels (INFO, WARNING, ERROR)

---

## Implementation Checklist

### Phase 5 Integration Checklist

```
STAGE 1: Database Initialization
  ☐ Generate Alembic migration
  ☐ Review auto-generated schema
  ☐ Apply migration (alembic upgrade head)
  ☐ Verify all 6 tables created
  ☐ Test database connection

STAGE 2: Repository Layer
  ☐ Create base_repository.py with CRUD methods
  ☐ Create team_repository.py
  ☐ Create employee_repository.py
  ☐ Create performance_repository.py
  ☐ Test all repository methods

STAGE 3: Update Services
  ☐ Update TeamService to use database
  ☐ Update PerformanceService (if exists)
  ☐ Update EmployeeService (if exists)
  ☐ Replace JSON file operations
  ☐ Add transaction handling
  ☐ Test all service methods

STAGE 4: Update API Routers
  ☐ Verify team_management router
  ☐ Update employee router
  ☐ Update performance router
  ☐ Test all endpoints

STAGE 5: Team Onboarding Persistence
  ☐ Add OnboardingState model (if needed)
  ☐ Create OnboardingRepository
  ☐ Update TeamOnboardingService
  ☐ Test persistence and recovery

STAGE 6: Data Migration
  ☐ Create migration script
  ☐ Test migration script
  ☐ Execute migration
  ☐ Verify all data migrated

STAGE 7: Testing & Verification
  ☐ Create unit tests
  ☐ Create integration tests
  ☐ Manual API testing
  ☐ Database validation
  ☐ All endpoints working

STAGE 8: Error Handling & Logging
  ☐ Add error handling
  ☐ Add logging
  ☐ Test error scenarios
  ☐ Verify logs
```

---

## File Structure After Integration

```
Backend/
├── config/
│   └── database.py ✅ (already set up)
├── models/
│   ├── models.py ✅ (already set up)
│   └── schemas.py ✅ (Pydantic schemas)
├── repositories/ 🆕 (New repository layer)
│   ├── __init__.py
│   ├── base_repository.py
│   ├── team_repository.py
│   ├── employee_repository.py
│   ├── performance_repository.py
│   └── onboarding_repository.py
├── services/
│   ├── team_service.py ✏️ (Updated for database)
│   ├── team_onboarding_service.py ✏️ (Persistence)
│   └── ... (other services)
├── api/routers/
│   ├── team_management.py ✅ (Already compatible)
│   ├── employee.py ✏️ (Updated)
│   └── ... (other routers)
├── scripts/ 🆕 (Migration scripts)
│   └── migrate_json_to_db.py
├── tests/ 🆕 (Unit & integration tests)
│   ├── __init__.py
│   ├── test_repositories.py
│   └── test_services.py
├── migrations/ 🆕 (Alembic migrations)
│   ├── versions/
│   ├── env.py
│   └── alembic.ini
└── app.py ✅ (No changes needed)

✅ = Already done
✏️ = Needs update
🆕 = Needs to create
```

---

## Success Criteria

### All items must be ✅ to proceed to Phase 5 Part 5:

```
☐ Database created and connected
☐ All models properly defined
☐ Alembic migrations working
☐ Repository layer implemented
☐ Services updated to use database
☐ All API endpoints working
☐ Team onboarding persisting to database
☐ JSON data migrated to database
☐ All tests passing
☐ Error handling in place
☐ Logging configured
☐ Zero compilation errors
☐ System fully functional with database backend
```

---

## Estimated Timeline

| Stage | Duration | Complexity |
|-------|----------|-----------|
| 1. Database Init | 30 min | Low |
| 2. Repository Layer | 90 min | Medium |
| 3. Update Services | 120 min | High |
| 4. Update Routers | 60 min | Medium |
| 5. Onboarding Persistence | 45 min | Medium |
| 6. Data Migration | 30 min | Low |
| 7. Testing & Verification | 60 min | Medium |
| 8. Error Handling & Logging | 45 min | Medium |
| **TOTAL** | **~480 min** | **~8 hours** |

---

## Next Phase (Phase 5 Part 5)

After integration is complete:

1. **Add Authentication** — User management and JWT
2. **Add Authorization** — Role-based access control
3. **Performance Optimization** — Query optimization and caching
4. **Advanced Features** — Audit trails, soft deletes, versioning
5. **Monitoring & Deployment** — APM, logging, containers

---

## Support & Resources

- **Database Issues**: See `Backend/DATABASE_SETUP.md`
- **Project Structure**: See `README_PROJECT_STRUCTURE.md`
- **Quick Reference**: See `QUICK_REFERENCE.md`
- **Previous Sessions**: See `.kiro/FINAL-SESSION-REPORT.md`

---

**Ready to begin Phase 5 Integration?**

Start with **Stage 1: Database Initialization** and work through each stage systematically.

All stages are designed to be independent — you can complete them in order and verify after each one.

