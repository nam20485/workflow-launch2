# Quilter PCB Renderer — Deep Dive on Highest-Risk Clarifying Questions (v2)

**Date:** 2026-01-30  
**Scope:** Expanded, practical clarifications for **Q3, Q10, Q11, Q6, Q12** from `quilter_interview_questions.md`, with concrete implementation implications for the PCB Renderer challenge.

This doc is designed to help you:
- understand what each question *really* controls in the implementation,
- anticipate the downstream blast radius of each answer,
- choose a sane default if the interviewer doesn’t answer in time,
- and (importantly) communicate your assumptions clearly.

## Sources this document is based on
- `Quilter Backend Engineer Code Challenge 1-27.pdf` (challenge requirements)
- `quilter_interview_questions.md` (your question list)
- `claude-code_design.md` (final design plan)
- `architecture_guide.md`, `development_plan.md`, `implementation_guide.md` (supporting plans)
- Sample boards: `board_6layer_hdi.json`, `board_complex_boundary.json`, `board_mixed_tech.json`, etc.

---

## What’s new vs v1 (key differences)

This v2 document intentionally changes/extends several parts of v1:

1. **Q10 is split into two separate decisions**:  
   (a) *physical placement transform for BACK components*, and  
   (b) *viewer convention for showing bottom-side layers* (top/X-ray vs flipped-board).  
   v1 treated these as one decision; v2 explains why they are separable and how to implement both safely.

2. **Q11 defaults are corrected to not assume layer names like `TOP`/`BOTTOM`.**  
   Sample boards show top/bottom copper may be named `L1_TOP` / `L6_BOT`, with a separate `layer_type` field. v2 recommends default selection based on `layer_type`, not string names.

3. **Q3 expands beyond “flat vs nested pairs”** to include:  
   - polygon closure policy,  
   - numeric sanity (NaN/Inf),  
   - coordinate normalization strategy,  
   - and ambiguity-handling rules that reduce rework and improve error messages.

4. **Q6 is expanded into a *detail-level ladder*** (body-only → pads → pin labels) with concrete readability and performance tradeoffs, plus a recommended “pin-1 marker” compromise.

5. **Q12 adds a keepout “semantic contract”**: how to validate `layer`/`keepout_type`, how to render keepouts in combined vs per-layer views, and what to do with unknown types.

---

# Q3 — Coordinate format handling

**Question (paraphrased):** boards may encode points as flat arrays `[x1,y1,x2,y2,...]` or nested pairs `[[x1,y1],[x2,y2],...]`. Should you support both, or is there one canonical format?

## Explanation (what it’s really asking)

This question is **not just** about parsing two list shapes. It’s asking whether your system should be:

- **Format-tolerant** (accept multiple encodings and normalize early), or
- **Schema-strict** (reject anything not matching a single canonical schema).

In practice, coordinate parsing is the “front door” to *every* geometry primitive: board boundary, trace paths, keepout polygons, pour boundaries, pad outlines, etc. Your decision here determines whether the rest of the pipeline can rely on a single internal representation (ideal) or must carry format-branching everywhere (bad).

## Implications (blast radius)

### If you support multiple formats
- **Parsing layer grows** slightly (more detection rules + better error messages).
- **Models become stable**: downstream can assume `List[Point]` always.
- **Validation becomes clearer**: you can classify problems as “MalformedCoordinatesError” instead of crashing mid-render.
- **Hidden test cases are less risky** (very likely in interview-style challenges).

### If you enforce one canonical format
- Parsing is simpler.
- But any provided board (or hidden test) that deviates becomes “invalid,” which may conflict with intent (“All files are valid JSON files,” but not necessarily schema-uniform).

## Embedded sub-decisions you must make (even if they don’t ask)

Even if they answer “support both,” you still must choose:

1) **Closure policy for polygons**  
   - Auto-close polygons when last point != first, or error?

2) **Degenerate geometry policy**  
   - Reject polygons with < 3 unique points?  
   - Reject polylines with < 2 points?

3) **Numeric sanity**  
   - Reject NaN/Inf?  
   - Clamp extreme coordinates?

4) **Coordinate types and units**  
   - Accept ints + floats (yes).  
   - Normalize units to mm at parse time.

5) **Ambiguity policy**  
   - What if you see `[ [x,y,z], ... ]` or `[x,y]` (only one point)?  
   Decide whether that is malformed vs coercible.

