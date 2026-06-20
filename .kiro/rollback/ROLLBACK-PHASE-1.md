# Phase 1 Rollback Guide

**Checkpoint**: PHASE-1-CHECKPOINT.md  
**If rollback is needed**, follow these steps to revert all Phase 1 changes.

---

## Quick Rollback

Run the automated script:
```powershell
.\ROLLBACK-PHASE-1.ps1
```

Then manually revert files per instructions below.

---

## Manual Rollback Steps

### Step 1: Delete `Frontend/src/constants/grades.ts`

**File**: `d:\Projects\PMS_Dashboard\Frontend\src\constants\grades.ts`  
**Action**: Delete entire file  
**Reason**: This file was created in Phase 1 and needs to be removed

```bash
rm Frontend/src/constants/grades.ts
```

---

### Step 2: Revert `Frontend/src/types.ts`

**File**: `d:\Projects\PMS_Dashboard\Frontend\src\types.ts`

**Remove these lines** (at the top):
```typescript
import { getGradeClass, type GradeClass } from './constants/grades';
```

**Replace this section** (around line 62):
```typescript
// --- Grade & Status Logic ---
// GradeClass type and getGradeClass() imported from constants/grades.ts
// This ensures a single source of truth for grade thresholds
```

**With this**:
```typescript
/** Grade classes based on score thresholds */
export type GradeClass = 'A' | 'B' | 'C' | 'D' | 'E';

// --- Grade & Status Logic ---

export function getGradeClass(score: number): GradeClass {
  if (score >= 90) return 'A';
  if (score >= 80) return 'B';
  if (score >= 70) return 'C';
  if (score >= 60) return 'D';
  return 'E';
}
```

---

### Step 3: Revert `Frontend/src/pages/EmployeeProfileView.tsx`

**File**: `d:\Projects\PMS_Dashboard\Frontend\src\pages\EmployeeProfileView.tsx`

#### 3a. Remove import

**Find**:
```typescript
import { getGradeClass } from '../constants/grades';
```

**Delete** that line.

#### 3b. Revert trend data sorting

**Find** (around line 670):
```typescript
const trendData = useMemo(() => {
  const history = backendProfile?.performance_history || [];
  const MONTH_ORDER: Record<string, number> = {
    January: 1, February: 2, March: 3, April: 4, May: 5, June: 6,
    July: 7, August: 8, September: 9, October: 10, November: 11, December: 12
  };

  return [...history]
    .sort((a, b) => (MONTH_ORDER[a.month] || 0) - (MONTH_ORDER[b.month] || 0))
    .map((h) => {
```

**Replace with**:
```typescript
const trendData = useMemo(() => {
  const history = backendProfile?.performance_history || [];
  return history.map((h) => {
```

---

### Step 4: Revert `Frontend/src/components/employee/KpiBreakdownPanel.tsx`

**File**: `d:\Projects\PMS_Dashboard\Frontend\src\components\employee\KpiBreakdownPanel.tsx`

**Find** (around line 40):
```typescript
  // Map hex colors to CSS variables with fallback for unmapped colors
  const COLOR_MAP: Record<string, string> = {
    '#3B82F6': 'var(--color-meet)',
    '#10B981': 'var(--color-exceeds)',
    '#8B5CF6': 'var(--color-purple)',
    '#F59E0B': 'var(--color-average)',
    '#EAB308': 'var(--color-average)',
    '#EF4444': 'var(--color-sip)',
    '#6366F1': 'var(--color-indigo)',
  };

  const barColor = COLOR_MAP[color] ?? 'var(--color-meet)';
```

**Replace with**:
```typescript
  let barColor = color;
  if (color === '#3B82F6') barColor = 'var(--color-meet)';
  else if (color === '#10B981') barColor = 'var(--color-exceeds)';
  else if (color === '#EF4444') barColor = 'var(--color-sip)';
  else if (color === '#F59E0B' || color === '#EAB308') barColor = 'var(--color-average)';
```

---

### Step 5: Revert `Backend/services/kpi_service.py`

**File**: `d:\Projects\PMS_Dashboard\Backend\services\kpi_service.py`

**Find** (at end of file):
```python
    @staticmethod
    def assign_grade(score: float) -> str:
        """Assign performance grade based on unified thresholds.
        
        Thresholds:
        - A: score >= 95
        - B: score >= 85
        - C: score >= 75
        - D: score >= 65
        - E: score < 65
        
        These thresholds are unified with Frontend (constants/grades.ts)
        to ensure consistent grading across the system.
        """
        if score >= 95.0:
            return "A"
        elif score >= 85.0:
            return "B"
        elif score >= 75.0:
            return "C"
        elif score >= 65.0:
            return "D"
        else:
            return "E"
```

**Replace with**:
```python
    @staticmethod
    def assign_grade(score: float) -> str:
        """Assign performance grade based on picture ranges."""
        if score >= 100.0:
            return "A"
        elif score >= 90.0:
            return "B"
        elif score >= 80.0:
            return "C"
        elif score >= 70.0:
            return "D"
        else:
            return "E"
```

---

## Verification After Rollback

After completing all steps, verify:

1. **Check compilation**:
   ```bash
   cd Frontend && npm run build
   cd Backend && python -m py_compile services/kpi_service.py
   ```

2. **Check no new errors** in modified files

3. **Confirm old behavior** returns:
   - Grade thresholds back to 90/80/70/60 (Frontend) and 100/90/80/70 (Backend)
   - Trend data unsorted (may show as disconnected dots)
   - Color mapping back to simple if-else logic

---

## If Rollback Fails

If you encounter issues during rollback:

1. **Check git status**:
   ```bash
   git status
   git diff
   ```

2. **Use git to revert** (if files were committed):
   ```bash
   git revert <commit-hash>
   ```

3. **Contact support** with error messages from compilation check

---

## When to Rollback

Consider rollback if:
- ❌ Grade calculations produce unexpected results
- ❌ Trend chart rendering breaks
- ❌ KPI colors don't display
- ❌ Backend API fails after changes
- ✅ Otherwise: Phase 1 is stable and ready for Phase 2

