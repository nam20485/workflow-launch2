# PCB Renderer Development Plan (Final)

## Timeline: 2 Calendar Days

Heavy AI assistance for implementation and testing.

## Technology Stack

- **Python 3.11+**: Fast implementation, easy review
- **Pydantic v2**: Schema validation with automatic error generation
- **NumPy**: Coordinate transforms
- **Matplotlib**: All output formats (SVG/PNG/PDF) via single `savefig()` API
- **pytest**: Testing framework
- **uv**: Package manager with lockfile

## Phase 1: Core Models & Parsing (4 hours)

### Objectives
- Define Pydantic models for all PCB elements
- Implement unit normalization (microns → mm)
- Parse coordinates from multiple formats
- Handle component transforms

### Deliverables
- `models.py`: Board, Component, Trace, Via, Keepout models
- `parse.py`: JSON loading with unit normalization
- `geometry.py`: Point, Polygon, Polyline primitives

### Validation Built-In
Pydantic validators catch:
- Non-finite coordinates (NaN, Inf)
- Negative widths/diameters
- Via holes ≥ outer diameter
- Polygons with <3 points

## Phase 2: Validation Layer (3 hours)

### Objectives
- Implement 14 error detection rules
- Use provided board files to map errors
- Return structured error objects

### Deliverables
- `validate.py`: All validation rules
- `errors.py`: Error codes and messages

### Error Mapping to Provided Boards
Test each of ~20 boards and document which demonstrates which error:
- `board_kappa.json` → trace with single point
- `board_theta.json` → via references nonexistent net
- `board_eta.json` → negative trace width
- etc.

### Error Codes
1. `MISSING_BOUNDARY` - No boundary defined
2. `MALFORMED_COORDINATES` - Invalid coordinate data
3. `INVALID_ROTATION` - Rotation outside 0-360°
4. `DANGLING_TRACE` - Trace references nonexistent net/layer
5. `NEGATIVE_WIDTH` - Trace/via has ≤0 dimension
6. `EMPTY_BOARD` - No components or traces
7. `INVALID_VIA_GEOMETRY` - Hole ≥ diameter
8. `NONEXISTENT_LAYER` - Feature on undefined layer
9. `NONEXISTENT_NET` - Feature on undeclared net
10. `SELF_INTERSECTING_BOUNDARY` - Board outline crosses itself
11. `COMPONENT_OUTSIDE_BOUNDARY` - Component placed beyond edge
12. `INVALID_PIN_REFERENCE` - Pin references wrong component
13. `MALFORMED_STACKUP` - Layer stack incomplete
14. `INVALID_UNIT_SPECIFICATION` - Unknown designUnits

## Phase 3: Coordinate System & Transforms (2 hours)

### Objectives
- Define ECAD coordinate system (origin bottom-left, +Y up)
- Implement Y-axis inversion for SVG output
- Handle component rotation and back-side mirroring

### Coordinate System Spec
- **ECAD**: Origin (0,0) at bottom-left, +X right, +Y up
- **SVG**: Origin top-left, +X right, +Y down
- **Conversion**: Apply Y-flip at render time only

### Transform Pipeline
For each component:
1. Translate to position
2. Rotate around centroid
3. Mirror if back-side (X-axis mirror for X-ray view)
4. Convert ECAD → SVG coordinates

### Deliverables
- `transform.py`: Coordinate conversions and transforms

## Phase 4: Rendering Engine (5 hours)

### Objectives
- Render all required elements with Matplotlib
- Support SVG/PNG/PDF output
- Implement professional ECAD styling defaults
- Ensure reference designators are readable (halo effect)

### Render Order (Deterministic)
1. Board boundary (black outline, no fill)
2. Copper pours (low opacity)
3. Traces (layer colors, proper width)
4. Vias (filled circles)
5. Component outlines
6. Reference designators (with halo)
7. Keepouts (hatched overlay)

### Layer Colors (Hardcoded Defaults)
- TOP: `#CC0000` (red)
- BOTTOM: `#0000CC` (blue)
- Inner layers: greens/purples
- Keepouts: red with `hatch='///'`

### Optional Color Config
Single file `colors.py` with dict:
```python
LAYER_COLORS = {
    'TOP': '#CC0000',
    'BOTTOM': '#0000CC',
    # ... expert users can edit
}
```

### Deliverables
- `render.py`: Main rendering logic
- `colors.py`: Optional color constants

## Phase 5: CLI (2 hours)

### Command Structure
```bash
python render.py input.json -o output.svg [--format svg] [--verbose] [--quiet]
```

### Arguments
- Positional: `input.json` (required)
- `-o, --output`: Output path (required)
- `--format`: svg|png|pdf (auto-detect from extension if omitted)
- `--verbose`: Progress messages (default: on)
- `--quiet`: Non-interactive mode, exit code only
- `--help`: Usage

### Behavior
- **Valid board**: Render, exit 0
- **Invalid board**: Print errors, exit 1
- **Verbose**: "Loading...", "Validating...", "Rendering..."
- **Quiet**: Only "Success" or error summary

### Deliverables
- `cli.py`: Argument parsing and orchestration
- `__main__.py`: Entry point

## Phase 6: Testing (4 hours)

### Unit Tests
- Geometry primitives (Point, Polygon)
- Coordinate transforms
- Unit normalization
- Pydantic validation triggers

### Integration Tests
- Load all ~20 provided boards
- Assert invalid boards produce correct error codes
- Assert valid boards render without errors

### Test Structure
```
tests/
  test_models.py      # Pydantic validation
  test_parse.py       # Unit normalization, coord parsing
  test_validate.py    # 14 error conditions
  test_transform.py   # Coordinate conversions
  test_render.py      # Rendering doesn't crash
  test_boards.py      # All provided boards
```

### No Snapshot Testing
Manual visual verification of rendered outputs is acceptable.

## Phase 7: CI/CD (1 hour)

### GitHub Actions Workflow
- Matrix: Windows, macOS, Linux × Python 3.11, 3.12
- Steps: checkout, setup Python, `uv sync`, `pytest`, `ruff`, `pyright`
- Coverage: `pytest-cov` with 80% minimum

### Local Development
- `uv sync` to install deps
- `pytest` to run tests
- `ruff check` for linting
- `pyright` for type checking

## Phase 8: Documentation (2 hours)

### README Structure
- Purpose and scope
- Installation (`uv sync`)
- Usage examples
- Error codes reference
- Testing (`pytest`)
- **Future Work** (empty outline section)

### Docstrings
- Google style for all public functions
- Type hints mandatory

## Total Timeline

- Phase 1: 4 hours
- Phase 2: 3 hours
- Phase 3: 2 hours
- Phase 4: 5 hours
- Phase 5: 2 hours
- Phase 6: 4 hours
- Phase 7: 1 hour
- Phase 8: 2 hours

**Total: 23 hours over 2 calendar days**

## Risk Mitigation

**Geometric edge cases**: Use Pydantic validators to catch early
**Platform differences**: CI matrix catches issues
**Time pressure**: AI assists with test generation and boilerplate

## Success Criteria

1. All 14 invalid boards detected correctly
2. Valid boards render with readable output
3. Code reviewable in 20 minutes:
   - Clear structure
   - Well-commented
   - Example outputs included
4. Tests pass on all platforms
5. Exit codes communicate success/failure
