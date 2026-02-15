**Application Implementation Specification: PCB Renderer CLI**

### **New Application**

**App Title:** PCB Board Renderer CLI

**Version:** 0.1.0

### **Development Plan**

**Summary:**

The development strategy adopts a phased, correctness-first approach designed to meet the strict "20-minute review" constraint while ensuring robust geometric handling.

1. **Foundation (Phase 1):** Define strict Pydantic models for the ECAD schema (Board, Component, Trace, Via) and implement the parsing logic that immediately normalizes all input units (mils, microns, inches) to millimeters.  
2. **Transforms (Phase 2):** Implement the geometric transformation pipeline using Numpy. This handles component rotations, translations, and mirroring (for bottom-layer components) to map local component coordinates to board-space coordinates.  
3. **Rendering (Phase 3):** Build the rendering engine using Matplotlib. This abstracts the drawing logic, allowing support for SVG, PNG, and PDF outputs as required by the spec.  
4. **Validation & Testing (Phase 4):** Implement the validation engine to detect the 14 specific error classes defined in the challenge. Establish property-based tests (Hypothesis) for geometric invariants and snapshot tests (Syrupy) for visual regression prevention.  
5. **CLI & Polish (Phase 5):** Wrap functionality in a user-friendly CLI, finalize documentation, and ensure the project is packaging-ready with uv.

### **Description**

A lightweight, high-performance Command Line Interface (CLI) tool designed to parse ECAD JSON files and render them into accurate visual representations (SVG, PNG, PDF). The application focuses on geometric correctness, handling complex coordinate transformations, and validating board integrity against a strict set of rules. It operates entirely offline and generates deterministic output suitable for automated regression testing.

### **Overview**

The PCB Renderer serves as a bridge between raw ECAD data and visual verification. Unlike complex CAD suites, this tool is a focused renderer and validator. It ingests a JSON definition of a PCB, performs rigorous validation to ensure the design is physically realizable (e.g., checking for closed boundaries, valid layer references, and non-negative dimensions), and then produces a layered visual output. It supports key PCB features such as copper traces, drilled vias, component outlines with reference designators (RefDes), and keepout regions.

### **Document Links**

