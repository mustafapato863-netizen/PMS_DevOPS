# Phase 5 Database Integration - Task List

## Overview
This spec provides structured tasks to fully integrate the database system into the PMS Dashboard backend, converting all services from JSON-based to database-driven architecture.

**Status**: Ready for execution  
**Total Stages**: 8  
**Estimated Duration**: ~8 hours  
**Success Metric**: All services working with database, zero errors, all tests passing

---

## Task Dependency Graph

```
Stage 1: Database Init
    ↓
Stage 2: Repository Layer
    ↓
Stage 3: Update Services ─── (parallel with 4)
    ↓                         ↓
Stage 4: Update Routers ─────┘
    ↓
Stage 5: Onboarding Persistence
    ↓
Stage 6: Data Migration
    ↓
Stage 7: Testing & Verification
    ↓
Stage 8: Error Handling & Logging
```

---

## STAGE 1: Database Initialization

### Task 1.1: Create Initial Alembic Migration
**Type**: Setup  
**Dependencies**: None  
**Subtasks**:
- Generate Alembic migration with `alembic revision --autogenerate -m "Initial schema creation"`
- Review auto-generated migration file
- Apply migration: `alembic upgrade head`
- Verify all 6 tables created in database

**Acceptance Criteria**:
- Migration file created in `Backend/migrations/versions/`
- `alembic upgrade head` completes without errors
- All tables visible in pgAdmin 4
- No database errors in logs

**Context**:
- Database: `PMS_Sys` (already created)
- Connection: `.env` already configured
- Models: Defined in `Backend/models/models.py`

---

### Task 1.2: Verify Database Schema
**Type**: Verification  
**Dependencies**: Task 1.1  
**Subtasks**:
- Connect to database with psql or pgAdmin
- List all tables: `SELECT table_name FROM information_schema.tables WHERE table_schema='public'`
- Verify primary keys and foreign keys
- Verify data types match models
- Test connection with sample queries

**Acceptance Criteria**:
- All 6 core tables exist: teams, team_kpi_config, employees, performance_records, kpi_values, upload_log
- Primary keys properly set
- Foreign key constraints in place
- Timestamps set to NOW() for created_at/updated_at
- Zero connection errors

---

## STAGE 2: Repository Layer

### Task 2.1: Create Base Repository
**Type**: Implementation  
**Dependencies**: Task 1.2  
**Subtasks**:
- Create `Backend/repositories/` directory structure
- Implement `base_repository.py` with CRUD operations:
  - `create(obj_in: dict) -> T`
  - `get_by_id(id: any) -> Optional[T]`
  - `get_all(skip, limit) -> List[T]`
  - `update(id: any, obj_in: dict) -> Optional[T]`
  - `delete(id: any) -> bool`
- Add transaction handling and commit logic
- Create `Backend/repositories/__init__.py` with exports

**Acceptance Criteria**:
- Base repository file created and properly formatted
- All CRUD methods implemented
- Proper error handling for database operations
- Generic type support working
- No import errors

**Code Reference**: See PHASE-5-INTEGRATION-PLAN.md Stage 2.1

---

### Task 2.2: Create Team Repository
**Type**: Implementation  
**Dependencies**: Task 2.1  
**Subtasks**:
- Create `Backend/repositories/team_repository.py`
- Implement TeamRepository(BaseRepository[Team]):
  - `get_by_name(name: str) -> Team`
  - `get_active_teams() -> List[Team]`
  - `count_by_region(region: str) -> int`
  - `soft_delete(id) -> Team` (set is_active=False)
  - `restore(id) -> Team` (set is_active=True)

**Acceptance Criteria**:
- Team repository file created
- All custom methods implemented
- Database queries optimized
- Proper error handling for not-found cases
- Tested with sample queries

---

