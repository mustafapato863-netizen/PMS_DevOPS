# Implementation Plan: Phase 5 Part 5 - Authentication, Optimization, Advanced Features & Monitoring

## Overview

This plan implements enterprise-grade authentication (JWT + bcrypt), role-based access control,
Redis caching and query optimization, advanced data management (audit trails, soft deletes,
versioning, bulk operations), and production monitoring (health checks, error tracking, logging,
Docker). All work builds on the existing SQLAlchemy / FastAPI backend established in Phase 5.

---

## Tasks

### Stage 1 — Authentication & Security

- [ ] 1. Update User model with authentication fields
  - Add `password_hash` (Text, not null), `failed_login_attempts` (Integer, default 0),
    `locked_until` (DateTime nullable), and `last_login` (DateTime nullable) columns to the
    `users` table in `Backend/models/models.py`
  - Add `is_active` (Boolean, default True, not null) to User, Employee, Team, and Action
    models to enable soft deletes (Req 10.1)
  - Generate an Alembic migration (`alembic revision --autogenerate`) for these schema changes
  - _Requirements: 1.2, 4.3, 4.4, 10.1_


- [ ] 2. Implement password validation and hashing utilities
  - [ ] 2.1 Create `Backend/services/password_service.py` with `validate_password_strength()`
    and `hash_password()` / `verify_password()` helpers using `bcrypt` (12 salt rounds)
    - Enforce: 12+ chars, uppercase, lowercase, digit, special character
    - Raise `ValueError` with descriptive message on policy violation
    - _Requirements: 4.1, 4.2, 4.5_
  - [ ]* 2.2 Write property test for password validation
    - **Property P3: password_hash is never stored in plaintext**
    - **Validates: Requirements 4.5**
    - Use Hypothesis to generate random valid and invalid passwords; verify that hashed output
      never equals plaintext input and always passes bcrypt verification

- [ ] 3. Implement AuthenticationService
  - [ ] 3.1 Create `Backend/services/auth_service.py` with `authenticate_user()`,
    `validate_token()`, `create_user()`, and `generate_reset_token()` methods
    - `authenticate_user()`: validate credentials, check lockout, verify bcrypt hash,
      increment/reset `failed_login_attempts`, set `locked_until` after 5 failures,
      update `last_login`, generate JWT (HS256, 1-hour expiry), store session in Redis
    - `validate_token()`: decode JWT, raise HTTP 401 on expired or invalid token
    - `create_user()`: validate password strength, hash with bcrypt, store user
    - `generate_reset_token()`: create time-limited token (24 h), return token payload
    - Add `JWT_SECRET`, `JWT_ALGORITHM`, `JWT_EXPIRE_MINUTES` to `Backend/config/settings.py`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 4.3, 4.4_
  - [ ]* 3.2 Write property test for JWT authentication
    - **Property P1: authenticate_user produces a valid JWT_Token for valid credentials**
    - **Property P2: validate_token returns False / raises 401 for expired or tampered tokens**
    - **Validates: Requirements 1.1, 1.3, 1.4**
    - Use Hypothesis to generate arbitrary token strings; verify only properly-signed,
      non-expired tokens are accepted


- [ ] 4. Implement authentication middleware and login router
  - [ ] 4.1 Create `Backend/api/middleware/auth_middleware.py` with `AuthMiddleware` that
    extracts the `Authorization: Bearer <token>` header, calls `AuthenticationService.validate_token()`,
    attaches the decoded payload to `request.state`, and returns HTTP 401 on failure
    - _Requirements: 1.3, 1.4_
  - [ ] 4.2 Create `Backend/api/routers/auth.py` with POST `/api/auth/login` and
    POST `/api/auth/logout` endpoints that delegate to `AuthenticationService`
    - Login: return `JWTToken` schema on success, HTTP 401/423 on failure
    - Logout: delete session cache key `session:{user_id}`
    - Register router in `Backend/main.py`
    - _Requirements: 1.1, 1.2_
  - [ ]* 4.3 Write unit tests for auth middleware and login endpoint
    - Test valid token passes through, expired token returns 401, locked account returns 423
    - _Requirements: 1.3, 1.4, 4.3_

