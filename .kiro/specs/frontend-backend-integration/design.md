# Design Document: Frontend-Backend Integration

## Overview

This document defines the technical design for integrating the React Frontend with the PostgreSQL-backed FastAPI Backend for the PMS Dashboard application. The integration establishes secure, real-time connectivity between the client and server systems, enabling JWT-based authentication, React Query-powered data synchronization, WebSocket notifications, and role-based UI rendering.

### Integration Scope

The integration spans five key technical areas:

1. **Foundation Configuration**: Environment management, React Query setup, and base URL configuration
2. **Authentication Bridge**: JWT token management, authenticated HTTP client, and auth context integration
3. **Data Hooks Validation**: Migration of existing hooks to use authenticated client with response validation
4. **Real-Time Notifications**: Socket.IO connection management and cache invalidation
5. **Role-Based UI Hardening**: JWT role extraction and conditional UI rendering

### Technical Context

**Frontend Stack**:
- React 19.2.5 with TypeScript 6.0.2
- TanStack React Query 5.101.0 for server state management
- Socket.IO Client 4.8.3 for real-time communication
- Vite 8.0.10 for build tooling
- Zustand 5.0.14 for local state management

**Backend Stack**:
- FastAPI with PostgreSQL database
- SQLAlchemy ORM for data access
- JWT-based authentication with Redis session management
- Socket.IO for real-time event broadcasting

**Existing Infrastructure**:
- Query client already configured with 2-minute stale time and 10-minute cache time
- Auth context provides login/logout functionality with localStorage persistence
- Multiple data hooks (usePerformanceData, useTeamConfig) fetch from mock data
- Socket infrastructure partially implemented with useSocketListener and useNotificationSocket


## Architecture

### High-Level Integration Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         React Frontend                          │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    React Query Layer                       │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │ │
│  │  │ useEmployee  │  │ usePerformance│  │ useTeamConfig│    │ │
│  │  │   Profile    │  │     Data      │  │              │    │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘    │ │
│  │           │                │                   │           │ │
│  │           └────────────────┴───────────────────┘           │ │
│  │                            │                                │ │
│  │                    ┌───────▼────────┐                      │ │
│  │                    │  API Client    │                      │ │
│  │                    │  (apiFetch)    │                      │ │
│  │                    └───────┬────────┘                      │ │
│  └────────────────────────────┼──────────────────────────────┘ │
│                                │                                │
│  ┌────────────────────────────┼──────────────────────────────┐ │
│  │         Auth Context       │                               │ │
│  │  ┌──────────────────┐     │     ┌──────────────────┐     │ │
│  │  │  JWT Storage     │◄────┼────►│  Role Context    │     │ │
│  │  │  localStorage    │     │     │  (jwt-decode)    │     │ │
│  │  └──────────────────┘     │     └──────────────────┘     │ │
│  └────────────────────────────┼──────────────────────────────┘ │
│                                │                                │
│  ┌────────────────────────────┼──────────────────────────────┐ │
│  │    Notification Layer      │                               │ │
│  │  ┌──────────────────┐     │     ┌──────────────────┐     │ │
│  │  │  Socket.IO       │     │     │ Cache Invalidation│    │ │
│  │  │  Connection      │     │     │ Event Handlers   │     │ │
│  │  └──────────────────┘     │     └──────────────────┘     │ │
│  └────────────────────────────┼──────────────────────────────┘ │
└────────────────────────────────┼────────────────────────────────┘
                                 │
                      HTTP/WebSocket
                                 │
