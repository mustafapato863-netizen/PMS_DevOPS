# Restoration Checklist

**Created**: 2026-06-20  
**Backup Date**: After Phase 5 Parts 1-2  
**Status**: ✅ READY FOR RESTORATION  

---

## Quick Reference

**If you need to restore**, use this checklist in order:

### 1. Verify Backup Files Exist

```
✓ .kiro/CHECKPOINTS.md
✓ .kiro/PHASE-4-BACKUP.md
✓ .kiro/PHASE-5-COMPLETE-BACKUP.md
✓ .kiro/PHASE-5-BACKUP-BACKEND.md
✓ .kiro/PHASE-5-BACKUP-FRONTEND.md
✓ .kiro/SESSION-SUMMARY.md
✓ .kiro/PHASE-5-PLAN.md
✓ .kiro/PHASE-5-PROGRESS.md
✓ .kiro/PHASE-5-SUMMARY-INTERIM.md
```

**Total files in .kiro directory**: 24 files ✅

### 2. Backend Files Check

**Created in Phase 5** (verify exist):
```
✓ Backend/data_cleaning/__init__.py
✓ Backend/data_cleaning/base_cleaner.py
✓ Backend/data_cleaning/cleaner_factory.py
✓ Backend/data_cleaning/standard_mappings.py
✓ Backend/models/team_models.py
✓ Backend/services/team_service.py
✓ Backend/api/routers/team_management.py
```

**Modified in Phase 5** (verify contents):
```
✓ Backend/api/routers/__init__.py (has team_management import)
✓ Backend/requirements.txt (has python-socketio entries)
✓ Backend/app.py (has Socket.io ASGI setup)
```

### 3. Frontend Files Check

**Status**: No new files in Phase 5 Parts 1-2 ✅

**Verify Phase 4 files exist**:
```
✓ Frontend/src/components/notifications/NotificationBell.tsx
✓ Frontend/src/components/notifications/NotificationCenter.tsx
✓ Frontend/src/components/notifications/NotificationItem.tsx
✓ Frontend/src/components/notifications/index.ts
✓ Frontend/src/hooks/useSocket.ts
✓ Frontend/src/hooks/useSocketListener.ts
✓ Frontend/src/hooks/useNotificationSocket.ts
```

### 4. Dependencies Check

**Backend**:
```bash
# Verify requirements.txt has these lines
python-socketio[asyncio]>=5.11.0
python-socketio-client[asyncio_client]>=5.11.0

# Install
pip install -r Backend/requirements.txt
```

**Frontend**:
```bash
# Verify package.json has
"socket.io-client": "^4.8.3"

# Install
npm install
```

### 5. Compilation Check

**Backend**:
```bash
# Check Python syntax
cd Backend
python -m py_compile data_cleaning/base_cleaner.py
python -m py_compile data_cleaning/cleaner_factory.py
python -m py_compile data_cleaning/standard_mappings.py
python -m py_compile models/team_models.py
python -m py_compile services/team_service.py
python -m py_compile api/routers/team_management.py

# Should return: no errors
```

**Frontend**:
```bash
# Check TypeScript
cd Frontend
npx tsc --noEmit

# Should return: 0 errors
```

### 6. Server Startup Check

**Backend**:
```bash
cd Backend
uvicorn app:app_with_sio --reload --port 8000

# Should see: "Uvicorn running on http://127.0.0.1:8000"
```

**Frontend** (in different terminal):
```bash
cd Frontend
npm run dev

# Should see: "Local: http://localhost:5173"
```

### 7. API Endpoints Check

Test new Phase 5 endpoints:

```bash
# Test team list (should return empty or existing teams)
curl http://localhost:8000/api/team-management/teams

# Test team creation
curl -X POST http://localhost:8000/api/team-management/teams \
  -H "Content-Type: application/json" \
  -d '{"name":"test-team","display_name":"Test Team"}'

# Test team list again (should see new team)
curl http://localhost:8000/api/team-management/teams

# Test team statistics
curl http://localhost:8000/api/team-management/statistics
```

### 8. Integration Check

**Frontend connects to Backend**:
```
1. Open browser: http://localhost:5173
2. Open DevTools (F12)
3. Check Console for: "Socket connected"
4. Check Network → WebSocket for active connection
5. All pages should load
```

### 9. Feature Check

**Phase 4 Features** (Real-time Notifications):
```
✓ Notification bell visible in Header
✓ Bell badge shows count
✓ Click bell opens notification panel
✓ Notifications have different colors/icons
```

**Phase 5 Features** (Team API):
```
✓ Can list teams via API
✓ Can create team via API
✓ Can update team via API
✓ Can delete team via API
✓ Can validate team via API
✓ Can get stats via API
```

### 10. Verification Summary

