# Frontend Bootstrapping & Initialization Flow

This document details the startup, authentication, and connection sequence executed by the React client application when bootstrapping.

---

## 1. Initialization Sequence Diagram

The sequence diagram below shows the startup steps, beginning with the login interface and ending with a fully active team dashboard:

```mermaid
sequenceDiagram
    autonumber
    actor User as User Browser
    participant App as React App (App.tsx)
    participant Auth as AuthContext (AuthContext.tsx)
    participant API as FastAPI Backend (api/auth)
    participant Socket as Socket.IO Client (useSocket)
    participant Query as TanStack Query Cache

    User->>App: Open Page
    App->>Auth: Check local token (localStorage)
    alt Token Missing
        Auth-->>App: Redirect to /login
        User->>App: Enter Username & Password
        App->>API: POST /api/auth/login
        API-->>App: Return JWT Token & Profile
        App->>Auth: Set Token in localStorage
    end

    Note over App, Auth: Initialize Authentication Gate
    App->>API: GET /api/auth/me (Authorization: Bearer JWT)
    API-->>App: Return Full Profile, Permissions & Assigned Teams
    App->>Auth: Load Profile & Assigned Teams into state

    Note over App, Sidebar: Render Navigation Structure
    App->>App: Filter Sidebar navigation items by permissions

    Note over App, Socket: Establish Real-Time Channel
    App->>Socket: Instantiate Socket.IO client (JWT handshake)
    Socket->>API: Connect & Request Join Rooms
    API-->>Socket: Join Rooms (e.g. admin, team_inbound)
    Socket-->>App: Connection established

    Note over App, Query: Populate Dashboard Data
    App->>Query: GET /api/performance (fetch latest month metrics)
    Query->>API: Fetch database records
    API-->>Query: Return performance aggregates
    Query-->>App: Update UI charts

    App-->>User: Workspace Ready (Render Dashboard)
```

---

## 2. Dynamic Initialization Gate

To prevent flash-of-unstyled-content (FOUC), unauthorized rendering, or API failures due to race conditions, the React application enforces a strict **Authentication Gate**:

### Why Initialization is Gated
1. **Permission Validation:** The client application does not know which sidebar navigation buttons (such as Settings, Planning, or Team Management) to display until it resolves user permissions via `/api/auth/me`.
2. **Data Fetching Scopes:** The application is unable to fetch team performance metrics until it verifies which teams the manager has permission to access.
3. **Socket Subscription:** The real-time listener cannot subscribe to the correct WebSocket rooms without knowing the active user's role and assigned teams.

### How Race Conditions are Avoided
- **Render Blocking:** The main application shell (`App.tsx`) monitors an `initializing` state variable from the `AuthContext`. If `initializing` is true, the app halts route routing and renders a full-screen skeleton loading interface.
- **Sequential Execution:** The Socket.IO connection is initialized only *after* the authentication profile has resolved successfully, ensuring the client has a valid JWT to present during the socket handshake.
- **Declarative Router Guards:** Private routes are wrapped in a `<ProtectedRoute>` wrapper that automatically intercepts attempts to bypass initialization, redirecting unauthorized browsers back to `/login`.