┌────────────────────────────────▼────────────────────────────────┐
│                      FastAPI Backend                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Auth       │  │  Performance │  │  Team Config │         │
│  │   Router     │  │    Router    │  │    Router    │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                  │                  │                 │
│  ┌──────▼──────────────────▼──────────────────▼───────┐        │
│  │            JWT Auth Middleware                      │        │
│  └──────┬──────────────────────────────────────────────┘        │
│         │                                                        │
│  ┌──────▼──────────────────┐   ┌──────────────────┐           │
│  │   PostgreSQL Database   │   │  Redis Cache     │           │
│  └─────────────────────────┘   └──────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```


### Authentication Flow

```
┌────────┐                 ┌────────────┐              ┌─────────┐
│ User   │                 │  Frontend  │              │ Backend │
└───┬────┘                 └─────┬──────┘              └────┬────┘
    │                             │                          │
    │ 1. Enter credentials        │                          │
    ├────────────────────────────►│                          │
    │                             │                          │
    │                             │ 2. POST /api/auth/login  │
    │                             ├─────────────────────────►│
    │                             │                          │
    │                             │ 3. Validate credentials  │
    │                             │    Query User table      │
    │                             │◄─────────────────────────┤
    │                             │                          │
    │                             │ 4. Generate JWT token    │
    │                             │◄─────────────────────────┤
    │                             │    {access_token, role}  │
    │                             │                          │
    │ 5. Store JWT in localStorage│                          │
    │◄────────────────────────────┤                          │
    │                             │                          │
    │                             │ 6. Decode JWT for role   │
    │                             │    using jwt-decode      │
    │                             │                          │
    │ 7. Redirect to dashboard    │                          │
    │◄────────────────────────────┤                          │
    │                             │                          │
    │ 8. All subsequent requests  │                          │
    │                             │ + Authorization: Bearer  │
    │                             ├─────────────────────────►│
    │                             │                          │
    │                             │ 9. Validate JWT          │
    │                             │◄─────────────────────────┤
    │                             │    Extract user_id, role │
    │                             │                          │
    │                             │ 10. Return data          │
    │◄────────────────────────────┼──────────────────────────┤
    │                             │                          │
```


### Real-Time Notification Flow

```
┌────────────┐                 ┌─────────────────┐            ┌─────────┐
│  Frontend  │                 │  Socket.IO      │            │ Backend │
└─────┬──────┘                 │  Connection     │            └────┬────┘
      │                        └────────┬────────┘                 │
      │ 1. User authenticates           │                          │
      ├────────────────────────────────►│                          │
      │                                 │                          │
      │ 2. Connect with JWT token       │                          │
      │    ?token=<jwt>                 ├─────────────────────────►│
      │                                 │                          │
      │                                 │ 3. Validate token        │
      │                                 │    Extract user_id       │
      │                                 │◄─────────────────────────┤
      │                                 │                          │
      │ 4. Connection established       │                          │
      │◄────────────────────────────────┤                          │
      │                                 │                          │
      │ 5. Join rooms                   │                          │
      │    - global                     ├─────────────────────────►│
      │    - team_{team_id}             │                          │
      │    - user_{user_id}             │                          │
      │                                 │                          │
      │                                 │ 6. Data updated event    │
      │                                 │◄─────────────────────────┤
      │                                 │    {entity: "employee"}  │
      │                                 │                          │
      │ 7. Invalidate React Query cache │                          │
      │    queryClient.invalidateQueries│                          │
      │    (["employee"])               │                          │
      │◄────────────────────────────────┤                          │
      │                                 │                          │
      │ 8. React Query refetches data   │                          │
      │    automatically                ├─────────────────────────►│
      │                                 │                          │
      │ 9. Fresh data returned          │                          │
      │◄────────────────────────────────┼──────────────────────────┤
      │                                 │                          │
```


## Components and Interfaces

### 1. Environment Configuration Module

**File**: `src/config.ts`

**Purpose**: Centralize environment-specific configuration and provide type-safe access to API endpoints.

**Interface**:
```typescript
export interface AppConfig {
  API_BASE: string;        // Base URL for HTTP API requests
  SOCKET_URL: string;      // WebSocket endpoint for Socket.IO
  ENV: 'development' | 'production';
}

export const API_BASE: string;
export const SOCKET_URL: string;
export const ENV: 'development' | 'production';

// Validation functions
function validateURL(url: string, protocol: 'http' | 'ws'): void;
function loadConfig(): AppConfig;
```

**Configuration Sources**:
- **Development**: `.env` file with `VITE_API_BASE` and `VITE_SOCKET_URL`
- **Production**: `.env.production` file with production endpoints
- **Defaults**: Fallback to `http://127.0.0.1:8000` and `ws://127.0.0.1:8000`

**Validation Rules**:
- `API_BASE` must start with `http://` or `https://`
- `SOCKET_URL` must start with `ws://` or `wss://`
- Throw descriptive errors if validation fails
- Log active configuration in development mode only

### 2. Authenticated HTTP Client

