# Rollback Guide — Phase 4

**Phase**: 4 of 5  
**Feature**: Real-time Notifications  
**Rollback Time**: ~5 minutes  
**Risk**: 🟢 ZERO (all changes are additive)  

---

## Quick Summary

Phase 4 added Socket.io real-time notifications. All changes are **non-breaking** and can be safely removed.

**Files to Delete**: 10 files
**Files to Modify**: 4 files (revert changes)
**Files to Keep**: All Phase 1-3 files intact

---

## Rollback Procedure

### Step 1: Backend Dependencies

#### File: `Backend/requirements.txt`

**Current (Phase 4)**:
```
fastapi==0.137.1
pydantic==2.13.4
uvicorn==0.49.0
pandas==3.0.3
openpyxl==3.1.5
numpy==2.4.6
python-multipart==0.0.32
python-socketio[asyncio]>=5.11.0
python-socketio-client[asyncio_client]>=5.11.0
watchfiles>=0.21.0
```

**Action**: Remove Socket.io lines

**New (Post-Rollback)**:
```
fastapi==0.137.1
pydantic==2.13.4
uvicorn==0.49.0
pandas==3.0.3
openpyxl==3.1.5
numpy==2.4.6
python-multipart==0.0.32
watchfiles>=0.21.0
```

---

### Step 2: Backend App Configuration

#### File: `Backend/app.py`

**Current (Phase 4)**:
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from socketio import ASGIApp

# Ensure Backend directory is on the import path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from api.routers import router as api_router
from services.seeding_service import DatabaseSeeder
from config.socket_config import sio

# ... lifespan setup ...

# Mount Routers
app.include_router(api_router, prefix="/api")

@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "status": "online",
        "api": "PMS Dashboard API - Clean Architecture",
        "version": "2.0.0",
    }

# Wrap FastAPI app with Socket.io ASGI app for production
app_with_sio = ASGIApp(sio, app)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app_with_sio", host="127.0.0.1", port=8000, reload=True)

# ========== Cloudflare Workers Compatibility Layer ==========
# Export FastAPI app for Workers compatibility
handler = app_with_sio
# ...
```

**Action**: Remove Socket.io import and wrapping

**New (Post-Rollback)**:
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

# Ensure Backend directory is on the import path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from api.routers import router as api_router
from services.seeding_service import DatabaseSeeder

# ... lifespan setup ...

# Mount Routers
app.include_router(api_router, prefix="/api")

@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "status": "online",
        "api": "PMS Dashboard API - Clean Architecture",
        "version": "2.0.0",
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="127.0.0.1", port=8000, reload=True)

# ========== Cloudflare Workers Compatibility Layer ==========
# Export FastAPI app for Workers compatibility
handler = app

try:
    from workers import WorkerEntrypoint
    import asgi

    class Default(WorkerEntrypoint):
        async def fetch(self, request):
            return await asgi.fetch(app, request, self.env)
            
    # Make the entrypoint class available as default export
    default = Default
except ImportError:
    # Local execution or non-worker environment
    pass
```

---

### Step 3: Delete Backend Socket.io Files

#### Delete: `Backend/config/socket_config.py`
```bash
rm Backend/config/socket_config.py
```

#### Delete: `Backend/services/socket_service.py`
```bash
rm Backend/services/socket_service.py
```

---

### Step 4: Frontend Component Changes

#### File: `Frontend/src/components/common/Header.tsx`

**Current (Phase 4)**:
```typescript
import { useState, useEffect, useCallback } from 'react';
import { useLocation, useSearchParams } from 'react-router-dom';
import {
  CalendarDays,
  ChevronDown,
  Menu,
  Target,
  LogOut,
  Sparkles,
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import type { MonthKey } from '../../types';
import ThemeToggle from './ThemeToggle';
import { useUserRole } from '../../context/RoleContext';
import { useAuth } from '../../context/AuthContext';
import { usePerformanceData } from '../../hooks/usePerformanceData';
import { NotificationBell } from '../notifications';

// ... component code ...

// In JSX:
<NotificationBell />
```

**Action**: Remove import and use placeholder

**New (Post-Rollback)**:
```typescript
import { useState, useEffect, useCallback } from 'react';
import { useLocation, useSearchParams } from 'react-router-dom';
import {
  Bell,
  CalendarDays,
  ChevronDown,
  Menu,
  Target,
  LogOut,
  Sparkles,
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import type { MonthKey } from '../../types';
import ThemeToggle from './ThemeToggle';
import { useUserRole } from '../../context/RoleContext';
import { useAuth } from '../../context/AuthContext';
import { usePerformanceData } from '../../hooks/usePerformanceData';

// ... add back placeholder function ...

/** Notification bell */
function NotificationBell() {
  return (
    <motion.button
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      aria-label="Notifications — 1 unread"
      className="relative p-2 text-[var(--text-secondary)] hover:text-[var(--text-primary)] bg-[var(--bg-surface)]/40 backdrop-blur-sm
        rounded-xl border border-[var(--border-light)] hover:bg-[var(--bg-surface)]/80 transition-all"
    >
      <Bell size={16} aria-hidden="true" />
      <span
        className="absolute top-1.5 right-1.5 w-1.5 h-1.5 bg-red-500 rounded-full
          ring-[1.5px] ring-[var(--bg-surface)]"
        aria-hidden="true"
      />
    </motion.button>
  );
}

// In JSX:
<NotificationBell />
```

---

#### File: `Frontend/src/App.tsx`

