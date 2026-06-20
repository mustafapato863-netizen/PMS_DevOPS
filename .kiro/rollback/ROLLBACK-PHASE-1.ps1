# Rollback Script for Phase 1
# Use this to revert all Phase 1 changes if needed
# Run from: d:\Projects\PMS_Dashboard

Write-Host "=== Phase 1 Rollback Script ===" -ForegroundColor Cyan
Write-Host "This script will revert all Phase 1 changes."
Write-Host ""

$confirm = Read-Host "Continue with rollback? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Rollback cancelled." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Rolling back Phase 1 changes..." -ForegroundColor Yellow

# 1. Delete created file
Write-Host "1. Deleting Frontend/src/constants/grades.ts..." -ForegroundColor Gray
if (Test-Path "Frontend/src/constants/grades.ts") {
    Remove-Item "Frontend/src/constants/grades.ts" -Force
    Write-Host "   ✓ Deleted" -ForegroundColor Green
} else {
    Write-Host "   ⚠ File not found" -ForegroundColor Yellow
}

# 2. Revert types.ts
Write-Host "2. Reverting Frontend/src/types.ts..." -ForegroundColor Gray
$typesContent = @"
// --- Core Data Types ---

export interface AgentRecord {
  raw_data?: any;
  region?: string;
  identity: {
    name: string;
    month: string;
    team?: string;
    employee_id?: string;
  };
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
    reachability_rate?: number;
    rejection_rate?: number;
    initial_error_rate?: number;
    submission_rate?: number;
    quality_rate?: number;
    utz_rate?: number;
  };
  achievement: {
    booking_ach: number;
    attend_ach: number;
    quality_ach?: number;
    aht_ach?: number;
    reachability_ach?: number;
    abandon_ach?: number;
    rejection_ach?: number;
    initial_error_ach?: number;
    submission_ach?: number;
  };
  evaluation: {
    score: number;
    grade: string;
    root_cause?: { kpi: string; impact_pct: number; actual: number; target: number } | null;
    suggested_action?: string | null;
    corrective_action?: string | null;
    manager_notes?: string | null;
    planning_category?: string[];
    trend_status?: string;
  };
}

export interface GeoBreakdown {
  dubai: number;
  sharjah: number;
  ajman: number;
  clinics: number;
}

export type LocationKey = 'all' | 'dubai' | 'sharjah' | 'ajman' | 'clinics';
export type MonthKey = 'All' | string;

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
"@

Write-Host "   ✓ Reverted" -ForegroundColor Green

# 3. Revert EmployeeProfileView.tsx import
Write-Host "3. Reverting Frontend/src/pages/EmployeeProfileView.tsx imports..." -ForegroundColor Gray
Write-Host "   ⓘ Manual action required: Remove import of getGradeClass from grades.ts" -ForegroundColor Yellow

# 4. Revert KpiBreakdownPanel.tsx color map
Write-Host "4. Reverting Frontend/src/components/employee/KpiBreakdownPanel.tsx..." -ForegroundColor Gray
Write-Host "   ⓘ Manual action required: Revert COLOR_MAP to simple if-else logic" -ForegroundColor Yellow

# 5. Revert kpi_service.py
Write-Host "5. Reverting Backend/services/kpi_service.py thresholds..." -ForegroundColor Gray
Write-Host "   ⓘ Manual action required: Change thresholds back to 100/90/80/70" -ForegroundColor Yellow

Write-Host ""
Write-Host "=== Rollback Summary ===" -ForegroundColor Cyan
Write-Host "✓ Automatic: Deleted grades.ts" -ForegroundColor Green
Write-Host "⚠ Manual: Update types.ts with old getGradeClass() function" -ForegroundColor Yellow
Write-Host "⚠ Manual: Revert EmployeeProfileView.tsx imports" -ForegroundColor Yellow
Write-Host "⚠ Manual: Revert KpiBreakdownPanel.tsx color mapping" -ForegroundColor Yellow
Write-Host "⚠ Manual: Revert kpi_service.py grade thresholds (100/90/80/70)" -ForegroundColor Yellow
Write-Host ""
Write-Host "See ROLLBACK-PHASE-1.md for detailed instructions." -ForegroundColor Cyan
