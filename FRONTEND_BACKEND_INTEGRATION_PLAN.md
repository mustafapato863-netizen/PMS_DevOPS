# PMS Dashboard — Frontend ↔ Backend Integration Plan

**Document Type**: Implementation Guide for Developer
**Created**: June 21, 2026
**Scope**: Connect existing React Frontend to live PostgreSQL-backed FastAPI Backend
**Prerequisite**: Backend running on `http://localhost:8000` | Migrations applied (`alembic upgrade head`)

---

## Current State Assessment

### What Already Exists (Do NOT rebuild)

| Layer | Status | Notes |
|---|---|---|
| `useEmployeeProfile.ts` | ✅ Ready | Hits `/api/employee/{id}/` correctly |
| `usePerformanceData.ts` | ✅ Ready | Hits `/api/performance` correctly |
| `useKpiWeights.ts` | ✅ Ready | Hits `/api/settings/weights` correctly |
| `appStore.ts` | ✅ Ready | Zustand store fully implemented |
| `App.tsx` | ✅ Ready | Auth guard + routing fully implemented |
| `useNotificationSocket` | ✅ Ready | Socket.io hook initialized in AppContent |
| Auth routes `/login` | ✅ Ready | LoginView + AuthContext wired |
| Role-based routing | ✅ Ready | RouteGuard with Admin/Manager/Executive |

### What Is Missing (The Actual Integration Gap)

| Missing Piece | Impact |
|---|---|
| `config.ts` — `API_BASE` undefined | Every hook fails silently at runtime |
| `AuthContext` not sending JWT to Backend | All protected endpoints return 401 |
| `QueryClientProvider` not wrapping the app | React Query hooks throw on mount |
| Auth hook — login/logout calls Backend | Currently likely hardcoded or mock |
| `useTeamConfig` hook | `TeamManagementView` has no data source |
| `useSocket` initialization | Notifications connect but room joining missing |
| Environment variables | No `.env` file referenced anywhere |

---

## Integration Phases

---

## Phase 1 — Foundation (Day 1)
**Goal**: Make every existing hook actually reach the Backend.
**Risk**: Zero — no component changes required.

---

### Step 1.1 — Create `config.ts`

**File to create**: `Frontend/src/config.ts`

```typescript
// Central API configuration
// All hooks import API_BASE from here

export const API_BASE = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8000';

export const SOCKET_URL = import.meta.env.VITE_SOCKET_URL ?? 'http://localhost:8000';

export const API_TIMEOUT_MS = 30_000;
```

**Why**: Every hook (`useEmployeeProfile`, `usePerformanceData`, `useKpiWeights`) already imports
`API_BASE` from `'../../config'` — this file simply does not exist yet.
Without it, the entire hook layer throws a module resolution error on startup.

---

### Step 1.2 — Create `.env` File

**File to create**: `Frontend/.env`

```env
VITE_API_BASE_URL=http://localhost:8000
VITE_SOCKET_URL=http://localhost:8000
```

**File to create**: `Frontend/.env.production`

```env
VITE_API_BASE_URL=https://your-production-domain.com
VITE_SOCKET_URL=https://your-production-domain.com
```

**Add to** `Frontend/.gitignore`:
```
.env
.env.local
.env.production
```

---

### Step 1.3 — Wrap App with QueryClientProvider

**File to edit**: `Frontend/src/main.tsx`

```typescript
import React from 'react';
import ReactDOM from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import App from './App';
import './index.css';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 2 * 60 * 1000,    // 2 minutes default
      retry: 2,
      refetchOnWindowFocus: false,
    },
  },
});

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </React.StrictMode>
);
```

**Why**: `App.tsx` uses `useNotificationSocket` and `AuthProvider` which internally
will trigger React Query hooks. Without `QueryClientProvider` as the outermost
wrapper, every `useQuery` call throws:
`"No QueryClient set, use QueryClientProvider to set one."`

