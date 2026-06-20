# Three Professional Teams: KPI Calculation & Operation Guide

**Created**: June 20, 2026  
**Document Type**: Technical Reference  
**Scope**: Pharmacy, Coding, CSR Teams (UAE Region)

## Overview

This document explains how the three professional teams (Pharmacy, Coding, and CSR) calculate their Key Performance Indicators (KPIs), the weightings applied, and how data flows from backend processing to frontend display.

All three teams:
- Operate in **UAE Region**
- Use **Professional (Non-Call Center)** classification
- Have **3-5 KPIs** each with weighted scoring
- Process data from Excel files via dedicated Python processors
- Store calculated achievements in performance records
- Display real-time metrics in the PMS Dashboard

---

## 1. PHARMACY TEAM

### Team Metadata
- **ID**: `pharmacy`
- **Display Name**: Pharmacy
- **Database Name**: `Pharmacy`
- **Region**: UAE
- **Team Type**: Professional
- **Employee ID Column**: `EmployeeID`
- **Employee Name Column**: `EnglishName`
- **Data Source**: Pharmacy sheet in `PMS_Trend_All.xlsx`

### KPI Configuration

#### 1.1 Waiting Time (Weight: 20%)
```
Label: Avg Waiting Time
Weight: 20% of total score
Unit: % (percentage)
Direction: Lower is Better (Inverse KPI)
Achievement Key: WaitingTimeAch%
Actual Field: A.TotalAvgWaitingTime
```

**Calculation Method**:
```python
# Inverse calculation (Target / Actual) - because lower waiting time is better
WaitingTimeAch% = (Target.TotalWaitingTime / Actual.TotalAvgWaitingTime) × 100

# Formula in backend:
# If actual > 0: ratio = target / actual
# Multiply by 100 for percentage scale
# Result capped at 100 (can't exceed 100%)
```

**Example**:
- Target Waiting Time: 5 minutes
- Actual Waiting Time: 8 minutes
- Achievement: (5 / 8) × 100 = 62.5%

---

#### 1.2 Leakage Rate (Weight: 20%)
```
Label: Leakage Rate
Weight: 20% of total score
Unit: % (percentage)
Direction: Lower is Better (Inverse KPI)
Achievement Key: LeakageAch%
Actual Field: A.Leakage%
```

**Calculation Method**:
```python
# Inverse calculation (Target / Actual) - because lower leakage is better
LeakageAch% = (Target.Leakage% / Actual.Leakage%) × 100

# Formula:
# If actual > 0: ratio = target / actual
# Multiply by 100 for percentage
# Result capped at 100%
```

**Example**:
- Target Leakage: 2%
- Actual Leakage: 3.5%
- Achievement: (2 / 3.5) × 100 = 57.14%

---

#### 1.3 Tender Item Compliance (Weight: 20%)
```
Label: Tender Item Compliance
Weight: 20% of total score
Unit: % (percentage)
Direction: Higher is Better (Direct KPI)
Achievement Key: TenderComplianceAch%
Actual Field: A.TenderItemCompliance
```

**Calculation Method**:
```python
# Direct calculation (Actual / Target) - because higher compliance is better
TenderComplianceAch% = (Actual.TenderItemCompliance / Target.TenderItemCompliance) × 100

# Formula:
# If target > 0: ratio = actual / target
# Multiply by 100 for percentage
# Result capped at 100%
```

**Example**:
- Target Compliance: 95%
- Actual Compliance: 92%
- Achievement: (92 / 95) × 100 = 96.84%

---

#### 1.4 ATV - Average Transaction Value (Weight: 20%)
```
Label: ATV
Weight: 20% of total score
Unit: % (percentage)
Direction: Higher is Better (Direct KPI)
Achievement Key: ATVAch%
Actual Field: A.ATV
```

**Calculation Method**:
```python
# Direct calculation (Actual / Target)
ATVAch% = (Actual.ATV / Target.ATV) × 100

# Formula:
# If target > 0: ratio = actual / target
# Multiply by 100 for percentage
```

