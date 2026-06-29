# Security & User Access Control

This document describes the security protocols, authorization layers, active session checks, role policies, and audit logging features of the system.

---

## 1. Authentication Layer (JWT)

Authentication is stateless and managed using JSON Web Tokens (JWT).
- **Token Generation:** Upon successful login, the backend issues an access token signed with a HS256 secret.
- **Header Verification:** Authenticated REST endpoints verify the token signature in the `Authorization: Bearer <token>` header.
- **Token Lifespan:** Expire timeouts are controlled via backend environment variables.

---

## 2. Active Session & User Suspension Policy

A major security rule protects the dashboard against deactivated or suspended accounts:
- **No Client-Only Authority:** The frontend localStorage session token is treated as information-only; it is not sufficient authority to access data.
- **Backend Verification:** On *every* authenticated request, the backend extracts the user's ID from the JWT payload and queries the database `users` table.
- **Instant Revocation:** If `is_active` is set to `false` (suspended) or the user is deleted, the request is immediately rejected with a `401 Unauthorized` status, terminating active API access.

---

## 3. Role-Based Access Control (RBAC)

The application implements four roles:

| Role | Access Scope | Allowed Operations |
| :--- | :--- | :--- |
| **Admin** | Global system access | Manage user credentials, upload performance data, edit KPI configurations, add new teams, override records. |
| **Manager** | Scoped team access | Record employee notes, trigger corrective actions (Training, Coaching, PIP), view dashboards for assigned teams. |
| **Executive** | Read-only global access | View all dashboards, run exports, read summaries, search employee profiles. (Blocked from write operations). |
| **Viewer** | Personal/Agent access | View personal profile card and team summary KPI cards. (Cannot record notes or alter settings). |

*Note:* Teams assigned to a Manager are declared in the `user_team_assignments` junction table. REST endpoints verify that the manager is assigned to the target team before processing commands.

---

## 4. Audit Logging

A structured audit engine tracks critical system modifications.
- **Action Logs:** Changes to employees, configurations, settings, user accounts, and upload operations write a record to `audit_log`.
- **Differential Payload:** Audit records store the `old_values` and `new_values` as JSONB payloads, logging the exact field differentials.
- **Identity Context:** Audit logs record the ID of the user performing the update, the operation timestamp, and the client's IP address.

---

## 5. Security Roadmap [Planned]

The following security features are planned for future infrastructure releases:
- **PostgreSQL Row Level Security (RLS):** Database policies checking active user IDs against team scopes, ensuring team scoping is enforced at the database query level itself (not just the application layer).
- **Active Session Invalidation (JWT Blacklist):** Storing revoked JWT signatures in Redis to support immediate logout invalidation before the token naturally expires.
- **Admin Password Complexity Policies:** Enforcing registration complexity rules.
- **Mandatory Password Renewal:** Enforcing a password update requirement upon the user's initial login.