**File**: `src/lib/apiClient.ts`

**Purpose**: Wrap the standard fetch API to automatically inject JWT tokens and handle authentication errors.

**Interface**:
```typescript
export interface ApiFetchOptions extends RequestInit {
  skipAuth?: boolean;  // Optional flag to skip auth header injection
}

export async function apiFetch(
  url: string,
  options?: ApiFetchOptions
): Promise<Response>;
```

**Implementation Details**:

1. **Token Retrieval**:
   - Read JWT from `localStorage.getItem('pms_jwt_token')`
   - If no token and `skipAuth` is not set, proceed without auth header

2. **Header Injection**:
   - Add `Authorization: Bearer <token>` to request headers
   - Preserve existing headers from options parameter
   - Merge auth header with user-provided headers

3. **Error Handling**:
   - **401 Unauthorized**: Clear localStorage, redirect to `/login`, throw error
   - **403 Forbidden**: Throw error with "Insufficient permissions" message
   - **Network errors**: Propagate to caller for React Query retry logic

4. **Response Handling**:
   - Return raw Response object without modification
   - Let calling code handle JSON parsing and validation


### 3. Authentication Context

**File**: `src/context/AuthContext.tsx`

**Purpose**: Manage user authentication state, provide login/logout functions, and integrate with Backend authentication API.

**Updated Interface**:
```typescript
export interface AuthContextProps {
  currentUser: User | null;
  users: User[];
  isAuthenticated: boolean;
  isLoading: boolean;
  
  // Methods
  login: (username: string, password: string) => Promise<LoginResult>;
  logout: () => Promise<void>;
  addUser: (name: string, username: string, password: string, role: Role) => Promise<UserOperationResult>;
  deleteUser: (id: string) => Promise<UserOperationResult>;
  refreshUsers: () => Promise<void>;
}

export interface LoginResult {
  success: boolean;
  error?: string;
  requiresMFA?: boolean;
}

export interface UserOperationResult {
  success: boolean;
  error?: string;
}

export interface User {
  id: string;
  name: string;
  username: string;
  role: 'Admin' | 'Manager' | 'Executive' | 'Viewer';
}
```

**Integration Changes**:

1. **Login Method**:
   - POST to `/api/auth/login` with `{username, password}`
   - Backend returns `StandardResponse` with `JWTToken` data:
     ```typescript
     {
       success: true,
       message: "Successfully authenticated",
       data: {
         access_token: string,
         token_type: "bearer",
         role: string,
         username: string
       }
     }
     ```
   - Store `access_token` in `localStorage` as `pms_jwt_token`
   - Store user object in `localStorage` as `pms_session_v1`
   - Update `currentUser` state with user information

2. **Logout Method**:
   - POST to `/api/auth/logout` (authenticated request via apiFetch)
   - Clear `pms_jwt_token` and `pms_session_v1` from localStorage
   - Clear `currentUser` state
   - Disconnect Socket.IO connection
   - Reset role context

3. **Session Persistence**:
   - On mount, check localStorage for existing session
   - Validate JWT token expiration
   - If expired, clear session and redirect to login


### 4. Role Context Provider

**File**: `src/context/RoleContext.tsx`

**Purpose**: Extract and provide user role from JWT token for role-based UI rendering.

**Interface**:
```typescript
export interface RoleContextProps {
  role: Role | null;
  permissions: Permission[];
  hasPermission: (permission: Permission) => boolean;
  canAccess: (route: string) => boolean;
}

export type Role = 'Admin' | 'Manager' | 'Executive' | 'Viewer';

export enum Permission {
  VIEW_DASHBOARD = 'view:dashboard',
  VIEW_EMPLOYEES = 'view:employees',
  EDIT_EMPLOYEES = 'edit:employees',
  VIEW_TEAM_CONFIG = 'view:team_config',
  EDIT_TEAM_CONFIG = 'edit:team_config',
  VIEW_ACTIONS = 'view:actions',
  CREATE_ACTIONS = 'create:actions',
  UPLOAD_DATA = 'upload:data',
  MANAGE_USERS = 'manage:users',
}
```

**Implementation Details**:

