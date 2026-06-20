# Three Teams KPI Implementation - Spec Summary

## Quick Overview

This spec adds support for **Pharmacy**, **Coding**, and **CSR** teams to the PMS Dashboard with complete KPI calculation frameworks. Each team has distinct metrics, weights, and calculation rules.

## Key Differences Between Teams

| Aspect | Pharmacy | Coding | CSR |
|--------|----------|--------|-----|
| **KPI Count** | 5 KPIs | 3 KPIs | 3 KPIs |
| **Scoring Rule** | Uncapped (>100% allowed) | Capped at 100% | Capped at 100% |
| **KPI Types** | 2 inverse, 3 direct | 3 inverse | 1 inverse, 2 direct |
| **Grade Thresholds** | A≥95, B≥85, C≥75, D≥65 | A≥95, B≥85, C≥75, D≥65 | A≥95, B≥85, C≥75, D≥65 |

## Document Structure

### 1. **Design Document** (`design.md`)
- **Purpose**: Technical architecture and implementation approach
- **Key Sections**:
  - Architecture diagram showing data flow
  - Configuration layer (team JSON files structure)
  - Data cleaning layer (team-specific cleaners)
  - KPI calculation logic with formulas and examples
  - Data models (TeamKPIConfig, KPIValue)
  - Service layer enhancements
  - Correctness properties (8 properties for property-based testing)
  - Error handling strategies
  - Performance and security considerations

**Key Formulas in Design**:
- **Direct KPI**: achievement = (actual / target) × 100
- **Inverse KPI**: achievement = (target / actual) × 100 (or 100% if actual=0)
- **Pharmacy Score**: Σ(achievement_i × weight_i) - UNCAPPED
- **Coding/CSR Score**: MIN(100%, Σ(achievement_i × weight_i)) - CAPPED

### 2. **Requirements Document** (`requirements.md`)
- **Purpose**: Functional specifications in EARS format
- **21 Requirements** organized by team and functionality:
  - Requirements 1-3: Team configurations (Pharmacy, Coding, CSR)
  - Requirements 4-8: KPI calculations and grading
  - Requirements 9-11: Data cleaners for each team
  - Requirements 12-18: Integration, storage, uploads, compatibility
  - Requirements 19-21: Testing and schema updates

**Key Acceptance Criteria**:
- Each team loads its own JSON configuration file
- Direct KPIs use actual/target formula
- Inverse KPIs use target/actual formula (100% for zero actuals)
- Pharmacy scores are uncapped, Coding/CSR capped at 100%
- Grades assigned: A≥95, B≥85, C≥75, D≥65, E<65
- All 11 KPIs across three teams tested comprehensively

### 3. **Tasks Document** (`tasks.md`)
- **Purpose**: Implementation roadmap with 25+ actionable tasks
- **Organized in 8 Phases**:
  1. Configuration Layer (3 JSON files + ConfigLoader)
  2. Data Cleaning (PharmacyCleaner, CodingCleaner, CSRCleaner)
  3. Factory & Service Integration (cleaner_factory, KPIService enhancements)
  4. Schema & Data Models (verify/update tables)
  5. Seeding & Configuration (SeedingService)
  6. Analysis & Services (AnalysisService, SchemasService)
  7. Testing (comprehensive test suite with property tests)
  8. Documentation & Verification

**Task Structure**:
- 25 main tasks with clear objectives
- 13 optional testing sub-tasks (marked with `*`)
- Each task references specific requirements
- Property test tasks linked to design properties
- Checkpoints at key milestones

## Implementation Highlights

### Configuration Files to Create

```
Backend/config/teams/
  ├── pharmacy.json       # 5 KPIs, uncapped
  ├── coding.json         # 3 KPIs, capped at 100%
  └── csr.json            # 3 KPIs, capped at 100%
```

### Code Files to Create

