# Final Decisions & Simplification Summary

**Purpose**
This document captures *all final decisions*, resolved ambiguities, and agreed simplifications for the Quilter PCB Renderer challenge. It is intended as a clean handoff reference for generating the final, simplified versions of the four core documents:

1. Development Plan
2. Architecture Guide
3. Implementation Guide
4. LLM Plugin Architecture

This reflects the *current, final state* of design intent and scope.

---

## 1. Rendering View & Coordinate System (Finalized)

### 1.1 Board View Model

**Decision:**
- The renderer uses a **top-down X-ray view**.
- Bottom-layer features are rendered **as seen through the board from the top**, i.e. mirrored horizontally (X-axis mirror) but *not* vertically flipped relative to the board outline.

**Rationale:**
- Matches common ECAD viewer conventions.
- Avoids mental gymnastics when visually correlating top and bottom features.
- Naturally supports semi-transparent middle layers.

### 1.2 Coordinate System

**Decision:**
- Industry-standard ECAD coordinate system:
  - Origin `(0, 0)` at **bottom-left** of the board
  - +X to the **right**
  - +Y **upwards**

**Internal Handling:**
- Internally preserve ECAD coordinates.
- Convert to screen/SVG coordinates at render time (Y-axis inversion only at final stage).

---

## 2. Validation Philosophy

### 2.1 Strict by Default

**Decision:**
- The renderer is **strict by default**.
- Invalid boards:
  - Do **not** render
  - Exit with **non-zero status code (1)**

### 2.2 Permissive Mode

**Decision:**
- A permissive mode may exist, but:
  - Must be **explicitly enabled via flag**
  - Is **non-core** and may be stubbed or lightly implemented

### 2.3 No Autofixes

**Decision:**
- No automatic geometry fixes.
- Invalid primitives are **not rendered**.

**Rationale:**
- Prevents hiding data errors.
- Aligns with validation-focused intent of the challenge.

---

## 3. CLI Design (Simplified)

### 3.1 Required CLI Shape

**Decision:**
- Single command, no subcommands.
- Required output flag:

```bash
python render.py input.json -o output.svg
```

### 3.2 Supported Options

**Included:**
- `--help`
- `--format` (svg / png / pdf)
- `--verbose` (progress output)
- `--quiet` or non-interactive mode:
  - No progress output
  - Success/failure only
  - Exit code communicates result

**Excluded:**
- No batch mode
- No multiple subcommands

---

## 4. Configuration & Styling

### 4.1 Styling Defaults

**Decision:**
- Hardcoded, professional ECAD defaults:
  - Top layer: **Red**
  - Bottom layer: **Blue**
  - Inner layers: muted greens/purples
  - Keepouts: hatched

### 4.2 Configuration Files

**Decision:**
- No general configuration system.
- At most:
  - A single optional constants file for colors/styles
  - Editable by advanced users if desired

---

## 5. Testing Strategy

### 5.1 Use Provided Boards

**Decision:**
- Use the ~20 provided board JSON files directly.
- Do *not* generate synthetic invalid boards.

### 5.2 Invalid Boards

**Decision:**
- Each invalid board maps to a specific error condition.
- Tests assert:
  - Correct error code
  - Correct failure behavior

### 5.3 Test Scope

**Included:**
- Basic unit tests (geometry, parsing, transforms)
- Validation tests for all required invalid cases

**Excluded:**
- Snapshot/image-diff testing
- CI/CD automation

---

## 6. Technology Choices

### 6.1 Language & Libraries

**Final Choices:**
- Python 3.11+
- Pydantic v2 for schema validation
- NumPy for transforms
- Matplotlib for rendering (SVG/PNG/PDF)

**Rationale:**
- Fast to implement
- Easy to review
- Deterministic output

---

## 7. LLM Plugin Architecture (Separated)

### 7.1 Separation of Concerns

**Decision:**
- LLM integration is **fully decoupled** from core renderer.
- Main app exposes a **stable interface** only.

### 7.2 Core App Responsibilities

- Parse board
- Validate board
- Produce:
  - Normalized geometry
  - Structured validation errors
  - Optional metadata summary

### 7.3 LLM Plugin Responsibilities

- Consume structured outputs
- Generate:
  - Natural-language explanations
  - Debug summaries
  - Suggestions (non-authoritative)

### 7.4 Documentation Requirement

**Decision:**
- LLM plugin has its **own design doc**.
- Main docs must describe:
  - Plugin boundary
  - Data contract
  - No runtime dependency on LLM

---

## 8. Timeline Reality & Scope Control

**Target:**
- ~2 calendar days
- Heavy AI assistance for:
  - Tests
  - LLM plugin implementation

**Scope Discipline:**
- Implement *only* what directly supports challenge requirements.
- Favor clarity and correctness over extensibility.

---

## 9. Open Items (Explicitly Deferred)

None blocking.
All major ambiguities have been resolved or consciously deferred beyond scope.

---

## 10. Next Step

Use this document as the authoritative reference to:
- Regenerate the **final simplified versions** of the four core markdown documents.

This document should not require further edits before that step.

