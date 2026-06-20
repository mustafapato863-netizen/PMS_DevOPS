# Implementation Plan: Three Teams KPI Implementation

## Overview

This implementation plan breaks down the three-teams KPI addition into discrete, incremental tasks. Each task builds on previous work, ensuring core functionality is validated early through code. The tasks follow a logical progression from configuration setup → data cleaning → KPI calculation → service integration → testing.

## Task Dependency Graph

```json
{
  "waves": [
    {"wave": 1, "title": "Configuration Setup", "tasks": ["1", "2", "3"]},
    {"wave": 2, "title": "Config Validation & Factory", "tasks": ["4", "3.1", "8", "8.1"]},
    {"wave": 3, "title": "Data Cleaners & Properties", "tasks": ["5", "6", "7", "5.1", "5.2", "5.3", "6.1", "6.2", "7.1", "7.2"]},
    {"wave": 4, "title": "Models & Database", "tasks": ["12", "13", "14", "15"]},
    {"wave": 5, "title": "Services Enhancement", "tasks": ["9", "10", "10.1", "10.2", "11"]},
    {"wave": 6, "title": "Seeding & Analysis", "tasks": ["16", "16.1", "17", "18"]},
    {"wave": 7, "title": "Testing Suite", "tasks": ["20", "20.1", "20.2", "20.3"]},
    {"wave": 8, "title": "Test Execution", "tasks": ["21", "22"]},
    {"wave": 9, "title": "Final Validation", "tasks": ["19", "23", "24", "25"]}
  ],
  "dependencies": {
    "1": [], "2": [], "3": [],
    "3.1": ["1", "2", "3"],
    "4": ["1", "2", "3"],
    "5": ["4"], "6": ["4"], "7": ["4"],
    "5.1": ["5"], "5.2": ["5"], "5.3": ["5"],
    "6.1": ["6"], "6.2": ["6"],
    "7.1": ["7"], "7.2": ["7"],
    "8": ["5", "6", "7"],
    "8.1": ["8"],
    "9": ["4"],
    "10": ["9", "4"],
    "10.1": ["10"], "10.2": ["10"],
    "11": ["8", "8.1", "10"],
    "12": [], "13": [], "14": [],
    "15": ["12", "13", "14"],
    "16": ["4", "15"],
    "16.1": ["16"],
    "17": ["10"],
    "18": ["10"],
    "19": ["5", "6", "7", "10", "11"],
    "20": [], "20.1": ["20"], "20.2": ["20"], "20.3": ["20"],
    "21": ["20", "20.1", "20.2", "20.3", "16.1"],
    "22": ["21"],
    "23": ["22"],
    "24": ["22"],
    "25": ["19", "22", "23", "24"]
  }
}
```

## Tasks

### Phase 1: Configuration Layer Setup

- [x] 1. Create pharmacy.json configuration file
  - Create: `Backend/config/teams/pharmacy.json`
  - Define team metadata: team="Pharmacy", db_name="Pharmacy", region="UAE"
  - Define 5 KPIs with correct weights (0.20 each): WaitingTime, Leakage, TenderCompliance, ATV, Prescription
  - Set directions: WaitingTime=lower_better, Leakage=lower_better, TenderCompliance=higher_better, ATV=higher_better, Prescription=higher_better
  - Set grade thresholds: A=95, B=85, C=75, D=65
  - Map Excel column names (A.TotalAvgWaitingTime, T.TotalWaitingTime, etc.)
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 20.1_

- [x] 2. Create coding.json configuration file
  - Create: `Backend/config/teams/coding.json`
  - Define team metadata: team="Coding", db_name="Coding", region="UAE"
  - Define 3 KPIs with weights: QualityErrors=0.20, Rejection=0.50, TAT=0.30
  - Set all directions as lower_better (inverse KPIs)
  - Set grade thresholds: A=95, B=85, C=75, D=65
  - Add capping flag: "capped_at_100"
  - Map Excel column names
  - _Requirements: 2.1, 2.2, 2.3, 20.2_

