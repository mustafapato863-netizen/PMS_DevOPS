# Requirements Document: Three Teams KPI Implementation

## Introduction

This document specifies the functional and technical requirements for adding support for three new teams (Pharmacy, Coding, CSR) to the PMS Dashboard. Each team has distinct KPI metrics, calculation methodologies, and achievement capping rules. The implementation must extend the existing KPI framework to handle multiple team configurations while maintaining system consistency and data integrity.

## Glossary

- **Actual**: Measured performance value from source data (Excel)
- **Target**: Expected or goal performance value from source data
- **Achievement**: Calculated ratio showing actual vs target performance (percentage)
- **Direct KPI**: Metric where higher values are better (achievement = actual / target)
- **Inverse KPI**: Metric where lower values are better (achievement = target / actual)
- **Capping**: Limiting achievement values to maximum 100% (not applicable to Pharmacy)
- **Uncapped**: Allowing achievement values to exceed 100% (Pharmacy only)
- **Performance Score**: Weighted sum of all KPI achievements for an employee in a period
- **Grade**: Letter grade (A, B, C, D, E) assigned based on performance score thresholds
- **Weight**: Percentage contribution of a KPI to final performance score (must sum to 100%)
- **Team Configuration**: JSON file defining KPIs, weights, directions, thresholds for a team
- **KPI Value**: Individual calculated achievement for a specific KPI
- **Performance Record**: Complete performance data for one employee in one period

## Requirements

### Requirement 1: Pharmacy Team KPI Configuration

**User Story:** As a system administrator, I want to configure the Pharmacy team with its specific KPI metrics and thresholds, so that the system can accurately calculate pharmacy staff performance.

#### Acceptance Criteria

1. THE System SHALL load a configuration file `Backend/config/teams/pharmacy.json` containing Pharmacy team metadata
2. WHEN the Pharmacy configuration is loaded, THE System SHALL contain exactly 5 KPI definitions with keys: WaitingTime, Leakage, TenderCompliance, ATV, Prescription
3. WHEN Pharmacy KPIs are configured, THE System SHALL assign weights such that each KPI is 20% (0.20) of total performance
4. THE System SHALL classify Pharmacy KPIs as follows:
   - WaitingTime: inverse direction (target/actual)
   - Leakage: inverse direction (target/actual)
   - TenderCompliance: direct direction (actual/target)
   - ATV: direct direction (actual/target)
   - Prescription: direct direction (actual/target)
5. THE System SHALL set Pharmacy grade thresholds to: A≥95, B≥85, C≥75, D≥65
6. WHEN a Pharmacy performance score is calculated, THE System SHALL NOT apply an upper bound limit, allowing scores to exceed 100%
7. THE System SHALL validate that Pharmacy configuration weights sum to 1.0 (100%) within 0.001 tolerance

### Requirement 2: Coding Team KPI Configuration

**User Story:** As a system administrator, I want to configure the Coding team with its specific KPI metrics and capping rules, so that the system correctly evaluates coding operations performance.

#### Acceptance Criteria

1. THE System SHALL load a configuration file `Backend/config/teams/coding.json` containing Coding team metadata
2. WHEN the Coding configuration is loaded, THE System SHALL contain exactly 3 KPI definitions with keys: QualityErrors, Rejection, TAT
3. WHEN Coding KPIs are configured, THE System SHALL assign weights: QualityErrors 20% (0.20), Rejection 50% (0.50), TAT 30% (0.30)
4. THE System SHALL classify Coding KPIs as inverse direction (lower is better)
5. THE System SHALL set Coding grade thresholds to: A≥95, B≥85, C≥75, D≥65
6. WHEN a Coding performance score is calculated, THE System SHALL apply capping at 100% using MIN(1.0, calculated_score)
7. THE System SHALL validate that Coding configuration weights sum to 1.0 (100%) within 0.001 tolerance

### Requirement 3: CSR Team KPI Configuration

**User Story:** As a system administrator, I want to configure the CSR team with its specific KPI metrics and capping rules, so that the system accurately measures CSR performance.

#### Acceptance Criteria

1. THE System SHALL load a configuration file `Backend/config/teams/csr.json` containing CSR team metadata
2. WHEN the CSR configuration is loaded, THE System SHALL contain exactly 3 KPI definitions with keys: Rejection, Queries, AttendedCR
3. WHEN CSR KPIs are configured, THE System SHALL assign weights: Rejection 40% (0.40), Queries 30% (0.30), AttendedCR 30% (0.30)
4. THE System SHALL classify CSR KPIs as: Rejection inverse, Queries direct, AttendedCR direct
5. THE System SHALL set CSR grade thresholds to: A≥95, B≥85, C≥75, D≥65
6. WHEN a CSR performance score is calculated, THE System SHALL apply capping at 100% using MIN(1.0, calculated_score)
7. THE System SHALL validate that CSR configuration weights sum to 1.0 (100%) within 0.001 tolerance