## Options (with pros/cons + recommendation)

### Option A — Accept both flat + nested pairs; normalize into canonical `List[Point]` (recommended)
**Pros**
- Most robust; minimizes rework if inputs vary.
- Keeps downstream code clean and testable.
- Lets you produce precise, user-friendly validation errors (critical for “14 invalid boards”).

**Cons**
- Slightly more parsing logic.
- Requires a well-defined detection order.

**Recommendation**
- Choose Option A by default for this challenge.

**Implementation notes**
- Use a single `parse_points(coords, *, context_path)` function that:
  - returns `List[Point]`,
  - raises/returns “MalformedCoordinatesError” with JSON path,
  - and optionally auto-closes polygons depending on a config flag.

**Suggested detection rules**
1) `coords` is list of numbers → flat, require even length  
2) `coords` is list of lists where each inner list has length 2 and both numeric → nested pairs  
3) else → malformed

### Option B — Require canonical nested pairs only
**Pros**
- Simplest implementation.
- Very predictable errors.

**Cons**
- High risk of rejecting boards that are “valid enough.”
- If hidden tests include flat arrays, you fail immediately.

**Recommendation**
- Only use if they guarantee canonical format (ideally in writing).

### Option C — Support both but only under explicit schemaVersion or metadata flag
**Pros**
- Makes parsing behavior explicit and versionable.
- Great long-term design (if schema evolves).

**Cons**
- Extra policy surface area not requested.
- Adds failure modes if files omit versioning.

**Recommendation**
- Not worth it unless the schema is clearly versioned and documented.

## Practical default (if unanswered)
- **Accept both formats**, normalize to `List[Point]`, and **auto-close polygons**.  
- Document this clearly under “Assumptions.”

## Testing strategy (to lock it down)
- Unit tests for:
  - flat even length,
  - flat odd length (error),
  - nested pairs,
  - nested malformed (inner length != 2),
  - NaN/Inf rejection,
  - polygon closure auto-close behavior.
- Property tests:
  - parsing + rendering never crashes for valid numeric lists.
- Add at least one “invalid board” fixture using odd-length flat coordinates to ensure the right error code.

---

# Q10 — Back-side component rendering (mirroring semantics)

**Question (paraphrased):** For back-side components, should they be mirrored as viewed from the top (X-ray view) or as if you flipped the physical board over?

## Explanation (what it’s really asking)

This question contains **two different problems** that are easy to accidentally merge:

### Decision 1: Physical placement transform for BACK components
Regardless of how you “view” the board, a BACK-side footprint is physically the *mirror* of its FRONT-side footprint when expressed in the same board coordinate system.

That means you need a well-defined transform pipeline that handles:
- translation,
- rotation,
- mirroring for back-side,
- and ECAD → render coordinate conversion (Y flip).

### Decision 2: Viewer convention (how you want to present bottom layers)
Separately, you may choose to:
- render everything in a **single top-view** (so bottom copper is “seen through”), or
- render a **bottom-view** (as if the board were flipped over), typically as a separate output.

These choices affect *global presentation*, not just component placement.

## Implications (blast radius)

### If you get the physical mirroring wrong
- Pads/pins on BACK components will not align with copper/vias.
- Rotations can appear “backwards.”
- Snapshot tests become brittle and confusing.

### If you get the viewer convention wrong
- The board may still be “physically correct” but will appear mirrored vs what reviewers expect.
- Reviewers may interpret the output as incorrect even if geometry is fine.

## Options (with pros/cons + recommendation)

### Option A — Single output in top-view (X-ray style) + physically mirror BACK component local geometry (recommended default)
**Pros**
- Best match for a “one combined render” strategy and quick review (single artifact).
- Makes it easy to overlay top + bottom layers if you choose.
- Simplifies CLI: one coordinate frame.

**Cons**
- RefDes on BACK components can become mirrored if you naïvely apply the same mirror transform to text.
- Requires “text readability normalization” (keep text upright and not reversed).

**Recommendation**
- Use Option A as default for the challenge.

**Implementation detail (critical)**
- **Mirror geometry, not text.**  
  For BACK components:
  - mirror pads/outlines,
  - then place RefDes using the component centroid, and clamp/normalize text rotation to keep it readable.

