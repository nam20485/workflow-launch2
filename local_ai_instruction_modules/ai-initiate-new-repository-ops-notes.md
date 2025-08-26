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

## References

- Assignment (authoritative): Initiate New Repository — https://github.com/nam20485/agent-instructions/blob/main/ai_instruction_modules/ai-workflow-assignments/initiate-new-repository.md