### Requirement 4: Direct KPI Achievement Calculation

**User Story:** As a performance analyst, I want direct KPIs to be calculated correctly, so that metrics where higher performance is better are represented accurately.

#### Acceptance Criteria

1. FOR direct KPIs, THE System SHALL calculate achievement using formula: achievement = (actual / target) × 100
2. WHEN target value is 0, THE System SHALL return achievement of 0% and log a warning
3. WHEN actual exceeds target, THE System SHALL allow achievement >100% for Pharmacy, or cap at 100% for Coding/CSR
4. WHEN actual = 0 and target > 0, THE System SHALL calculate achievement as 0%
5. THE System SHALL handle fractional actual/target values (e.g., 0.95) by normalizing to percentage scale if needed

### Requirement 5: Inverse KPI Achievement Calculation

**User Story:** As a performance analyst, I want inverse KPIs to calculate correctly, so that metrics where lower performance is better are represented accurately.

#### Acceptance Criteria

1. FOR inverse KPIs, THE System SHALL calculate achievement using formula: achievement = (target / actual) × 100
2. WHEN actual value is 0, THE System SHALL return achievement of 100% (no division by zero error)
3. WHEN target = 0 and actual = 0, THE System SHALL return achievement of 100%
4. WHEN target = 0 and actual > 0, THE System SHALL calculate achievement as 0%
5. THE System SHALL handle fractional target/actual values correctly
6. THE System SHALL log any inverse KPI calculations where actual = 0 for audit purposes

### Requirement 6: Performance Score Calculation - Uncapped (Pharmacy)

**User Story:** As a performance analyst, I want Pharmacy team performance scores to be uncapped, so that excellent performance can be recognized beyond 100%.

#### Acceptance Criteria

1. WHEN calculating Pharmacy performance score, THE System SHALL apply formula: score = Σ(achievement_i × weight_i) without upper bound
2. THE System SHALL allow Pharmacy performance scores to exceed 100%
3. WHEN all Pharmacy KPIs achieve 100%, THE System SHALL calculate score as 100%
4. WHEN multiple Pharmacy KPIs exceed 100%, THE System SHALL sum their weighted contributions
5. THE System SHALL NOT truncate or cap Pharmacy scores at any point in calculation

### Requirement 7: Performance Score Calculation - Capped (Coding & CSR)

**User Story:** As a performance analyst, I want Coding and CSR performance scores to be capped at 100%, so that score distribution remains bounded and comparable.

#### Acceptance Criteria

1. WHEN calculating Coding performance score, THE System SHALL apply formula: score = MIN(1.0, Σ(achievement_i × weight_i)) × 100
2. WHEN calculating CSR performance score, THE System SHALL apply formula: score = MIN(1.0, Σ(achievement_i × weight_i)) × 100
3. WHEN individual KPI achievement exceeds 100%, THE System SHALL cap it at 100% before weighting
4. WHEN weighted sum exceeds 100%, THE System SHALL cap final score at 100%
5. THE System SHALL guarantee Coding and CSR scores never exceed 100%

### Requirement 8: Grade Assignment

**User Story:** As a manager, I want performance grades to be assigned based on score thresholds, so that employee performance can be quickly assessed.

#### Acceptance Criteria

1. THE System SHALL assign grades using thresholds: A≥95, B≥85, C≥75, D≥65, E<65
2. WHEN score ≥ 95, THE System SHALL assign grade "A"
3. WHEN score ≥ 85 and < 95, THE System SHALL assign grade "B"
4. WHEN score ≥ 75 and < 85, THE System SHALL assign grade "C"
5. WHEN score ≥ 65 and < 75, THE System SHALL assign grade "D"
6. WHEN score < 65, THE System SHALL assign grade "E"

### Requirement 9: Data Cleaner for Pharmacy Team

**User Story:** As a data engineer, I want a data cleaner for Pharmacy team, so that raw Excel data is standardized before KPI calculation.

#### Acceptance Criteria

1. WHEN the Pharmacy data cleaner processes an Excel file, THE System SHALL standardize column names by removing whitespace
2. WHEN parsing percentage columns, THE System SHALL handle both "95%" (string) and 0.95 (decimal) formats
3. WHEN calculating Pharmacy KPIs, THE System SHALL use the cleaner to produce standardized actual/target pairs
4. THE System SHALL create file: `Backend/Data_Cleaning_Teams/pharmacy.py` containing PharmacyCleaner class inheriting from BaseCleaner
5. THE System SHALL ensure Pharmacy cleaner correctly identifies and parses: WaitingTime, Leakage, TenderCompliance, ATV, Prescription columns

