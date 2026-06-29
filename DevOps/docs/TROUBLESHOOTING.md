# Troubleshooting Guide

This document lists operational scenarios, errors, and system failures encountered during development and deployment, providing clear instructions for diagnosis and resolution.

---

## 1. Redis Cache Unavailable

### Symptoms
- Increased API latency.
- Log error messages: `ConnectionError: Error connecting to Redis` or `Redis connection refused`.
- Dynamic configurations are loaded from database on every single API request.

### Root Cause
- The Redis container is stopped, unreachable due to docker network misconfiguration, or credentials are bad.

### Diagnosis
- Check container status: `docker ps | grep redis`
- Run internal ping check: `docker exec -it pms_redis_cache_prod redis-cli ping` (expected output: `PONG`).

### Resolution
1. Verify Redis URL in `.env`: `REDIS_URL=redis://redis:6379/0`.
2. Restart Redis container: `docker compose restart redis`.
3. If Redis is down, check fallback validation: the application will continue running by transparently falling back to local in-memory LRU cache stores, avoiding gateway crashes.

### Prevention
- Configure service restarts in Compose: `restart: unless-stopped`.
- Implement alerts on Sentry for Redis connection failures.

---

## 2. Database (PostgreSQL) Unavailable

### Symptoms
- Health checks return HTTP 503 Service Unavailable.
- App routes crash with `ConnectionRefusedError` or `OperationalError: Could not connect to server`.
- Login, planning, user management, and Excel uploads fail completely.

### Root Cause
- Postgres container is down, disk volume is full, or the database credentials (URL) are incorrect.

### Diagnosis
- Check DB container health: `docker inspect --format='{{json .State.Health}}' pms_postgres_db_prod`
- Manually run connection probe: `pg_isready -h localhost -p 5432 -U postgres`

### Resolution
1. Verify database connection variables inside `.env`.
2. Check database log traces: `docker compose logs db`.
3. Restart postgres services: `docker compose restart db`.

### Prevention
- Enable Prometheus alerting on database storage capacity.
- Set up connection pools dynamically in `database.py` with recycling checks (`pool_pre_ping=True`).

---

## 3. JSON Fallback Activated

### Symptoms
- Dashboard loads and operates normally, but updates made in the database or uploads do not reflect.
- Log traces show warnings: `Database unreachable or empty. Operating in local JSON fallback mode.`

### Root Cause
- The database is empty (unseeded) or connection was lost, causing the repository layer to delegate queries to fallback JSON files in `Backend/data/`.

### Diagnosis
- Query performance records count: `SELECT COUNT(*) FROM performance_records;`
- Inspect log trace files for `Operating in local JSON fallback mode`.

### Resolution
1. If database is unreachable, resolve database connectivity as detailed in **Section 2**.
2. If database is connected but empty, run startup seeds to populate relational structures: `alembic upgrade head` and restart backend to run seeding logic.

### Prevention
- Ensure Alembic migration runner script is chained in startup commands inside Dockerfiles or container scripts.

---

## 4. Duplicate Excel Upload

### Symptoms
- Ingestion endpoint returns HTTP 400 Bad Request.
- Error message: `Duplicate upload. Performance data already exists for this team, month, and year.`

### Root Cause
- A workbook has already been successfully processed for the specified combination of team, month, and year. Enforced by unique constraints (`uq_perf_employee_month_year`).

### Diagnosis
- Look at database table `upload_log` to verify records:
  ```sql
  SELECT status, uploaded_at FROM upload_log WHERE team_id = :team_id AND month = :month AND year = :year;
  ```

### Resolution
1. If the previous data was incorrect, delete the previous upload to clear records.
2. Re-upload the corrected spreadsheet workbook.

### Prevention
- Implement frontend warnings before uploading if data has already been recorded for the month.

---

## 5. Duplicate Employee IDs in Database

### Symptoms
- Excel uploads fail with constraint violation errors: `duplicate key value violates unique constraint "employees_employee_id_key"`.
- Backend logs show transaction rollbacks.