### Task 2.3: Create Employee Repository
**Type**: Implementation  
**Dependencies**: Task 2.1  
**Subtasks**:
- Create `Backend/repositories/employee_repository.py`
- Implement EmployeeRepository(BaseRepository[Employee]):
  - `get_by_employee_id(employee_id: str) -> Employee`
  - `get_by_team(team_id) -> List[Employee]`
  - `get_active_by_team(team_id) -> List[Employee]`
  - `search_by_name(name: str) -> List[Employee]`

**Acceptance Criteria**:
- Employee repository file created
- All custom methods implemented
- Team relationship queries working
- Search functionality efficient
- Tested with sample data

---

### Task 2.4: Create Performance Repository
**Type**: Implementation  
**Dependencies**: Task 2.1  
**Subtasks**:
- Create `Backend/repositories/performance_repository.py`
- Implement PerformanceRepository(BaseRepository[PerformanceRecord]):
  - `get_by_employee_month(employee_id, month, year) -> PerformanceRecord`
  - `get_monthly_records(team_id, month, year) -> List[PerformanceRecord]`
  - `get_employee_history(employee_id) -> List[PerformanceRecord]`
  - `get_by_date_range(start_date, end_date) -> List[PerformanceRecord]`

**Acceptance Criteria**:
- Performance repository file created
- All custom methods implemented
- Date-based queries working correctly
- Employee history queries optimized
- Tested with sample performance data

---

### Task 2.5: Create Additional Repositories (User, Action, AuditLog)
**Type**: Implementation  
**Dependencies**: Task 2.1  
**Subtasks**:
- Create `Backend/repositories/user_repository.py`:
  - `get_by_username(username) -> User`
  - `get_by_email(email) -> User`
  - `get_by_role(role) -> List[User]`
  - `disable_user(user_id) -> User`
- Create `Backend/repositories/action_repository.py`:
  - `get_by_employee(employee_id) -> List[Action]`
  - `get_by_team(team_id) -> List[Action]`
  - `get_by_status(status) -> List[Action]`
- Create `Backend/repositories/audit_log_repository.py`:
  - `get_by_table(table_name) -> List[AuditLog]`
  - `get_by_record(table_name, record_id) -> List[AuditLog]`
  - `get_recent(limit) -> List[AuditLog]`

**Acceptance Criteria**:
- All repository files created
- All methods implemented
- Queries optimized for common operations
- Error handling in place
- Tested with sample data

---

### Task 2.6: Test All Repositories
**Type**: Testing  
**Dependencies**: Task 2.5  
**Subtasks**:
- Create `Backend/tests/test_repositories.py`
- Test each repository CRUD operation
- Test custom query methods
- Test error handling
- Test database transactions
- Create integration test for repository interactions

**Acceptance Criteria**:
- All tests passing (100% success rate)
- Repository methods return correct data
- Error handling working as expected
- Database transactions committing properly
- No connection leaks

---

## STAGE 3: Update Services

### Task 3.1: Update TeamService
**Type**: Implementation  
**Dependencies**: Task 2.2  
**Subtasks**:
- Update `Backend/services/team_service.py`:
  - Replace JSON loading with TeamRepository queries
  - Update `get_all_teams()` to query database
  - Update `get_team(name)` to use `repo.get_by_name()`
  - Update `create_team()` to insert into teams + team_kpi_config with transaction
  - Update `update_team()` for multi-field database updates
  - Update `delete_team()` to soft-delete (set is_active=False)
  - Update `validate_team()` to check database constraints
  - Remove all `_save_team_config()` and JSON file operations

**Acceptance Criteria**:
- All JSON file I/O removed
- Database queries functioning correctly
- Multi-table transactions working
- Soft delete working (is_active flag)
- Error handling for database failures
- All methods tested with database data

---

### Task 3.2: Update PerformanceService
**Type**: Implementation  
**Dependencies**: Task 2.4  
**Subtasks**:
- Update performance service to use PerformanceRepository
- Replace JSON queries with database queries
- Implement monthly record retrieval
- Implement employee history queries
- Add date range filtering