### Requirement 10: Data Cleaner for Coding Team

**User Story:** As a data engineer, I want a data cleaner for Coding team, so that raw Excel data is standardized before KPI calculation.

#### Acceptance Criteria

1. WHEN the Coding data cleaner processes an Excel file, THE System SHALL standardize column names by removing whitespace
2. WHEN parsing numeric columns, THE System SHALL handle integers and decimals uniformly
3. THE System SHALL create file: `Backend/Data_Cleaning_Teams/coding.py` containing CodingCleaner class inheriting from BaseCleaner
4. THE System SHALL ensure Coding cleaner correctly identifies and parses: QualityErrors, Rejection, TAT columns
5. THE System SHALL ensure Coding cleaner applies capping logic during achievement calculation

### Requirement 11: Data Cleaner for CSR Team

**User Story:** As a data engineer, I want a data cleaner for CSR team, so that raw Excel data is standardized before KPI calculation.

#### Acceptance Criteria

1. WHEN the CSR data cleaner processes an Excel file, THE System SHALL standardize column names by removing whitespace
2. WHEN parsing numeric columns, THE System SHALL handle integers and decimals uniformly
3. THE System SHALL create file: `Backend/Data_Cleaning_Teams/csr.py` containing CSRCleaner class inheriting from BaseCleaner
4. THE System SHALL ensure CSR cleaner correctly identifies and parses: Rejection, Queries, AttendedCR columns
5. THE System SHALL ensure CSR cleaner applies capping logic during achievement calculation

### Requirement 12: Configuration Factory Integration

**User Story:** As a developer, I want the cleaner factory to automatically select the correct data cleaner for each team, so that processing is automated and reliable.

#### Acceptance Criteria

1. WHEN the cleaner factory receives "Pharmacy", THE System SHALL return an instance of PharmacyCleaner
2. WHEN the cleaner factory receives "Coding", THE System SHALL return an instance of CodingCleaner
3. WHEN the cleaner factory receives "CSR", THE System SHALL return an instance of CSRCleaner
4. THE System SHALL modify: `Backend/data_cleaning/cleaner_factory.py` to include all three new teams
5. WHEN an unknown team is requested, THE System SHALL raise ValueError with clear error message

### Requirement 13: KPI Configuration Loader

**User Story:** As a system architect, I want a configuration loader that validates and provides team KPI configurations, so that the system operates with correct team definitions.

#### Acceptance Criteria

1. WHEN configuration is loaded, THE System SHALL read JSON files from `Backend/config/teams/{team_name}.json`
2. WHEN JSON is invalid, THE System SHALL raise ConfigurationError with specific parsing details
3. WHEN configuration is missing required fields, THE System SHALL raise ConfigurationError listing all missing fields
4. WHEN weights do not sum to 1.0 (within 0.001 tolerance), THE System SHALL raise WeightValidationError
5. WHEN grade thresholds are not in descending order, THE System SHALL raise ThresholdValidationError

### Requirement 14: KPI Service Enhancement for Multi-Team Support

**User Story:** As a developer, I want the KPI service to support multiple team configurations, so that different teams can be processed with their specific rules.

#### Acceptance Criteria

1. WHEN KPIService.calculate_performance() is called with team_id parameter, THE System SHALL load that team's configuration
2. WHEN calculating achievements, THE System SHALL use team-specific direction (direct/inverse) from configuration
3. WHEN calculating final score, THE System SHALL apply team-specific capping rule (uncapped for Pharmacy, capped for Coding/CSR)
4. THE System SHALL modify `services/kpi_service.py` to handle team-specific configurations
5. THE System SHALL return KPIValue objects containing: actual, target, achievement, weight, contribution for each KPI

### Requirement 15: Performance Record Storage with KPI Details

**User Story:** As a data analyst, I want to store detailed KPI values with each performance record, so that performance breakdowns can be analyzed later.

#### Acceptance Criteria

1. WHEN a performance record is created, THE System SHALL also create corresponding KPIValue records for each KPI
2. EACH KPIValue SHALL store: actual, target, achievement_ratio, weight_applied, contribution
3. WHEN the performance record is stored, THE System SHALL use composite key (record_id, record_year) to track KPI values
4. THE System SHALL modify `models.KPIValue` to include all required fields for achievement tracking
5. WHEN querying performance data, THE System SHALL be able to retrieve detailed KPI breakdowns