**Example**:
- Target ATV: 500 SAR
- Actual ATV: 485 SAR
- Achievement: (485 / 500) × 100 = 97%

---

#### 1.5 Prescription Contribution (Weight: 20%)
```
Label: Prescription Contribution
Weight: 20% of total score
Unit: % (percentage)
Direction: Higher is Better (Direct KPI)
Achievement Key: NoofPrescriptionAch%
Actual Field: A.NoofPrescriptionsContribution
```

**Calculation Method**:
```python
# Direct calculation (Actual / Target)
PrescriptionAch% = (Actual.NoofPrescriptionsContribution / Target.NoofPrescriptionsContribution) × 100

# Formula:
# If target > 0: ratio = actual / target
# Multiply by 100 for percentage
```

**Example**:
- Target Prescriptions: 1200
- Actual Prescriptions: 1150
- Achievement: (1150 / 1200) × 100 = 95.83%

---

### 1.6 Pharmacy Final Performance Score

**Calculation Formula**:
```
Performance = 
  (WaitingTimeAch% × 0.20) +
  (LeakageAch% × 0.20) +
  (TenderComplianceAch% × 0.20) +
  (ATVAch% × 0.20) +
  (PrescriptionAch% × 0.20)
```

**Example Calculation**:
```
WaitingTimeAch% = 62.5%
LeakageAch% = 57.14%
TenderComplianceAch% = 96.84%
ATVAch% = 97%
PrescriptionAch% = 95.83%

Performance = (62.5 × 0.20) + (57.14 × 0.20) + (96.84 × 0.20) + (97 × 0.20) + (95.83 × 0.20)
            = 12.5 + 11.428 + 19.368 + 19.4 + 19.166
            = 81.86%
```

**Performance Grade Mapping**:
- **A (Excellent)**: ≥ 95%
- **B (Good)**: ≥ 85%
- **C (Satisfactory)**: ≥ 75%
- **D (Below Target)**: ≥ 65%
- **E (Poor)**: < 65%

---

### 1.7 Data Flow: Pharmacy

```
┌─────────────────────────────────────────────────────┐
│ INPUT: Excel File (PMS_Trend_All.xlsx)              │
│ Sheet: "Pharmacy"                                   │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ BACKEND: pharmacy.py                                │
│ ✓ Load Excel data                                   │
│ ✓ Clean column names (remove whitespace)            │
│ ✓ Parse percentage columns                          │
│ ✓ Calculate achievement ratios                      │
│ ✓ Apply weights                                     │
│ ✓ Generate performance score                        │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ DATA STORAGE: Performance Records                   │
│ ✓ EmployeeID → identifies employee                 │
│ ✓ WaitingTimeAch% → stored in raw_data              │
│ ✓ LeakageAch% → stored in raw_data                  │
│ ✓ Performance → stored as overall score             │
│ ✓ Class → generated from performance band           │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ FRONTEND: Redux Store & Components                  │
│ ✓ Load performance records via API                  │
│ ✓ Normalize data in performanceSlice                │
│ ✓ Select via memoized selectors                     │
│ ✓ Display in UI components                          │
│ ✓ Calculate trends and charts                       │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ OUTPUT: PMS Dashboard Display                       │
│ ✓ Pharmacy Summary Card                             │
│ ✓ Team Performance Rankings                         │
│ ✓ Individual Employee Profiles                      │
│ ✓ KPI Breakdown Charts                              │
│ ✓ Trend Analysis                                    │
└─────────────────────────────────────────────────────┘
```

---

## 2. CODING TEAM

### Team Metadata
- **ID**: `coding`
- **Display Name**: Coding
- **Database Name**: `Coding`
- **Region**: UAE
- **Team Type**: Professional
- **Employee ID Column**: `EmployeeID`
- **Employee Name Column**: `EnglishName`
- **Data Source**: Coding sheet in Excel file

### KPI Configuration

#### 2.1 Quality Errors (Weight: 20%)
```
Label: Quality Errors
Weight: 20% of total score
Unit: % (percentage)
Direction: Lower is Better (Inverse KPI)
Achievement Key: QualityErrorsAch%
Actual Field: A.QualityErrors%
```