**Acceptance Criteria**:
- All JSON operations removed
- Database queries optimized
- Performance data retrievable
- History queries working
- Error handling in place

---

### Task 3.3: Update EmployeeService
**Type**: Implementation  
**Dependencies**: Task 2.3  
**Subtasks**:
- Update employee service to use EmployeeRepository
- Replace JSON loading with database queries
- Implement team relationship queries
- Add filtering by team
- Add search functionality

**Acceptance Criteria**:
- All JSON operations removed
- Database queries working
- Team filtering functional
- Search efficient and accurate
- Error handling in place

---

### Task 3.4: Test All Services
**Type**: Testing  
**Dependencies**: Task 3.3  
**Subtasks**:
- Create `Backend/tests/test_services.py`
- Test each service method with database data
- Test error handling for missing records
- Test transaction handling
- Test relationship queries

**Acceptance Criteria**:
- All service tests passing
- Methods return correct database objects
- Error handling working
- No database errors in logs
- Services fully functional with database

---

## STAGE 4: Update API Routers

### Task 4.1: Verify Team Management Router
**Type**: Integration  
**Dependencies**: Task 3.1  
**Subtasks**:
- Verify `Backend/api/routers/team_management.py` compatibility
- Ensure endpoints call updated TeamService
- Test response schemas match database models
- Test error handling for database errors

**Acceptance Criteria**:
- All team endpoints functional
- Responses properly formatted
- Database errors handled gracefully
- No schema mismatches

---

### Task 4.2: Update Employee Router
**Type**: Integration  
**Dependencies**: Task 3.3  
**Subtasks**:
- Update `Backend/api/routers/employee.py`:
  - GET /api/employees → Query all from database
  - GET /api/employees/{id} → Query by ID from database
  - POST /api/employees → Insert into database
  - PUT /api/employees/{id} → Update database record
  - DELETE /api/employees/{id} → Soft delete
- Test all endpoints with database backend

**Acceptance Criteria**:
- All CRUD endpoints working
- Responses include all employee fields
- Relationships loaded properly
- Error handling working
- Tests passing

---

### Task 4.3: Update Performance Router
**Type**: Integration  
**Dependencies**: Task 3.2  
**Subtasks**:
- Update `Backend/api/routers/performance.py`:
  - GET /api/performance/records → Query from database
  - GET /api/performance/{emp_id}/{month} → Database query
  - GET /api/performance/team/{team_id} → Team performance data
  - POST /api/performance/records → Insert bulk records
- Test all endpoints

**Acceptance Criteria**:
- All performance endpoints functional
- Data retrieved from database
- Date filtering working
- Bulk operations supported
- Tests passing

---

### Task 4.4: Test All API Endpoints
**Type**: Testing  
**Dependencies**: Task 4.3  
**Subtasks**:
- Create integration tests for all API endpoints
- Test CRUD operations on each router
- Test error responses
- Test response schemas
- Manual testing with curl/Postman

**Acceptance Criteria**:
- All endpoints responding correctly
- Response schemas valid
- Error handling working
- Status codes appropriate
- All tests passing

---

## STAGE 5: Team Onboarding Persistence

### Task 5.1: Create OnboardingRepository
**Type**: Implementation  
**Dependencies**: Task 2.1  
**Subtasks**:
- Create `Backend/repositories/onboarding_repository.py`
- Implement OnboardingRepository(BaseRepository[OnboardingState]):
  - `get_by_team(team_id) -> OnboardingState`
  - `get_or_create(team_id) -> OnboardingState`
  - `update_step(team_id, step: int, status: str) -> OnboardingState`
  - `mark_failed(team_id, error: str) -> OnboardingState`
  - `mark_completed(team_id) -> OnboardingState`

**Acceptance Criteria**:
- Repository file created
- All methods implemented
- Database persistence working
- State recovery possible
- Tested with sample transitions

---

