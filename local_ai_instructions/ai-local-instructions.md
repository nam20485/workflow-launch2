# Local AI Instructions

Guidance for always-on and first time correctness in resolving dynamic workflows and assignments.

- Instructions that govern agents/tooling for this repo.

1) Resolution trace first, then steps
- Before describing or executing steps: resolve `workflow_name` → dynamic workflow → terminal assignment → Acceptance Criteria. Record this as a trace.

2) Authoritative source of truth
- If an assignment or dynamic workflow cannot be strictly fulfilled from files in this repo, consult the [nam20485/agent-instructions](https://github.com/nam20485/agent-instructions/tree/main) repository (main branch) for the canonical assignment files and examples.
- In other words: “Look for files in the `agent-instructions` repo for fulfilling calculation of workflow and dynamic workflow assignments.”
- Always check the `agent-instructions` repo first or right after consulting local files.
- Never only read local files; always check the remote `agent-instructions` repo.

3) Acceptance-criteria gating
- Treat the terminal assignment’s Acceptance Criteria as the Definition of Done. Do not substitute steps from memory; verify against the canonical file.

4) Run report
- Produce a run report (or plan, for dry runs) that maps each step to the acceptance criteria it satisfies. Include the resolution trace.

5) Local index for fast resolution
- Maintain a local index of dynamic workflows → terminal assignments and the terminal assignment’s short summary. Keep it small and high-signal. This enables offline, first-try correctness. See the [assignment-index.json](assignment-index.json) file in this repo for the format. 