## ARFI Pass v2 — Deep, Claude-aligned, Gemini cross-check

Do another analysis, review, feedback, improve (ARFI) pass with the following explicit guidance and templates to make this document and the related workflow immediately actionable.

### Mindset
- Think deeply. Prefer concrete, verifiable changes over vague advice.
- Optimize for clarity and reproducibility; assume PowerShell (pwsh.exe) on Windows by default.
- Keep edits small and testable; add guardrails and validation steps.

### Use Claude code best practices (curated highlights)
Incorporate the relevant practices from Anthropic’s Claude engineering guidance:
- Define a tiny contract before you build: inputs, outputs, constraints, and success criteria.
- Handle edge cases up front; write the checks you wish you had later.
- Keep functions small and explicit; avoid hidden state and side effects.
- Make it runnable and testable: provide quick smoke tests and sample invocations.
- Log and fail fast on invalid input; prefer explicit, actionable errors.
- Document assumptions and link to sources of truth. Prefer idempotent steps.

Reference: https://www.anthropic.com/engineering/claude-code-best-practices

### Collaborate with Gemini (cross-model review)
Before finalizing, run a cross-check with Gemini to:
- Challenge assumptions and missing edge cases.
- Suggest additional tests and validation steps.
- Critique prompt wording for ambiguity and hidden requirements.

Use the prompts in the “Gemini cross-check” section below.

---

## ARFI template for this repo (apply to this file and the associated scripts)

### 1) Contract
- Goal: Create and maintain a repeatable workflow to generate a repository with “plan docs,” aligned to local automation policies.
- Non-goals: Anything that requires manual GitHub UI work unless documented as fallback.
- Inputs: Config/plan sources, target repo metadata, credentials (via environment or gh), local toolchain (pwsh).
- Outputs: Created repo, populated plan docs, automation reports, and a validation log.
- Constraints: Windows + pwsh, ≥90% GitHub automation coverage, no web-fetch tool; use PowerShell Invoke-WebRequest/curl if fetching remote RAW files.

### 2) Edge cases to address
- Missing/invalid credentials (gh not authenticated) or insufficient permissions.
- Network failures or partial successes (repo created but docs not pushed).
- Idempotency: rerunning should not duplicate content or corrupt state.
- Rate limits and retries for GitHub operations.
- Mismatch between local template version and remote canonical instruction modules.

### 3) Quality gates (must pass)
- Build/setup: Scripts lint or basic syntax check succeeds.
- Typecheck/lint where applicable (pwsh: basic script analysis).
- Unit/smoke test: dry-run or “what-if” completes without error; small end-to-end on a test repo.
- Validation: repository contains expected files; automation coverage ≥90% per policy.

### 4) Automation checkpoint (per local policy)
Target ≥90% automation coverage for GitHub operations. Use MCP GitHub tools first, VS Code integration second, gh CLI last.

- Tool discovery completed: reference `local_ai_instruction_modules/ai-tools-and-automation.md` and `toolset.selected.json`.
- Manual steps must include justification and fallback plan.

| Task | Primary tool | Automation status | Manual justification |
|------|---------------|-------------------|---------------------|
| Create repo | MCP GitHub | Auto | — |
| Push plan docs | MCP GitHub | Auto | — |
| Labels/milestones | MCP GitHub | Auto | — |
| PR scaffolding | MCP GitHub | Auto | — |
| Any manual UI step | — | Manual | Only if MCP/VS Code/gh unavailable |

### 5) Runbook (pwsh-first)
Note: Don’t assume bash; detect shell if needed. Prefer Invoke-WebRequest or curl for RAW files when required.

1) Validate environment: PowerShell version, gh auth status, network.
2) Fetch canonical instruction modules from RAW URLs if needed and cache with version.
3) Create target repo and branches via MCP GitHub tools (fallback: VS Code GitHub, then gh).
4) Generate and push plan docs in a single commit; include README and acceptance checks.
5) Configure labels/milestones via automation; record results.
6) Open a validation PR with checklist and CI run.

### 6) Validation steps
- Verify repo exists and is public/private as intended.
- Confirm required files and directories are present (docs/, local_ai_instruction_modules/, scripts/ where applicable).
- Check automation coverage table updated and ≥90%.
- Perform a dry-run rerun to confirm idempotency (no duplicate files/labels).

### 7) Troubleshooting and rollback
- If creation partially succeeds, prefer scripted cleanup (delete repo) or complete the missing steps; record actions.
- Log encountered errors and environment info for reproducibility.

### 8) Security and secrets
- Never print tokens; rely on gh auth store or environment-secure variables.
- Avoid embedding secrets into docs or commit history; validate .gitignore if generating files.

### 9) Acceptance criteria (for this ARFI pass)
- This document now contains a clear contract, edge cases, runbook, validation, and automation checkpoint.
- Claude best practices and Gemini cross-check guidance are embedded.
- Readers can execute the workflow end-to-end with minimal ambiguity.

---

## Gemini cross-check prompts (copy-paste)
Use these with Gemini to stress-test the plan:

1) “List 5 edge cases this runbook might miss for Windows pwsh environments and propose concrete mitigations.”
2) “Given the automation policy (≥90%), where could we inadvertently drop below the threshold? Suggest tool-first fixes.”
3) “Propose a 5-minute smoke test that validates repo creation and plan-doc integrity without requiring destructive cleanup.”
4) “Critique the acceptance criteria for being too weak/strong and propose measurable improvements.”
5) “Suggest minimal telemetry/logging we should capture to aid later debugging without leaking secrets.”

---

## Next actions
- Apply the Runbook to a throwaway test repo to validate idempotency and automation coverage.
- Capture findings in a short validation log under docs/ and update the automation table accordingly.