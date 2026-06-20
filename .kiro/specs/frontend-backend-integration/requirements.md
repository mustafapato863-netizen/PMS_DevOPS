# Requirements Document

## Introduction

This document defines the requirements for integrating the existing React Frontend with the live PostgreSQL-backed FastAPI Backend for the PMS Dashboard application. The integration spans five phases: foundation configuration, authentication bridge, data hooks validation, real-time notifications, and role-based UI hardening. The objective is to establish end-to-end connectivity between the Frontend and Backend systems, enabling secure JWT-based authentication, real-time data flow from PostgreSQL to UI components, WebSocket-based notifications, and role-based access control.

## Glossary

- **Frontend**: The React-based client application built with TypeScript, React Query, and Vite
- **Backend**: The FastAPI server application using PostgreSQL, SQLAlchemy, and Socket.IO
- **API_Client**: The HTTP client wrapper module that adds JWT authentication headers to fetch requests
- **Auth_Context**: The React Context provider managing user authentication state and JWT tokens
- **Query_Client**: The TanStack React Query client managing server state cache and data fetching
- **Notification_Socket**: The Socket.IO client connection for real-time server-to-client notifications
- **Role_Context**: The React Context provider managing user role and permission state
- **JWT_Token**: JSON Web Token containing user identity and role claims
- **API_Hook**: A React Query hook that fetches data from Backend endpoints
- **Socket_Room**: A Socket.IO namespace for broadcasting notifications to specific user groups
- **Environment_Variable**: Configuration value stored in .env files (API_BASE, SOCKET_URL)
- **Authorization_Header**: HTTP header containing "Bearer {JWT_Token}" for authenticated requests
- **Cache_Invalidation**: Process of clearing stale React Query cache when data changes
- **Round_Trip_Property**: A requirement ensuring parse-then-serialize-then-parse produces equivalent output

## Requirements

### Requirement 1: Foundation Configuration

**User Story:** As a developer, I want centralized environment configuration, so that I can easily switch between development and production backends.

#### Acceptance Criteria

1. THE Frontend SHALL define API_BASE and SOCKET_URL constants in a config.ts module
2. THE Frontend SHALL load environment variables from .env and .env.production files
3. WHEN building for production, THE Frontend SHALL use production environment variable values
4. THE Frontend SHALL wrap the App component with QueryClientProvider in main.tsx
5. THE Config_Module SHALL export API_BASE as the base URL for all HTTP requests
6. THE Config_Module SHALL export SOCKET_URL as the WebSocket endpoint for notifications

### Requirement 2: JWT Authentication Client

**User Story:** As a developer, I want an authenticated HTTP client, so that all API requests include valid JWT tokens.

#### Acceptance Criteria

1. THE API_Client SHALL create an apiFetch wrapper function that extends the standard fetch API
2. WHEN making an HTTP request, THE API_Client SHALL retrieve the JWT_Token from localStorage
3. WHEN a JWT_Token exists, THE API_Client SHALL add an Authorization_Header with value "Bearer {JWT_Token}"
4. WHEN a request returns HTTP 401 status, THE API_Client SHALL clear authentication state and redirect to login
5. THE API_Client SHALL forward all standard fetch options (method, headers, body) to the underlying fetch call
6. THE API_Client SHALL return the Response object without modification to preserve response handling flexibility

### Requirement 3: Authentication Context Integration

**User Story:** As a user, I want to log in with my credentials, so that I can access protected resources on the Backend.

#### Acceptance Criteria

1. WHEN a user submits login credentials, THE Auth_Context SHALL send a POST request to /api/auth/login with username and password
2. WHEN the Backend returns a successful login response, THE Auth_Context SHALL extract the JWT_Token from the response
3. WHEN a JWT_Token is received, THE Auth_Context SHALL store it in localStorage with key "pms_jwt_token"
4. WHEN a JWT_Token is received, THE Auth_Context SHALL store the user object in localStorage with key "pms_session_v1"
5. WHEN a user logs out, THE Auth_Context SHALL remove both "pms_jwt_token" and "pms_session_v1" from localStorage
6. WHEN a user logs out, THE Auth_Context SHALL send a POST request to /api/auth/logout
7. THE Auth_Context SHALL provide the current authentication state to all child components via React Context

### Requirement 4: API Hooks Migration

**User Story:** As a developer, I want all data hooks to use the authenticated client, so that they fetch real data from PostgreSQL.

