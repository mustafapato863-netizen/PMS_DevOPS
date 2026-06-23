# New Team Onboarding Guide

Use this guide to add a new team with the fewest possible changes.

## Source of Truth

- Team config JSON: `Backend/config/teams/*.json`
- Team creation flow: `Backend/services/team_service.py`
- Config discovery API: `GET /api/config/teams`
- Team registry API: `GET /api/team-management/teams`
- Team weights API: `GET /api/settings/weights`
- Team-specific cleaner: `Backend/Data_Cleaning_Teams/`
- User access scope, team assignment, and notification visibility are handled centrally in auth/socket flow, not in team onboarding.

## Important Lessons From Submission Onboarding

Submission exposed two failure modes that should be treated as onboarding rules for every new team:

1. The raw Excel sheet can use a different employee ID/name column set than the legacy default. The import flow must read the values from the team config first and only fall back to legacy column names when config values are missing.
2. KPI labels in the UI can differ from the raw weight keys in the stored config. The frontend should support both the canonical config key and the legacy display key for the same KPI so weights and contributions still render.
3. Any row with `Performance Grade` equal to `-`, `New Staff`, or `Leave` must be excluded from import before scoring. This filter belongs to the raw ingestion path, not the calculated performance score.

## Required Setup

1. Add a JSON file in `Backend/config/teams/`.
2. Fill in:
   - `team`
   - `db_name`
   - `region`
   - `employee_id_col`
   - `employee_name_col`
   - `grade_thresholds`
   - `kpis`
3. Keep KPI weights summing to `1.0`.
4. Make sure each KPI includes:
   - `key`
   - `label`
   - `weight`
   - `direction`
   - `unit`
   - `color`
   - `actual_col`
   - `target_col`
5. Add a cleaner only if the Excel layout is different.
6. Register the cleaner in `Backend/data_cleaning/cleaner_factory.py` only if auto-discovery does not find it.
7. Verify the raw workbook column names for employee ID, employee name, and `Performance Grade` before import.
8. If the KPI key differs between raw config and display logic, document both names in the team onboarding notes.

## Create and Verify

1. Create the team through the normal team-management flow.
2. Confirm the team appears in:
   - `/api/config/teams`
   - `/api/team-management/teams`
   - `GET /api/settings/weights`
3. Upload a sample workbook and confirm cleaning works.
4. Check the team dashboard and employee profile for correct KPI rendering and score calculation.
5. Confirm weights and contribution values appear for every KPI card, including the new team.

## Rules

- Prefer config changes over code changes.
- Do not add hardcoded team branches unless the team has a genuinely unique rule.
- Keep the unified scoring model unchanged.
- Keep score capping and weight capping unchanged.
- Keep raw-grade exclusion in the ingestion layer, not in the scoring layer.
- Keep UI label-to-weight mapping tolerant of both legacy and canonical KPI keys.

## When Code Changes Are Needed

Only add code when the new team has:

- a different Excel structure
- a different KPI formula
- a different cleaner
- a display rule that cannot be expressed in config
- a mismatch between raw KPI keys and display labels that requires a safe fallback mapping

## Quick Checks

```powershell
cd Backend
pytest tests/test_three_teams.py -q
pytest tests/test_submission_team.py -q
pytest tests/test_services.py -q

cd ..\Frontend
npm run build
```