- [ ] 5. Implement RBAC models and seeding
  - [ ] 5.1 Create `RolePermission` model in `Backend/models/models.py` (role, permission,
    unique constraint on `(role, permission)`), `UserTeamAssignment` model (user_id, team_id,
    access_level), and generate the Alembic migration
    - _Requirements: 2.1, 3.1, 3.2_
  - [ ] 5.2 Create `Backend/services/permission_seed.py` that seeds the `role_permissions`
    table with the `PERMISSION_MATRIX` (Admin, Manager, Executive, Viewer) defined in the design
    - Call seeder on application startup if table is empty
    - _Requirements: 3.1, 3.2_

- [ ] 6. Implement authorization middleware
  - [ ] 6.1 Create `Backend/api/middleware/rbac_middleware.py` with
    `AuthorizationMiddleware.check_permission()` that reads session from Redis cache, falls back
    to DB load, enforces role-permission checks, and validates team assignments for scoped operations
    - Return HTTP 403 when permission denied
    - Cache team-assignment result for 1 hour
    - _Requirements: 2.2, 2.3, 2.4, 2.5, 3.3, 3.4_
  - [ ]* 6.2 Write property test for authorization consistency
    - **Property P4: check_permission is consistent — Admin always True, Viewer write always False**
    - **Property P5: revoked team assignment immediately denies access**
    - **Validates: Requirements 2.2, 2.5, 2.6, 3.4**
    - Use Hypothesis with role/permission combinations; verify Admin is never denied,
      Viewer is denied all write operations

- [ ] 7. Checkpoint — Stage 1 complete
  - Ensure all authentication and RBAC tests pass. Run `pytest Backend/tests/test_auth.py
    Backend/tests/test_rbac.py -v`. Ask the user if any questions arise before proceeding.


---

### Stage 2 — Performance Optimization

- [ ] 8. Create Alembic migration for database indexes
  - [ ] 8.1 Write a new Alembic migration script in `Backend/migrations/versions/` that creates
    all composite and partial indexes defined in design section 3.1:
    - `idx_performance_employee_month_year` on `(employee_id, month, year)`
    - `idx_performance_team_month_year` on `(team_id, month, year)`
    - `idx_performance_year` on `(year)` (partition key hint)
    - `idx_kpi_values_record` on `(record_id, record_year)`
    - `idx_users_username` on `(username)`
    - `idx_user_team_assignments_user` on `(user_id, team_id)`
    - `idx_audit_log_table_record` on `(table_name, record_id, performed_at DESC)`
    - Partial indexes `idx_employees_active` and `idx_teams_active` (WHERE is_active = true)
    - GIN indexes `idx_audit_log_new_values` and `idx_audit_log_old_values` on JSONB columns
    - _Requirements: 5.1, 5.6, 9.1_

- [ ] 9. Implement Redis cache service
  - [ ] 9.1 Create `Backend/services/cache_service.py` with `CacheService` class
    - `get_performance_cache()` / `set_performance_cache()` using key
      `performance:{employee_id}:{month}:{year}`, TTL 3600 s
    - `get_team_performance_cache()` / `set_team_performance_cache()` using key
      `team_performance:{team_id}:{month}:{year}`, TTL 3600 s
    - Transparent `redis.ConnectionError` fallback (return `None`, log warning)
    - Add `REDIS_URL` to `Backend/config/settings.py`; initialize Redis client in
      `Backend/config/database.py`
    - _Requirements: 6.1, 6.2, 6.6_
  - [ ] 9.2 Create `Backend/services/cache_invalidation_service.py` with
    `CacheInvalidationService.invalidate_performance_record()` and
    `invalidate_team_config()` that delete relevant Redis keys and publish a
    `cache_invalidation` message for multi-instance synchronization
    - _Requirements: 6.3, 7.3, 7.5_
  - [ ]* 9.3 Write property test for cache TTL and invalidation
    - **Property P8: cache entries are absent after their TTL expires**
    - **Property P9: write operations invalidate all related cache keys**
    - **Validates: Requirements 6.3, 6.4**
    - Use Hypothesis with various `(employee_id, month, year)` combos; verify that after
      invalidation, `get_performance_cache` returns `None`