**Current (Phase 4)**:
```typescript
import { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AnimatePresence } from 'framer-motion';
import Sidebar from './components/common/Sidebar';
import Header from './components/common/Header';
import ExecutiveView from './pages/ExecutiveView';
import TeamDashboardView from './pages/TeamDashboardView';
import EmployeeProfileView from './pages/EmployeeProfileView';
import PlanningView from './pages/PlanningView';
import SettingsView from './pages/SettingsView';
import LoginView from './pages/LoginView';
import { AuthProvider, useAuth } from './context/AuthContext';
import { RoleProvider, useUserRole } from './context/RoleContext';
import { ThemeProvider } from './context/ThemeContext';
import { useNotificationSocket } from './hooks/useNotificationSocket';

// ... component code ...

function AppContent() {
  const { currentUser } = useAuth();
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  // Initialize real-time notifications
  useNotificationSocket();

  // ... rest of code ...
}
```

**Action**: Remove import and hook call

**New (Post-Rollback)**:
```typescript
import { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AnimatePresence } from 'framer-motion';
import Sidebar from './components/common/Sidebar';
import Header from './components/common/Header';
import ExecutiveView from './pages/ExecutiveView';
import TeamDashboardView from './pages/TeamDashboardView';
import EmployeeProfileView from './pages/EmployeeProfileView';
import PlanningView from './pages/PlanningView';
import SettingsView from './pages/SettingsView';
import LoginView from './pages/LoginView';
import { AuthProvider, useAuth } from './context/AuthContext';
import { RoleProvider, useUserRole } from './context/RoleContext';
import { ThemeProvider } from './context/ThemeContext';

// ... component code ...

function AppContent() {
  const { currentUser } = useAuth();
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  // ... rest of code ...
}
```

---

### Step 5: Delete Frontend Socket Hooks

#### Delete: `Frontend/src/hooks/useSocket.ts`
```bash
rm Frontend/src/hooks/useSocket.ts
```

#### Delete: `Frontend/src/hooks/useSocketListener.ts`
```bash
rm Frontend/src/hooks/useSocketListener.ts
```

#### Delete: `Frontend/src/hooks/useNotificationSocket.ts`
```bash
rm Frontend/src/hooks/useNotificationSocket.ts
```

---

### Step 6: Delete Frontend Notification Components

#### Delete: `Frontend/src/components/notifications/` directory
```bash
rm -r Frontend/src/components/notifications/
```

This removes:
- `NotificationBell.tsx`
- `NotificationCenter.tsx`
- `NotificationItem.tsx`
- `index.ts`

---

## Verification

After completing rollback, verify:

### 1. Backend Compilation
```bash
cd Backend
python -m py_compile app.py
python -m py_compile config/socket_config.py  # Should fail (file deleted)
python -m py_compile services/socket_service.py  # Should fail (file deleted)
```

### 2. Frontend Compilation
```bash
cd Frontend
npm run build
# Should complete without errors
```

### 3. App Functionality
1. Start backend: `cd Backend && uvicorn app:app --reload`
2. Start frontend: `cd Frontend && npm run dev`
3. Verify no socket connection attempts in console
4. Verify notification bell shows placeholder icon
5. Verify all Phase 1-3 features work normally

### 4. Network Tab
- Should NOT see WebSocket connection
- Should NOT see Socket.io handshake

---

## Rollback Verification Checklist

- [ ] `Backend/requirements.txt` updated
- [ ] `Backend/app.py` reverted
- [ ] `Backend/config/socket_config.py` deleted
- [ ] `Backend/services/socket_service.py` deleted
- [ ] `Frontend/src/components/common/Header.tsx` reverted
- [ ] `Frontend/src/App.tsx` reverted
- [ ] `Frontend/src/hooks/useSocket.ts` deleted
- [ ] `Frontend/src/hooks/useSocketListener.ts` deleted
- [ ] `Frontend/src/hooks/useNotificationSocket.ts` deleted
- [ ] `Frontend/src/components/notifications/` deleted
- [ ] Backend compiles successfully
- [ ] Frontend builds successfully
- [ ] App runs without socket errors
- [ ] All Phase 1-3 features work

---

## If Rollback Fails

### Issue: "Module not found" errors in frontend

**Cause**: Socket hooks still referenced somewhere
**Solution**: Search codebase for `useSocket`, `NotificationBell`, `useNotificationSocket`

```bash
grep -r "useSocket" Frontend/src/
grep -r "NotificationBell" Frontend/src/
```

Remove any remaining references.

### Issue: Backend won't start

**Cause**: Socket.io still imported
**Solution**: Verify `app.py` doesn't have any socket imports

```bash
grep -i "socket" Backend/app.py
# Should return no results
```

### Issue: Notification state errors

**Cause**: Zustand store from Phase 3 still has notification methods
**Solution**: This is OK - just don't use them. Zustand store is unchanged from Phase 3.

---

## Reverting to Phase 4

If you need to go back to Phase 4 after rollback, reference:
- This guide (in reverse)
- Phase 4 checkpoint for file contents
- Git history (if available)

---

## Post-Rollback Status

After successful rollback:
- ✅ System returns to Phase 3 state
- ✅ All Phase 1-3 features work
- ✅ Notification components removed
- ✅ Socket.io infrastructure removed
- ✅ Zero breaking changes
- ✅ Ready for alternative Phase 4 approach (if needed)

---

## Questions?

If rollback doesn't work or you need help:
1. Check compilation errors: `npm run build`
2. Check console errors: F12 → Console tab
3. Review this guide step-by-step
4. Verify all files were deleted (not just empty)
5. Compare with Phase 3 checkpoint for reference