**Critical ordering rule**:
```
QueryClientProvider        ← outermost
  ThemeProvider
    AuthProvider
      RoleProvider
        Router
          AppContent       ← useNotificationSocket lives here
```

---

### Phase 1 Verification Checklist
- [ ] `npm run dev` starts without module resolution errors
- [ ] Browser console shows no `API_BASE is not defined` errors
- [ ] Network tab shows requests reaching `http://localhost:8000`
- [ ] Backend health check responds: `GET /api/health → 200 OK`

---

## Phase 2 — Authentication Bridge (Day 1–2)
**Goal**: `AuthContext` sends JWT to Backend. Protected routes work end-to-end.
**Risk**: Low — isolated to Auth layer only.

---

### Step 2.1 — Audit `AuthContext`

**File to inspect**: `Frontend/src/context/AuthContext.tsx`

Check whether the current login function:

```typescript
// Current (likely mock/hardcoded):
const login = async (username: string, password: string) => {
  // Hardcoded users or localStorage check
}

// Required (real Backend call):
const login = async (username: string, password: string) => {
  const res = await fetch(`${API_BASE}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  if (!res.ok) throw new Error('Invalid credentials');
  const { data } = await res.json();
  // data = { access_token, token_type, user: { id, role, username } }
  setCurrentUser(data.user);
  localStorage.setItem('pms_token', data.access_token);
};
```

---

### Step 2.2 — Add JWT to All API Hooks

**File to create**: `Frontend/src/lib/apiClient.ts`

```typescript
import { API_BASE } from '../config';

// Central fetch wrapper — adds JWT automatically
export async function apiFetch<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = localStorage.getItem('pms_token');

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers,
  });

  if (res.status === 401) {
    // Token expired — clear auth and redirect to login
    localStorage.removeItem('pms_token');
    window.location.href = '/login';
    throw new Error('Session expired');
  }

  if (!res.ok) {
    const error = await res.json().catch(() => ({ message: res.statusText }));
    throw new Error(error.message || `HTTP ${res.status}`);
  }

  return res.json();
}
```

**Then update each hook** to use `apiFetch` instead of raw `fetch`:

```typescript
// useEmployeeProfile.ts — before:
const res = await fetch(`${API_BASE}/api/employee/${employeeId}/`, { headers });

// After:
const data = await apiFetch<{ success: boolean; data: EmployeeProfile }>(
  `/api/employee/${employeeId}/`
);
return data.data;
```

Apply the same pattern to `usePerformanceData.ts` and `useKpiWeights.ts`.

---

### Step 2.3 — Verify Backend Auth Endpoint

Confirm the Backend `auth` router (already in `__init__.py`) exposes:

```
POST /api/auth/login    → { access_token, token_type, user }
POST /api/auth/logout   → 200 OK
GET  /api/auth/me       → { user }
```

If the Backend returns a different shape, adjust `AuthContext` to match.

---

### Phase 2 Verification Checklist
- [ ] Login with valid credentials → redirects to `/executive`
- [ ] Login with wrong password → shows error message
- [ ] All API calls include `Authorization: Bearer <token>` header
- [ ] Expired/invalid token → auto-redirects to `/login`
- [ ] Logout clears token and redirects to `/login`

---

## Phase 3 — Data Hooks Validation (Day 2)
**Goal**: Confirm each existing hook returns real data from the DB.
**Risk**: Zero — hooks already written, just need Backend data to exist.

---

### Step 3.1 — Validate `usePerformanceData`

**Endpoint**: `GET /api/performance?month=May&team=Sales`

**Expected Backend response shape** (Frontend hook parses `json.data`):
```json
{
  "success": true,
  "data": {
    "team": "Sales",
    "month": "May",
    "employees": [
      { "id": "SGHD04093", "name": "Saher Ahmed", "score": 100.0, "grade": "A", "status": "Exceeds" }
    ]
  }
}
```

If the Backend returns a different shape (e.g., flat array instead of nested object),
update the `PerformanceData` interface in `usePerformanceData.ts` to match exactly.

---

### Step 3.2 — Validate `useEmployeeProfile`

**Endpoint**: `GET /api/employee/SGHD04093/`

**Expected Backend response shape**:
```json
{
  "success": true,
  "data": {
    "employee": { "id": "SGHD04093", "name": "Saher Ahmed", "team": "Sales", "status": "Exceeds" },
    "performance_history": [
      { "month": "January", "evaluation": { "score": 100.0, "grade": "A" }, "achievement": {} }
    ],
    "corrective_action_history": []
  }
}
```

**Critical**: The `performance_history` array must be sorted by month on the Backend
(January → May). If not sorted, the Frontend trend chart renders disconnected dots.

Backend sort fix in the employee endpoint:
```python
MONTH_ORDER = {
  "January": 1, "February": 2, "March": 3, "April": 4,
  "May": 5, "June": 6, "July": 7, "August": 8,
  "September": 9, "October": 10, "November": 11, "December": 12
}
history.sort(key=lambda r: MONTH_ORDER.get(r["month"], 0))
```

---

### Step 3.3 — Add `useTeamConfig` Hook

**File to create**: `Frontend/src/hooks/api/useTeamConfig.ts`

```typescript
import { useQuery } from '@tanstack/react-query';
import { apiFetch } from '../../lib/apiClient';