- [x] 3. Create csr.json configuration file
  - Create: `Backend/config/teams/csr.json`
  - Define team metadata: team="CSR", db_name="CSR", region="UAE"
  - Define 3 KPIs with weights: Rejection=0.40, Queries=0.30, AttendedCR=0.30
  - Set directions: Rejection=lower_better, Queries=higher_better, AttendedCR=higher_better
  - Set grade thresholds: A=95, B=85, C=75, D=65
  - Add capping flag: "capped_at_100"
  - Map Excel column names
  - _Requirements: 3.1, 3.2, 3.3, 20.3_

- [ ]* 3.1 Write property test for configuration loading
  - **Property 7: Configuration Round-Trip Consistency**
  - **Validates: Requirements 20.1, 20.2, 20.3**
  - Test that loading then saving pharmacy/coding/csr configs produces identical results
  - Verify all numeric values (weights, thresholds) maintain precision

- [x] 4. Create ConfigLoader utility class
  - Create: `Backend/config/loader.py` (or add to existing loader.py)
  - Implement `load_team_config(team_name: str) -> TeamConfig` method
  - Validate all required fields are present in JSON
  - Validate weights sum to 1.0 (within 0.001 tolerance)
  - Validate grade thresholds in descending order (A > B > C > D)
  - Raise appropriate validation errors with descriptive messages
  - _Requirements: 1.7, 2.7, 3.7, 13.1-13.5_

- [ ]* 4.1 Write unit tests for ConfigLoader
  - Test valid configuration loading for all three teams
  - Test error handling: missing fields, invalid weights, bad thresholds
  - Test weight validation with 0.001 tolerance
  - _Requirements: 19.2_

### Phase 2: Data Cleaning Layer

- [x] 5. Enhance PharmacyCleaner in pharmacy.py
  - Modify: `Backend/Data_Cleaning_Teams/pharmacy.py`
  - Implement column standardization (remove all whitespace)
  - Implement percentage parsing: handle "95%", "0.95", 95 formats
  - Implement `_parse_kpi_value()` method for safe parsing
  - Create KPI-specific calculation methods using defined weights
  - Calculate uncapped performance score: Σ(achievement_i × weight_i)
  - Apply grade assignment based on thresholds
  - Ensure all 5 KPIs are calculated: WaitingTime, Leakage, TenderCompliance, ATV, Prescription
  - _Requirements: 9.1-9.5, 4.1-4.5, 5.1-5.6_

- [ ]* 5.1 Write property test for Pharmacy direct KPI calculation
  - **Property 1: Achievement Calculation Correctness (Direct KPIs)**
  - **Validates: Requirements 4.1-4.3**
  - Generate random (actual, target) pairs where actual ≥ 0, target > 0
  - Verify: achievement = (actual/target) × 100 produces result ≥ 0
  - Test edge cases: actual=0, target=0.001, large values (10000/1)

- [ ]* 5.2 Write property test for Pharmacy inverse KPI calculation
  - **Property 2: Achievement Calculation Correctness (Inverse KPIs)**
  - **Validates: Requirements 5.1-5.6, 8.1**
  - Generate random (actual, target) pairs for inverse KPIs
  - Verify: achievement = (target/actual) × 100 when actual > 0
  - Verify: achievement = 100 when actual = 0 (no division error)
  - Test edge cases: actual=0, target=0, both zero

- [ ]* 5.3 Write property test for Pharmacy uncapped scoring
  - **Property 3: Uncapped Achievement for Pharmacy**
  - **Validates: Requirements 6.1-6.5**
  - Generate random KPI achievements with values > 100% for some KPIs
  - Verify: final_score = Σ(achievement_i × weight_i) without capping
  - Verify: score can exceed 100%
  - Test: all KPIs at 100% → score = 100%, all KPIs at 120% → score = 120%