- [ ] 10. Implement in-memory session cache
  - [ ] 10.1 Create `Backend/services/session_cache.py` with `SessionCache` class
    (dict-based, TTL tracking, LRU eviction, 1 GB cap) implementing `get_session()`,
    `set_session()`, and `invalidate_session()` methods
    - `set_session()` enforces memory cap, evicting the LRU entry when exceeded
    - Config: KPI config TTL 4 hours, session TTL 1 hour
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  - [ ]* 10.2 Write unit tests for session cache LRU eviction
    - Verify that adding entries beyond the cap evicts the least-recently-used item
    - Verify TTL expiry causes `get_session()` to return `None`
    - _Requirements: 7.2, 7.4_

- [ ] 11. Implement QueryOptimizer service
  - [ ] 11.1 Create `Backend/services/query_optimizer.py` with `QueryOptimizer` class
    implementing `get_performance_records()`, `get_team_performance_aggregated()`, and
    `list_employees_paginated()` following the eager-load and pagination patterns from design 3.2
    - Wire cache reads/writes from `CacheService`
    - `list_employees_paginated()` enforces `limit <= 100`
    - _Requirements: 5.1, 5.2, 5.3, 5.5, 6.1, 6.2_
  - [ ]* 11.2 Write property test for pagination
    - **Property P7: paginated results always return ≤ limit records**
    - **Validates: Requirements 5.2**
    - Use Hypothesis to generate arbitrary `page` / `limit` values; verify `len(result.data) <= limit`
      and `limit` is always capped at 100

- [ ] 12. Checkpoint — Stage 2 complete
  - Run `pytest Backend/tests/test_cache.py Backend/tests/test_query_optimizer.py -v`.
    Confirm index migration applied with `alembic upgrade head`. Ask the user if any questions arise.


---

### Stage 3 — Advanced Features

- [ ] 13. Implement audit log model and service
  - [ ] 13.1 Create `AuditLog` SQLAlchemy model in `Backend/models/models.py`
    (`table_name`, `operation`, `record_id`, `old_values` JSONB, `new_values` JSONB,
    `performed_by_user_id`, `performed_at`, `ip_address` INET, `request_id`) and generate
    the Alembic migration
    - _Requirements: 9.1_
  - [ ] 13.2 Create `Backend/services/audit_service.py` with `AuditService` class
    implementing `log_operation()`, `get_record_history()`, and `export_audit_logs()` (CSV)
    - `get_record_history()` returns entries ordered `performed_at DESC`
    - `export_audit_logs()` accepts start/end date range and optional `table_name` filter
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.6_
  - [ ]* 13.3 Write property test for audit trail completeness
    - **Property P10: every data modification creates an audit log entry**
    - **Property P11: audit log query returns entries in reverse chronological order**
    - **Validates: Requirements 9.1, 9.4**
    - Use Hypothesis to simulate N random CRUD operations; verify exactly N audit log entries
      are created and returned newest-first

