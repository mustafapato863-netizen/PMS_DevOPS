# Phase 3 Rollback Guide

**Checkpoint**: PHASE-3-CHECKPOINT.md  
**If rollback is needed**, follow these steps to revert all Phase 3 changes.

---

## Quick Summary

Phase 3 added React Query, Zustand store, and API hooks. Removing these is straightforward:

1. Delete 7 new files
2. Revert main.tsx to original
3. Remove imports from any components

---

## Manual Rollback Steps

### Step 1: Delete React Query Client Configuration

**File**: `Frontend/src/lib/queryClient.ts`

```bash
rm Frontend/src/lib/queryClient.ts
```

**Impact**: QueryClient configuration removed, but providers still look for it (see Step 4).

---

### Step 2: Delete Global State Store

**File**: `Frontend/src/store/appStore.ts`

```bash
rm Frontend/src/store/appStore.ts
```

**Impact**: Zustand store removed. Components using `useAppStore()` will error until updated.

---

### Step 3: Delete API Hooks Directory

**Directory**: `Frontend/src/hooks/api/`

Delete entire directory with all hook files:
```bash
rm -r Frontend/src/hooks/api
```

Or manually delete:
- `Frontend/src/hooks/api/useEmployeeProfile.ts`
- `Frontend/src/hooks/api/usePerformanceData.ts`
- `Frontend/src/hooks/api/useKpiWeights.ts`
- `Frontend/src/hooks/api/index.ts`

**Impact**: React Query hooks removed. Components using these hooks will error.

---

### Step 4: Revert main.tsx

**File**: `Frontend/src/main.tsx`

**Find**:
```typescript
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClientProvider } from '@tanstack/react-query'
import { queryClient } from './lib/queryClient'
import './index.css'
import App from './App.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </StrictMode>,
)
```

**Replace with**:
```typescript
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
```

**Impact**: QueryClientProvider removed. App no longer has React Query support.

---

### Step 5: Remove Imports from Components

Search your codebase for imports of deleted files and remove them:

**Remove any imports like**:
```typescript
import { useEmployeeProfile, usePerformanceData } from '@/hooks/api';
import { useAppStore } from '@/store/appStore';
import { queryClient } from '@/lib/queryClient';
```

**Search locations**:
- `src/pages/**/*.tsx`
- `src/components/**/*.tsx`
- Any custom component files

---

### Step 6: Restore Original Data Fetching Pattern

Components that were using new React Query hooks will need to revert to old pattern:

**Before** (Phase 3):
```typescript
const { data: profile, isLoading, error } = useEmployeeProfile(employeeId);
```

**After** (Phase 2 or earlier):
```typescript
const [profile, setProfile] = useState(null);
const [loading, setLoading] = useState(true);

useEffect(() => {
  fetch(`/api/employee/${employeeId}/`)
    .then(r => r.json())
    .then(d => {
      if (d.success) setProfile(d.data);
    })
    .finally(() => setLoading(false));
}, [employeeId]);
```

---

## Verification After Rollback

After completing all steps, verify:

1. **Check Frontend compiles**:
   ```bash
   cd Frontend && npm run build
   ```
   Should compile without errors.

2. **Search for remaining imports**:
   ```bash
   grep -r "useEmployeeProfile\|usePerformanceData\|useAppStore\|queryClient" src/
   ```
   Should return no results (or only in comments).

3. **Check main.tsx**:
   ```bash
   grep "QueryClientProvider" src/main.tsx
   ```
   Should return no results.

4. **Verify old patterns work**:
   Open a component and verify it uses old useState + useEffect pattern.

---

## Rollback Timeline

- **Expected duration**: 10-15 minutes (manual steps)
- **Search and remove imports**: 5 minutes
- **Verification**: 2-3 minutes
- **Total**: 15-20 minutes

---

## When to Rollback

Consider rollback if:
- ❌ QueryClientProvider causes app to not render
- ❌ Zustand store has conflicts with other state management
- ❌ React Query hooks not working as expected
- ❌ Performance issues with caching
- ✅ Otherwise: Phase 3 is stable and ready for Phase 4

---

## If Rollback Fails

### Issue: App won't start after removing QueryClientProvider
**Solution**: Make sure you reverted main.tsx completely. Check for any lingering imports.

### Issue: Components error about missing hooks
**Solution**: Either remove imports or manually revert components to old fetch pattern.

### Issue: TypeScript errors after deletion
**Solution**: Run `npm run build` to see all errors, then remove problematic imports.

### Issue: Git conflicts during revert
**Solution**: Use git to revert:
```bash
git checkout HEAD -- src/main.tsx
rm -r src/lib/queryClient.ts src/store/appStore.ts src/hooks/api/
```

---

## Recovery Checklist

Before considering rollback complete:

- [ ] `/lib/queryClient.ts` deleted
- [ ] `/store/appStore.ts` deleted
- [ ] `/hooks/api/` directory deleted
- [ ] `main.tsx` reverted to original
- [ ] All imports of deleted files removed
- [ ] App compiles without errors
- [ ] No QueryClientProvider in main.tsx
- [ ] Components use old useState + useEffect pattern

---

## Partial Rollback

If only partial rollback is needed:

**Keep Phase 3 but remove one component**:
- Remove just the imports from that component
- Replace with old fetch pattern
- Leave React Query infrastructure intact

**Remove React Query but keep Zustand**:
- Delete `/lib/queryClient.ts`
- Remove QueryClientProvider from main.tsx
- Keep `/store/appStore.ts` and imports
- Components can still use useAppStore()

**Remove Zustand but keep React Query**:
- Delete `/store/appStore.ts`
- Keep QueryClientProvider in main.tsx
- Keep `/hooks/api/` and imports
- Components can still use React Query hooks

---

## Important Notes

- **Phase 3 is low risk**: No breaking changes to other systems
- **Safe to rollback anytime**: Doesn't affect Backend or Phase 1-2 work
- **No side effects**: Removing state management doesn't corrupt data
- **Data persists**: localStorage and server data unaffected