- [x] 6. Create CodingCleaner in coding.py
  - Create: `Backend/Data_Cleaning_Teams/coding.py`
  - Implement column standardization (remove all whitespace)
  - Implement numeric parsing for all three KPIs
  - Implement achievement calculation with capping: MIN(achievement, 100)
  - Calculate capped performance score: MIN(100, Σ(achievement_i × weight_i))
  - Apply grade assignment based on thresholds
  - Ensure all 3 KPIs are calculated: QualityErrors (inverse), Rejection (inverse), TAT (inverse)
  - _Requirements: 10.1-10.5, 4.1-4.5, 5.1-5.6, 7.1-7.5_

- [ ]* 6.1 Write property test for Coding inverse KPI calculation
  - **Property 2: Achievement Calculation Correctness (Inverse KPIs)**
  - **Validates: Requirements 5.1-5.6**
  - Same as 5.2 but for Coding team's inverse KPIs

- [ ]* 6.2 Write property test for Coding capped scoring
  - **Property 4: Capped Achievement for Coding & CSR**
  - **Validates: Requirements 7.1-7.5**
  - Generate random KPI achievements for Coding team
  - Verify: each achievement capped at 100% before weighting
  - Verify: final_score = MIN(100%, Σ(...)) 
  - Test: weighted sum = 120% → capped to 100%, weighted sum = 95% → no capping

- [x] 7. Create CSRCleaner in csr.py
  - Create: `Backend/Data_Cleaning_Teams/csr.py`
  - Implement column standardization (remove all whitespace)
  - Implement numeric parsing for all three KPIs
  - Implement direct KPI calculation for Queries, AttendedCR (actual/target)
  - Implement inverse KPI calculation for Rejection (target/actual)
  - Implement capping: MIN(achievement, 100) for each KPI before weighting
  - Calculate capped performance score: MIN(100, Σ(achievement_i × weight_i))
  - Apply grade assignment based on thresholds
  - _Requirements: 11.1-11.5, 4.1-4.5, 5.1-5.6, 7.1-7.5_

- [x]* 7.1 Write property test for CSR mixed KPI types
  - Generate random data for direct (Queries, AttendedCR) and inverse (Rejection) KPIs
  - Verify: direct achievements = actual/target, inverse = target/actual
  - Verify: all achievements capped at 100% before weighting

- [ ]* 7.2 Write property test for CSR capped scoring
  - **Property 4: Capped Achievement for Coding & CSR**
  - **Validates: Requirements 7.1-7.5**
  - Same as 6.2 but for CSR team

### Phase 3: Factory & Service Integration

- [x] 8. Enhance cleaner_factory.py
  - Modify: `Backend/data_cleaning/cleaner_factory.py`
  - Add imports for PharmacyCleaner, CodingCleaner, CSRCleaner
  - Update factory mapping to include: "Pharmacy" → PharmacyCleaner, "Coding" → CodingCleaner, "CSR" → CSRCleaner
  - Test factory returns correct cleaner instance for each team
  - Verify error handling for unknown teams
  - _Requirements: 12.1-12.5_

- [ ]* 8.1 Write unit tests for cleaner factory
  - Test factory returns correct cleaner for "Pharmacy", "Coding", "CSR"
  - Test factory raises ValueError for unknown team
  - Test each cleaner instance processes data correctly

- [x] 9. Enhance data_cleaning/__init__.py
  - Modify: `Backend/data_cleaning/__init__.py`
  - Export PharmacyCleaner, CodingCleaner, CSRCleaner
  - Ensure imports do not break existing code

- [ ] 10. Enhance KPIService for multi-team support
  - Modify: `Backend/services/kpi_service.py`
  - Update `calculate_performance()` to accept team_id/team_name parameter
  - Load team configuration using ConfigLoader for the given team
  - Apply team-specific direction (direct/inverse) from configuration
  - Apply team-specific capping rule in score calculation
  - Return detailed KPIValue dict with: actual, target, achievement_ratio, weight_applied, contribution
  - Ensure PharmacyCleaner works without capping, Coding/CSR with capping
  - _Requirements: 14.1-14.5_

