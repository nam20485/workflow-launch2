# AI Workflow Resolution: First-try Correctness Playbook

- This document explains how to make dynamic workflow answers correct on the first try.
- Authoritative specs live in the separate repository: [nam20485/agent-instructions](https://github.com/nam20485/agent-instructions/tree/main) (main branch is the source of truth).
- Always consult agent-instructions first (or immediately after local files) and gate on Acceptance Criteria from the terminal assignment.

## Why answers can drift
- This repo often doesn’t contain the canonical assignment specs; dynamic workflows are just routing.
- The real steps and the Definition of Done are in the terminal assignment’s Acceptance Criteria. Missing that leads to omissions (e.g., devcontainer/workspace rename).

## Always-on guidance (embed this mindset)
1) Resolution trace first, then steps
- Resolve `workflow_name` → dynamic workflow → terminal assignment → Acceptance Criteria. Record the trace.

2) Authoritative source of truth
- If an assignment/dynamic workflow cannot be strictly fulfilled from local files, consult the agent-instructions repo.

3) Acceptance-criteria gating
- Treat the terminal assignment’s Acceptance Criteria as the Definition of Done. Do not substitute steps from memory.

4) Run report / plan artifacts
- Produce a run report (or dry-run plan) mapping each step to the acceptance criteria. Include the resolution trace.

5) Local index for fast resolution
- Maintain a minimal local index for the workflows you actually use. Path: `local_ai_instructions/assignment-index.json` (the tracer uses this and will fall back to `.ai/assignment-index.json` if present).

## Local quick-reference of modules
- See [local_ai_instructions/agent-instructions-catalog.md](./agent-instructions-catalog.md) for curated links and acceptance criteria snapshots for the modules we use most.

## Utilities in this repo

1) Resolution Tracer (dry run)
- Script: [scripts/workflow-resolution.ps1](../scripts/workflow-resolution.ps1)
- Mode: `-TraceOnly` (no side effects)
- Inputs: `-WorkflowName`, `-ContextRepoName`, `-AppPlanDocs` (array)
- Output: writes plan artifacts (JSON + Markdown) under `run-plans/` and prints a trace to console.

2) Ahead-of-Time (AOT) Planner
- Same script without `-TraceOnly` still only emits the execution plan (what would be done) mapped to Acceptance Criteria. Review or hand off to automation.

Both modes read the local index: [assignment-index.json](./assignment-index.json).

## Index format
The local index includes:
- Dynamic workflows → ordered list of assignment short IDs with `passContext` flags.
- Assignments → title, inputs, acceptanceCriteria, detailedSteps (with tokenized command templates).

## Keeping things aligned
- When a canonical assignment changes in agent-instructions, update the local index to match (especially Acceptance Criteria and rename/migration steps).
- Keep the index scoped to workflows you actually use; for others, consult agent-instructions on demand.

## Optional: Golden tests for plans
- You can validate the tracer’s output by comparing generated plans to committed “golden” plans.
- Utility: `scripts/plan-compare.ps1` compares two files (JSON or Markdown) and returns success/failure.
- Recommended pattern: commit golden JSON/MD plans under `tests/goldens/<workflow>/<case>.{plan.json,plan.md}` and have CI run the tracer then `plan-compare.ps1`.

### Example (Windows PowerShell)
```
pwsh -NoProfile -File .\scripts\workflow-resolution.ps1 -WorkflowName 'initiate-new-repo' -ContextRepoName 'sample-repo' -AppPlanDocs @('docs\plan.md') -TraceOnly
pwsh -NoProfile -File .\scripts\plan-compare.ps1 -Expected .\tests\goldens\initiate-new-repo\sample.plan.json -Actual .\run-plans\initiate-new-repo-sample-repo-YYYYMMDD-HHMMSS.plan.json -Kind json
```

