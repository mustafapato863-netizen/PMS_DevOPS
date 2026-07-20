# Monthly Performance Report Builder - Implementation

## Supported Layouts
- **Blank / Custom:** 16:9 canvas allowing arbitrary stacking of standard blocks.
- **Title Slide:** Handled automatically for the first slide of a generated presentation, injecting report name and scope dynamically.
- **Predefined Story Templates:** Executive, Team, Position, Employee, Grade Distribution, Corrective Actions, KPI, Data Quality.

## Supported Block Types
1. **Title Block (`title`)**: Simple text block for headers.
2. **Narrative Text (`narrative`)**: Text block capable of receiving AI-generated deterministic summaries based on KPI direction (higher is better vs lower is better).
3. **KPI Summary (`kpi_summary`)**: 3-column highlighted numbers.
4. **Bar Chart (`bar_chart`)**: Displays comparisons.
5. **Line Chart (`line_chart`)**: Displays trends.
6. **Data Table (`data_table`)**: Flexible rows and columns.

## PowerPoint Generation Method
- Native generation via `python-pptx` (Version 1.0.2).
- Replaces legacy raw OpenXML string construction, eliminating brittle string concatenation risks when producing charts and complex layouts.
- Renders deterministic layouts sequentially on the slide master (SlideLayout 5 - Blank/Title Only).

## Narrative Generation Rules
- Located in `services.narrative_engine.generate_narrative`.
- Deterministic approach analyzing `record_count`, `grade_distribution`, and `status_distribution` from the scope payload.
- Automatically sets the title configuration for `narrative` blocks before passing them to the PPTX builder.

## Permission Behavior
- Adheres strictly to the existing `PERMISSION_MATRIX`.
- `useReportOptions` returns only valid regions, teams, and employees allowed for the user's role.
- Generation validates that the selected configuration parameters intersect with the user's allowed scope.

## Deferred Capabilities
- Direct interactive chart editing on the canvas (currently uses form-based settings).
- Custom font and color palette injection (hardcoded to PMS branding).
- Complex grid layouts on a single slide (currently vertically stacks blocks).

## Risks Requiring Manual Review
- `python-pptx` chart API is powerful but complex; the `pptx_builder.py` currently uses shapes as placeholders for charts until the actual chart API calls are fully integrated in a follow-up phase.