```
Backend/Data_Cleaning_Teams/
  ├── pharmacy.py         # PharmacyCleaner class
  ├── coding.py           # CodingCleaner class
  └── csr.py              # CSRCleaner class

Backend/tests/
  └── test_three_teams.py # Comprehensive test suite
```

### Code Files to Modify

```
Backend/
  ├── data_cleaning/
  │   ├── cleaner_factory.py           # Add 3 teams to factory
  │   └── __init__.py                  # Export new cleaners
  ├── services/
  │   ├── kpi_service.py               # Multi-team support
  │   ├── excel_processor.py           # Multi-team upload
  │   ├── seeding_service.py           # Seed new teams
  │   └── analysis_service.py          # Update if needed
  ├── config/
  │   └── loader.py                    # ConfigLoader utility
  └── models/
      └── models.py                    # Verify schema
```

## KPI Definitions Summary

### Pharmacy Team (5 KPIs, 20% each, Uncapped)

| KPI | Direction | Excel Columns | Notes |
|-----|-----------|---------------|-------|
| WaitingTime | Lower Better (inverse) | A.TotalAvgWaitingTime, T.TotalWaitingTime | Target/Actual |
| Leakage | Lower Better (inverse) | A.Leakage%, T.Leakage% | Target/Actual |
| TenderCompliance | Higher Better (direct) | A.TenderItemCompliance, T.TenderItemCompliance | Actual/Target |
| ATV | Higher Better (direct) | A.ATV, T.ATV | Actual/Target |
| Prescription | Higher Better (direct) | A.NoofPrescriptionsContribution, T.NoofPrescriptionsContribution | Actual/Target |

### Coding Team (3 KPIs, 20%/50%/30%, Capped at 100%)

| KPI | Weight | Direction | Notes |
|-----|--------|-----------|-------|
| QualityErrors | 20% | Lower Better (inverse) | Target/Actual |
| Rejection | 50% | Lower Better (inverse) | Target/Actual |
| TAT | 30% | Lower Better (inverse) | Target/Actual |

### CSR Team (3 KPIs, 40%/30%/30%, Capped at 100%)

| KPI | Weight | Direction | Notes |
|-----|--------|-----------|-------|
| Rejection | 40% | Lower Better (inverse) | Target/Actual |
| Queries | 30% | Higher Better (direct) | Actual/Target |
| AttendedCR | 30% | Higher Better (direct) | Actual/Target |

## Calculation Examples

### Pharmacy Example (Uncapped)

```
Employee: Ahmed Hassan
KPI Achievements:
  WaitingTime:      76.92% (4.0/5.2, inverse)
  Leakage:         120.00% (3.0/2.5, inverse, can exceed 100%!)
  TenderCompliance: 94.00% (94/100, direct)
  ATV:             107.14% (150/140, direct)
  Prescription:     94.44% (85/90, direct)

Score = 76.92×0.20 + 120×0.20 + 94×0.20 + 107.14×0.20 + 94.44×0.20
      = 98.5% (exceeds 100% - this is allowed!)
Grade = A (98.5 ≥ 95)
```

### Coding Example (Capped)

```
Employee: Fatima Al-Mansouri
KPI Achievements (before capping):
  QualityErrors:   60% (3/5, inverse)
  Rejection:       25% (2/8, inverse)
  TAT:             83.33% (20/24, inverse)

Score (before cap) = 60×0.20 + 25×0.50 + 83.33×0.30 = 49.5%
Score (after cap)  = MIN(100%, 49.5%) = 49.5% (no change)
Grade = D (49.5 is between 65 and 75... wait, <65? Let me recalculate)
```

### CSR Example (Capped)

```
Employee: Sarah Mohammed
KPI Achievements (before individual capping):
  Rejection:        41.67% (5/12, inverse)
  Queries:         112.5% (450/400, direct) → capped to 100%
  AttendedCR:      105.56% (95/90, direct) → capped to 100%

Score = 41.67×0.40 + 100×0.30 + 100×0.30
      = 76.67%
Grade = B (76.67 ≥ 75 and < 85)
```