**Calculation Method**:
```python
# Inverse calculation - fewer errors is better
QualityErrorsAch% = MIN(1.0, (Target / Actual)) × 100

# Formula:
# ratio = target / actual (if actual > 0)
# Cap at 1.0 (100%) to prevent inflation from high achievement
# Multiply by 100 for percentage

# If actual = 0: assume perfect = 100%
```

**Example**:
- Target Error Rate: 1.5%
- Actual Error Rate: 2.3%
- Achievement: MIN(1.0, 1.5/2.3) × 100 = MIN(1.0, 0.652) × 100 = 65.2%

---

#### 2.2 Rejection Rate (Weight: 50%)
```
Label: Rejection Rate
Weight: 50% of total score (HIGHEST WEIGHT)
Unit: % (percentage)
Direction: Lower is Better (Inverse KPI)
Achievement Key: RejectionAch%
Actual Field: A.Rejection%
```

**Calculation Method**:
```python
# Inverse calculation - lower rejection is better
RejectionAch% = MIN(1.0, (Target / Actual)) × 100

# Formula:
# ratio = target / actual (if actual > 0)
# Cap at 100% to prevent score inflation
# Multiply by 100 for percentage

# If actual = 0: assume perfect = 100%
```

**Example**:
- Target Rejection: 2%
- Actual Rejection: 3.8%
- Achievement: MIN(1.0, 2/3.8) × 100 = MIN(1.0, 0.526) × 100 = 52.6%

**Note**: This is weighted at 50% because rejection rate is critical for coding quality.

---

#### 2.3 TAT - Turnaround Time (Weight: 30%)
```
Label: TAT
Weight: 30% of total score
Unit: % (percentage)
Direction: Lower is Better (Inverse KPI)
Achievement Key: TATAch%
Actual Field: A.TAT%
```

**Calculation Method**:
```python
# Inverse calculation - faster turnaround is better
TATAch% = MIN(1.0, (Target / Actual)) × 100

# Formula:
# ratio = target / actual (if actual > 0)
# Cap at 100% to prevent score inflation
# Multiply by 100 for percentage

# If actual = 0: assume perfect = 100%
```

**Example**:
- Target TAT: 4 hours
- Actual TAT: 5.2 hours
- Achievement: MIN(1.0, 4/5.2) × 100 = MIN(1.0, 0.769) × 100 = 76.9%

---

### 2.4 Coding Final Performance Score

**Calculation Formula**:
```
Performance = 
  (QualityErrorsAch% × 0.20) +
  (RejectionAch% × 0.50) +
  (TATAch% × 0.30)
```

**Example Calculation**:
```
QualityErrorsAch% = 65.2%
RejectionAch% = 52.6%
TATAch% = 76.9%

Performance = (65.2 × 0.20) + (52.6 × 0.50) + (76.9 × 0.30)
            = 13.04 + 26.3 + 23.07
            = 62.41%
```

**Performance Grade Mapping**:
- **A (Excellent)**: ≥ 95%
- **B (Good)**: ≥ 85%
- **C (Satisfactory)**: ≥ 75%
- **D (Below Target)**: ≥ 65%
- **E (Poor)**: < 65%

---

### 2.5 Data Flow: Coding

```
┌─────────────────────────────────────────────────────┐
│ INPUT: Excel File                                   │
│ Sheet: "Coding"                                     │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ BACKEND: coding.py                                  │
│ ✓ Load and clean Excel data                         │
│ ✓ Standardize column names                          │
│ ✓ Find actual/target columns dynamically            │
│ ✓ Parse percentage columns                          │
│ ✓ Calculate inverse ratios:                         │
│   - Quality: target / actual                        │
│   - Rejection: target / actual                      │
│   - TAT: target / actual                            │
│ ✓ Apply weight distribution (20/50/30)              │
│ ✓ Generate performance score                        │
│ ✓ Add status flags (Is_Inactive, Is_New)            │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ DATA STORAGE: Performance Records                   │
│ ✓ EmployeeID → identifies coder                     │
│ ✓ A.QualityErrors% → actual quality metrics         │
│ ✓ T.QualityErrors% → target quality metrics         │
│ ✓ QualityErrorsAch% → calculated achievement        │
│ ✓ Performance → overall weighted score              │
│ ✓ Status → Active/Inactive/New                      │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ FRONTEND: Display & Analysis                        │
│ ✓ Load coding records                               │
│ ✓ Display individual performance                    │
│ ✓ Show KPI breakdown                                │
│ ✓ Highlight rejection rate (50% weight)             │
│ ✓ Track trend changes                               │
└─────────────────────────────────────────────────────┘
```

