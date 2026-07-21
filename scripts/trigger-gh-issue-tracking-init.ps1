#!/usr/bin/env pwsh
#requires -Version 7.0

<#
.SYNOPSIS
    Trigger `/gh-issue-tracking-init` on a freshly seeded agent-context clone.

.DESCRIPTION
    Creates a dispatch issue on the target repo whose body is the single-line
    trigger `/gh-issue-tracking-init`. By default the issue is created bare
    (no labels): the gh-issue-tracking-init skill neither needs nor reads the
    legacy `orchestration:dispatch` label, and manages its own label taxonomy.

    To support the old orchestration method (or dual-method flows), pass
    -ImportLegacyLabels: this bootstraps the `orchestration:dispatch` label
    from -BootstrapLabelsFile and attaches it to the dispatch issue.

    This is the replacement trigger for `trigger-project-setup.ps1`: the legacy
    script dispatches `/orchestrate-dynamic-workflow $workflow_name = project-setup`
    via `create-dispatch-issue.ps1`, which is incompatible with agent-context's
    new structure. This script dispatches the correct follow-up.

    Reuses the existing `create-dispatch-issue.ps1` for issue creation and
    dot-sources the shared `dispatch-labels.ps1` library for the
    `Ensure-DispatchBootstrapLabel` helper (legacy mode only).

.PARAMETER Repo
    Target repository in "owner/repo" form (required).

.PARAMETER BootstrapLabelsFile
    Path to the clone's `.github/.labels.json` used to bootstrap the
    `orchestration:dispatch` label. Only used when -ImportLegacyLabels is set;
    ignored otherwise. Throws if missing when -ImportLegacyLabels is set and
    -DryRun is not.

.PARAMETER ImportLegacyLabels
    Enable legacy orchestration:dispatch label behavior (old method): bootstrap
    the label from -BootstrapLabelsFile and attach it to the dispatch issue.
    Default off: the gh-issue-tracking-init method creates a bare, unlabeled
    dispatch issue.

.PARAMETER DryRun
    Show what would be created without making any changes.

.EXAMPLE
    # Default (new method): bare dispatch issue, no labels.
    ./scripts/trigger-gh-issue-tracking-init.ps1 `
        -Repo "intel-agency/my-app-delta12"

.EXAMPLE
    # Legacy method: bootstrap orchestration:dispatch and label the issue.
    ./scripts/trigger-gh-issue-tracking-init.ps1 `
        -Repo "intel-agency/my-app-delta12" -ImportLegacyLabels `
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

    [Parameter(HelpMessage = 'Path to the clone''s .github/.labels.json used to bootstrap the orchestration:dispatch label. Only used when -ImportLegacyLabels is set.')]
    [string]$BootstrapLabelsFile,

    [Parameter(HelpMessage = 'Enable legacy orchestration:dispatch label behavior: bootstrap the label from -BootstrapLabelsFile and attach it to the dispatch issue (old method). Default off: the gh-issue-tracking-init method creates a bare, unlabeled dispatch issue.')]
    [switch]$ImportLegacyLabels,

    [Parameter(HelpMessage = 'Show what would be created without making any changes.')]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host '=== trigger-gh-issue-tracking-init ===' -ForegroundColor Cyan
if ($DryRun) { Write-Host '[DRY-RUN MODE]' -ForegroundColor Yellow }

$scriptDir = $PSScriptRoot
$createDispatch = Join-Path $scriptDir 'create-dispatch-issue.ps1'
if (-not (Test-Path -LiteralPath $createDispatch)) {
    throw "Required script not found: $createDispatch"
}

# Dot-source the shared dispatch-labels library for Ensure-DispatchBootstrapLabel.
# (Functions only; does not run any dispatch logic, unlike trigger-project-setup.ps1.)
$dispatchLabels = Join-Path $scriptDir 'dispatch-labels.ps1'
if (-not (Test-Path -LiteralPath $dispatchLabels)) {
    throw "Required helper not found: $dispatchLabels (for Ensure-DispatchBootstrapLabel)"
}
. $dispatchLabels

# Legacy label behavior (old orchestration method). Off by default: the new
# gh-issue-tracking-init method creates a bare dispatch issue and does not need
# orchestration:dispatch. Enable to support the old method / dual-method flows.
if ($ImportLegacyLabels) {
    if (-not $BootstrapLabelsFile) {
        throw '-ImportLegacyLabels requires -BootstrapLabelsFile.'
    }
    if (-not (Test-Path -LiteralPath $BootstrapLabelsFile)) {
        throw "Bootstrap labels file not found: $BootstrapLabelsFile"
    }
    Write-Host "Bootstrapping orchestration:dispatch label on $Repo..." -ForegroundColor Cyan -NoNewline
    Ensure-DispatchBootstrapLabel -TargetRepo $Repo -LabelsFile $BootstrapLabelsFile -IsDryRun:$DryRun
    Write-Host ' done' -ForegroundColor Green
}
else {
    Write-Verbose 'Legacy label import disabled (default); dispatch issue will be created without orchestration:dispatch.'
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
    Repo  = $Repo
    Title = $title
    Body  = $body
}
if ($ImportLegacyLabels) {
    $dispatchParams['Labels'] = @('orchestration:dispatch')
}
if ($DryRun) { $dispatchParams['DryRun'] = $true }

& $createDispatch @dispatchParams

Write-Host '=== trigger complete ===' -ForegroundColor Green
