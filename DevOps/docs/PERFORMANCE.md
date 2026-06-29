# Performance Guide

This document describes the performance considerations, data-caching layers, database index structures, and future optimization targets designed to keep the PMS Dashboard highly responsive under heavy corporate workloads.

---

## 1. Data Retrieval Strategy

To balance speed and consistency, the system follows a structured hierarchy for fetching data:

```
                  Client Request
                        |
                        v
               Check Redis Cache (Cache Hit) ---> Return cached JSON
                        |
                  (Cache Miss)
                        |
                        v
               Read PostgreSQL DB (DB-First) ---> Populate Redis & Return
                        |
               (PostgreSQL Offline)
                        |
                        v
             Read Local JSON Files (Fallback) --> Return static data
```

### A. DB-First Reads
Endpoints querying dashboard scores, metrics, or employee profiles query the database first via SQLAlchemy ORM. This ensures that managers always see real-time data after an Excel workbook upload is completed.

### B. Repository Pattern
Data retrieval logic is encapsulated in repositories (located under `Backend/repositories/`). The repository abstracts database execution, handling connections, fallback triggers, and joins. This separation of concerns prevents data access code from leaking into FastAPI routers or service layers.

### C. Redis Caching
- **Target:** Dashboard aggregates and team settings configurations are cached in Redis to bypass database query latency.
- **Cache Invalidation:** The caching service invalidates specific keys (e.g. `team_performance_*`, `team_weights_*`) immediately upon new Excel workbook uploads or manual user updates, preventing stale data.
- **Failover:** If Redis is down, the system transparently falls back to local in-memory LRU cache stores without throwing errors.

### D. JSON Fallbacks
If the PostgreSQL database is unreachable or completely empty, the repository layer automatically degrades to reading static pre-seeded JSON data files located under `Backend/data/`. This maintains dashboard functionality in testing or disconnected staging environments.

---

## 2. Database Index Specifications

To speed up common read paths and search queries, PostgreSQL indexes are applied as follows:

| Index Name | Table | Columns | Type | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `idx_employees_name_trgm` | `employees` | `name` | GIN | Enables fast, trigram-based fuzzy text search on employee names. |
| `idx_audit_log_performed_at` | `audit_log` | `performed_at` | B-Tree | Speeds up timeline ordering and chronological filtering. |
| `idx_perf_team_month_year` | `performance_records`| `team_id, month, year` | B-Tree | Optimizes dashboard query aggregation filters. |
| `uq_perf_employee_month_year`| `performance_records`| `employee_id, month, year`| Unique | Prevents duplicate ingestion records at the database tier. |

---

## 3. Dynamic Query Optimization & Telemetry

### Query Eager Loading
To prevent $N+1$ query issues, repositories utilize SQLAlchemy's `joinedload` and `selectinload` directives. When fetching employee profiles, related team records, and monthly performance stats, the system retrieves the entire object graph in a single query.

### Request & Ingestion Performance Logs
The API instrumentator logs request timing metrics automatically. Every request prints a structured JSON log containing:
- Target endpoint URL path.
- Request method (GET/POST/etc).
- Response HTTP status code.
- Round-trip execution latency in milliseconds (`duration_ms`).

Example timing log:
```json
{
  "timestamp": "2026-06-25T12:00:00Z",
  "level": "INFO",
  "logger": "app",
  "message": "request completed",
  "request_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
  "path": "/api/performance/team/inbound_egy",
  "method": "GET",
  "status_code": 200,
  "duration_ms": 14.52
}
```

Excel workbook ingestion times are also logged inside `ExcelProcessor` to measure ingestion pipeline latency.

---

## 4. Performance Scaling Roadmap

As workforce records grow, the following items will be implemented to keep latency low:

### A. Materialized Views [Planned]
- **Objective:** Pre-aggregate monthly team metrics (headcount, average scores, grade counts, status percentages) into a materialized view `mv_team_monthly_summary`.
- **Latency Impact:** Reduces dashboard query time from $O(N)$ dynamic database scans to $O(1)$ flat record fetches.
- **Refresh Schedule:** Refreshed concurrently on a background scheduler following workbook ingestion.

### B. Asynchronous Upload Processing [Planned]
- **Objective:** Excel imports containing large rosters can block FastAPI ASGI request threads, leading to HTTP 504 gateway timeouts.
- **Implementation:** Introduce Celery workers or a lightweight task queue (Redis Queue) to process files asynchronously, returning a task token immediately.
- **Client UX:** Frontend displays a progress bar and receives processing completion notifications via Socket.IO push alerts.

---

## 5. Performance Benchmarking Recommendations

To validate platform responsiveness, engineers should conduct tests under simulated concurrency profiles:

### Load Testing
- **Tools:** Use `Locust` or `k6` to simulate concurrent API requests on dashboard endpoints.
- **Target Metrics:** Peak concurrency of 500 agents/managers reading reports, with 95% of response latencies under `150ms`.

### Query Profiling
- **Slow Query Tracking:** Configure PostgreSQL's `log_min_duration_statement` to `200` to automatically write trace records for queries taking longer than 200ms.
- **Execution Plans:** Run `EXPLAIN ANALYZE` on SQLAlchemy-generated SQL text to verify index utilization.