### Task 5.2: Update TeamOnboardingService
**Type**: Implementation  
**Dependencies**: Task 5.1  
**Subtasks**:
- Update `Backend/services/team_onboarding_service.py`:
  - Add database session management
  - Persist state after each workflow step
  - Track started_at, completed_at, last_error
  - Implement recovery from database state
  - Update status tracking

**Acceptance Criteria**:
- State persisting to database after each step
- Recovery working after restart
- Error tracking working
- Timestamps accurate
- Tests passing

---

### Task 5.3: Test Onboarding Persistence
**Type**: Testing  
**Dependencies**: Task 5.2  
**Subtasks**:
- Create onboarding persistence tests
- Test state transitions
- Test recovery after failure
- Test database state consistency
- Simulate restart recovery

**Acceptance Criteria**:
- All persistence tests passing
- State correctly recoverable
- No data loss on failure
- Recovery process working
- Integration tests passing

---

## STAGE 6: Data Migration

### Task 6.1: Create Migration Script
**Type**: Implementation  
**Dependencies**: Task 2.2, Task 2.3  
**Subtasks**:
- Create `Backend/scripts/migrate_json_to_db.py`
- Implement migrate_teams() to load from JSON configs to database
- Implement migrate_employees() if JSON data exists
- Implement migrate_performance() if JSON data exists
- Add dry-run mode for testing
- Add verification queries

**Acceptance Criteria**:
- Migration script created
- Handles all JSON data types
- Dry-run mode working
- Error handling for duplicates
- Ready for execution

---

### Task 6.2: Execute Data Migration
**Type**: Execution  
**Dependencies**: Task 6.1  
**Subtasks**:
- Run migration script in dry-run mode
- Verify no errors in dry-run output
- Execute migration script
- Verify all data migrated to database
- Validate data integrity

**Acceptance Criteria**:
- All teams migrated from JSON to database
- All KPI configs created in team_kpi_config table
- All relationships properly set
- No duplicate records
- Data integrity verified

---

### Task 6.3: Verify Migration Results
**Type**: Verification  
**Dependencies**: Task 6.2  
**Subtasks**:
- Query database for migrated data
- Compare record counts: JSON vs database
- Spot-check data samples
- Verify foreign keys
- Verify all fields populated correctly

**Acceptance Criteria**:
- All expected records found in database
- Record counts match source JSON
- Data fields complete and correct
- Foreign key relationships valid
- No orphaned records

---

## STAGE 7: Testing & Verification

### Task 7.1: Create Comprehensive Unit Tests
**Type**: Testing  
**Dependencies**: Task 6.3  
**Subtasks**:
- Create test suite for:
  - Repository CRUD operations
  - Service layer queries
  - API endpoint responses
  - Error handling scenarios
  - Database transaction behavior
- Implement tests for all 6 repositories
- Implement tests for all 3 updated services

**Acceptance Criteria**:
- All unit tests created
- Tests cover happy path and error cases
- 100% test pass rate
- Code coverage > 80%

---

### Task 7.2: Create Integration Tests
**Type**: Testing  
**Dependencies**: Task 7.1  
**Subtasks**:
- Create integration test suite
- Test repository interactions with services
- Test service interactions with API
- Test end-to-end workflows
- Test error propagation

**Acceptance Criteria**:
- All integration tests passing
- Multi-layer interactions working
- Workflows functional end-to-end
- Error handling integrated properly

---

### Task 7.3: Manual API Testing
**Type**: Testing  
**Dependencies**: Task 7.2  
**Subtasks**:
- Start backend server
- Test all CRUD endpoints manually
- Verify response data
- Test error scenarios
- Check response times

**Acceptance Criteria**:
- All endpoints responding
- Response data correct and complete
- Error responses informative
- Response times acceptable

---

### Task 7.4: Database Validation
**Type**: Verification  
**Dependencies**: Task 7.3  
**Subtasks**:
- Query all tables to verify data
- Test foreign key integrity
- Test constraint enforcement
- Run performance test queries
- Verify indexes present and efficient