1. **JWT Decoding**:
   - Install `jwt-decode` package
   - Decode token on context initialization: `jwtDecode<JWTPayload>(token)`
   - JWT payload structure:
     ```typescript
     interface JWTPayload {
       user_id: string;
       username: string;
       role: Role;
       exp: number;  // Expiration timestamp
       iat: number;  // Issued at timestamp
     }
     ```

2. **Permission Mapping**:
   ```typescript
   const rolePermissions: Record<Role, Permission[]> = {
     Admin: [/* all permissions */],
     Manager: [
       Permission.VIEW_DASHBOARD,
       Permission.VIEW_EMPLOYEES,
       Permission.VIEW_TEAM_CONFIG,
       Permission.VIEW_ACTIONS,
       Permission.CREATE_ACTIONS,
     ],
     Executive: [
       Permission.VIEW_DASHBOARD,
       Permission.VIEW_EMPLOYEES,
     ],
     Viewer: [
       Permission.VIEW_DASHBOARD,
     ],
   };
   ```

3. **Token Validation**:
   - Check `exp` claim against current time
   - If expired, trigger logout
   - If invalid format, set role to null

4. **Context Updates**:
   - Listen to localStorage changes for `pms_jwt_token`
   - Re-decode token when it changes
   - Clear role when token is removed


### 5. React Query Client Configuration

**File**: `src/lib/queryClient.ts`

**Purpose**: Configure global React Query settings for cache management and retry logic.

**Updated Configuration**:
```typescript
import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60000,              // 1 minute (Requirement 18)
      gcTime: 300000,                // 5 minutes (Requirement 18)
      refetchOnWindowFocus: true,    // Requirement 18
      refetchOnReconnect: true,
      refetchOnMount: true,
      retry: (failureCount, error) => {
        // Don't retry on auth/permission errors (Requirement 16)
        const status = (error as any)?.status;
        if ([400, 401, 403, 404].includes(status)) {
          return false;
        }
        // Retry up to 3 times for server/network errors
        return failureCount < 3;
      },
      retryDelay: (attemptIndex) => {
        // Exponential backoff: 1s, 2s, 4s (Requirement 16)
        return Math.min(1000 * 2 ** attemptIndex, 30000);
      },
    },
    mutations: {
      retry: 1,
    },
  },
});
```

**Cache Invalidation Strategy**:
- Manual invalidation via socket events (see Notification Socket)
- Automatic background refetching when data becomes stale
- Preserve last successful data until new data is fetched (Requirement 18)


### 6. API Data Hooks

#### 6.1 useEmployeeProfile Hook

**File**: `src/hooks/api/useEmployeeProfile.ts`

**Purpose**: Fetch employee profile data with type validation.

**Interface**:
```typescript
export interface EmployeeProfileData {
  id: string;
  employee_id: string;
  name: string;
  team_id: string;
  team: string;
  status: string;
  hiring_date?: string;
  region?: string;
}

export function useEmployeeProfile(employeeId: string) {
  return useQuery<EmployeeProfileData>({
    queryKey: ['employee', employeeId],
    queryFn: async () => {
      const response = await apiFetch(`${API_BASE}/api/employee/${employeeId}`);
      if (!response.ok) {
        throw new Error(`Failed to fetch employee: ${response.status}`);
      }
      const result = await response.json();
      return validateEmployeeProfile(result.data);
    },
    enabled: !!employeeId,
    staleTime: 300000,  // 5 minutes
  });
}
```

**Validation Function**:
```typescript
function validateEmployeeProfile(data: any): EmployeeProfileData {
  const required = ['id', 'employee_id', 'name', 'team_id'];
  const missing = required.filter(field => !(field in data));
  
  if (missing.length > 0) {
    throw new Error(`Missing required fields: ${missing.join(', ')}`);
  }
  
  return data as EmployeeProfileData;
}
```

#### 6.2 usePerformanceData Hook

**File**: `src/hooks/usePerformanceData.ts`

**Integration Changes**:
- Replace direct `fetch` calls with `apiFetch`
- Update endpoint to `/api/performance`
- Add response validation for `PerformanceRecord[]` schema
- Keep existing data transformation logic
- Maintain backward compatibility with existing consumers

