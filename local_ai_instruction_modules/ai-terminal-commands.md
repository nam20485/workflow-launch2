# Operational Notes: Initiate New Repository (Run #2)

These notes capture practical gotchas and reliable PowerShell/gh snippets observed when executing the “initiate-new-repository” assignment on Windows.

## Scope

- Environment: Windows, PowerShell (pwsh), GitHub CLI (gh)
- Target org: nam20485
- Template: nam20485/ai-new-app-template

## Gotchas and workarounds

- Project templating is unreliable
  - The CLI option to set the “Basic Kanban” template is inconsistent across environments. Create the project without a template, then customize it.
- JSON handling and quoting in PowerShell
  - Prefer: gh --format json | ConvertFrom-Json and keep filters in PowerShell instead of complex jq-like expressions.
- Paths and filenames with spaces
  - Use -LiteralPath or careful quoting for Copy-Item and git add. Example file: "Advanced Memory .NET - Dev Plan.md".
- Default branch alignment
  - Template defaults to development; confirm the default branch to avoid pushing to an unexpected branch.
- Label import edge cases
  - Colors must be hex without the leading #; duplicates return 422. Treat as update, not create. The provided script handles this.
- Milestone dates and idempotency
  - Due dates must be YYYY-MM-DD; attempting to recreate an existing title returns 422. Use "skip existing" logic.
- Rate limits / flakiness
  - Tight loops (labels/milestones) may trigger secondary rate limits. Add small sleeps between requests when needed.

## Idempotent PowerShell/gh snippets

> Note: these snippets assume the environment variable NEW_REPO_NAME is set to the repo name created for this run.

### Owner-level project creation (no template)

```powershell
# Requires gh auth with project scope
$ErrorActionPreference = 'Stop'
$title = $env:NEW_REPO_NAME
$existing = gh project list --owner nam20485 --limit 200 --format json |
  ConvertFrom-Json | Where-Object { $_.title -eq $title } | Select-Object -First 1
if (-not $existing) {
  $proj = gh project create --owner nam20485 --title $title --format json | ConvertFrom-Json
  Write-Host ("Created project #{0} -> {1}" -f $proj.number, $proj.url) -ForegroundColor Green
} else {
  Write-Host ("Project exists: #{0} -> {1}" -f $existing.number, $existing.shortDescriptionURL) -ForegroundColor Yellow
}
```

### Create repository from template

```powershell
# Public repo from template with AGPL license
gh repo create "nam20485/$($env:NEW_REPO_NAME)" `
  --template nam20485/ai-new-app-template `
  --public `
  --license agpl-3.0
```

### Ensure default branch

```powershell
gh repo edit "nam20485/$($env:NEW_REPO_NAME)" --default-branch development
```

### Clone into dynamic_workflows folder

```powershell
$dest = "E:\src\github\nam20485\dynamic_workflows\$($env:NEW_REPO_NAME)"
if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
git clone "https://github.com/nam20485/$($env:NEW_REPO_NAME).git" $dest
```

> Root cause (Run #2): Wrong clone destination path
- Symptom: The new repo ended up rooted under `E:\src\github\nam20485\dynamic_workflows\...` instead of the workspace-local `workflow-launch2\dynamic_workflows\...` folder.
- Cause: The snippet above hard-codes a parent folder path that is a sibling of the workspace (missing the `workflow-launch2` segment). This diverges from the detailed steps in the assignment, which assume cloning under the workspace’s `dynamic_workflows/` folder.
- Fix: Anchor the clone destination to the workspace root (not a sibling path) and construct the path with `Join-Path`. Add guards to ensure we’re under the expected workspace.

### Safer, workspace-anchored clone (recommended)

```powershell
# Run this from anywhere. It discovers the current Git repo root (the workspace root)
$ErrorActionPreference = 'Stop'

# Discover workspace root via Git (fallback to current directory if not in a Git repo)
$workspaceRoot = try { (git rev-parse --show-toplevel).Trim() } catch { (Resolve-Path ".").Path }

# Expected dynamic_workflows directory under the workspace
$dynamicWorkflows = Join-Path $workspaceRoot 'dynamic_workflows'
if (-not (Test-Path -LiteralPath $dynamicWorkflows)) {
  New-Item -ItemType Directory -Path $dynamicWorkflows | Out-Null
}

# Destination: workspace\dynamic_workflows\<repo>
$dest = Join-Path $dynamicWorkflows $env:NEW_REPO_NAME
if (-not (Test-Path -LiteralPath $dest)) {
  New-Item -ItemType Directory -Path $dest | Out-Null
}

# Safety assert: refuse to clone outside the intended root
if (-not ($dest.ToLowerInvariant().StartsWith($dynamicWorkflows.ToLowerInvariant()))) {
  throw "Refusing to clone outside workspace dynamic_workflows root: $dest"
}

