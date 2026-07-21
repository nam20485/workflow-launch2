#!/usr/bin/env pwsh
#requires -Version 7.0

<#
.SYNOPSIS
    Trigger `/gh-issue-tracking-init` on a freshly seeded agent-context clone.

.DESCRIPTION
    Creates an `orchestration:dispatch`-labeled issue on the target repo whose
    body is the single-line dispatch trigger `/gh-issue-tracking-init`. The
    skill's no-arg defaults resolve to the current repo + seeded plan_docs/,
    which matches the post-clone state exactly.

    This is the replacement trigger for `trigger-project-setup.ps1`: the legacy
    script dispatches `/orchestrate-dynamic-workflow $workflow_name = project-setup`
    via `create-dispatch-issue.ps1`, which is incompatible with agent-context's
    new structure. This script dispatches the correct follow-up.

    Reuses the existing `create-dispatch-issue.ps1` for issue creation and
    dot-sources `trigger-project-setup.ps1` for the `Ensure-DispatchBootstrapLabel`
    helper.

.PARAMETER Repo
    Target repository in "owner/repo" form (required).

.PARAMETER BootstrapLabelsFile
    Path to the clone's `.github/.labels.json` used to bootstrap the
    `orchestration:dispatch` label if it doesn't yet exist (required unless
    -DryRun). Throws if missing when -DryRun is not set.

.PARAMETER DryRun
    Show what would be created without making any changes.

.EXAMPLE
    ./scripts/trigger-gh-issue-tracking-init.ps1 `
        -Repo "intel-agency/my-app-delta12" `
        -BootstrapLabelsFile "./clones/my-app-delta12/.github/.labels.json"

.EXAMPLE
    ./scripts/trigger-gh-issue-tracking-init.ps1 `
        -Repo "intel-agency/my-app-delta12" -DryRun

.NOTES
    Part of W1.5 (replace broken hierarchy-init trigger) from the
    template-content-strategy plan. Coexists with legacy
    `trigger-project-setup.ps1` — does not replace or modify it.
    See docs/plans/workflow-launch2-clone-pipeline-class2-cleanup.md.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'Target repository in "owner/repo" form.')]
    [ValidatePattern('^[^/]+/[^/]+$')]
    [string]$Repo,

    [Parameter(HelpMessage = 'Path to the clone''s .github/.labels.json used to bootstrap the orchestration:dispatch label.')]
    [string]$BootstrapLabelsFile,

    [Parameter(HelpMessage = 'Show what would be created without making any changes.')]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host '=== trigger-gh-issue-tracking-init ===' -ForegroundColor Cyan
if ($DryRun) { Write-Host '[DRY-RUN MODE]' -ForegroundColor Yellow }

$scriptDir = $PSScriptRoot
$createDispatch = Join-Path $scriptDir 'create-dispatch-issue.ps1'
$projectSetupTrigger = Join-Path $scriptDir 'trigger-project-setup.ps1'

if (-not (Test-Path -LiteralPath $createDispatch)) {
    throw "Required script not found: $createDispatch"
}
if (-not (Test-Path -LiteralPath $projectSetupTrigger)) {
    throw "Required helper not found: $projectSetupTrigger (for Ensure-DispatchBootstrapLabel)"
}

# Dot-source the legacy trigger to borrow its label helpers. We use its
# Ensure-DispatchBootstrapLabel function to ensure the orchestration:dispatch
# label exists before issue creation.
. $projectSetupTrigger

# Bootstrap the required label if a labels file was provided.
if ($BootstrapLabelsFile) {
    if (-not (Test-Path -LiteralPath $BootstrapLabelsFile)) {
        throw "Bootstrap labels file not found: $BootstrapLabelsFile"
    }
    Write-Host "Bootstrapping orchestration:dispatch label on $Repo..." -ForegroundColor Cyan -NoNewline
    Ensure-DispatchBootstrapLabel -TargetRepo $Repo -LabelsFile $BootstrapLabelsFile -IsDryRun:$DryRun
    Write-Host ' done' -ForegroundColor Green
}
else {
    Write-Verbose 'No BootstrapLabelsFile provided; skipping orchestration:dispatch label bootstrap'
}

# Build the dispatch issue body: a single-line invocation of the skill.
# No args — the skill's defaults (current repo + plan_docs/) are exactly the
# right state for a freshly seeded clone.
$body = '/gh-issue-tracking-init'
$title = 'gh-issue-tracking-init'

Write-Host "Creating dispatch issue on $Repo..." -ForegroundColor Cyan -NoNewline
if ($DryRun) {
    Write-Host " [dry-run] would create issue '$title' with body: '$body'" -ForegroundColor Yellow
}

$dispatchParams = @{
    Repo   = $Repo
    Title  = $title
    Body   = $body
    Labels = @('orchestration:dispatch')
}
if ($DryRun) { $dispatchParams['DryRun'] = $true }

& $createDispatch @dispatchParams

Write-Host '=== trigger complete ===' -ForegroundColor Green