#### Acceptance Criteria

1. THE useEmployeeProfile hook SHALL replace fetch with apiFetch for all HTTP requests
2. THE usePerformanceData hook SHALL replace fetch with apiFetch for all HTTP requests
3. THE useKpiWeights hook SHALL replace fetch with apiFetch for all HTTP requests
4. WHEN an API_Hook makes a request, THE API_Hook SHALL use apiFetch to automatically include the Authorization_Header
5. WHEN an API_Hook receives a response, THE API_Hook SHALL validate the response shape matches the Backend schema
6. IF a response shape mismatch occurs, THE API_Hook SHALL log a detailed error message with expected and actual shapes

### Requirement 5: Team Configuration Hook

**User Story:** As a developer, I want a hook to fetch team configuration, so that I can display team-specific KPI weights and labels.

#### Acceptance Criteria

1. THE Frontend SHALL create a useTeamConfig hook in hooks/api/useTeamConfig.ts
2. WHEN invoked with a team name, THE useTeamConfig hook SHALL fetch data from GET /api/config/teams/{team_name}
3. THE useTeamConfig hook SHALL use React Query with query key ["teamConfig", team_name]
4. THE useTeamConfig hook SHALL return team configuration including KPI definitions, weights, and grade thresholds
5. THE useTeamConfig hook SHALL cache the configuration for 5 minutes (staleTime: 300000)
6. WHEN the team name parameter changes, THE useTeamConfig hook SHALL refetch the configuration

### Requirement 6: Corrective Actions Hook

**User Story:** As a developer, I want a hook to fetch corrective actions, so that I can display actions for underperforming employees.

#### Acceptance Criteria

1. THE Frontend SHALL create a useActions hook in hooks/api/useActions.ts
2. WHEN invoked with an employee ID, THE useActions hook SHALL fetch data from GET /api/actions?employee_id={employee_id}
3. THE useActions hook SHALL use React Query with query key ["actions", employee_id]
4. THE useActions hook SHALL return an array of corrective action objects with fields: id, employee_id, action_text, created_at, status
5. THE useActions hook SHALL enable real-time updates by configuring refetchInterval to 30000 milliseconds
6. WHEN no employee_id is provided, THE useActions hook SHALL not execute the query (enabled: false)

### Requirement 7: Real-Time Notification Socket

**User Story:** As a user, I want to receive real-time notifications, so that I am immediately informed of system events.

#### Acceptance Criteria

1. THE Notification_Socket SHALL establish a Socket.IO connection to SOCKET_URL when the user is authenticated
2. WHEN the socket connection is established, THE Notification_Socket SHALL emit a "join_room" event with room "global"
3. WHEN the user has a team assignment, THE Notification_Socket SHALL emit a "join_room" event with room "team_{team_id}"
4. WHEN the socket receives a "notification" event, THE Notification_Socket SHALL add the notification to the local state
5. WHEN the socket receives a "data_updated" event with entity type, THE Notification_Socket SHALL invalidate the corresponding React Query cache
6. THE Notification_Socket SHALL automatically reconnect with exponential backoff if the connection is lost
7. WHEN the user logs out, THE Notification_Socket SHALL disconnect the socket and clear all socket event listeners

### Requirement 8: Socket-Based Cache Invalidation

**User Story:** As a developer, I want cache invalidation on data updates, so that the UI always displays the latest data.

#### Acceptance Criteria

1. WHEN a "data_updated" event is received with entity "employee", THE Notification_Socket SHALL invalidate all queries with key starting with "employee"
2. WHEN a "data_updated" event is received with entity "performance", THE Notification_Socket SHALL invalidate all queries with key starting with "performance"
3. WHEN a "data_updated" event is received with entity "team", THE Notification_Socket SHALL invalidate all queries with key starting with "team"
4. WHEN a "data_updated" event is received with entity "actions", THE Notification_Socket SHALL invalidate all queries with key starting with "actions"
5. THE Notification_Socket SHALL use queryClient.invalidateQueries() to trigger cache invalidation
6. WHEN cache invalidation occurs, THE Query_Client SHALL automatically refetch all active queries that were invalidated

### Requirement 9: Role Extraction from JWT

**User Story:** As a developer, I want to extract the role from the JWT token, so that I can enforce role-based UI rendering.

#### Acceptance Criteria