export interface TeamConfig {
  id: string;
  name: string;
  db_name: string;
  region: string;
  is_active: boolean;
  kpi_configs: Array<{
    kpi_key: string;
    kpi_label: string;
    weight: number;
    direction: 'higher_better' | 'lower_better';
    unit: string;
    color: string;
    display_order: number;
  }>;
  grade_thresholds: { A: number; B: number; C: number; D: number };
}

export function useAllTeamConfigs() {
  return useQuery({
    queryKey: ['team-configs'],
    queryFn: () =>
      apiFetch<{ success: boolean; data: TeamConfig[] }>('/api/team-management/teams')
        .then((r) => r.data),
    staleTime: Infinity,  // Config never changes during a session
  });
}

export function useTeamConfig(teamName: string) {
  return useQuery({
    queryKey: ['team-config', teamName],
    queryFn: () =>
      apiFetch<{ success: boolean; data: TeamConfig }>(
        `/api/team-management/teams/${teamName}`
      ).then((r) => r.data),
    enabled: !!teamName,
    staleTime: Infinity,
  });
}
```

**Export in** `Frontend/src/hooks/api/index.ts`:
```typescript
export * from './useTeamConfig';
```

---

### Step 3.4 — Add `useActions` Hook

**File to create**: `Frontend/src/hooks/api/useActions.ts`

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiFetch } from '../../lib/apiClient';

export interface ActionPayload {
  employee_id: string;
  team: string;
  month: string;
  action_type: 'Training' | 'Reward' | 'PIP' | 'Monitor' | 'Coaching' | 'Warning';
  action_text: string;
  root_cause_note?: string;
}

export function useCreateAction() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: ActionPayload) =>
      apiFetch('/api/corrective-actions/', {
        method: 'POST',
        body: JSON.stringify(payload),
      }),
    onSuccess: (_, variables) => {
      // Invalidate employee cache so action appears immediately
      queryClient.invalidateQueries({ queryKey: ['employee', variables.employee_id] });
    },
  });
}
```

---

### Phase 3 Verification Checklist
- [ ] `ExecutiveView` renders real team summaries from DB
- [ ] `TeamDashboardView` shows real employee list with scores
- [ ] `EmployeeProfileView` trend chart shows a connected line (data sorted)
- [ ] `TeamManagementView` lists all 8 teams from DB
- [ ] KPI weights load and match the team's DB configuration

---

## Phase 4 — Real-time Notifications (Day 3)
**Goal**: Socket.io connection reaches Backend. Upload and action events appear in bell.
**Risk**: Low — `useNotificationSocket` hook already exists.

---

### Step 4.1 — Audit `useNotificationSocket`

