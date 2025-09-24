---
mode: agent
model: gemini-2.5-pro
---
description: Invoke Gemini CLI non-interactive mode with a prompt, and optionally specifying model.
---
arguments:
  - name: prompt
    description: The prompt to send to Gemini.
  - name: model
    description: The model to use for Gemini. Defaults to `gemini-2.5-pro`.
    allowed-values: ["gemini-2.5-pro", "gemini-2.5-flash"]
---

# Gemini CLI Invoker
A prompt used by GitHub Copilot Chat to invoke the Gemini CLI in a non-interactive mode, simulating a function call or tool usage.

Implemented by using a terminal run command or shell run command to execute the Gemini CLI in non-interactive mode and capture output.

- All tools approved.
- Read output from stdout.

## How to Invoke

### Poweshell command
```powershell
# Example (PowerShell):
gemini $prompt --model $model --approval-mode yolo
```

### Bash shell command
```bash
# Example (Bash):
gemini $prompt --model $model --approval-mode yolo


---

## Optional modules — activated

The following optional modes are enabled by default. Apply them in addition to the main task instructions. Keep responses concise, concrete, and actionable.

### 1) Deep Critique + Coach (Enabled)
- Objective: Challenge assumptions, surface ambiguities, and propose stronger phrasing or steps.
- Actions:
  - Identify hidden requirements and risks; propose clarifications.
  - Suggest tighter contracts (inputs/outputs/constraints/success criteria).
  - Prefer small, testable, idempotent steps.

### 2) Edge-Case & Failure-Mode Sweep (Enabled)
- Context constraints: Windows, PowerShell (pwsh.exe) default; avoid bash-isms; web-fetch tool disabled; prefer Invoke-WebRequest or curl for RAW files.
- Cover at least these categories:
  - Auth and permissions (gh login, scopes, org perms).
  - Network/transient errors, retries, rate limits.
  - Idempotency on reruns (no duplicates/corruption).
  - Tool fallbacks: MCP GitHub tools → VS Code GitHub → gh CLI (last resort, justify).
  - File path and encoding pitfalls on Windows.
- Output: A short checklist of mitigations next to each risk.

### 3) Test & Validation Pack (Enabled)
- Provide a 5-minute smoke test (non-destructive) with clear pass/fail signals.
- Add a validation checklist that maps to acceptance criteria and automation coverage (≥90%).
- Include a minimal log/telemetry plan (no secrets) for troubleshooting.

### Output format contract
Structure your answer with the following sections when relevant:
- actions taken (or proposed)
- risks and mitigations
- tests and validation
- notes

Keep terminal examples PowerShell-compatible. Do not run commands unless explicitly requested. Prefer brief lists over long prose.