- [ ] 14. Implement soft delete service
  - [ ] 14.1 Create `Backend/services/soft_delete_service.py` with `SoftDeleteService`
    implementing `soft_delete_employee()`, `restore_employee()`, and generic helpers
    `soft_delete_record()` / `restore_record()` for Team, User, and Action models
    - Each method sets `is_active=False` / `True` and calls `AuditService.log_operation()`
      with operation type `SOFT_DELETE` or `RESTORE`
    - _Requirements: 10.1, 10.2, 10.5_
  - [ ] 14.2 Update existing query methods in `Backend/repositories/` and `Backend/services/`
    to add `WHERE is_active = True` filters by default; add `include_deleted` parameter
    support to employee / team list endpoints
    - Update `Backend/api/routers/employee.py` and `team.py` with the soft-delete filter
    - _Requirements: 10.3, 10.4, 10.6_
  - [ ]* 14.3 Write unit tests for soft delete and restore
    - Verify soft-deleted records are excluded from default queries
    - Verify `include_deleted=true` parameter returns soft-deleted records
    - Verify restore makes record visible again
    - _Requirements: 10.3, 10.4, 10.5_

- [ ] 15. Implement data versioning service
  - [ ] 15.1 Create `PerformanceRecordVersion` model in `Backend/models/models.py`
    (`original_record_id`, `version_number`, `score`, `grade`, `status`,
    `changed_by_user_id`, `changed_at`, `change_reason`) and generate the Alembic migration
    - _Requirements: 11.1, 11.2_
  - [ ] 15.2 Create `Backend/services/versioning_service.py` with `VersioningService`
    implementing `create_version()`, `get_version_history()`, `get_record_as_of_date()`,
    and `diff_versions()`
    - `create_version()` auto-increments `version_number` using `MAX + 1`
    - `get_record_as_of_date()` returns the latest version snapshot before the given date
    - `diff_versions()` returns a dict of `{field: {old, new}}` for changed fields between two versions
    - _Requirements: 11.2, 11.3, 11.4, 11.6_
  - [ ]* 15.3 Write unit tests for versioning
    - Verify version numbers increment sequentially
    - Verify `get_record_as_of_date()` returns correct snapshot for a past date
    - Verify `diff_versions()` highlights exactly the changed fields
    - _Requirements: 11.3, 11.4, 11.6_

- [ ] 16. Implement batch processor service
  - [ ] 16.1 Create `Backend/services/batch_processor.py` with `BatchProcessor` class
    implementing `batch_insert_performance_records()` and `batch_update_kpi_weights()`
    - Validate all records up-front; return validation errors without inserting any data
    - Process in chunks of 1000 using a transaction per chunk
    - On per-record error: log to `failed_records`, continue remaining; on chunk-level error:
      log all chunk records as failed
    - Create `AuditLog` entry for each successful insert/update
    - Return `BatchResult` with `success_count`, `failed_count`, and first-100 `failed_records`
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 12.1, 12.2, 12.3, 12.4_
  - [ ]* 16.2 Write property test for batch atomicity
    - **Property P12: batch insert is all-or-nothing — if validation fails, zero records inserted**
    - **Property P13: N records processed in ⌈N/1000⌉ chunk transactions**
    - **Validates: Requirements 8.3, 12.3, 12.4**
    - Use Hypothesis to generate record lists with injected invalid entries; verify pre-validation
      returns zero DB rows and `success_count = 0`

- [ ] 17. Implement bulk operations API endpoints
  - [ ] 17.1 Create `Backend/api/routers/bulk_operations.py` with the following endpoints,
    protected by RBAC middleware (`upload_data` / `delete_data` permissions):
    - `POST /api/performance/records/bulk` → `BatchProcessor.batch_insert_performance_records()`
    - `PATCH /api/teams/{team_id}/kpi-config/bulk-update` → `BatchProcessor.batch_update_kpi_weights()`
    - `DELETE /api/employees/bulk` → soft-delete 100 employee records in a single transaction
      via `SoftDeleteService`; invalidate related cache entries
    - Register router in `Backend/main.py`
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_
  - [ ]* 17.2 Write integration tests for bulk endpoints
    - Test `POST /api/performance/records/bulk` with 100 valid records → verify 100 inserted
    - Test with mixed valid/invalid records → verify zero inserted, errors reported
    - Test `DELETE /api/employees/bulk` → verify `is_active=False` for all targeted records
    - _Requirements: 12.1, 12.4, 12.5_