1. THE Frontend SHALL install the jwt-decode npm package
2. THE Role_Context SHALL retrieve the JWT_Token from localStorage on initialization
3. WHEN a JWT_Token exists, THE Role_Context SHALL decode the token using jwt-decode library
4. THE Role_Context SHALL extract the "role" claim from the decoded JWT payload
5. THE Role_Context SHALL provide the role value to all child components via React Context
6. WHEN the JWT_Token is invalid or expired, THE Role_Context SHALL set role to null and trigger logout
7. WHEN the user logs out, THE Role_Context SHALL reset the role state to null

### Requirement 10: Role-Based UI Conditional Rendering

**User Story:** As a user, I want UI elements to match my permissions, so that I only see features I can access.

#### Acceptance Criteria

1. WHEN the user role is "Admin", THE Frontend SHALL display user management, team configuration, and bulk upload UI elements
2. WHEN the user role is "Manager", THE Frontend SHALL display team performance dashboard and corrective actions UI elements
3. WHEN the user role is "Executive", THE Frontend SHALL display read-only executive dashboard and reports UI elements
4. WHEN the user role is "Viewer", THE Frontend SHALL display only read-only employee profile and performance history UI elements
5. THE Frontend SHALL hide navigation menu items for features not accessible to the current role
6. THE Frontend SHALL disable action buttons for operations not permitted by the current role

### Requirement 11: Environment Configuration Files

**User Story:** As a developer, I want environment-specific configuration files, so that I can deploy to different environments without code changes.

#### Acceptance Criteria

1. THE Frontend SHALL create a .env file with variables VITE_API_BASE and VITE_SOCKET_URL for development
2. THE Frontend SHALL create a .env.production file with production values for VITE_API_BASE and VITE_SOCKET_URL
3. WHEN running npm run dev, THE Frontend SHALL load variables from .env file
4. WHEN running npm run build, THE Frontend SHALL load variables from .env.production file
5. THE config.ts module SHALL read environment variables using import.meta.env.VITE_API_BASE and import.meta.env.VITE_SOCKET_URL
6. IF an environment variable is undefined, THE config.ts module SHALL provide a sensible default value

### Requirement 12: Response Shape Validation

**User Story:** As a developer, I want response validation, so that I can detect Backend API schema changes early.

#### Acceptance Criteria

1. THE useEmployeeProfile hook SHALL validate that the response contains required fields: id, employee_id, name, team_id
2. THE usePerformanceData hook SHALL validate that the response contains required fields: month, year, performance_score, grade
3. THE useKpiWeights hook SHALL validate that the response contains required fields: kpi_key, weight, label
4. WHEN a required field is missing from the response, THE API_Hook SHALL throw a descriptive error with the missing field name
5. WHEN a field has an unexpected type, THE API_Hook SHALL log a warning with the field name, expected type, and actual type
6. THE API_Hook SHALL allow optional fields to be absent without throwing errors

### Requirement 13: Integration Verification Endpoint

**User Story:** As a developer, I want a test endpoint to verify integration, so that I can confirm end-to-end connectivity.

#### Acceptance Criteria

1. THE Backend SHALL provide a GET /api/health endpoint that returns database and cache connection status
2. WHEN the Frontend loads, THE Frontend SHALL call GET /api/health to verify Backend connectivity
3. IF the health check fails, THE Frontend SHALL display a connection error banner with retry option
4. THE Frontend SHALL log the health check response to the browser console for debugging
5. THE health check SHALL complete within 2 seconds or display a timeout message
6. WHEN the Backend is unreachable, THE Frontend SHALL display "Backend server is offline. Please contact support."

### Requirement 14: JWT Token Refresh

**User Story:** As a user, I want my session to stay active, so that I am not logged out during active use.

#### Acceptance Criteria

1. WHEN a JWT_Token is within 5 minutes of expiration, THE API_Client SHALL send a request to POST /api/auth/refresh
2. WHEN the refresh request succeeds, THE API_Client SHALL store the new JWT_Token in localStorage
3. WHEN the refresh request fails with HTTP 401, THE API_Client SHALL log the user out
4. THE API_Client SHALL decode the JWT_Token to extract the expiration time (exp claim)
5. THE API_Client SHALL schedule a refresh check 1 minute before the token expires
6. WHEN the user is inactive for 30 minutes, THE Auth_Context SHALL log the user out automatically

### Requirement 15: WebSocket Authentication

**User Story:** As a developer, I want authenticated WebSocket connections, so that socket rooms are secured by user identity.

#### Acceptance Criteria

