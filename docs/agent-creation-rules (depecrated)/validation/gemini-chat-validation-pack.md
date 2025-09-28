# Gemini Chat Validation Pack

Use these copy/paste prompts directly in Gemini chat (with your cached OAuth). No CLI or API keys are required for this validation.

This pack validates that:
- Optional modules are mentally loaded (Deep Critique + Coach, Edge-Case Sweep, Test & Validation Pack)
- The model follows precise constraints
- You receive actionable, checklisted outputs aligned to your Windows + PowerShell environment and automation policy

---

## Step 1 — Activation handshake
Purpose: Confirm the optional modules and constraints are understood.

Copy/paste:

You are reviewing a prompt policy for a Windows + PowerShell (pwsh.exe) environment with these requirements:
- Optional modules enabled by default:
  1) Deep Critique + Coach
  2) Edge-Case & Failure-Mode Sweep
  3) Test & Validation Pack
- Output format contract sections when relevant:
  - actions taken (or proposed)
  - risks and mitigations
  - tests and validation
  - notes
- Constraints:
  - Prefer small, idempotent, testable steps
  - Use MCP GitHub tools → VS Code GitHub → gh CLI (last resort + justification)
  - Avoid bash-isms; assume pwsh; if fetching RAW files, use Invoke-WebRequest or curl
- Claude best practices applied: tiny contract, explicit assumptions, fast failures, runnable tests.

Reply only with:
ACK
modules=3
fallback=MCP→VSCode→gh
shell=pwsh
bestpractices=ON

PASS if: The reply matches exactly these 5 lines with the same keys/values and no extra text.

---

## Step 2 — Minimal compliance test
Purpose: Verify precise instruction-following.

Copy/paste:

Reply with the single word:
PONG

Constraints:
- No punctuation, whitespace, or other text before or after the word.
- If you cannot comply, reply with exactly: FAIL

PASS if: The reply is exactly `PONG` (all caps, nothing else).

---

## Step 3 — Edge-case sweep + validation pack
Purpose: Exercise the optional modules and output contract.

Copy/paste:

Using the Output format contract, produce:
- actions taken: A compact plan to validate a repo creation workflow (Windows + pwsh) with ≥90% GitHub automation coverage.
- risks and mitigations: At least 6 items covering auth/permissions, rate limits/retries, idempotency, tool fallbacks, Windows path/encoding, and network flakiness—each with 1-line mitigation.
- tests and validation: A 5-minute smoke test (non-destructive), an idempotency re-run check, and an acceptance checklist that maps directly to the automation policy (≥90%).
- notes: Any assumptions and where to capture logs/telemetry (no secrets).

Constraints:
- Keep it concise and skimmable.
- Use checklists where helpful.
- Assume no web-fetch tool in the environment; if fetching RAW URLs, prefer Invoke-WebRequest or curl.

PASS if:
- Sections match the exact contract headings: actions taken, risks and mitigations, tests and validation, notes
- ≥6 risk items with paired mitigations
- Tests include fast smoke test, idempotency re-run, and automation coverage mapping
- Notes include assumptions and where logs go (no secrets)

---

## Quick Results Checklist
- [ ] Step 1 PASS
- [ ] Step 2 PASS
- [ ] Step 3 PASS

If any step fails, copy the response, note the deviation from PASS criteria, and adjust the prompt phrasing minimally (e.g., enforce exact wording or add stricter constraints) before retrying.