* [Architecture Guide](https://www.google.com/search?q=./architecture_guide.md)  
* [Design Plan](https://www.google.com/search?q=./claude-code_design.md)  
* [Development Plan](https://www.google.com/search?q=./development_plan.md)  
* [Implementation Guide](https://www.google.com/search?q=./implementation_guide.md)  
* [Challenge Requirements](https://www.google.com/search?q=./Quilter%2520Backend%2520Engineer%2520Code%2520Challenge%25201-27.pdf)

### ---

**Requirements**

#### **Features**

* **CLI Commands:**  
  * render \<file\> \-o \<output\>: core command to process a board. Options include \--format (svg/png/pdf), \--dpi, and \--layers (to render specific stackup layers).  
  * validate \<file\>: Runs the validation suite against a file without generating graphics, returning a JSON report of errors found.  
  * info \<file\>: Prints board metadata (dimensions, layer count, component count) to stdout.  
* **Data Ingestion & Normalization:**  
  * Parses JSON files matching the provided Quilter schema.  
  * **Auto-normalization:** Immediately converts mixed units (e.g., microns in board\_6layer\_hdi.json) to a standard internal millimeter (mm) representation.  
* **Geometric Validation Engine:**  
  * Detects fatal errors (e.g., open polygons for board boundaries).  
  * Validates topology (e.g., vias referencing non-existent layers).  
  * Enforces physical constraints (e.g., non-negative trace widths).  
* **Rendering capabilities:**  
  * **Board Boundary:** Draws the board outline/cutout.  
  * **Stackup Visualization:** Color-coded layers (Red=Top, Blue=Bottom, Inner=Green/Purple).  
  * **Component Rendering:** Draws component bounding boxes and shapes. Handles mirror boolean for bottom-side components (flipping geometry) and rotation (CCW degrees).  
  * **Text/RefDes:** Renders component names (e.g., "R1", "U2") oriented correctly for readability, using a "halo" or background stroke to ensure contrast against copper pours.  
  * **Vias:** Renders drilled holes with annular rings.  
  * **Keepouts:** Renders restricted areas with distinct hatching patterns (///) and warning colors.

#### **Test Cases**

* **Unit Tests:**  
  * Verify coordinate transforms (Local \-\> World \-\> Screen).  
  * Test individual parsing of Point, Segment, Polyline.  
* **Property-Based Tests (Hypothesis):**  
  * *Invariant:* Rotation of a polygon by 360° results in the original polygon.  
  * *Invariant:* A board's bounding box area must be \>= the area of its boundary polygon.  
* **Snapshot Tests:**  
  * Visual regression testing using syrupy. Renders board.json and board\_kappa.json to SVG and compares against stored "golden" files to ensure pixel-perfect stability.  
* **Invalid Board Suite:**  
  * Explicit tests against the 14 required failure scenarios (e.g., missing\_boundary, self\_intersecting\_polygon).

#### **Logging**

* **Standard Library:** Python logging module.  
* **CLI Output:**  
  * INFO: High-level status ("Parsing board...", "Rendering layer TOP...").  
  * ERROR: Structured validation failures.  
* **Debug Mode:** \--verbose flag enables DEBUG logs showing matrix transformation details and bounding box calculations.

#### **Containerization: Docker**

* **Base Image:** python:3.11-slim (Minimizes image size).  
* **Build:** Multi-stage build using uv to compile dependencies and install the package.  
* **Volumes:** Maps a local ./data directory to the container to allow rendering files on the host machine.  
* **Entrypoint:** pcb-render

#### **Containerization: Docker Compose**

* **Service Name:** renderer  
* **Config:** Mounts local current directory to /app/workdir.  
* **Environment:** Sets PCB\_RENDER\_DPI=300 and PCB\_RENDER\_FORMAT=svg defaults.

#### **Swagger/OpenAPI**

* *N/A*: This is a CLI application. If a REST API wrapper is added later, FastAPI will be used to auto-generate OpenAPI specs.

#### **Documentation**

* **README:** Quickstart guide for uv installation and basic usage.  
* **Error Reference:** A document mapping error codes (e.g., E001) to human-readable explanations and fixes (e.g., "The board boundary must be a closed polygon.").  
* **Developer Guide:** Instructions for running the property-based validation suite and updating image snapshots.

#### **Acceptance Criteria**

1. **Valid Rendering:** The tool successfully renders board.json, board\_kappa.json, and board\_mixed\_tech.json to SVG without crashing.  
2. **Invalid Detection:** The tool correctly identifies and reports errors for **all 14** invalid board categories mentioned in the challenge (e.g., "Component placed outside boundary", "Trace width negative").  
3. **Visual Accuracy:**  
   * Top layer traces are Red.  
   * Bottom layer traces are Blue.  
   * Component RefDes text is legible.  
   * Board orientation matches the input coordinates (Origin at 0,0 or specified datum).  
4. **Performance/Review:** The codebase is structured and documented such that a reviewer can verify the logic and run the tests within **20 minutes**.

### ---

**Technology Stack**

#### **Language**

* **Language:** Python  
* **Version:** 3.11+  
  * *Rationale:* Required for precise type hinting (typing.Self), high performance, and compatibility with modern scientific libraries.

#### **Frameworks, Tools, Packages**

* **Core Logic:**  
  * pydantic \~= 2.0: Strict data parsing and schema validation.  
  * numpy \~= 1.26: Vectorized geometric transformations and matrix math.  
* **CLI:**  
  * argparse: Standard library (Zero-dependency preference for simpler review) OR typer (if modern DX is preferred). *Plan assumes standard library to minimize deps.*  
* **Rendering:**  
  * matplotlib \~= 3.8: Robust, backend-agnostic 2D plotting engine for SVG/PDF/PNG generation.  
* **Testing & QA:**  
  * pytest: Test runner.  
  * hypothesis: Property-based testing engine.  
  * syrupy: Snapshot testing for visual outputs.  
  * ruff: High-speed linter/formatter.  
  * uv: Fast Python package installer and resolver.

#### **Project Structure / Package System**

* **Build System:** pyproject.toml (PEP 621 compliant).  
* **Layout:**  
  Plaintext  
  pcb-renderer/  
  ├── pyproject.toml      \# Dependencies and Tool Config  
  ├── uv.lock             \# Pinned dependency tree  
  ├── src/  
  │   └── pcb\_render/  
  │       ├── \_\_init\_\_.py  
  │       ├── cli.py          \# Entry point  
  │       ├── models.py       \# Pydantic Schemas (Board, Component, etc.)  
  │       ├── geometry.py     \# Matrix transforms & math utils  
  │       ├── render.py       \# Matplotlib drawing logic  
  │       └── validate.py     \# 14-rule validation engine  
  ├── tests/  
  │   ├── fixtures/           \# Valid JSON examples  
  │   ├── invalid\_boards/     \# 14 invalid JSON test cases  
  │   └── snapshots/          \# SVG Gold Masters  
  └── README.md

#### **GitHub**

* **Repo:** https://github.com/\[user\]/pcb-renderer  
* **Branch:** main  
* **CI/CD:** GitHub Actions workflow (ci.yml) that runs:  
  1. uv sync (Install deps)  
  2. ruff check . (Lint)  
  3. pytest \--cov (Test with coverage)

#### **Deliverables**

1. **Source Code:** Complete Python package in src/.  
2. **CLI Tool:** Executable script available on path after install.  
3. **Test Report:** Pass rate for unit, property, and snapshot tests.  
4. **Validation Logic:** A distinct module demonstrating the logic for catching the 14 invalid board states.  
5. **Rendered Artifacts:** Example SVGs generated from the provided board\*.json files.

### ---

**Specific Implementation Details (from Challenge Context)**

#### **Validation Logic (The "14 Invalid Boards")**

The validate.py module will specifically check for:

1. **Syntax/Schema:** JSON malformed, missing required keys (boundary, stackup).  
2. **Geometry:** Self-intersecting polygons (Bowtie effect), open loops for boundaries.  
3. **Physical:** Negative dimensions (trace width \< 0, drill diameter \< 0).  
4. **Topology:** Vias referencing undefined layers, components referencing undefined footprints.  
5. **Placement:** Components fully outside the board boundary.  
6. **Stackup:** Duplicate layer names, invalid material definitions.

#### **Rendering "Halo" Requirement**

To ensure text legibility (one of the specific requirements in the PDF is "Board renders correctly and is easy readable"), the renderer will implement a text path effect:

Python

\# Pseudo-code for Matplotlib text effect  
text\_path \= TextPath((x, y), ref\_des, size=font\_size)  
patch \= PathPatch(text\_path, facecolor='white', linewidth=3, edgecolor='white') \# Halo  
ax.add\_patch(patch)  
ax.text(x, y, ref\_des, color='black') \# Text on top

#### **Coordinate Normalization**

As detailed in the Design Plan, the app will handle the designUnits field in metadata immediately.

* If designUnits \== "MICRON": Divide all coords by 1000\.  
* If designUnits \== "MILS": Multiply by 0.0254.  
* If designUnits \== "INCH": Multiply by 25.4.  
* Internal state is **always** millimeters.

Application Implementation Specification \- PCB Renderer CLI.mdJan 28, 3:31 PMTry again without Canvas