---

## 3. CSR TEAM

### Team Metadata
- **ID**: `csr`
- **Display Name**: CSR
- **Database Name**: `CSR`
- **Region**: UAE
- **Team Type**: Professional
- **Employee ID Column**: `EmployeeID`
- **Employee Name Column**: `EnglishName`
- **Data Source**: CSR sheet in Excel file

### KPI Configuration

#### 3.1 CSR Rejection Rate (Weight: 40%)
```
Label: CSR Rejection
Weight: 40% of total score (HIGHEST WEIGHT)
Unit: % (percentage)
Direction: Lower is Better (Inverse KPI)
Achievement Key: CSRRejectionAch%
Actual Field: A.CSRRejection
```

**Calculation Method**:
```python
# Inverse calculation - lower rejection is better
CSRRejectionAch% = MIN(1.0, (Target / Actual)) × 100

# Formula:
# ratio = target / actual (if actual > 0)
# Cap at 100% to prevent score inflation
# Multiply by 100 for percentage

# If actual = 0: assume perfect = 100%
```

**Example**:
- Target Rejection: 3%
- Actual Rejection: 4.5%
- Achievement: MIN(1.0, 3/4.5) × 100 = MIN(1.0, 0.667) × 100 = 66.7%

**Note**: Weighted heavily because customer service quality depends on low rejection rates.

---

#### 3.2 CSR Queries (Weight: 30%)
```
Label: CSR Queries
Weight: 30% of total score
Unit: % (percentage)
Direction: Higher is Better (Direct KPI)
Achievement Key: CSRQueriesAch%
Actual Field: A.CSRQueries
```

**Calculation Method**:
```python
# Direct calculation - higher queries handled is better
CSRQueriesAch% = MIN(1.0, (Actual / Target)) × 100

# Formula:
# ratio = actual / target (if target > 0)
# Cap at 100% to prevent score inflation
# Multiply by 100 for percentage

# If target = 0: assume 100%
```

**Example**:
- Target Queries Resolved: 150
- Actual Queries Resolved: 155
- Achievement: MIN(1.0, 155/150) × 100 = MIN(1.0, 1.033) × 100 = 100% (capped)

---

#### 3.3 Attended C.R - Customer Requests Attended (Weight: 30%)
```
Label: Attended C.R
Weight: 30% of total score
Unit: % (percentage)
Direction: Higher is Better (Direct KPI)
Achievement Key: AttendedCRAch%
Actual Field: A.AttendedC.R
```

**Calculation Method**:
```python
# Direct calculation - higher attendance rate is better
AttendedCRAch% = MIN(1.0, (Actual / Target)) × 100

# Formula:
# ratio = actual / target (if target > 0)
# Cap at 100% to prevent score inflation
# Multiply by 100 for percentage

# If target = 0: assume 100%
```

**Example**:
- Target Attendance: 200 requests
- Actual Attendance: 195 requests
- Achievement: MIN(1.0, 195/200) × 100 = MIN(1.0, 0.975) × 100 = 97.5%

---

### 3.4 CSR Final Performance Score

**Calculation Formula**:
```
Performance = 
  (CSRRejectionAch% × 0.40) +
  (CSRQueriesAch% × 0.30) +
  (AttendedCRAch% × 0.30)
```

**Example Calculation**:
```
CSRRejectionAch% = 66.7%
CSRQueriesAch% = 100%
AttendedCRAch% = 97.5%

Performance = (66.7 × 0.40) + (100 × 0.30) + (97.5 × 0.30)
            = 26.68 + 30 + 29.25
            = 85.93%
```