**File to inspect**: `Frontend/src/hooks/useNotificationSocket.ts`

Confirm it:
1. Connects to `SOCKET_URL` (from `config.ts`)
2. Joins the `global` room on connect
3. Joins `team_{teamId}` room when `activeTeam` changes in the store
4. Calls `addNotification` from `useAppStore` on each event

**Required Backend socket events** (verify in `socket_service.py`):
```
data_uploaded     → room: "global"
action_recorded   → room: "team_{team_name}"
onboarding_step   → room: "team_{team_name}"
```

---

### Step 4.2 — Room Joining Pattern

The socket must join rooms dynamically as the user navigates:

```typescript
// Inside useNotificationSocket:
const activeTeam = useAppStore((s) => s.activeTeam);

useEffect(() => {
  if (activeTeam) {
    socket.emit('join_room', { room: `team_${activeTeam}` });
  }
  return () => {
    if (activeTeam) {
      socket.emit('leave_room', { room: `team_${activeTeam}` });
    }
  };
}, [activeTeam]);
```

---

### Step 4.3 — Cache Invalidation on Socket Events

When a `data_uploaded` event arrives, stale team data must refresh automatically:

```typescript
socket.on('data_uploaded', (event) => {
  addNotification({
    type: 'upload',
    message: `New data uploaded for ${event.team} — ${event.month}`,
    timestamp: new Date().toISOString(),
  });
  // Force React Query to refetch affected data
  queryClient.invalidateQueries({ queryKey: ['performance'] });
  queryClient.invalidateQueries({ queryKey: ['team-configs'] });
});
```

---

### Phase 4 Verification Checklist
- [ ] Upload Excel → bell badge increments within 1 second on all open browser tabs
- [ ] Add action on employee → team room members see notification
- [ ] Notification click navigates to correct employee/team
- [ ] After data upload, team dashboard refreshes without manual page reload

---

## Phase 5 — Role-Based UI Hardening (Day 3–4)
**Goal**: UI elements respect roles from the Backend JWT, not hardcoded strings.
**Risk**: Low — routing guards already exist, just needs real role source.

---

### Step 5.1 — Extract Role from JWT

After login, the JWT payload contains the user's role. Extract it in `AuthContext`:

```typescript
import { jwtDecode } from 'jwt-decode';

interface JWTPayload {
  sub: string;        // user id
  role: string;       // Admin | Manager | Executive | Viewer
  username: string;
  exp: number;
}

const token = localStorage.getItem('pms_token');
if (token) {
  const decoded = jwtDecode<JWTPayload>(token);
  setCurrentUser({ id: decoded.sub, role: decoded.role, username: decoded.username });
}
```

Install: `npm install jwt-decode`

---

### Step 5.2 — Role Propagation to `RoleContext`

`RoleContext` must read role from `AuthContext`, not from a separate source:

```typescript
// RoleContext.tsx
const { currentUser } = useAuth();
const role = currentUser?.role ?? 'Viewer';
```

This ensures `RouteGuard` in `App.tsx` always reflects the real Backend role.

---

### Step 5.3 — Conditional UI Elements by Role

Apply role checks to UI actions (not just routes):

| UI Element | Required Role |
|---|---|
| Upload Excel button | Admin, Manager |
| Add Corrective Action button | Admin, Manager |
| Team Management menu item | Admin only |
| Export data | Admin, Executive |
| View all teams | Admin, Executive |
| View own team only | Manager |

```typescript
// Example in any component:
const { role } = useUserRole();

{['Admin', 'Manager'].includes(role) && (
  <button onClick={handleAddAction}>+ Add Action</button>
)}
```

---

### Phase 5 Verification Checklist
- [ ] Admin user sees Team Management in sidebar
- [ ] Manager user sees only their assigned teams
- [ ] Viewer user sees no upload or action buttons
- [ ] Role change in Backend reflects on next login (not stale)

---

## Complete File Change Map