1. WHEN establishing a Socket.IO connection, THE Notification_Socket SHALL include the JWT_Token in the connection query string
2. THE Backend SHALL validate the JWT_Token before accepting the socket connection
3. IF the JWT_Token is invalid or expired, THE Backend SHALL reject the socket connection with error "Authentication failed"
4. WHEN the socket connection is authenticated, THE Backend SHALL extract the user_id from the JWT_Token
5. THE Backend SHALL automatically join the socket to room "user_{user_id}"
6. WHEN a socket connection is rejected, THE Frontend SHALL log the rejection reason and display "Unable to connect to notification service"

### Requirement 16: API Request Retry Logic

**User Story:** As a user, I want automatic request retries, so that transient network errors do not disrupt my work.

#### Acceptance Criteria

1. WHEN an API request fails with a network error, THE Query_Client SHALL retry the request up to 3 times
2. THE Query_Client SHALL wait 1 second before the first retry, 2 seconds before the second retry, and 4 seconds before the third retry (exponential backoff)
3. WHEN all retries are exhausted, THE Query_Client SHALL display an error message "Failed to load data. Please check your connection."
4. THE Query_Client SHALL not retry requests that fail with HTTP 400, 401, 403, or 404 status codes
5. THE Query_Client SHALL retry requests that fail with HTTP 500, 502, 503, or 504 status codes
6. WHEN a retry succeeds, THE Query_Client SHALL not display any error message to the user

### Requirement 17: Environment Configuration Round-Trip

**User Story:** As a developer, I want configuration validation, so that I can detect misconfigured environment variables.

#### Acceptance Criteria

1. WHEN the Frontend loads, THE config.ts module SHALL validate that API_BASE is a valid URL format
2. WHEN the Frontend loads, THE config.ts module SHALL validate that SOCKET_URL is a valid WebSocket URL format
3. IF API_BASE does not start with "http://" or "https://", THE config.ts module SHALL throw an error "Invalid API_BASE URL"
4. IF SOCKET_URL does not start with "ws://" or "wss://", THE config.ts module SHALL throw an error "Invalid SOCKET_URL"
5. THE config.ts module SHALL log the active configuration values to the console in development mode
6. THE config.ts module SHALL not log configuration values in production mode

### Requirement 18: Query Client Configuration

**User Story:** As a developer, I want optimized query caching, so that the UI is responsive and minimizes unnecessary API calls.

#### Acceptance Criteria

1. THE Query_Client SHALL set default staleTime to 60000 milliseconds (1 minute)
2. THE Query_Client SHALL set default cacheTime to 300000 milliseconds (5 minutes)
3. THE Query_Client SHALL enable refetchOnWindowFocus for all queries
4. THE Query_Client SHALL disable retries for queries by default (retry: false in global config)
5. THE Query_Client SHALL enable retries per-hook using the retry option when appropriate
6. WHEN a query fails, THE Query_Client SHALL keep the last successful data in cache until new data is fetched

### Requirement 19: Notification Display and Persistence

**User Story:** As a user, I want to see notification history, so that I do not miss important alerts.

#### Acceptance Criteria

1. WHEN a notification is received via socket, THE Frontend SHALL display a toast notification for 5 seconds
2. THE Frontend SHALL store notifications in local state with maximum capacity of 50 notifications
3. WHEN the notification count exceeds 50, THE Frontend SHALL remove the oldest notification
4. THE Frontend SHALL provide a notification panel showing all recent notifications
5. WHEN a user clicks a notification, THE Frontend SHALL mark it as read and navigate to the relevant page
6. THE Frontend SHALL persist unread notification count in localStorage
7. WHEN the user logs out, THE Frontend SHALL clear all notifications from state and localStorage

### Requirement 20: Error Boundary for API Failures

**User Story:** As a user, I want graceful error handling, so that a single API failure does not crash the entire application.

#### Acceptance Criteria

1. THE Frontend SHALL wrap all page components with an ErrorBoundary component
2. WHEN a component throws an error during rendering, THE ErrorBoundary SHALL catch the error
3. THE ErrorBoundary SHALL display a fallback UI with message "Something went wrong. Please refresh the page."
4. THE ErrorBoundary SHALL log the error details to the console for debugging
5. THE ErrorBoundary SHALL provide a "Retry" button that resets the error state and re-renders the component
6. WHEN an API_Hook encounters a fatal error, THE ErrorBoundary SHALL display the error without crashing the app
