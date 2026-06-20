# Phase 2 Rollback Guide

**Checkpoint**: PHASE-2-CHECKPOINT.md  
**If rollback is needed**, follow these steps to revert all Phase 2 changes.

---

## Quick Rollback

Automated rollback script coming soon (Phase 2.1 enhancement).

For now, follow manual steps below.

---

## Manual Rollback Steps

### Step 1: Delete Team Configuration Directory

**Directory**: `Backend/config/teams/`

Delete the entire directory with all team JSON files:
```bash
rm -r Backend/config/teams
```

Or manually delete:
- `Backend/config/teams/inbound.json`
- `Backend/config/teams/outbound.json`
- `Backend/config/teams/inbound_uae.json`
- `Backend/config/teams/pre_approvals_offshore.json`
- `Backend/config/teams/sales.json`

---

### Step 2: Delete Backend Config Loader

**File**: `Backend/config/loader.py`

```bash
rm Backend/config/loader.py
```

**Impact**: Backend will no longer be able to load team configs from files.

---

### Step 3: Delete Config API Router

**File**: `Backend/api/routers/config.py`

```bash
rm Backend/api/routers/config.py
```

**Impact**: Config API endpoints (`/api/config/teams/*`) will no longer exist.

---

### Step 4: Remove Config Router from API

**File**: `Backend/api/routers/__init__.py`

**Find**:
```python
from .config import router as config_router
```

**Delete** that line.

**Find**:
```python
router.include_router(config_router, tags=["Configuration"])
```

**Delete** that line.

**Result**: After removal, file should look like:
```python
from fastapi import APIRouter

from .performance import router as performance_router
from .employee import router as employee_router
from .team import router as team_router
from .settings import router as settings_router
from .upload import router as upload_router
from .users_and_actions import users_router, actions_router

router = APIRouter()

router.include_router(performance_router, tags=["Performance"])
router.include_router(employee_router, prefix="/employee", tags=["Employee"])
router.include_router(team_router, prefix="/team-actions", tags=["Team Actions"])
router.include_router(settings_router, prefix="/settings", tags=["Settings"])
router.include_router(upload_router, prefix="/uploads", tags=["Uploads"])
router.include_router(users_router, prefix="/users", tags=["Users"])
router.include_router(actions_router, prefix="/corrective-actions", tags=["Corrective Actions"])
```

---

### Step 5: Delete Frontend Team Config Schema

**File**: `Frontend/src/schemas/teamConfig.schema.ts`

```bash
rm Frontend/src/schemas/teamConfig.schema.ts
```

**Impact**: Zod schema for team config validation will no longer exist.

---

### Step 6: Delete Frontend Team Config Hook

**File**: `Frontend/src/hooks/useTeamConfig.ts`

```bash
rm Frontend/src/hooks/useTeamConfig.ts
```

**Impact**: React Query hooks for fetching team configs will no longer exist.

---

### Step 7: Search and Remove Imports

If any components have imported `useTeamConfig` or Zod schemas, remove those imports.

**Search for**:
```typescript
import { useTeamConfig, useAllTeamConfigs } from '../hooks/useTeamConfig';
import { TeamConfigSchema, validateTeamConfig } from '../schemas/teamConfig.schema';
```

**Remove** any matching imports from your codebase.

---

## Verification After Rollback

After completing all steps, verify:

1. **Check Backend compiles**:
   ```bash
   cd Backend && python -m py_compile api/routers/__init__.py config/loader.py api/routers/config.py
   ```
   Should fail gracefully if loader.py and config.py don't exist (expected).

2. **Check API endpoints removed**:
   ```bash
   curl http://localhost:8000/api/config/teams
   ```
   Should return 404 (Not Found).

3. **Check Frontend compiles**:
   ```bash
   cd Frontend && npm run build
   ```
   Should compile without errors.

4. **Confirm old behavior** returns:
   - Team configs no longer fetched from API
   - Frontend uses old hardcoded `teamRegistry.ts` or similar
   - No Zod validation of configs
   - No React Query hooks for team configs

---

## Rollback Timeline

- **Expected duration**: 5-10 minutes (manual steps)
- **Automated script**: Coming in Phase 2.1
- **Verification**: 2-3 minutes

---

## When to Rollback

Consider rollback if:
- ❌ Config API endpoints return 500 errors
- ❌ Team configs are not loading correctly
- ❌ Frontend cannot fetch team configs
- ❌ Zod validation is too strict/breaking
- ✅ Otherwise: Phase 2 is stable and ready for Phase 3

---

## If Rollback Fails

If you encounter issues during rollback:

1. **Check file permissions**:
   ```bash
   ls -la Backend/config/teams/
   ls -la Frontend/src/schemas/
   ```

2. **Check for open file handles**:
   ```bash
   lsof | grep config.py
   lsof | grep teamConfig.schema.ts
   ```

3. **Use git to revert** (if files were committed):
   ```bash
   git status
   git log --oneline | head -5
   git revert <commit-hash>
   ```

4. **Contact support** with error messages

---

## Recovery Notes

If a partial rollback was done:

- **If only backend deleted but not frontend**: Frontend will error when trying to fetch from `/api/config/teams` (404). Remove `useTeamConfig` imports from components.
- **If only frontend deleted but not backend**: API endpoints will still exist but won't be used by frontend. Safe to leave as-is.
- **If loader.py deleted but config.py remains**: config.py will fail to import loader functions. Either delete config.py or restore loader.py.

---

## Completeness Checklist

Before considering rollback complete, verify:

- [ ] `/Backend/config/teams/` directory deleted
- [ ] `Backend/config/loader.py` deleted
- [ ] `Backend/api/routers/config.py` deleted
- [ ] Config router removed from `Backend/api/routers/__init__.py`
- [ ] `Frontend/src/schemas/teamConfig.schema.ts` deleted
- [ ] `Frontend/src/hooks/useTeamConfig.ts` deleted
- [ ] All imports of deleted files removed
- [ ] Backend compiles without errors
- [ ] Frontend compiles without errors
- [ ] API endpoints return 404

