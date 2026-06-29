# API Reference

This document provides a comprehensive specification of all REST API endpoints exposed by the PMS Dashboard.

All endpoints are prefixed with `/api` unless otherwise specified.

---

## 1. Authentication Endpoints

### `POST /api/auth/login`
Authenticates a user and issues a JSON Web Token (JWT).
- **Description:** Verifies credentials and returns user profile, role permissions, and access token.
- **Authentication Required:** No
- **Request Body Example:**
  ```json
  {
    "username": "admin",
    "password": "SecurePassword123!"
  }
  ```
- **Response Example (200 OK):**
  ```json
  {
    "success": true,
    "message": "Login successful",
    "data": {
      "access_token": "eyJhbGciOiJIUzI1NiIsIn...",
      "token_type": "bearer",
      "user": {
        "user_id": "c1a6b0c2-55d6-47e1-88f2-8c9e0d1a2b3c",
        "username": "admin",
        "email": "admin@pms.local",
        "role": "Admin"
      }
    }
  }
  ```
- **Error Responses:**
  * **401 Unauthorized:** Invalid username or password.
  * **423 Locked:** Account locked due to excessive failed attempts.

### `POST /api/auth/logout`
Deauthorizes the current user session.
- **Description:** Clears the active session and blacklists the token JTI in Redis (when active).
- **Authentication Required:** Yes
- **Response Example (200 OK):**
  ```json
  {
    "success": true,
    "message": "Logout successful"
  }
  ```

### `GET /api/auth/me`
Retrieves the profile and permissions of the active session.
- **Description:** Decodes token and fetches active user data from the database.
- **Authentication Required:** Yes
- **Response Example (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "user_id": "c1a6b0c2-55d6-47e1-88f2-8c9e0d1a2b3c",
      "username": "admin",
      "email": "admin@pms.local",
      "role": "Admin",
      "permissions": ["read:performance", "write:team", "manage:users"]
    }
  }
  ```

---

## 2. Dashboard Endpoints

### `GET /api/performance`
Fetches aggregated summary metrics for the dashboard view.
- **Description:** Returns average score, team rosters, grade distributions, and headcount stats.
- **Authentication Required:** Yes
- **Query Parameters:**
  * `month` (string, optional, e.g. `'January'`, `'All'`)
  * `year` (integer, optional, e.g. `2024`)
- **Response Example (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "average_score": 85.4,
      "headcount": 42,
      "grade_distribution": { "A": 5, "B": 12, "C": 20, "D": 4, "E": 1 },
      "headcount_note": "Current headcount based on May"
    }
  }
  ```

---

## 3. Employee Endpoints

### `GET /api/employee`
Lists all active employees.
- **Description:** Returns paginated list of employee metadata.
- **Authentication Required:** Yes
- **Query Parameters:**
  * `skip` (integer, default `0`)
  * `limit` (integer, default `100`)
- **Response Example (200 OK):**
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "e87f9da4-ed8f-4731-8335-3ac20e889a3b",
        "employee_id": "SGHD70170",
        "name": "Jane Doe",
        "team_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
        "region": "EGY"
      }
    ]
  }
  ```

### `POST /api/employee`
Creates a new employee record.
- **Description:** Saves a new employee profile. Enforces SGHD prefix constraints for specific teams.
- **Authentication Required:** Yes
- **Required Permission:** `write:employee`
- **Request Body Example:**
  ```json
  {
    "employee_id": "SGHD70170",
    "name": "Jane Doe",
    "team_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
    "region": "EGY"
  }
  ```
- **Validation Rules:**
  * `employee_id` must use the SGHD prefix if the team is Inbound, Outbound, or Pre-Approvals.

---

## 4. Team Endpoints

### `GET /api/team-management/teams`
Lists all operational teams and configuration links.
- **Authentication Required:** Yes
- **Response Example (200 OK):**
  ```json
  {
    "teams": [
      {
        "id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
        "name": "inbound_egy",
        "db_name": "Inbound",
        "region": "EGY",
        "is_active": true
      }
    ]
  }
  ```

---

## 5. Upload Endpoints

### `POST /api/uploads/pms`
Uploads and processes a team Excel workbook.
- **Description:** Ingests monthly performance spreadsheets, cleans data via factory rules, and commits transactions.
- **Authentication Required:** Yes
- **Required Permission:** `upload:data`
- **Request Parameters (Multipart Form):**
  * `file`: Binary file path (`.xlsx`)
  * `team_id`: UUID
  * `month`: String (e.g. `'May'`)
  * `year`: Integer (e.g. `2024`)
- **Response Example (200 OK):**
  ```json
  {
    "success": true,
    "message": "Ingestion successful",
    "records_inserted": 42
  }
  ```
- **Error Responses:**
  * **400 Bad Request:** Missing columns, invalid data formats, or duplicate record constraints.

---

## 6. Notification Endpoints

### `GET /api/users/notifications`
Lists notifications for the authenticated user session.
- **Authentication Required:** Yes
- **Response Example (200 OK):**
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "f8a9b0c1-d2e3-4f5a-6b7c-8d9e0f1a2b3c",
        "notification_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
        "type": "grade_alert",
        "title": "Grade Alert",
        "message": "Jane Doe scored Grade E on Utilization.",
        "is_read": false,
        "created_at": "2026-06-25T12:00:00Z"
      }
    ]
  }
  ```

### `PUT /api/users/notifications/{recipient_id}/read`
Marks a specific notification recipient record as read.
- **Authentication Required:** Yes
- **Response Example (200 OK):**
  ```json
  {
    "success": true,
    "message": "Notification marked as read"
  }
  ```

---

## 7. Settings Endpoints

### `GET /api/settings/weights`
Retrieves configured KPI weights and metadata.
- **Authentication Required:** Yes
- **Response Example (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "inbound_egy": {
        "attendance": 0.70,
        "qa": 0.10,
        "aht": 0.10,
        "nps": 0.10
      }
    }
  }
  ```

---

## 8. Planning Endpoints

### `GET /api/performance/planning`
Lists corrective actions and team targets.
- **Authentication Required:** Yes
- **Required Permission:** `read:performance`
- **Response Example (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "actions": [
        {
          "id": "e87f9da4-ed8f-4731-8335-3ac20e889a3b",
          "employee_id": "SGHD70170",
          "action_type": "PIP",
          "status": "Open",
          "action_text": "Schedule daily attendance mentoring sessions."
        }
      ]
    }
  }
  ```

---

## 9. Health & System Probes

### `GET /api/health`
General system health status checker.
- **Authentication Required:** No
- **Response Example (200 OK):**
  ```json
  {
    "status": "healthy",
    "details": {
      "database": "online",
      "redis": "online"
    }
  }
  ```

### `GET /api/health/liveness`
Orchestrator probe verifying app server responsiveness.
- **Authentication Required:** No
- **Response Example (200 OK):**
  ```json
  {
    "status": "alive"
  }
  ```

### `GET /api/health/readiness`
Orchestrator probe verifying database and cache link state.
- **Authentication Required:** No
- **Response Example (200 OK):**
  ```json
  {
    "status": "healthy",
    "details": {
      "database": "online",
      "redis": "online"
    }
  }
  ```