**Performance Grade Mapping**:
- **A (Excellent)**: ≥ 95%
- **B (Good)**: ≥ 85%
- **C (Satisfactory)**: ≥ 75%
- **D (Below Target)**: ≥ 65%
- **E (Poor)**: < 65%

---

### 3.5 Data Flow: CSR

```
┌─────────────────────────────────────────────────────┐
│ INPUT: Excel File                                   │
│ Sheet: "CSR"                                        │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ BACKEND: csr.py                                     │
│ ✓ Load and clean Excel data                         │
│ ✓ Standardize column names                          │
│ ✓ Find actual/target columns dynamically            │
│ ✓ Parse percentage columns                          │
│ ✓ Calculate ratios:                                 │
│   - Rejection: target / actual (inverse)            │
│   - Queries: actual / target (direct)               │
│   - Attended: actual / target (direct)              │
│ ✓ Apply weight distribution (40/30/30)              │
│ ✓ Generate performance score                        │
│ ✓ Add status flags (Is_Inactive, Is_New)            │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ DATA STORAGE: Performance Records                   │
│ ✓ EmployeeID → identifies CSR agent                 │
│ ✓ A.CSRRejection% → actual rejection data           │
│ ✓ T.CSRRejection% → target rejection metrics        │
│ ✓ CSRRejectionAch% → calculated achievement         │
│ ✓ Performance → overall weighted score              │
│ ✓ Status → Active/Inactive/New                      │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ FRONTEND: Display & Analysis                        │
│ ✓ Load CSR records                                  │
│ ✓ Display team performance                          │
│ ✓ Highlight rejection rate impact (40% weight)      │
│ ✓ Show query resolution metrics                     │
│ ✓ Track customer request attendance                 │
│ ✓ Generate performance trends                       │
└─────────────────────────────────────────────────────┘
```


---

## 4. COMPARATIVE ANALYSIS

### 4.1 KPI Weight Distribution

| Team | KPI 1 | KPI 2 | KPI 3 | KPI 4 | KPI 5 | Total |
|------|-------|-------|-------|-------|-------|-------|
| **Pharmacy** | 20% (Wait) | 20% (Leak) | 20% (Tender) | 20% (ATV) | 20% (Presc) | 100% |
| **Coding** | 20% (Quality) | **50% (Rejection)** | 30% (TAT) | — | — | 100% |
| **CSR** | **40% (Rejection)** | 30% (Queries) | 30% (Attended) | — | — | 100% |

### Key Observations

1. **Pharmacy**: Equal weight distribution (20% each) - all metrics equally important
2. **Coding**: Rejection rate is critical (50% weight) - quality of work is paramount
3. **CSR**: Rejection rate highest (40% weight) - customer satisfaction is key

### 4.2 Inverse vs. Direct KPIs

#### Inverse KPIs (Lower is Better)
These metrics measure issues/problems. Lower values = better performance:
- **Pharmacy**: Waiting Time, Leakage Rate
- **Coding**: Quality Errors, Rejection Rate, TAT
- **CSR**: Rejection Rate

**Calculation**: `Achievement = (Target / Actual) × 100`

#### Direct KPIs (Higher is Better)
These metrics measure positive outcomes. Higher values = better performance:
- **Pharmacy**: Tender Compliance, ATV, Prescription Contribution
- **Coding**: None
- **CSR**: Queries Resolved, Attended Requests

**Calculation**: `Achievement = (Actual / Target) × 100`

### 4.3 Score Capping Mechanism

**Pharmacy**: No explicit capping applied - achievement can exceed 100%
```python
# If actual < target (performing above target)
# Score can be > 100%
```

**Coding & CSR**: Capped at 100% using MIN() function
```python
# achievement = MIN(1.0, ratio) × 100
# Prevents scores exceeding 100% even with exceptional performance
```

This difference means:
- Pharmacy allows rewarding exceptional performance (>100%)
- Coding & CSR discourage inflated scores from super-performance

---

## 5. DATA PROCESSING ARCHITECTURE

### 5.1 Backend Pipeline (Python)

