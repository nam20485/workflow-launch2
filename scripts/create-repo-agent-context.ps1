#!/usr/bin/env pwsh
#requires -Version 7.0

<#
.SYNOPSIS
    Create a new `agent-context`-seeded repo with Class-2 cleanup and
    `/gh-issue-tracking-init` hierarchy dispatch.

.DESCRIPTION
    Thin wrapper over the existing `create-repo-with-plan-docs.ps1` + the new
    `cleanup-template-state.ps1` and `trigger-gh-issue-tracking-init.ps1`.

    It accepts the same core parameters as `create-repo-from-slug.ps1` (Slug,
    Owner, Visibility, Count, Yes) plus agent-context-specific ones
    (-TriggerHierarchyInit, default $true). The legacy project-setup dispatch
    (`/orchestrate-dynamic-workflow $workflow_name = project-setup`) is never
    fired by this wrapper, so other templates relying on the legacy trigger are
    unaffected.

    Pipeline order per repo:
      1. create-repo-with-plan-docs.ps1 -SkipProjectSetup <params>
      2. cleanup-template-state.ps1 -RepoRoot <clonePath>
      3. trigger-gh-issue-tracking-init.ps1 -Repo "$Owner/$RepoName"
         -BootstrapLabelsFile "$clonePath/.github/.labels.json"

    The existing `create-repo-with-plan-docs.ps1` main loop is unchanged; only
    the optional `-SkipProjectSetup` switch is added (default behavior
    identical).

.PARAMETER Slug
    Base app-plan slug (prefix). A random suffix is appended to form the final
    repo name.

.PARAMETER Owner
    Repository owner. Default: intel-agency.

.PARAMETER Visibility
    Repository visibility: public or private.

.PARAMETER Count
    How many repos to create from the slug.

.PARAMETER Yes
    Non-interactive mode. Assume yes for all confirmations.

.PARAMETER LaunchAgent
    Launch the editor against the newly created repo after creation.

.PARAMETER TriggerHierarchyInit
    Whether to invoke `/gh-issue-tracking-init` on the new repo after cleanup.
    Default: $true.

.PARAMETER DryRun
    Forward -DryRun to all invoked scripts.

.EXAMPLE
    ./scripts/create-repo-agent-context.ps1 `
        -Slug "gap-miner-v2" -Visibility public -Yes

.EXAMPLE
    ./scripts/create-repo-agent-context.ps1 `
        -Slug "my-app" -Count 2 -Yes -DryRun

.NOTES
    Part of W1.5 (replace broken hierarchy-init trigger) from the
    template-content-strategy plan.
    See docs/plans/workflow-launch2-clone-pipeline-class2-cleanup.md.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'Base app-plan slug (prefix).')]
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$Slug,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Owner = 'intel-agency',

    [Parameter()]
    [ValidateSet('public', 'private')]
    [string]$Visibility = 'public',

    [Parameter()]
    [ValidateScript({ $_ -ge 1 })]
    [int]$Count = 1,

    [Parameter()]
    [switch]$Yes,

    [Parameter()]
    [switch]$LaunchAgent,

    [Parameter()]
    [bool]$TriggerHierarchyInit = $true,

    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host '=== create-repo-agent-context ===' -ForegroundColor Cyan
if ($DryRun) { Write-Host '[DRY-RUN MODE]' -ForegroundColor Yellow }

$scriptDir = $PSScriptRoot
$createRepoScript = Join-Path $scriptDir 'create-repo-with-plan-docs.ps1'
$cleanupScript = Join-Path $scriptDir 'cleanup-template-state.ps1'
$triggerScript = Join-Path $scriptDir 'trigger-gh-issue-tracking-init.ps1'

foreach ($required in @($createRepoScript, $cleanupScript, $triggerScript)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Required script not found: $required"
    }
}

# Agent-context template identity — hardcoded (this wrapper is agent-context-specific).
$TemplateRepoName = 'agent-context'
$TemplateOwner = 'intel-agency'

# Launcher conventions.
$PlanDocsDir = "./plan_docs/$Slug"
$CloneParentDir = '../dynamic_workflows'

Write-Host "Calling create-repo-with-plan-docs.ps1 (with -SkipProjectSetup)..." -ForegroundColor Cyan

$createParams = @{
    RepoName          = $Slug
    Owner             = $Owner
    Visibility        = $Visibility
    Count             = $Count
    PlanDocsDir       = $PlanDocsDir
    CloneParentDir    = $CloneParentDir
    TemplateRepoName  = $TemplateRepoName
    TemplateOwner     = $TemplateOwner
    SkipProjectSetup  = $true
}
if ($Yes)        { $createParams['Yes'] = $true }
if ($LaunchAgent){ $createParams['LaunchEditor'] = $true }
if ($DryRun)     { $createParams['DryRun'] = $true }

# Invoke the existing workflow. It returns each clone path on the pipeline
# (Write-Output) and signals failure via its exit code (exit 1).
$clonePaths = @(& $createRepoScript @createParams | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) })
if ($LASTEXITCODE -ne 0) {
    throw "create-repo-with-plan-docs failed (exit code $LASTEXITCODE)."
}
if ($clonePaths.Count -eq 0) {
    throw 'create-repo-with-plan-docs returned no clone paths.'
}

Write-Host ''
Write-Host "Found $($clonePaths.Count) freshly cloned repo(s):" -ForegroundColor Cyan
foreach ($p in $clonePaths) { Write-Host "  - $p" -ForegroundColor DarkGray }
Write-Host ''

foreach ($clonePath in $clonePaths) {
    $repoName = Split-Path -Leaf $clonePath
    $repoFullName = "$Owner/$repoName"

    Write-Host "=== post-clone: $repoFullName ===" -ForegroundColor Cyan

    # Step 2: Class-2 cleanup
    Write-Host 'Running cleanup-template-state.ps1...' -ForegroundColor Cyan -NoNewline
    $cleanupParams = @{ RepoRoot = $clonePath }
    if ($DryRun) { $cleanupParams['DryRun'] = $true }
    & $cleanupScript @cleanupParams
    Write-Host ' done' -ForegroundColor Green

    # Amend the seed commit to include the cleanup changes, then force-push.
    if (-not $DryRun) {
        Write-Host 'Amending seed commit with cleanup...' -ForegroundColor Cyan -NoNewline
        Push-Location -LiteralPath $clonePath
        try {
            & git add .
            & git commit --amend --no-edit --message "Seed $repoName from template with plan docs, placeholder replacements, and Class-2 cleanup"
        }
        finally {
            Pop-Location
        }
        Write-Host ' done' -ForegroundColor Green
    }

    # Step 3: Dispatch /gh-issue-tracking-init
    if ($TriggerHierarchyInit) {
        Write-Host "Running trigger-gh-issue-tracking-init.ps1 on $repoFullName..." -ForegroundColor Cyan
        $triggerParams = @{ Repo = $repoFullName }
        $labelsFile = Join-Path $clonePath '.github/.labels.json'
        if (Test-Path -LiteralPath $labelsFile) {
            $triggerParams['BootstrapLabelsFile'] = $labelsFile
        }
        if ($DryRun) { $triggerParams['DryRun'] = $true }
        & $triggerScript @triggerParams
        Write-Host ' done' -ForegroundColor Green
    }
    else {
        Write-Verbose "-TriggerHierarchyInit is $false; skipping trigger on $repoFullName"
    }
}

Write-Host '=== all done ===' -ForegroundColor Green