- [ ] 18. Checkpoint — Stage 3 complete
  - Run `pytest Backend/tests/test_audit.py Backend/tests/test_batch.py
    Backend/tests/test_bulk_api.py -v`.
    Verify Alembic migrations applied. Ask the user if any questions arise.


---

### Stage 4 — Monitoring & Deployment

- [ ] 19. Implement health check endpoint
  - [ ] 19.1 Create `Backend/services/health_check_service.py` with `HealthCheckService`
    - `check_health()`: probe DB with `SELECT 1` and Redis with `PING`; measure response times;
      return structured JSON with `status`, `timestamp`, `components`, `overall_response_time_ms`
    - Use in-memory status cache with 10-second TTL to limit DB/cache probing
    - DB unavailable → HTTP 503; Redis unavailable → HTTP 200 (degraded)
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6_
  - [ ] 19.2 Create `Backend/api/routers/health.py` with `GET /api/health` endpoint that
    calls `HealthCheckService.check_health()` and returns the appropriate HTTP status code
    - Register router in `Backend/main.py`
    - _Requirements: 13.1, 13.2, 13.3_
  - [ ]* 19.3 Write property test for health check response
    - **Property P14: health check always responds in < 100ms**
    - **Property P15: component unavailability produces correct HTTP status**
    - **Validates: Requirements 13.1, 13.2, 13.3, 13.5**
    - Mock DB and Redis; verify healthy → 200, DB down → 503, Redis down → 200 degraded

- [ ] 20. Implement error tracking and alerting
  - [ ] 20.1 Create `ErrorLog` SQLAlchemy model in `Backend/models/models.py`
    (`error_type`, `message`, `stack_trace`, `endpoint`, `method`, `user_id`,
    `request_id`, `context` JSONB, `occurred_at`, `severity`) and generate the Alembic migration
    - _Requirements: 14.1, 14.4_
  - [ ] 20.2 Create `Backend/services/error_tracker.py` with `ErrorTracker.log_error()` that
    captures full stack trace, endpoint, method, user_id, request_id, and severity, then stores
    an `ErrorLog` entry; calls `_check_alert_threshold()` after each log entry
    - `_check_alert_threshold()`: count errors and requests in the last 5 minutes; trigger
      `AlertService.send_alert()` if error rate > 1%
    - _Requirements: 14.1, 14.2, 14.3, 14.4_
  - [ ] 20.3 Create `Backend/services/alert_service.py` with `AlertService.send_alert()`
    that logs the alert and dispatches to Slack webhook (if `SLACK_WEBHOOK_URL` configured)
    and/or email (if `SMTP_*` settings configured)
    - _Requirements: 14.2, 14.3, 14.6_
  - [ ] 20.4 Create `Backend/api/middleware/error_handling_middleware.py` with
    `ErrorHandlingMiddleware` that catches `HTTPException`, `ValueError`, and generic
    `Exception`; delegates to `ErrorTracker.log_error()`; returns user-friendly JSON response
    - Register middleware in `Backend/main.py` (outermost layer)
    - _Requirements: 14.1, 14.4_
  - [ ]* 20.5 Write unit tests for error tracking
    - Verify that an unhandled exception creates an `ErrorLog` entry with correct fields
    - Verify that error rate > 1% triggers `AlertService.send_alert()`
    - _Requirements: 14.1, 14.2_