Write-Host "Cloning into: $dest" -ForegroundColor Cyan
git clone "https://github.com/nam20485/$($env:NEW_REPO_NAME).git" $dest
```

Notes:
- If you prefer a fixed, explicit workspace path, set once: `$env:WS_ROOT = 'E:\src\github\nam20485\workflow-launch2'` then use `Join-Path $env:WS_ROOT 'dynamic_workflows'` to avoid drift.
- This approach keeps all runs consistent with the assignment’s detailed steps and prevents “wrong root” placements.

### CWD/workspace drift gotchas (why it can change between runs)

- Terminals retain their own current directory; switching terminals or reusing a pane may change `$PWD` unexpectedly.
- Invoking scripts via the editor, tasks, or chat agents might execute from a different working directory than the one you expect.
- `Resolve-Path "."` resolves from the current process CWD, not the script location. Prefer `$PSScriptRoot` for script-relative files and discover the workspace root with `git rev-parse --show-toplevel` or a pinned `$env:WS_ROOT`.
- Relative clone destinations (`..\..`) are brittle after moving files/folders (e.g., reorganizing `local_ai_instruction_modules`). Use absolute paths or build them with `Join-Path` from a known anchor.

### Diagnostics: verify environment before clone

```powershell
$ErrorActionPreference = 'Stop'
Write-Host "=== Diagnostics (pre-clone) ===" -ForegroundColor Yellow
Write-Host ("PWD: {0}" -f (Get-Location).Path)
Write-Host ("PSScriptRoot: {0}" -f ($PSScriptRoot ?? '<null>'))
try {
  $gitRoot = (git rev-parse --show-toplevel).Trim()
  Write-Host ("git rev-parse --show-toplevel: {0}" -f $gitRoot)
} catch {
  Write-Host "git rev-parse failed (not in a git repo?)" -ForegroundColor DarkYellow
}
Write-Host ("WS_ROOT (optional): {0}" -f ($env:WS_ROOT ?? '<unset>'))

# Decide workspace root in a stable way
$workspaceRoot = if ($env:WS_ROOT) { $env:WS_ROOT } else { try { $gitRoot } catch { (Resolve-Path ".").Path } }
Write-Host ("Chosen workspaceRoot: {0}" -f $workspaceRoot) -ForegroundColor Cyan

$dynamicWorkflows = Join-Path $workspaceRoot 'dynamic_workflows'
Write-Host ("dynamic_workflows path: {0}" -f $dynamicWorkflows)
```

### Stabilization guardrails

- Anchor on a canonical root: either `$env:WS_ROOT` or `git rev-parse --show-toplevel`.
- Use `Join-Path` for all path composition; avoid string concatenation with `\` where possible.
- Use `-LiteralPath` for anything that might include spaces or special chars.
- After cloning, `Set-Location $dest` before running any relative `git` or script commands.

### Copy docs with spaces safely

```powershell
Copy-Item -LiteralPath "E:\src\github\nam20485\workflow-launch2\docs\advanced_memory\Advanced Memory .NET - Dev Plan.md" `
          -Destination "$dest\docs\Advanced Memory .NET - Dev Plan.md" -Force
Copy-Item -LiteralPath "E:\src\github\nam20485\workflow-launch2\docs\advanced_memory\index.html" `
          -Destination "$dest\docs\index.html" -Force
```

### Import labels (idempotent)

```powershell
# Run from the repo root ($dest)
Set-Location $dest
./scripts/import-labels.ps1 -Owner "nam20485" -Repo $env:NEW_REPO_NAME -LabelsPath ".labels.json"
```

### Create milestones (idempotent; optional sleeps)

```powershell
./scripts/create-milestones.ps1 -Owner "nam20485" -Repo $env:NEW_REPO_NAME `
  -Titles @("Phase 1: Foundation","Phase 2: Core Features","Phase 3: Validation") `
  -DueDates @("2025-09-15","2025-10-15","2025-11-15") `
  -SkipExisting
# Optional delay between API calls if rate limiting occurs
Start-Sleep -Milliseconds 200
```

### Commit and push (branch-safe)

```powershell
git checkout -B development
git add .
git commit -m "Seed docs, labels, milestones, workspace/devcontainer rename"
git push -u origin development
```

## Issues and retries log (Run #2)

- Wrong clone destination (rooted under sibling path)
  - Tries: 1 (clone succeeded but to the wrong folder)
  - Root cause: Hard-coded path omitted the `workflow-launch2` segment, diverging from the expected workspace-local `dynamic_workflows/` root.
  - Fix: Use the safer, workspace-anchored clone snippet above.

- Label import script
  - Tries: 2
  - First attempt: Included an unsupported parameter (e.g., `-SkipExisting`) leading to: `A parameter cannot be found that matches parameter name 'SkipExisting'.`
  - Second attempt: Removed the unsupported parameter; labels created/updated successfully.

- Milestones creation
  - Tries: 1
  - Used `-SkipExisting`; all milestones created without errors.

- HTML doc copy and linter warning (Chart.js usage)
  - Tries: 2
  - Initial copy raised a linter warning about an unused Chart instantiation; a follow-up edit introduced a transient syntax error ("," expected).
  - Fixed by restoring the source and assigning the Chart instance to a variable/global to mark it as used.

## References

- Assignment (authoritative): Initiate New Repository — https://github.com/nam20485/agent-instructions/blob/main/ai_instruction_modules/ai-workflow-assignments/initiate-new-repository.md

---

## Append-only updates

- 2025-08-26
  - Established this file as the single append-only log for operational terminal guidance; do not place assignment-specific ops elsewhere.
  - Added safer, workspace-anchored clone snippet with a safety assert to prevent wrong-root clones.
  - Documented CWD/workspace drift gotchas and provided a diagnostics block to verify environment before cloning.
  - Logged Issues and retries for Run #2 (labels: 2 tries; milestones: 1; HTML linter fix: 2; wrong clone root: 1 with remediation).