### Option B — Produce separate “TOP view” and “BOTTOM view” outputs (flip-board convention for the bottom)
**Pros**
- Very intuitive for humans: bottom view looks like what you’d see if you flipped the PCB.
- Text on bottom can be “naturally readable” without special casing.

**Cons**
- Requires extra CLI semantics and output naming conventions.
- Doubles snapshot artifacts/tests.
- Still requires correct physical mirroring for BACK components in board coordinates (Decision 1 still exists).

**Recommendation**
- Great as an *optional flag* (`--view top|bottom|both`) if time permits.

### Option C — Render BACK components without mirroring (treat as FRONT)
**Pros**
- Simplest.

**Cons**
- Highly likely wrong for any footprint with asymmetry or labeled pins.
- Pads won’t line up if input assumes FRONT-local footprint coordinates.

**Recommendation**
- Avoid unless they confirm the JSON already encodes bottom-local geometry pre-mirrored.

## The subtle part: mirror axis + rotation sign

Most errors come from mixing these up:
- mirroring before vs after rotation,
- mirroring across local X vs local Y,
- whether rotation is defined in “top-view” coordinates.

If you don’t get clarification, protect yourself by:
- making the mirror axis configurable (`--back-mirror-axis x|y`),
- but default to the documented assumption from your design plan.

## Practical default (if unanswered)
- Implement Option A (single top-view).  
- Mirror BACK component geometry per the transform pipeline in your design docs.  
- Keep RefDes readable via rotation normalization / halo.

## Testing strategy
Because the provided sample boards do not include BACK components, add a synthetic fixture:
- A clearly asymmetric footprint (e.g., rectangle + pin-1 marker on left).
- Render it FRONT and BACK at the same position; verify BACK is mirrored in the expected direction.
- Add a snapshot test for that fixture.

---

# Q11 — Multi-layer rendering strategy

**Question (paraphrased):** For multi-layer boards with inner layers, should you render everything in a single output with transparency, or separate files per layer (or layer pairs like top+bottom)?

## Explanation (what it’s really asking)

It’s tempting to treat Q11 as “one file or many,” but it actually controls:

1) **Default reviewer experience** (one artifact vs many, readability vs completeness)  
2) **Your CLI contract** (`--layers`, output naming, defaults)  
3) **How you treat planes** (solid fills can destroy readability)  
4) **How you color-code** and explain the stackup

The core requirement is: traces are colored by layer; it does *not* explicitly require multi-file outputs.

## Implications (blast radius)

### Combined output (single file)
- Simplest for reviewers (“20 minute review”).
- But potentially visually noisy, especially on dense HDI boards.

### Per-layer outputs
- Very readable and CAD-like.
- But increases deliverables, test maintenance, and reviewer time.

### Layer naming gotcha (important correction vs v1)
You **cannot assume layer names** are literally `TOP` and `BOTTOM`.  
For example, the 6-layer sample board uses `L1_TOP` and `L6_BOT` names, but still marks them with `layer_type: "TOP"` and `layer_type: "BOTTOM"`.

So your default layer selection must be based on `layer_type`, not the layer name string.

## Options (with pros/cons + recommendation)

### Option A — Single combined output; default to outer copper only; allow `--layers` (recommended)
**Pros**
- Best match for the review constraint and simplest UX.
- “Outer copper only” is usually the least cluttered and still demonstrates correctness.
- Still supports power users: `--layers all` or explicit layer lists.

**Cons**
- Reviewers may wonder “where are the inner layers?”
- Needs clear README + CLI help text.

**Recommendation**
- Use Option A as default.

**Implementation notes**
- Define `outer_layers = [layer for layer in stackup.layers if layer.layer_type in {"TOP","BOTTOM"}]`.
- Default render set = outer layers.
- `--layers` accepts:
  - comma-separated layer names (exact match),
  - or special tokens: `outer`, `all`, maybe `signal`, `planes`.
- When rendering combined view, use transparency for inner layers and plane layers to preserve readability.

### Option B — Single combined output; render *all* copper layers by default
**Pros**
- Shows “full board” without extra flags.
- Demonstrates layer-color mapping strongly.

**Cons**
- Can become unreadable on complex boards (especially with large planes).
- Harder to debug visually.

**Recommendation**
- Not ideal as default; good as `--layers all`.