### Requirement 16: Excel Processor Enhancement for Multi-Team Upload

**User Story:** As an administrator, I want to upload Excel files for new teams, so that performance data can be imported for Pharmacy, Coding, and CSR teams.

#### Acceptance Criteria

1. WHEN uploading an Excel file, THE System SHALL accept team name parameter (Pharmacy, Coding, or CSR)
2. WHEN processing the file, THE System SHALL use the appropriate data cleaner for that team
3. WHEN processing rows, THE System SHALL calculate KPI achievements using team-specific logic
4. THE System SHALL modify `services/excel_processor.py` to support multi-team processing
5. THE System SHALL create PerformanceRecord and KPIValue objects for all employees in the file

### Requirement 17: Seeding Service for Team Configuration

**User Story:** As a system administrator, I want to seed the database with new team configurations on initial setup, so that all teams are configured without manual intervention.

#### Acceptance Criteria

1. WHEN seeding is executed, THE System SHALL load pharmacy.json, coding.json, and csr.json
2. THE System SHALL create Team records for Pharmacy, Coding, and CSR with correct metadata
3. THE System SHALL create GradeThreshold records for each team with correct thresholds
4. THE System SHALL create TeamKPIConfig records for all KPIs (5 for Pharmacy, 3 for Coding, 3 for CSR)
5. THE System SHALL modify `services/seeding_service.py` to include all three teams
6. WHEN seeding completes, THE System SHALL verify all teams and KPIs are queryable

### Requirement 18: Data Migration and Backward Compatibility

**User Story:** As a database administrator, I want existing data to remain valid after new teams are added, so that the system maintains data integrity.

#### Acceptance Criteria

1. WHEN new teams are added, THE System SHALL not modify existing team configurations
2. WHEN new KPI definitions are added, THE System SHALL not affect existing team KPIs
3. THE System SHALL support querying and filtering by team_name for all operations
4. THE System SHALL maintain referential integrity for all foreign keys
5. WHEN existing performance records are queried, THE System SHALL return correct data without modification

### Requirement 19: Testing for Three Teams Implementation

**User Story:** As a quality engineer, I want comprehensive tests for the three teams implementation, so that correctness is verified before production deployment.

#### Acceptance Criteria

1. WHEN running unit tests, THE System SHALL test KPI calculations for all 11 KPIs across three teams
2. WHEN running unit tests, THE System SHALL test achievement calculation (direct, inverse, zero-handling, capping)
3. WHEN running integration tests, THE System SHALL test complete workflow: load config → process Excel → calculate → store
4. WHEN running property tests, THE System SHALL verify:
   - Direct KPI achievement = actual/target for all valid numeric values
   - Inverse KPI achievement = target/actual for all valid numeric values
   - Pharmacy scores can exceed 100%, Coding/CSR capped at 100%
   - Grade assignments match thresholds for all score ranges
5. THE System SHALL create file: `Backend/tests/test_three_teams.py` with comprehensive test coverage

### Requirement 20: Configuration JSON Files Creation

**User Story:** As a system architect, I want JSON configuration files for all three teams, so that team definitions are stored and versioned.

#### Acceptance Criteria

1. THE System SHALL create `Backend/config/teams/pharmacy.json` with Pharmacy team metadata and 5 KPI definitions
2. THE System SHALL create `Backend/config/teams/coding.json` with Coding team metadata and 3 KPI definitions
3. THE System SHALL create `Backend/config/teams/csr.json` with CSR team metadata and 3 KPI definitions
4. EACH configuration file SHALL include: team, db_name, region, employee_id_col, employee_name_col, grade_thresholds, kpis array
5. EACH KPI definition SHALL include: key, label, weight, direction, unit, color, actual_col, target_col, capping

### Requirement 21: Schema Updates for KPI Tracking

**User Story:** As a database architect, I want the database schema to support detailed KPI tracking, so that performance analysis queries are efficient.

#### Acceptance Criteria

1. THE System SHALL ensure TeamKPIConfig table exists with columns: id, team_id, kpi_key, kpi_label, weight, direction, unit, color, actual_col, target_col, achievement_col, capping, display_order
2. THE System SHALL ensure KPIValue table exists with columns: id, record_id, record_year, kpi_key, actual_value, target_value, achievement_ratio, weight_applied, contribution
3. THE System SHALL create indexes on (team_id, kpi_key) for quick config lookups
4. THE System SHALL create indexes on (record_id, record_year) for KPI value queries
5. WHEN querying performance data, THE System SHALL be able to retrieve complete KPI breakdowns efficiently