**Key Changes**:
```typescript
async function fetchPerformanceData() {
  try {
    const response = await apiFetch(`${API_BASE}/api/performance`);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const result = await response.json();
    
    // Validate response structure
    if (!result || !result.success || !Array.isArray(result.data)) {
      throw new Error(result?.message || 'Invalid API response structure');
    }
    
    cachedData = result.data as AgentRecord[];
    listeners.forEach((listener) => listener(cachedData!));
  } catch (error) {
    console.error('Failed to fetch from Backend API:', error);
    // Fallback to local data if needed
    listeners.forEach((listener) => listener(processedRawData as AgentRecord[]));
  }
}
```


#### 6.3 useTeamConfig Hook

**File**: `src/hooks/useTeamConfig.ts`

**Current Implementation**: Already uses React Query and validates response structure

**Integration Changes**:
- Replace `fetch` with `apiFetch` in `queryFn`
- No schema changes needed (already has `validateTeamConfig`)
- Update error handling to account for auth errors

**Updated Implementation**:
```typescript
export function useTeamConfig(teamName: string) {
  return useQuery({
    queryKey: ['team-config', teamName],
    queryFn: async () => {
      const res = await apiFetch(`${API_BASE}/api/config/teams/${teamName}`);
      if (!res.ok) {
        throw new Error(`Failed to fetch team config for ${teamName}: ${res.statusText}`);
      }
      const json = await res.json();
      if (!json.success) {
        throw new Error(json.error || `Failed to fetch team config for ${teamName}`);
      }
      return validateTeamConfig(json.data);
    },
    enabled: !!teamName,
    staleTime: Infinity,
    retry: 2,
  });
}
```

#### 6.4 useActions Hook (New)

**File**: `src/hooks/api/useActions.ts`

**Purpose**: Fetch corrective actions for specific employees with real-time updates.

**Interface**:
```typescript
export interface CorrectiveAction {
  id: string;
  employee_id: string;
  employee_name: string;
  team: string;
  month: string;
  score: number;
  grade: string;
  root_cause: string;
  suggested_action: string;
  manager_action: string;
  manager_notes: string;
  timestamp: string;
}

export function useActions(employeeId: string | null) {
  return useQuery<CorrectiveAction[]>({
    queryKey: ['actions', employeeId],
    queryFn: async () => {
      const response = await apiFetch(
        `${API_BASE}/api/actions?employee_id=${employeeId}`
      );
      if (!response.ok) {
        throw new Error(`Failed to fetch actions: ${response.status}`);
      }
      const result = await response.json();
      return result.data as CorrectiveAction[];
    },
    enabled: !!employeeId,
    refetchInterval: 30000,  // Poll every 30 seconds (Requirement 6)
  });
}
```


### 7. Notification Socket Manager

**File**: `src/hooks/useNotificationSocket.ts`

**Purpose**: Manage Socket.IO connection, handle real-time notifications, and trigger cache invalidation.

**Updated Interface**:
```typescript
export interface NotificationSocketOptions {
  autoConnect?: boolean;
  onConnect?: () => void;
  onDisconnect?: () => void;
  onError?: (error: Error) => void;
}

export function useNotificationSocket(options?: NotificationSocketOptions): void;
```

**Implementation Details**:

1. **Connection Establishment**:
   ```typescript
   const socket = io(SOCKET_URL, {
     auth: {
       token: localStorage.getItem('pms_jwt_token')
     },
     transports: ['websocket', 'polling'],
     reconnection: true,
     reconnectionAttempts: 5,
     reconnectionDelay: 1000,
     reconnectionDelayMax: 5000,
   });
   ```

2. **Room Joining**:
   ```typescript
   socket.on('connect', () => {
     // Join global room
     socket.emit('join_room', 'global');
     
     // Join team room if user has team assignment
     const user = JSON.parse(localStorage.getItem('pms_session_v1') || '{}');
     if (user.team_id) {
       socket.emit('join_room', `team_${user.team_id}`);
     }
     
     // Join user-specific room (auto-joined by backend based on JWT)
     // socket.emit('join_room', `user_${user.id}`);
   });
   ```