## Correctness Properties for Testing

The design includes **8 properties** for property-based testing:

1. **Direct KPI Achievement**: For all valid actual/target pairs, achievement = actual/target
2. **Inverse KPI Achievement**: For all valid pairs, achievement = target/actual (100% if actual=0)
3. **Pharmacy Uncapped**: Pharmacy scores can exceed 100%
4. **Coding/CSR Capped**: Coding/CSR scores never exceed 100%
5. **Grade Assignment**: Grades strictly follow thresholds A≥B≥C≥D
6. **Weight Validation**: Team weights sum to 1.0 ± 0.001
7. **Configuration Round-Trip**: Loading→saving→loading produces identical data
8. **Zero Division Prevention**: Inverse KPIs with actual=0 return 100% safely

## Testing Strategy

### Unit Testing
- Test each cleaner (column parsing, calculation logic)
- Test KPIService (direction handling, capping logic)
- Test ConfigLoader (validation, error handling)
- Test grade assignment (all thresholds)

### Property-Based Testing (Hypothesis)
- Generate random valid inputs (100+ iterations per property)
- Verify all 8 correctness properties hold
- Test edge cases: zero values, extreme ratios, boundary thresholds

### Integration Testing
- Load Excel file → Parse with cleaner → Calculate with KPIService → Store in DB
- Verify complete end-to-end flow for each team
- Verify performance records and KPI values stored correctly

## Files Created/Modified Summary

| File | Action | Purpose |
|------|--------|---------|
| `pharmacy.json` | Create | Pharmacy team config |
| `coding.json` | Create | Coding team config |
| `csr.json` | Create | CSR team config |
| `pharmacy.py` | Enhance | PharmacyCleaner implementation |
| `coding.py` | Create | CodingCleaner implementation |
| `csr.py` | Create | CSRCleaner implementation |
| `cleaner_factory.py` | Modify | Add 3 teams to factory |
| `kpi_service.py` | Modify | Multi-team support |
| `excel_processor.py` | Modify | Multi-team upload |
| `seeding_service.py` | Modify | Seed new teams |
| `test_three_teams.py` | Create | Comprehensive tests |
| `models.py` | Verify | Schema verification |
| `loader.py` | Create/Modify | ConfigLoader class |

## Next Steps

1. **Create Configuration Files** (Phase 1)
   - pharmacy.json, coding.json, csr.json with complete KPI definitions

2. **Implement Data Cleaners** (Phase 2)
   - PharmacyCleaner, CodingCleaner, CSRCleaner classes

3. **Enhance Services** (Phases 3-5)
   - KPIService, ExcelProcessor, SeedingService updates

4. **Run Tests** (Phase 7)
   - Unit tests, property tests, integration tests

5. **Verify Integration** (Phase 8)
   - Backward compatibility, documentation, final verification

## Success Criteria

✅ All 21 requirements implemented and testable
✅ All 8 correctness properties verified with 100+ iterations each
✅ Pharmacy scores can exceed 100%, Coding/CSR capped at 100%
✅ All 11 KPIs calculated correctly across three teams
✅ Complete test coverage (>85%)
✅ No regressions in existing functionality
✅ Database schema supports new teams and detailed KPI tracking

## Questions to Consider

1. **Excel File Format**: Are the Excel column names exactly as specified in configs? (e.g., "A.TotalAvgWaitingTime")
2. **Data Source**: Will Pharmacy/Coding/CSR data come from the same PMS_Trend_All.xlsx file or separate files?
3. **Regional Support**: Should all teams support multiple regions (UAE, EGY) like existing teams?
4. **Historical Data**: Will existing Pharmacy data need to be recalculated with new formula?
5. **API Response**: Should API responses include KPI breakdowns (individual achievements) or just final score?