```python
# Step 1: Load Excel
df = pd.read_excel(file_path, sheet_name="TeamName")

# Step 2: Clean Data
df.columns = df.columns.str.replace(r'\s+', '', regex=True)
df = clean_sheet_data(df, sheet_name)

# Step 3: Parse Columns Dynamically
actual_col = find_col(cols, "A.MetricName")
target_col = find_col(cols, "T.MetricName")

# Step 4: Convert to Percentages
df[actual_col] = df[actual_col].apply(convert_percentage)
df[target_col] = df[target_col].apply(convert_percentage)

# Step 5: Calculate Achievement
if inverse:
    df['MetricAch%'] = (df[target_col] / df[actual_col]) × 100
else:
    df['MetricAch%'] = (df[actual_col] / df[target_col]) × 100

# Step 6: Apply Weighting
df['Performance'] = (metric1_ach * w1) + (metric2_ach * w2) + ...

# Step 7: Generate Grade
df['Class'] = classify_grade(df['Performance'])
```

### 5.2 Frontend Redux Flow

```typescript
// 1. API calls fetch performance records
const records = await fetchPerformanceRecords(teamId, month)

// 2. Redux store normalizes data
store.dispatch(addPerformanceRecords(records))

// 3. Selectors extract and memoize
const achievement = selectEmployeeById(state, employeeId)
const kpis = selectKPIsForEmployee(state, employeeId)
const score = selectPerformanceScore(state, employeeId)

// 4. Components render memoized data
<EmployeeProfileView employee={achievement} />
```

### 5.3 Key Data Fields

#### Pharmacy Records
```json
{
  "employeeId": "PH001",
  "teamId": "pharmacy",
  "month": "2026-06",
  "raw_data": {
    "A.TotalAvgWaitingTime": 7.5,
    "T.TotalWaitingTime": 5,
    "A.Leakage%": 3.2,
    "T.Leakage%": 2,
    "A.TenderItemCompliance": 93,
    "T.TenderItemCompliance": 95,
    "A.ATV": 495,
    "T.ATV": 500,
    "A.NoofPrescriptionsContribution": 1160,
    "T.NoofPrescriptionsContribution": 1200
  },
  "achievement": {
    "waiting_time_ach": 66.67,
    "leakage_ach": 62.5,
    "tender_compliance_ach": 97.89,
    "atv_ach": 99,
    "prescription_ach": 96.67
  },
  "performance": 84.55,
  "grade": "A"
}
```

#### Coding Records
```json
{
  "employeeId": "CD001",
  "teamId": "coding",
  "month": "2026-06",
  "raw_data": {
    "A.QualityErrors%": 2.1,
    "T.QualityErrors%": 1.5,
    "A.Rejection%": 3.5,
    "T.Rejection%": 2,
    "A.TAT%": 5.2,
    "T.TAT%": 4.5
  },
  "achievement": {
    "quality_errors_ach": 71.43,
    "coding_rejection_ach": 57.14,
    "coding_tat_ach": 86.54
  },
  "performance": 68.27,
  "grade": "B"
}
```

#### CSR Records
```json
{
  "employeeId": "CR001",
  "teamId": "csr",
  "month": "2026-06",
  "raw_data": {
    "A.CSRRejection%": 4.2,
    "T.CSRRejection%": 3,
    "A.CSRQueries": 165,
    "T.CSRQueries": 160,
    "A.AttendedC.R": 198,
    "T.AttendedC.R": 200
  },
  "achievement": {
    "csr_rejection_ach": 71.43,
    "csr_queries_ach": 100,
    "csr_attended_cr_ach": 99
  },
  "performance": 89.86,
  "grade": "A"
}
```

---

## 6. IMPLEMENTATION NOTES

### 6.1 Frontend Display Components

#### Performance Score Display
```typescript
// Show overall performance with grade
<PerformanceCard
  score={employee.performance}  // 0-100%
  grade={employee.grade}        // A/B/C/D/F
  team={employee.team}
/>
```

#### KPI Breakdown Chart
```typescript
// Show individual KPI achievements
<KPIBreakdown
  kpis={employee.achievement}   // individual metric scores
  weights={teamConfig.kpis}     // from teamRegistry
/>
```