3. **Event Handlers**:
   ```typescript
   // Handle notifications
   socket.on('notification', (data) => {
     const notification: Notification = {
       type: data.type || 'info',
       message: data.message,
       timestamp: data.timestamp || new Date().toISOString(),
     };
     addNotification(notification);
   });
   
   // Handle cache invalidation
   socket.on('data_updated', (data: { entity: string, id?: string }) => {
     switch (data.entity) {
       case 'employee':
         queryClient.invalidateQueries({ queryKey: ['employee'] });
         break;
       case 'performance':
         queryClient.invalidateQueries({ queryKey: ['performance'] });
         break;
       case 'team':
         queryClient.invalidateQueries({ queryKey: ['team'] });
         break;
       case 'actions':
         queryClient.invalidateQueries({ queryKey: ['actions'] });
         break;
     }
   });
   
   // Handle errors
   socket.on('connect_error', (error) => {
     console.error('Socket connection error:', error);
     addNotification({
       type: 'error',
       message: 'Unable to connect to notification service',
       timestamp: new Date().toISOString(),
     });
   });
   ```

4. **Cleanup on Logout**:
   ```typescript
   export function disconnectSocket(): void {
     if (socket && socket.connected) {
       socket.removeAllListeners();
       socket.disconnect();
     }
   }
   ```


### 8. Error Boundary Component

**File**: `src/components/ErrorBoundary.tsx`

**Purpose**: Catch and gracefully handle errors in React component tree.

**Interface**:
```typescript
export interface ErrorBoundaryProps {
  children: React.ReactNode;
  fallback?: React.ReactNode;
  onError?: (error: Error, errorInfo: React.ErrorInfo) => void;
}

export interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends React.Component<
  ErrorBoundaryProps,
  ErrorBoundaryState
>;
```

**Implementation**:
```typescript
class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('ErrorBoundary caught error:', error, errorInfo);
    this.props.onError?.(error, errorInfo);
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div className="error-boundary-fallback">
          <h2>Something went wrong</h2>
          <p>{this.state.error?.message}</p>
          <button onClick={this.handleReset}>Retry</button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

**Usage**:
```typescript
// Wrap page components in App.tsx
<ErrorBoundary>
  <Routes>
    <Route path="/dashboard" element={<Dashboard />} />
    <Route path="/employees" element={<EmployeeList />} />
  </Routes>
</ErrorBoundary>
```


### 9. Health Check Integration

**File**: `src/hooks/useHealthCheck.ts`

**Purpose**: Verify backend connectivity on application load.

**Interface**:
```typescript
export interface HealthCheckResult {
  status: 'healthy' | 'degraded' | 'unhealthy';
  database: {
    status: 'connected' | 'disconnected';
    latency_ms?: number;
  };
  cache: {
    status: 'connected' | 'disconnected';
    latency_ms?: number;
  };
  timestamp: string;
}

export function useHealthCheck() {
  return useQuery<HealthCheckResult>({
    queryKey: ['health'],
    queryFn: async () => {
      const response = await apiFetch(
        `${API_BASE}/api/health`,
        { skipAuth: true }  // Public endpoint
      );
      
      if (!response.ok) {
        throw new Error(`Health check failed: ${response.status}`);
      }
      
      return await response.json();
    },
    refetchInterval: 60000,  // Check every minute
    retry: 3,
    staleTime: 30000,
  });
}
```

**Usage in App Component**:
```typescript
function App() {
  const { data: health, error } = useHealthCheck();
  
  if (error || health?.status === 'unhealthy') {
    return (
      <ConnectionErrorBanner 
        message="Backend server is offline. Please contact support."
        onRetry={() => queryClient.invalidateQueries(['health'])}
      />
    );
  }
  
  return <AppContent />;
}
```


### 10. JWT Token Refresh Mechanism

**File**: `src/lib/tokenRefresh.ts`

**Purpose**: Automatically refresh JWT tokens before expiration to maintain active sessions.

**Interface**:
```typescript
export interface TokenRefreshResult {
  success: boolean;
  token?: string;
  expiresAt?: number;
}