- [ ] 21. Configure structured logging
  - [ ] 21.1 Create `Backend/config/logging_config.py` that configures Python's `logging`
    module to emit structured JSON output (`timestamp`, `level`, `message`, `request_id`,
    `user_id`, `endpoint`, `method`, `response_status`, `response_time_ms`)
    - Add a `RequestLoggingMiddleware` that logs every request/response with the fields above
    - Add log rotation via `RotatingFileHandler` (daily rotation, 30-day retention, compression)
    - Initialize the logging config in `Backend/main.py` on startup
    - _Requirements: 16.1, 16.4, 16.5_
  - [ ] 21.2 Add database operation logging: wrap key service methods in `Backend/services/`
    with log calls that emit `operation`, `table`, `duration_ms`, and `rows_affected`
    - _Requirements: 16.2_
  - [ ]* 21.3 Write unit tests for structured log output
    - Verify that a simulated request produces a JSON log line containing all required fields
    - _Requirements: 16.1_

- [ ] 22. Update Dockerfile and add Docker Compose configuration
  - [ ] 22.1 Update `Backend/Dockerfile` to:
    - Use `python:3.11-slim` base image
    - Install `postgresql-client` system dependency
    - Copy `requirements.txt` and run `pip install --no-cache-dir`
    - Copy application code; create non-root user `appuser` (UID 1000)
    - Add `HEALTHCHECK` calling `GET http://localhost:8000/api/health`
    - `EXPOSE 8000`; `CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]`
    - _Requirements: 15.2_
  - [ ] 22.2 Create `docker-compose.yml` in the project root with `db` (postgres:15-alpine),
    `redis` (redis:7-alpine), and `backend` services as defined in design section 8.4
    - Include health checks, `depends_on` conditions, and volume mounts
    - Reference `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET`, and `ENVIRONMENT` via `.env`
    - _Requirements: 15.4_
  - [ ] 22.3 Create `.github/workflows/deploy.yml` with build, test, and deploy stages
    as defined in design section 8.2
    - Test job spins up `postgres:15` and `redis:7` service containers
    - Run `pytest tests/ -v --cov=. --cov-report=xml` in the test job
    - Build and push Docker image tagged with git commit SHA
    - _Requirements: 15.1, 15.3, 15.6_

- [ ] 23. Final checkpoint — All tests pass
  - Run `pytest Backend/tests/ -v --cov=Backend --cov-report=term-missing`.
    Verify Docker build succeeds with `docker build -t pms-backend ./Backend`.
    Ask the user if any questions arise before concluding.


---

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP delivery
- Every stage has a checkpoint task — do not skip them; they surface integration issues early
- All property-based tests use **Hypothesis** (Python); install with `pip install hypothesis`
- All new code must be registered in `Backend/main.py` (routers, middleware, startup events)
- Run `alembic upgrade head` after completing tasks 1, 5.1, 13.1, 15.1, and 20.1 before proceeding
- `Backend/config/settings.py` should expose: `JWT_SECRET`, `JWT_ALGORITHM`, `REDIS_URL`,
  `SLACK_WEBHOOK_URL`, `SMTP_*` settings — load from environment variables only
- Never store plaintext passwords in logs, configuration files, or cache values

---

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1"] },
    { "id": 1, "tasks": ["2.1", "5.1"] },
    { "id": 2, "tasks": ["2.2", "3.1", "8.1"] },
    { "id": 3, "tasks": ["3.2", "4.1", "4.2", "9.1"] },
    { "id": 4, "tasks": ["4.3", "5.2", "9.2", "10.1", "13.1"] },
    { "id": 5, "tasks": ["6.1", "9.3", "10.2", "11.1", "13.2", "14.1", "15.1", "20.1"] },
    { "id": 6, "tasks": ["6.2", "11.2", "13.3", "14.2", "15.2", "16.1", "20.2"] },
    { "id": 7, "tasks": ["11.3", "14.3", "15.3", "16.2", "17.1", "19.1", "20.3", "20.4", "21.1"] },
    { "id": 8, "tasks": ["17.2", "19.2", "20.5", "21.2"] },
    { "id": 9, "tasks": ["19.3", "21.3", "22.1"] },
    { "id": 10, "tasks": ["22.2"] },
    { "id": 11, "tasks": ["22.3"] }
  ]
}
```