- [ ]* 10.1 Write property test for KPIService direction handling
  - Generate rows with mixed direct and inverse KPIs
  - Verify: direct KPIs calculate as actual/target
  - Verify: inverse KPIs calculate as target/actual

- [ ]* 10.2 Write property test for KPIService capping logic
  - **Property 4: Capped Achievement for Coding & CSR**
  - **Validates: Requirements 7.1-7.5**
  - Test KPIService applies correct capping for each team

- [ ] 11. Enhance Excel Processor for multi-team upload
  - Modify: `Backend/services/excel_processor.py`
  - Update main processing flow to accept team_name parameter
  - Use cleaner_factory to get correct cleaner for team
  - Load team configuration and KPI definitions
  - Process each row using team-specific cleaner
  - Calculate KPI values using enhanced KPIService
  - Create PerformanceRecord and KPIValue objects for each employee
  - Store relationships correctly (record_id, record_year)
  - _Requirements: 16.1-16.5_

- [ ]* 11.1 Write integration test for Pharmacy upload
  - Create sample Excel file with Pharmacy data
  - Process using Excel Processor with team="Pharmacy"
  - Verify PerformanceRecords created with correct scores/grades
  - Verify KPIValues stored with correct achievements

### Phase 4: Schema & Data Model

- [x] 12. Ensure TeamKPIConfig table structure
  - Verify: `Backend/models/models.py` has TeamKPIConfig class
  - Verify columns: id, team_id, kpi_key, kpi_label, weight, direction, unit, color, actual_col, target_col, achievement_col, capping
  - Add capping field if not present (nullable String with default "uncapped")
  - Create indexes on (team_id, kpi_key)
  - _Requirements: 21.1-21.5_

- [x] 13. Ensure KPIValue table structure
  - Verify: `Backend/models/models.py` has KPIValue class
  - Verify columns: id, record_id, record_year, kpi_key, actual_value, target_value, achievement_ratio, weight_applied, contribution
  - Ensure composite foreign key (record_id, record_year) references PerformanceRecord
  - Create indexes on (record_id, record_year) and (kpi_key)
  - _Requirements: 21.1-21.5_

- [x] 14. Ensure PerformanceRecord schema supports new teams
  - Verify: PerformanceRecord can store pharmacy, coding, csr team performance
  - Ensure team_id foreign key allows filtering by team
  - Verify composite key (id, year) works for partitioning
  - _Requirements: 18.1-18.5_

- [ ] 15. Create/run database migration
  - Verify migrations directory has migration files
  - Run alembic upgrade to ensure schema is current
  - Verify all new columns and indexes are created
  - _Requirements: 21.1_

### Phase 5: Seeding & Configuration