### Option C — Output one file per layer (and optionally one combined overview)
**Pros**
- Very readable.
- Feels like a CAD layer viewer.

**Cons**
- Many files; naming + organization required.
- Snapshot test count explodes.

**Recommendation**
- Make it optional (`--split-layers`) if you have time.

### Option D — Output specific “manufacturing-ish” bundles (Top, Bottom, Inner Signals, Planes)
**Pros**
- A nice compromise: not too many files, but still readable.

**Cons**
- Requires a policy for what counts as “signal vs plane.”
- More documentation required.

**Recommendation**
- Nice-to-have; do not default unless asked.

## Practical default (if unanswered)
- Render one combined output.
- Default to outer copper layers (by `layer_type`), plus always draw boundary/components/vias/keepouts.

## Testing strategy
- Unit tests:
  - correct identification of outer layers by `layer_type` even when names differ.
- Integration test:
  - render a multi-layer board twice:
    - default (outer only),
    - `--layers all`,
  - ensure both succeed and outputs differ (e.g., via snapshot).

---

# Q6 — Component detail level

**Question (paraphrased):** Should components be rendered with real footprint geometry, or are simplified bounding boxes acceptable? What about pin numbers vs pads?

## Explanation (what it’s really asking)

This is primarily a **scope control** question, but it also affects correctness perception.

The challenge spec requires:
- component outlines at transformed positions,
- reference designators,
- rotation handled correctly.

It does **not** explicitly require rendering pads/pins, but many sample JSONs include pin geometries (rectangles/circles) that you *could* render.

So the question is: how much detail is expected for “correct enough” vs “impressive but risky”?

## Implications (blast radius)

### If you render only body outline + RefDes
- Very readable.
- Much less code and fewer edge cases.
- Less likely to blow the “20-minute review” budget.

### If you render pads/pins
- Significantly more geometry primitives (especially BGA/QFN).
- More transform correctness surface area (pin rotations, through-hole, etc.).
- Potential readability issues unless you style carefully (alpha, z-order).

### If you render pin labels/numbers
- Text clutter is very likely.
- You need collision avoidance or aggressive scaling.

## A useful mental model: detail ladder

Think in terms of levels you can progressively enable:

**Level 0 — Component body only**  
- outline (rectangle/polygon) + RefDes

**Level 1 — Body + orientation marker**  
- add a small “pin 1 dot/notch” indicator (cheap clarity)

**Level 2 — Body + pads/pins**  
- draw pad shapes from `pins[*].shape` at transformed positions

**Level 3 — Body + pads + pin labels**  
- draw text for pin names/numbers (rarely readable in full-board view)

## Options (with pros/cons + recommendation)

### Option A — Body outline + RefDes only (recommended default)
**Pros**
- Meets explicit requirements.
- Keeps output readable.
- Lowest implementation risk.

**Cons**
- Less “CAD-like.”
- Reviewers can’t visually inspect pad placement.

**Recommendation**
- Default to Option A.

### Option B — Add a pin-1 orientation marker (recommended enhancement)
**Pros**
- Tiny extra code; big clarity boost.
- Helps validate rotation correctness without full pad rendering.

**Cons**
- Requires pin-1 definition source; may need heuristic:
  - if pins are named “1”, “A1”, etc.
  - if not, you can approximate using a corner dot.

**Recommendation**
- If you want one “impressive but safe” enhancement, pick this.

### Option C — Render pads/pins (optional flag)
**Pros**
- Very informative and impressive.
- Uses data already present in JSON (pin shapes and local positions).

**Cons**
- Can be expensive/slow for BGA-like parts.
- Can destroy readability unless you tune alpha and z-order.

**Recommendation**
- Implement behind a flag: `--component-detail pads`.

### Option D — Render pin labels/numbers (not recommended as default)
**Pros**
- Max detail.

**Cons**
- Almost always unreadable at board-scale.
- Requires label rotation normalization and collision management.

**Recommendation**
- Avoid unless explicitly requested.

## Practical default (if unanswered)
- Default to **Option A**, plus RefDes halo/contrast for readability.  
- Add Option C behind a flag if time allows.

## Testing strategy
- Unit tests:
  - rotation transform correctness (outline corners rotate properly),
  - refdes orientation normalization (text remains upright).
- Snapshot test:
  - render a board with multiple rotated components (e.g., mixed-tech board includes rotations).

---

