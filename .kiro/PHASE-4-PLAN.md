# Phase 4 Execution Plan — Real-time Notifications

**Date Started**: 2026-06-20  
**Phase**: 4 of 5  
**Duration**: Week 5–6  
**Risk Level**: 🟠 MEDIUM  

---

## Overview

Phase 4 implements real-time notifications using Socket.io. This enables live updates across the dashboard without requiring page refreshes.

### Goals
1. Backend Socket.io server setup
2. Frontend socket connection hook
3. Notification bell component with badge
4. Real-time data update listeners
5. Notification persistence in Zustand store

---

## Implementation Breakdown

### Part 1: Backend Socket.io Setup

**Files to Create**:
- `Backend/config/socket_config.py` — Socket.io configuration
- `Backend/services/socket_service.py` — Socket event handlers and broadcasting

**Files to Modify**:
- `Backend/app.py` — Add Socket.io initialization

**Files to Review**:
- `Backend/api/routers/` — Identify endpoints that should trigger notifications

**Expected Changes**:
- ~200 lines of new backend code
- Zero breaking changes to existing APIs

### Part 2: Frontend Socket Hook

**Files to Create**:
- `Frontend/src/hooks/useSocket.ts` — Socket connection management
- `Frontend/src/hooks/useSocketListener.ts` — Socket event listener hook

**Files to Review**:
- `Frontend/src/lib/queryClient.ts` — May need to invalidate queries on socket events
- `Frontend/src/main.tsx` — May need to initialize socket connection

**Expected Changes**:
- ~150 lines of new frontend code

### Part 3: Notification Components

**Files to Create**:
- `Frontend/src/components/notifications/NotificationBell.tsx` — Bell icon with badge
- `Frontend/src/components/notifications/NotificationCenter.tsx` — Notification list panel
- `Frontend/src/components/notifications/NotificationToast.tsx` — Toast notifications

**Files to Modify**:
- `Frontend/src/store/appStore.ts` — Add notification state (already in Phase 3)

**Expected Changes**:
- ~300 lines of new UI code
- Uses existing Zustand store

### Part 4: Integration & Testing

**Files to Modify**:
- `Frontend/src/App.tsx` or main layout — Add NotificationBell to header
- `Backend/main.py` — Ensure Socket.io starts with app

**Expected Changes**:
- ~50 lines of integration code

---

## Execution Sequence

### Step 1: Backend Socket.io Setup (Low Risk)
- Create socket configuration
- Create socket event handlers
- Integrate with Flask app
- Verify server starts without errors

### Step 2: Frontend Socket Hook (Low Risk)
- Create socket connection hook
- Create socket listener hook
- Handle connection/disconnection
- Verify hooks work in development

### Step 3: Notification Components (Medium Risk)
- Create notification bell component
- Create notification center panel
- Create toast component
- Integrate with Zustand store

### Step 4: Integration & Real-time Updates (Medium Risk)
- Connect socket listeners to notification updates
- Trigger React Query invalidations on updates
- Add notification bell to main layout
- Test end-to-end real-time flow

---

## Verification Checklist

### Compilation
- [ ] All new TypeScript files compile (0 errors)
- [ ] All new Python files have no syntax errors
- [ ] No type errors in React components

### Functionality
- [ ] Socket.io server starts when backend runs
- [ ] Frontend can connect to Socket.io server
- [ ] Notifications appear in real-time
- [ ] Notification badge shows unread count
- [ ] Notifications persist across page navigations

### Regression
- [ ] All Phase 3 functionality still works
- [ ] All existing APIs still respond correctly
- [ ] No UI changes to existing components
- [ ] No breaking changes to existing hooks

### Performance
- [ ] Socket connection doesn't block app startup
- [ ] Notification updates don't cause lag
- [ ] Unread count badge updates smoothly

---

## Risk Mitigation

**Risk**: Socket.io server doesn't start
- **Mitigation**: Test backend startup before frontend changes

**Risk**: Frontend socket connection fails
- **Mitigation**: Graceful fallback if Socket.io unavailable

**Risk**: Too many socket events overwhelm browser
- **Mitigation**: Implement event debouncing/throttling

**Risk**: Notifications break existing UI
- **Mitigation**: Use existing Zustand store structure

---

## Files Summary

### Files to Create (Total: 8)
1. `Backend/config/socket_config.py`
2. `Backend/services/socket_service.py`
3. `Frontend/src/hooks/useSocket.ts`
4. `Frontend/src/hooks/useSocketListener.ts`
5. `Frontend/src/components/notifications/NotificationBell.tsx`
6. `Frontend/src/components/notifications/NotificationCenter.tsx`
7. `Frontend/src/components/notifications/NotificationToast.tsx`
8. `Frontend/src/components/notifications/index.ts`

### Files to Modify (Total: 2)
1. `Backend/app.py`
2. `Frontend/src/App.tsx` (or main layout)

### Files to Review (Total: 4)
1. `Backend/api/routers/` — Identify notification triggers
2. `Frontend/src/lib/queryClient.ts` — Query invalidation
3. `Frontend/src/main.tsx` — Socket initialization
4. `Frontend/src/store/appStore.ts` — Notification state

---

## Status: Ready to Begin

Phase 4 execution plan complete. Ready to implement.

Next step: Backend Socket.io Configuration