### Files to Create
```
Frontend/src/config.ts                        ← API_BASE + SOCKET_URL
Frontend/src/lib/apiClient.ts                 ← JWT fetch wrapper
Frontend/src/hooks/api/useTeamConfig.ts       ← team config from DB
Frontend/src/hooks/api/useActions.ts          ← create/fetch actions
Frontend/.env                                 ← local env vars
Frontend/.env.production                      ← production env vars
```

### Files to Edit
```
Frontend/src/main.tsx                         ← Add QueryClientProvider
Frontend/src/context/AuthContext.tsx          ← Real login → Backend
Frontend/src/hooks/api/useEmployeeProfile.ts  ← Use apiFetch
Frontend/src/hooks/api/usePerformanceData.ts  ← Use apiFetch
Frontend/src/hooks/api/useKpiWeights.ts       ← Use apiFetch
Frontend/src/hooks/api/index.ts               ← Export useTeamConfig, useActions
Frontend/src/context/RoleContext.tsx          ← Read role from AuthContext
Frontend/src/hooks/useNotificationSocket.ts   ← Use SOCKET_URL, add room joining
```

### Files That Need Zero Changes
```
Frontend/src/App.tsx                          ✅ Complete
Frontend/src/store/appStore.ts                ✅ Complete
Frontend/src/hooks/api/useEmployeeProfile.ts  ✅ Structure correct (only fetch → apiFetch)
Frontend/src/hooks/api/usePerformanceData.ts  ✅ Structure correct
Frontend/src/hooks/api/useKpiWeights.ts       ✅ Structure correct
```

---

## Backend Compatibility Requirements

Before starting Phase 1, verify these Backend endpoints return the exact shapes
the Frontend hooks expect:

| Endpoint | Hook | Expected `json.data` shape |
|---|---|---|
| `GET /api/performance` | `usePerformanceData` | `{ team, month, employees[] }` |
| `GET /api/employee/{id}/` | `useEmployeeProfile` | `{ employee, performance_history[], corrective_action_history[] }` |
| `GET /api/settings/weights` | `useKpiWeights` | `[{ team, weights: {} }]` |
| `POST /api/auth/login` | `AuthContext` | `{ access_token, token_type, user: { id, role, username } }` |
| `GET /api/team-management/teams` | `useTeamConfig` | `[{ id, name, db_name, kpi_configs[], grade_thresholds }]` |
| `POST /api/corrective-actions/` | `useActions` | `{ success: true, data: { id } }` |

If any endpoint returns a different shape, fix the Backend response first —
do not adapt the Frontend hooks to handle inconsistent shapes.

---

## Recommended Implementation Order

```
Day 1 AM:  Step 1.1 → 1.2 → 1.3  (config + env + QueryClientProvider)
Day 1 PM:  Step 2.1 → 2.2 → 2.3  (AuthContext + JWT + apiFetch)
Day 2 AM:  Step 3.1 → 3.2         (validate existing hooks against real DB data)
Day 2 PM:  Step 3.3 → 3.4         (add missing hooks: useTeamConfig + useActions)
Day 3 AM:  Step 4.1 → 4.2 → 4.3  (Socket.io rooms + cache invalidation)
Day 3 PM:  Step 5.1 → 5.2 → 5.3  (JWT role extraction + UI hardening)
```

---

## Risk Register

| Risk | Likelihood | Mitigation |
|---|---|---|
| Backend response shape mismatch | High | Compare each endpoint in Swagger UI (`/docs`) before writing hook |
| CORS error on first connection | Medium | Verify `allow_origins` in `app.py` includes frontend dev port (5173) |
| JWT expiry not handled | Medium | `apiFetch` 401 handler auto-clears token and redirects |
| Socket.io connection refused | Low | Check Backend mounts `ASGIApp(sio, app)` — already in `app.py` |
| Role not in JWT payload | Low | Verify Backend `auth` router includes role in token claims |

---

*Document Status: Ready for Implementation*
*Author: Architecture Review*
*Date: June 21, 2026*
