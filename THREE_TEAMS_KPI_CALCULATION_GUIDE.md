# Three Teams KPI Calculation Guide

Last updated: June 21, 2026

This guide covers the three professional UAE teams: Pharmacy, Coding, and CSR.

## Scoring Rule

For every KPI:

```python
if direction == "higher_better":
    achievement_ratio = (actual_value / target_value) * 100
else:
    achievement_ratio = (target_value / actual_value) * 100

effective_ratio = min(achievement_ratio, 100)
contribution = effective_ratio * weight
```

Final score:

```python
final_score = min(sum(contribution for contribution in kpis), 100)
```

This means:

- KPI achievement is uncapped and may exceed 100%.
- KPI contribution is capped by the KPI's configured weight.
- The final performance score is capped at 100%.

## Team Notes

### Pharmacy

- Pharmacy has 5 KPIs weighted at 20% each.
- Pharmacy KPI achievements may exceed 100%, but each KPI contribution is capped by its weight and the final score cannot exceed 100%.
- Typical KPI directions:
  - Waiting Time: lower is better
  - Leakage: lower is better
  - Tender Compliance: higher is better
  - ATV: higher is better
  - Prescription Contribution: higher is better

### Coding

- Coding has 3 KPIs with weights 20%, 50%, and 30%.
- KPI achievements may be calculated above 100% and are capped before contribution.
- Final score cannot exceed 100%.

### CSR

- CSR has 3 KPIs with weights 40%, 30%, and 30%.
- KPI achievements may be calculated above 100% and are capped before contribution.
- Final score cannot exceed 100%.

## Examples

### Direct KPI Above Target

```text
actual = 150
target = 100
weight = 0.20

achievement_ratio = 150
effective_ratio = 100
contribution = 20
```

### Inverse KPI Above Target

```text
actual = 2
target = 4
weight = 0.20

achievement_ratio = 200
effective_ratio = 100
contribution = 20
```

### Mixed Final Score

```text
KPI 1 achievement = 80,  weight = 0.20 -> contribution = 16
KPI 2 achievement = 120, weight = 0.30 -> contribution = 30
KPI 3 achievement = 90,  weight = 0.50 -> contribution = 45

final_score = 91
```

## Operational Summary

- Store the real KPI achievement in `achievement_ratio`.
- Store the configured KPI weight in `weight_applied`.
- Store the capped weighted result in `contribution`.
- Keep `performance_records.score` within `0..100`.