export function startTokenRefreshTimer(): void;
export function stopTokenRefreshTimer(): void;
export async function refreshToken(): Promise<TokenRefreshResult>;
```

**Implementation Details**:

1. **Token Expiration Detection**:
   ```typescript
   function getTokenExpiration(token: string): number | null {
     try {
       const decoded = jwtDecode<{ exp: number }>(token);
       return decoded.exp * 1000;  // Convert to milliseconds
     } catch {
       return null;
     }
   }
   ```

2. **Refresh Timer**:
   ```typescript
   let refreshTimer: NodeJS.Timeout | null = null;
   
   export function startTokenRefreshTimer(): void {
     const token = localStorage.getItem('pms_jwt_token');
     if (!token) return;
     
     const expiresAt = getTokenExpiration(token);
     if (!expiresAt) return;
     
     // Schedule refresh 5 minutes before expiration
     const refreshTime = expiresAt - Date.now() - (5 * 60 * 1000);
     
     if (refreshTime > 0) {
       refreshTimer = setTimeout(async () => {
         const result = await refreshToken();
         if (result.success && result.token) {
           localStorage.setItem('pms_jwt_token', result.token);
           startTokenRefreshTimer();  // Schedule next refresh
         } else {
           // Refresh failed, log user out
           window.location.href = '/login';
         }
       }, refreshTime);
     }
   }
   ```

3. **Refresh API Call**:
   ```typescript
   export async function refreshToken(): Promise<TokenRefreshResult> {
     try {
       const response = await apiFetch(`${API_BASE}/api/auth/refresh`, {
         method: 'POST',
       });
       
       if (!response.ok) {
         return { success: false };
       }
       
       const result = await response.json();
       return {
         success: true,
         token: result.data.access_token,
         expiresAt: getTokenExpiration(result.data.access_token),
       };
     } catch {
       return { success: false };
     }
   }
   ```

4. **Activity-Based Logout**:
   ```typescript
   let activityTimer: NodeJS.Timeout | null = null;
   const INACTIVITY_TIMEOUT = 30 * 60 * 1000;  // 30 minutes
   
   function resetActivityTimer() {
     if (activityTimer) clearTimeout(activityTimer);
     
     activityTimer = setTimeout(() => {
       localStorage.clear();
       window.location.href = '/login';
     }, INACTIVITY_TIMEOUT);
   }
   
   // Listen for user activity
   ['mousedown', 'keydown', 'scroll', 'touchstart'].forEach(event => {
     document.addEventListener(event, resetActivityTimer, true);
   });
   ```


## Data Models

### Frontend Data Models

#### JWT Token Payload
```typescript
interface JWTPayload {
  user_id: string;      // Unique user identifier
  username: string;     // User's username
  role: Role;           // User's role for permissions
  exp: number;          // Expiration timestamp (Unix epoch)
  iat: number;          // Issued at timestamp (Unix epoch)
}
```

#### Standard API Response
```typescript
interface StandardResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  error?: string;
}
```

#### Employee Profile
```typescript
interface EmployeeProfile {
  id: string;
  employee_id: string;
  name: string;
  team_id: string;
  team: string;
  status: 'Active' | 'Inactive';
  hiring_date?: string;
  region?: 'EGY' | 'UAE';
}
```

#### Performance Record
```typescript
interface PerformanceRecord {
  id: string;
  employee_id: string;
  employee_name: string;
  team: string;
  month: string;
  region: string;
  
  calls: {
    inbound: number;
    outbound: number;
    total_handled: number;
    abandoned: number;
    aht_raw: string;
  };
  
  geo: {
    bookings: GeoBreakdown;
    attended: GeoBreakdown;
  };
  
  actual: {
    booking_rate: number;
    attend_rate: number;
    abandon_rate: number;
    // ... other metrics
  };
  
  evaluation: {
    score: number;
    grade: string;
    root_cause?: {
      kpi: string;
      impact_pct: number;
      actual: number;
      target: number;
    };
    suggested_action?: string;
    manager_notes?: string;
  };
  
  raw_data: Record<string, any>;
}
```

#### Team Configuration
```typescript
interface TeamConfig {
  team_name: string;
  kpis: KPIDefinition[];
  grade_thresholds: GradeThresholds;
}

interface KPIDefinition {
  key: string;
  label: string;
  weight: number;
  target: number;
  unit: string;
  is_lower_better: boolean;
}