# Q12 — Keepout scope and types

**Question (paraphrased):** Do keepouts apply globally or per-layer? Should you differentiate “no copper” vs “no components” keepouts?

## Explanation (what it’s really asking)

Keepouts are “restricted regions,” but restriction meaning varies:
- **No copper / routing keepout** (prevents traces/pours)
- **No components** (placement keepout)
- **No vias / drill** (mechanical)
- **All** (generic “don’t use this region”)

The challenge spec requires:
- keepout areas drawn distinctly,
- marked as restricted areas.

It does not require enforcing DRC (e.g., clipping copper out), only *rendering* them clearly.

## Implications (blast radius)

### Layer scope matters because of Q11
- In combined view, you must avoid drawing keepouts multiple times or inconsistently.
- In per-layer view, you must decide whether to show only keepouts that apply to that layer.

### Type differentiation matters because of user meaning
- If you style all keepouts identically, you may lose semantic signal.
- If you style by type, you must define a vocabulary and fallback for unknown types.

### Validation & “invalid board” detection
Keepouts create extra invalid cases:
- malformed polygon,
- keepout references nonexistent layer name,
- invalid type value (if types are enumerated).

## Concrete observation from sample data
The complex boundary sample includes a keepout with:
- `layer: "ALL"`
- `keepout_type: "ALL"`

This suggests at least one global keepout mode exists and must be supported.

## Options (with pros/cons + recommendation)

### Option A — Treat all keepouts as global overlays; ignore type; render same style
**Pros**
- Simplest.
- Guarantees keepouts are always visible.

**Cons**
- Incorrect if some keepouts are layer-specific.
- Loses semantic differentiation.

**Recommendation**
- Acceptable only if data uses mostly global keepouts.

### Option B — Respect keepout layer scope; generic style (recommended default)
Interpretation:
- if `layer in {"ALL", "*"} or missing` → applies to all rendered views
- else → applies only if that layer is included in the current render set

**Pros**
- Correct for both global and per-layer keepouts.
- Minimal extra complexity.
- Keeps combined view consistent with `--layers`.

**Cons**
- Requires consistent definition of what a “layer match” means.

**Recommendation**
- Default to Option B.

### Option C — Respect layer scope + style by keepout_type (optional enhancement)
**Pros**
- Most informative output.
- Demonstrates domain awareness.

**Cons**
- Requires type vocabulary stability.
- Adds styling complexity and snapshot churn.

**Recommendation**
- Implement only if they confirm keepout types or if sample data clearly defines them.

### Option D — Actually “mask” copper under keepouts (DRC-like visualization)
**Pros**
- Very strong visual cue: restricted area is enforced.

**Cons**
- Harder (requires polygon clipping / boolean ops).
- Not required by spec; likely overkill for interview.

**Recommendation**
- Avoid for submission; mention as future work.

## Practical default (if unanswered)
- Implement Option B:
  - respect layer scope,
  - style keepouts generically with hatch + warning edge color,
  - draw keepouts last/topmost.

## Rendering style guidance (to satisfy “easy readable”)
- Use diagonal hatching (`///`) + semi-transparent fill.
- Use high z-order so keepouts overlay traces/components.
- Consider adding a small label at keepout centroid (name) only if it won’t clutter.

## Testing strategy
- Snapshot test:
  - render complex boundary board and ensure the keepout is visible and hatched.
- Validation tests:
  - keepout with invalid layer reference → NonexistentLayerError (or a keepout-specific error code).
  - keepout polygon with <3 points → geometry error.

---

## One-page default assumptions (if you get no answers)

If the interviewer doesn’t respond in time, these defaults minimize rework while remaining reasonable:

- **Q3:** Support both flat + nested coordinate encodings; normalize to canonical `List[Point]`; auto-close polygons; reject malformed/NaN/Inf.  
- **Q10:** Render in a single top-view; mirror BACK component geometry per documented transform pipeline; keep RefDes readable (do not mirror text).  
- **Q11:** Single combined output; default to outer copper layers by `layer_type`; inner layers optional via `--layers all`.  
- **Q6:** Component body outline + RefDes by default; optional pads behind `--component-detail pads`; consider pin-1 marker as safe enhancement.  
- **Q12:** Respect keepout layer scope; generic hatched warning style; draw keepouts last/topmost; unknown keepout types treated generically.