**Acceptance Criteria**:
- All 6 tables contain expected data
- Foreign keys working
- Constraints enforced
- Query performance acceptable
- Indexes functioning

---

## STAGE 8: Error Handling & Logging

### Task 8.1: Implement Error Handling
**Type**: Implementation  
**Dependencies**: Task 7.4  
**Subtasks**:
- Add try-except blocks to all repository calls
- Add try-except blocks to all service methods
- Add try-except blocks to all API endpoints
- Implement specific error messages
- Return appropriate HTTP status codes

**Acceptance Criteria**:
- All database operations error-handled
- Meaningful error messages returned
- No unhandled exceptions
- HTTP status codes appropriate
- Client errors properly differentiated from server errors

---

### Task 8.2: Implement Logging
**Type**: Implementation  
**Dependencies**: Task 8.1  
**Subtasks**:
- Add logging to all database operations
- Log successful operations at INFO level
- Log errors at ERROR level
- Log warnings for edge cases
- Configure log levels (INFO, WARNING, ERROR)
- Create structured logs for monitoring

**Acceptance Criteria**:
- All database operations logged
- Log messages informative
- Error logs include stack traces
- Log levels appropriate
- Logs usable for debugging

---

### Task 8.3: Test Error Scenarios
**Type**: Testing  
**Dependencies**: Task 8.2  
**Subtasks**:
- Test database connection failure
- Test missing record scenarios
- Test invalid input handling
- Test transaction rollback on error
- Verify error logs captured

**Acceptance Criteria**:
- All error scenarios handled gracefully
- System recovers from errors
- Error information logged
- User-facing errors informative
- No data corruption on error

---

### Task 8.4: Final System Verification
**Type**: Verification  
**Dependencies**: Task 8.3  
**Subtasks**:
- Run full test suite
- Verify zero compilation errors
- Check all services functional
- Verify all API endpoints working
- Confirm database fully integrated

**Acceptance Criteria**:
- All tests passing
- No compilation errors
- All services functional
- All endpoints working
- Database fully integrated
- System ready for Phase 5 Part 5

---

## Execution Checklist

### Pre-Execution
- [ ] Database `PMS_Sys` created and accessible
- [ ] `.env` configured with DATABASE_URL
- [ ] Models defined in `Backend/models/models.py`
- [ ] Alembic configured in `Backend/migrations/`
- [ ] All dependencies installed

### Execution Progress
- [ ] Stage 1 Complete
- [ ] Stage 2 Complete
- [ ] Stage 3 Complete
- [ ] Stage 4 Complete
- [ ] Stage 5 Complete
- [ ] Stage 6 Complete
- [ ] Stage 7 Complete
- [ ] Stage 8 Complete

### Post-Execution
- [ ] All 74+ tests passing
- [ ] Zero errors in logs
- [ ] All endpoints functional
- [ ] Database migration successful
- [ ] Ready for Phase 5 Part 5

---

## Success Metrics

| Metric | Target | Status |
|--------|--------|--------|
| All tests passing | 100% | ⏳ |
| Compilation errors | 0 | ⏳ |
| API endpoints working | 100% | ⏳ |
| Database tables populated | 6/6 | ⏳ |
| Services using database | 11/11 | ⏳ |
| Average query time | < 50ms | ⏳ |
| Error handling coverage | 100% | ⏳ |
| Logging implemented | 100% | ⏳ |

---

## References

- **Integration Plan**: `.kiro/PHASE-5-INTEGRATION-PLAN.md`
- **Execution Guide**: `Backend/PHASE-5-EXECUTION-GUIDE.md`
- **Database Setup**: `Backend/DATABASE_SETUP.md`
- **Models Reference**: `Backend/models/models.py`
- **Previous Context**: `.kiro/SESSION-SUMMARY.md`

---

**Ready to begin execution!**

Start with **Stage 1: Database Initialization** and proceed through each stage systematically.