- [ ] 16. Enhance SeedingService for new teams
  - Modify: `Backend/services/seeding_service.py`
  - Add seed_team() method that:
    1. Loads JSON configuration for team
    2. Creates Team record if not exists
    3. Creates GradeThreshold record
    4. Creates TeamKPIConfig records (one per KPI with all details)
  - Add seed_three_teams() method that calls seed_team("Pharmacy"), seed_team("Coding"), seed_team("CSR")
  - Verify team lookup by name for duplicate check
  - Handle idempotency (don't create duplicates if run multiple times)
  - _Requirements: 17.1-17.6_

- [ ]* 16.1 Write integration test for seeding
  - Clear database of test teams
  - Run seed_three_teams()
  - Verify: Team records created with correct names
  - Verify: GradeThreshold records created with correct thresholds
  - Verify: TeamKPIConfig records created (5 for Pharmacy, 3 for Coding, 3 for CSR)
  - Verify: All teams/KPIs queryable

### Phase 6: Analysis & Services Enhancement

- [ ] 17. Review and update AnalysisService if needed
  - Verify: AnalysisService can handle new teams
  - Ensure: root cause analysis works for all 11 KPIs
  - Ensure: suggested actions appropriate for team context
  - Modify if necessary to support Pharmacy, Coding, CSR metrics
  - _Requirements: 16.5_

- [ ] 18. Review and update SchemasService if needed
  - Verify: ActualMetrics schema includes all new KPIs
  - Verify: AchievementMetrics schema includes all new KPIs
  - Add/update Pydantic schemas for Pharmacy, Coding, CSR responses
  - _Requirements: 15.1-15.3_

- [ ] 19. Checkpoint - Verify core calculations work
  - Run sample data through complete pipeline:
    - Load config → Parse data → Calculate achievements → Assign grades → Store
  - Verify: Pharmacy scores can exceed 100%
  - Verify: Coding scores capped at 100%
  - Verify: CSR scores capped at 100%
  - Verify: Correct grades assigned for each score
  - Ask user if questions arise.

### Phase 7: Testing

- [x] 20. Create comprehensive test suite
  - Create: `Backend/tests/test_three_teams.py`
  - Unit tests for each cleaner:
    - Test column standardization
    - Test percentage parsing
    - Test direct/inverse calculations
    - Test capping logic
    - Test grade assignment
  - Unit tests for KPIService:
    - Test multi-team configuration loading
    - Test achievement calculations
    - Test score calculations (capped/uncapped)
  - Integration tests:
    - Test end-to-end Excel upload for each team
    - Test performance record creation
    - Test KPI value storage and retrieval
  - _Requirements: 19.1-19.5_

- [ ]* 20.1 Write property test for grade assignment
  - **Property 5: Grade Assignment Consistency**
  - **Validates: Requirements 8.1-8.6**
  - Generate random scores across entire range
  - Verify: A for ≥95, B for ≥85<95, C for ≥75<85, D for ≥65<75, E for <65
  - Verify: no score gets multiple grades

- [ ]* 20.2 Write property test for weight validation
  - **Property 6: Weight Sum Validation**
  - **Validates: Requirements 1.7, 2.7, 3.7**
  - For each team configuration, verify weights sum to 1.0 ± 0.001

- [ ]* 20.3 Write property test for zero division prevention
  - **Property 8: Zero Division Prevention for Inverse KPIs**
  - **Validates: Requirements 5.6**
  - Generate inverse KPI data with actual=0
  - Verify: returns 100% without raising error

- [ ] 21. Run all tests and verify coverage
  - Run unit tests: ensure all team-specific logic tested
  - Run property tests: verify all properties with 100+ iterations each
  - Run integration tests: verify complete workflows
  - Check test coverage target: >85% for new code
  - Fix any failing tests before proceeding
  - _Requirements: 19.1-19.5_

- [ ] 22. Checkpoint - All tests pass
  - Ensure all tests in test_three_teams.py pass
  - Ensure no regressions in existing tests
  - Verify property tests completed 100+ iterations each
  - Ask user if questions arise.

### Phase 8: Documentation & Final Verification

- [ ] 23. Verify backward compatibility
  - Query existing teams (Inbound, Outbound, Sales, etc.)
  - Verify existing performance records unchanged
  - Verify existing KPI configurations unchanged
  - Run existing test suite to ensure no regressions
  - _Requirements: 18.1-18.5_

- [ ] 24. Documentation update
  - Add new teams to system documentation
  - Document KPI configurations and calculation formulas
  - Document when to use each team (pharmacy, coding, csr)
  - Add example calculations to README or wiki

- [ ] 25. Final integration checkpoint
  - Seed all teams including new three teams
  - Process sample Excel file for each team
  - Verify all performance records and KPI values created
  - Verify API responses include all three teams
  - Verify dashboards display all new teams correctly
  - Ask user if questions arise.

## Notes

- Tasks marked with `*` are optional testing sub-tasks. Core implementation tasks (without `*`) must be completed.
- Each property test task references a specific property from the design document for traceability.
- Configuration files (pharmacy.json, coding.json, csr.json) are prerequisites and must be created first.
- Database migrations must run successfully before seeding can proceed.
- All new code should follow existing project patterns and conventions.
- Property tests use hypothesis library and run minimum 100 iterations per property.