### Root Cause
- The workbook spreadsheet contains multiple employee profiles with identical HR IDs, or the ID is already mapped to a different name in the database.

### Diagnosis
- Search for the duplicate ID inside the database:
  ```sql
  SELECT * FROM employees WHERE employee_id = :id;
  ```

### Resolution
1. Open the Excel spreadsheet and look for duplicate rows.
2. Correct the names or IDs to align with HR metadata, ensuring one unique ID per employee.

### Prevention
- Implement Excel pre-upload validation checks in `ExcelProcessor` to verify name/ID mapping sanity before transactional execution.

---

## 6. SGHD Employee Code Mismatch

### Symptoms
- Workbook upload rejected with validation error: `Invalid Employee Code format for team. Must match prefix SGHD.`
- Employees list shows non-conforming HR identifiers.

### Root Cause
- For Inbound, Outbound, and Pre-Approvals IP Offshore teams, employee codes must start with the prefix `SGHD`.

### Diagnosis
- Check the workbook sheet row values: find rows where code does not match `^SGHD\d+$`.

### Resolution
1. Adjust the Excel source sheet data to correct invalid employee codes.
2. Re-upload.

### Prevention
- Enforce regex checks in the front-end file analyzer.

---

## 7. Decimal Conversion Syntax Error

### Symptoms
- Excel uploads crash during column conversion.
- Backend error trace: `InvalidOperation: [<class 'decimal.ConversionSyntax'>]`.

### Root Cause
- The workbook contains textual entries (e.g. `'N/A'`, `'EXEMPT'`) in columns designated for numeric scores (e.g. actual, target).

### Diagnosis
- Inspect logs to locate the column key causing the failure (e.g., target_col, actual_col).

### Resolution
1. Modify spreadsheet cell contents to either be numeric value or blank.
2. In the team configurations JSON, verify target/actual mappings.

### Prevention
- Utilize robust cleaners (e.g. `parse_percentage`) that handle non-numeric cells by converting them to defaults (e.g., `0.0` or `None`).

---

## 8. Upload Transaction Rollback

### Symptoms
- Ingestion endpoint returns HTTP 400 or 500.
- `upload_log` records show status `'failed'` with error traceback details.
- No new employee profiles or performance score records appear in the database.

### Root Cause
- Database transaction rolls back completely when any row fails verification, protecting integrity.

### Diagnosis
- Read log trace error block and inspect `upload_log.error_message`.

### Resolution
- Address the specific data validation error highlighted in the log, then retry the upload.

### Prevention
- Ensure all repository operations are executed inside `db.begin()` blocks.

---

## 9. LogRecord Filename Overwrite Warning

### Symptoms
- Logger outputs warning messages: `LogRecord property 'filename' overwritten by...`

### Root Cause
- Structured logging configuration inserts custom keys (e.g., filename) that collide with standard Python `logging.LogRecord` properties.

### Diagnosis
- Check keys in `JSONFormatter` class mapping.

### Resolution
- Rename custom log record attributes to avoid collision (e.g. use `log_filename` instead of `filename`).

### Prevention
- Restrict custom extra variables to distinct nested JSON keys.

---

## 10. Socket.IO Reconnection Loops

### Symptoms
- Browser console shows continuous loops: `Socket connected`, `Socket disconnected`, `reconnecting...`.
- Real-time notification banners flash repeatedly.

### Root Cause
- Client/server protocol mismatch (e.g. WebSocket connection blocked, falling back to polling), or missing CORS configs on Socket.IO server constructor.

### Diagnosis
- Open DevTools Network tab, check WS handshake status, and search for failed socket requests.

### Resolution
1. Verify `VITE_SOCKET_URL` origin configurations.
2. In `socket_config.py`, verify `cors_allowed_origins` matches the frontend server.

### Prevention
- Enable automated fallback transports (`['websocket', 'polling']`).

---

## 11. Manager Sidebar Initialization Delay

### Symptoms
- Manager logs in, but sidebar links (e.g., assigned teams) take several seconds to appear.
- Empty states show briefly: "No assigned teams".

### Root Cause
- Gated sequence routing wait: sidebar links depend on resolution of `/api/auth/me` endpoints.