interface GradeThresholds {
  A: number;
  B: number;
  C: number;
  D: number;
  E: number;
}
```

#### Corrective Action
```typescript
interface CorrectiveAction {
  id: string;
  employee_id: string;
  employee_name: string;
  team: string;
  month: string;
  score: number;
  grade: string;
  root_cause: string;
  suggested_action: string;
  manager_action: string;
  manager_notes: string;
  timestamp: string;
}
```

#### Notification
```typescript
interface Notification {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error';
  message: string;
  timestamp: string;
  read: boolean;
  actionUrl?: string;
}
```


### Backend API Endpoints

#### Authentication Endpoints

**POST /api/auth/login**
- **Purpose**: Authenticate user and issue JWT token
- **Request Body**:
  ```json
  {
    "username": "string",
    "password": "string"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "message": "Successfully authenticated",
    "data": {
      "access_token": "eyJhbGciOiJIUzI1NiIs...",
      "token_type": "bearer",
      "role": "Admin",
      "username": "john.doe"
    }
  }
  ```
- **Error Responses**:
  - `401 Unauthorized`: Invalid credentials
  - `423 Locked`: Account locked due to failed attempts
  - `500 Internal Server Error`: Server error

**POST /api/auth/logout**
- **Purpose**: Invalidate user session
- **Headers**: `Authorization: Bearer <token>`
- **Response**:
  ```json
  {
    "success": true,
    "message": "Successfully logged out"
  }
  ```

**POST /api/auth/refresh**
- **Purpose**: Refresh JWT token before expiration
- **Headers**: `Authorization: Bearer <token>`
- **Response**:
  ```json
  {
    "success": true,
    "data": {
      "access_token": "eyJhbGciOiJIUzI1NiIs...",
      "token_type": "bearer"
    }
  }
  ```

#### Data Endpoints

**GET /api/health**
- **Purpose**: Check backend service health
- **Authentication**: Public (no auth required)
- **Response**:
  ```json
  {
    "status": "healthy",
    "database": {
      "status": "connected",
      "latency_ms": 5
    },
    "cache": {
      "status": "connected",
      "latency_ms": 2
    },
    "timestamp": "2025-01-15T10:30:00Z"
  }
  ```

**GET /api/performance**
- **Purpose**: Fetch all performance records
- **Headers**: `Authorization: Bearer <token>`
- **Query Parameters**: Optional filters (month, team, region)
- **Response**:
  ```json
  {
    "success": true,
    "data": [/* PerformanceRecord[] */]
  }
  ```

**GET /api/employee/{employee_id}**
- **Purpose**: Fetch employee profile
- **Headers**: `Authorization: Bearer <token>`
- **Response**:
  ```json
  {
    "success": true,
    "data": {/* EmployeeProfile */}
  }
  ```

**GET /api/config/teams/{team_name}**
- **Purpose**: Fetch team configuration
- **Headers**: `Authorization: Bearer <token>`
- **Response**:
  ```json
  {
    "success": true,
    "data": {/* TeamConfig */}
  }
  ```

**GET /api/actions?employee_id={id}**
- **Purpose**: Fetch corrective actions for employee
- **Headers**: `Authorization: Bearer <token>`
- **Response**:
  ```json
  {
    "success": true,
    "data": [/* CorrectiveAction[] */]
  }
  ```


### Socket.IO Events

#### Client-to-Server Events

**join_room**
- **Purpose**: Join a Socket.IO room for targeted notifications
- **Payload**: 
  ```typescript
  {
    room: 'global' | `team_${team_id}` | `user_${user_id}`
  }
  ```

**leave_room**
- **Purpose**: Leave a Socket.IO room
- **Payload**: 
  ```typescript
  {
    room: string
  }
  ```

#### Server-to-Client Events

**notification**
- **Purpose**: General notification to user
- **Payload**:
  ```typescript
  {
    type: 'info' | 'success' | 'warning' | 'error',
    message: string,
    timestamp: string,
    actionUrl?: string
  }
  ```

**data_updated**
- **Purpose**: Signal that cached data should be invalidated
- **Payload**:
  ```typescript
  {
    entity: 'employee' | 'performance' | 'team' | 'actions',
    id?: string
  }
  ```

**performance_updated**
- **Purpose**: Specific notification for performance metric changes
- **Payload**:
  ```typescript
  {
    team_name: string,
    metric_name: string,
    new_value: number,
    timestamp: string
  }
  ```

**connect**
- **Purpose**: Connection established
- **Payload**: None

**disconnect**
- **Purpose**: Connection terminated
- **Payload**: None

**connect_error**
- **Purpose**: Connection error occurred
- **Payload**:
  ```typescript
  {
    message: string,
    code?: string
  }
  ```