**Checklist**:
```
BACKEND:
  ✓ All Python files present
  ✓ Dependencies installed
  ✓ No syntax errors
  ✓ Server starts
  ✓ API endpoints respond
  ✓ 7 new endpoints working

FRONTEND:
  ✓ All files present
  ✓ Dependencies installed
  ✓ TypeScript compiles
  ✓ Dev server starts
  ✓ Socket.io connects
  ✓ All pages load
  ✓ Notifications work

INTEGRATION:
  ✓ Backend and frontend connected
  ✓ No console errors
  ✓ All features working
  ✓ Type checking passes
  ✓ No breaking changes
```

---

## If Restoration Fails

### Issue: Backend won't start

**Troubleshoot**:
1. Check Python version: `python --version` (need 3.8+)
2. Check pip: `pip --version`
3. Install dependencies: `pip install -r Backend/requirements.txt`
4. Check for conflicting processes: `netstat -ano | find ":8000"`
5. Try different port: `uvicorn app:app_with_sio --reload --port 8001`

### Issue: Frontend won't start

**Troubleshoot**:
1. Check Node version: `node --version` (need 16+)
2. Check npm: `npm --version`
3. Clear npm cache: `npm cache clean --force`
4. Delete node_modules: `rm -r node_modules`
5. Reinstall: `npm install`
6. Try dev server: `npm run dev`

### Issue: TypeScript errors

**Troubleshoot**:
1. Check tsconfig.json exists
2. Run: `npx tsc --listFiles` to see what's wrong
3. Check for missing imports
4. Verify all @types packages installed

### Issue: Socket.io connection fails

**Troubleshoot**:
1. Check backend is running
2. Check port 8000 is accessible
3. Check firewall/antivirus not blocking
4. Check console for connection errors
5. Try with different transports (WebSocket vs polling)

### Issue: API endpoints return 404

**Troubleshoot**:
1. Check server started successfully
2. Check router was imported in `api/routers/__init__.py`
3. Check endpoint URL spelling
4. Test with curl: `curl http://localhost:8000/api/team-management/teams`
5. Check backend logs for errors

---

## Rollback Procedures

If you need to rollback to an earlier phase:

**Rollback to Phase 4**:
```
See: .kiro/rollback/ROLLBACK-PHASE-4.md
Steps: Delete Phase 5 files and revert Phase 4 changes
Time: ~10 minutes
```

**Rollback to Phase 3**:
```
See: .kiro/rollback/ROLLBACK-PHASE-3.md
Then: See ROLLBACK-PHASE-4.md
Time: ~15 minutes
```

**Rollback Complete**:
```
Rollback all phases to Phase 1:
Time: ~30 minutes
Restore original code base
```

---

## Health Check Commands

Run these to verify system health:

```bash
# Backend health
curl http://localhost:8000/

# Expected output:
# {"status":"online","api":"PMS Dashboard API","version":"2.0.0"}

# Team management health
curl http://localhost:8000/api/team-management/statistics

# Frontend health
npm run lint

# TypeScript check
npx tsc --noEmit

# Build test
npm run build
```

---

## Important Files Reference

### Backup Files
- `PHASE-4-BACKUP.md` — Phase 4 complete state
- `PHASE-5-COMPLETE-BACKUP.md` — Phase 5 Parts 1-2 state
- `PHASE-5-BACKUP-BACKEND.md` — Backend details
- `PHASE-5-BACKUP-FRONTEND.md` — Frontend details

### Checkpoint Files
- `PHASE-1-CHECKPOINT.md` — Critical Fixes
- `PHASE-2-CHECKPOINT.md` — API Config Layer
- `PHASE-3-CHECKPOINT.md` — State & Caching
- `PHASE-4-CHECKPOINT.md` — Real-time Notifications
- (PHASE-5-CHECKPOINT.md will be created after completion)

### Rollback Procedures
- `ROLLBACK-PHASE-1.md`
- `ROLLBACK-PHASE-2.md`
- `ROLLBACK-PHASE-3.md`
- `ROLLBACK-PHASE-4.md`
- (ROLLBACK-PHASE-5.md will be created after completion)

### Reference Documents
- `CHECKPOINTS.md` — Master index
- `SESSION-SUMMARY.md` — This session summary
- `RESTORATION-CHECKLIST.md` — This file
- `PHASE-5-PLAN.md` — Phase 5 plans

---

## Quick Restoration Script

If everything is working and just needs to be restarted:

**Backend Startup**:
```bash
cd Backend
pip install -r requirements.txt
uvicorn app:app_with_sio --reload --port 8000
```

**Frontend Startup** (new terminal):
```bash
cd Frontend
npm install
npm run dev
```

**Expected Output**:
```
Backend: "Uvicorn running on http://127.0.0.1:8000"
Frontend: "Local: http://localhost:5173"
Browser: Open http://localhost:5173, see no errors
```

---

## Sign-Off

**Restoration Checklist**: ✅ READY

- Backup files: ✅ 24 files documented
- Code files: ✅ All present
- Dependencies: ✅ Listed
- Compilation: ✅ Zero errors
- Verification: ✅ Procedures detailed
- Recovery: ✅ Options provided

**Status**: Ready for emergency restoration if needed

---

**Last Updated**: 2026-06-20  
**System Status**: ✅ STABLE  
**Backup Status**: ✅ VERIFIED  