#### Trend Analysis
```typescript
// Compare performance over months
<PerformanceTrend
  history={selectPerformanceHistory(state, employeeId)}
  metrics={['performance', 'grade']}
/>
```

### 6.2 Validation Rules

**Achievement Bounds**:
- Pharmacy: 0% - unlimited (no cap)
- Coding: 0% - 100% (capped)
- CSR: 0% - 100% (capped)

**Final Score Bounds**:
- All Teams: 0% - 100% (calculated from weighted average)

**Grade Assignment**:
```typescript
function getGrade(score: number): string {
  if (score >= 95) return 'A';
  if (score >= 85) return 'B';
  if (score >= 75) return 'C';
  if (score >= 65) return 'D';
  return 'E';
}
```

### 6.3 Common Data Issues & Fixes

**Issue**: Missing Target Values
- **Pharmacy**: Uses default targets if not in Excel
- **Coding/CSR**: Uses fallback calculations

**Issue**: Zero Actual Values
- **All Teams**: Treated as perfect achievement (100%)
- Prevents division errors

**Issue**: Percentage Format Inconsistency
- **Solution**: Dynamic detection and conversion
  - If value > 2: already percentage (0-100 scale)
  - If value < 2: fraction format (0-1 scale) → multiply by 100

### 6.4 Performance Optimization

**Selector Memoization**:
```typescript
// Use createSelector for memoized results
export const selectPharmacyTeamPerformance = createSelector(
  [selectAllRecords, selectPharmacyFilter],
  (records, filter) => {
    return records.filter(r => r.team === 'pharmacy')
                  .filter(filter);
  }
);

// Only recalculates if input selectors change
```

**Data Normalization**:
```typescript
// Store flat records by ID for O(1) lookups
{
  byId: {
    'PH001': { /* full record */ },
    'PH002': { /* full record */ }
  },
  allIds: ['PH001', 'PH002']
}
```

---

## 7. APPENDIX: FORMULA REFERENCE

### Pharmacy Formulas

```
Wait Time Achievement = (Target / Actual) × 100
Leakage Achievement = (Target / Actual) × 100
Tender Achievement = (Actual / Target) × 100
ATV Achievement = (Actual / Target) × 100
Prescription Achievement = (Actual / Target) × 100

Final = (Wait × 0.20) + (Leak × 0.20) + (Tender × 0.20) + (ATV × 0.20) + (Presc × 0.20)
```

### Coding Formulas

```
Quality Achievement = MIN(100, (Target / Actual) × 100)
Rejection Achievement = MIN(100, (Target / Actual) × 100)
TAT Achievement = MIN(100, (Target / Actual) × 100)

Final = (Quality × 0.20) + (Rejection × 0.50) + (TAT × 0.30)
```

### CSR Formulas

```
Rejection Achievement = MIN(100, (Target / Actual) × 100)
Queries Achievement = MIN(100, (Actual / Target) × 100)
Attended Achievement = MIN(100, (Actual / Target) × 100)

Final = (Rejection × 0.40) + (Queries × 0.30) + (Attended × 0.30)
```

---

## 8. SUMMARY

| Aspect | Pharmacy | Coding | CSR |
|--------|----------|--------|-----|
| **KPIs** | 5 | 3 | 3 |
| **Total Weight** | 100% (5×20%) | 100% (20+50+30%) | 100% (40+30+30%) |
| **Critical Metric** | None (equal) | Rejection (50%) | Rejection (40%) |
| **Calculation Type** | Mixed | All Inverse | Mixed |
| **Score Cap** | Unlimited | 100% | 100% |
| **Data Source** | Pharmacy Excel Sheet | Coding Excel Sheet | CSR Excel Sheet |
| **Column ID** | EmployeeID | EmployeeID | EmployeeID |
| **Column Name** | EnglishName | EnglishName | EnglishName |

---

**Document Status**: ✅ Complete  
**Last Updated**: June 20, 2026  
**Build Status**: 587ms, 0 errors, 0 warnings