### Diagnosis
- Check DevTools Network tab for duration of `/api/auth/me` query execution.

### Resolution
- Cache user team assignments in Zustand store.

### Prevention
- Implement loading skeletons on sidebars while auth states are resolving.

---

## 12. Executive vs. All Teams Summary Mismatch

### Symptoms
- Executive dashboard aggregates show differences in headcount or average scores compared to the sum of individual team views.

### Root Cause
- Selection of month filters (e.g., "All Months") compiles repeated employee rows in individual dashboards while the Executive summaries cap values.

### Diagnosis
- Run database aggregate queries comparing distinct user counts versus performance record sums.

### Resolution
- Check that the dashboard metrics cards utilize latest available month headcount for All Months, while trend lines compile sums across all months.

### Prevention
- Keep warnings and notes clearly displayed on cards.

---

## 13. Dashboard Latest-Month Behavior

### Symptoms
- Selecting a team displays data from a past month (e.g. May) by default instead of the current calendar month.

### Root Cause
- The dashboard is designed to default to the latest available month containing actual database performance records.

### Diagnosis
- Verify database max upload record: `SELECT MAX(year), MAX(month) FROM performance_records;`

### Resolution
- Upload data for the current month to update the dashboard defaults.

### Prevention
- Document this intended design behavior to prevent confusion.

---

## 14. JWT Session Invalidation Failure

### Symptoms
- Administrator disables a user user in the database, but the disabled user is still able to execute API commands using their active token.

### Root Cause
- JWT is stateless; the backend only validates the token signature, signature expiry, and payload parameters, without checking the database.

### Diagnosis
- Disable user in database, call API route with active token, and check if request completes.

### Resolution
- Deploy the security check middleware (`AuthMiddleware`) which queries the database for user status on every request, immediately rejecting requests if `is_active` is false.

### Prevention
- Enforce DB check on every request.

---

## 15. Suspended Users Bypass

### Symptoms
- Suspended manager logins are rejected, but their WebSockets connection remains active, receiving real-time alerts.

### Root Cause
- WebSockets authentication only happens during handshake. Session deactivation does not force disconnect active connections.

### Diagnosis
- Suspend user, trigger upload notification, check if socket listener client gets push events.

### Resolution
- Register socket middleware that checks user active status during event dissemination, or force disconnect socket sessions on user suspension.

### Prevention
- Run periodic checks on active socket connection pool status.

---

## 16. Frontend Build Failures

### Symptoms
- Running `npm run build` crashes.
- Logs: `TypeScript error: Property does not exist...` or `Type 'any' is not assignable to...`.

### Root Cause
- Strict TypeScript configuration checks fail due to type discrepancies or missing exports.

### Diagnosis
- Run local check: `npx tsc --noEmit` and check output log locations.

### Resolution
- Address strict type mismatches or utilize explicit typing instead of `any`.

### Prevention
- Enable pre-commit build checks.

---

## 17. Docker Startup Failures

### Symptoms
- Running `docker compose up` crashes immediately.
- Container status: `Exited (1)`.

### Root Cause
- Port collisions (e.g., local PostgreSQL running on host port 5432, preventing Docker from binding port 5432) or malformed `.env` parameters.

### Diagnosis
- Check port bindings on the host: `netstat -ano | findstr 5432` or `docker compose logs`.

### Resolution
1. Stop host services (e.g. stop local postgres service: `Stop-Service postgresql`).
2. Update ports in `docker-compose.yml` if necessary.

### Prevention
- Ensure ports are configured dynamically through `.env` variable overrides.

---

## 18. Alembic Migration Failures

### Symptoms
- Database migrations crash with schema errors: `relation already exists` or `column does not exist`.

### Root Cause
- Schema changes made manually on the database out of sync with migration history files.

### Diagnosis
- Run migration status: `alembic current` and inspect differences.

### Resolution
1. Revert manual database adjustments.
2. In extreme cases, rebuild database from schema files and re-run migrations.

### Prevention
- Never adjust production schemas outside Alembic migrations.
