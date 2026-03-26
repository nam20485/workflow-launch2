#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Trigger the project-setup dynamic workflow on a target repository.

.DESCRIPTION
    Creates an "orchestrate-dynamic-workflow" dispatch issue on the target
    repository with $workflow_name = project-setup.  This is intended to be
    called at the end of create-repo-from-plan-docs.ps1 (or any script that
    finishes provisioning a new repo instance) to kick off the orchestrator.

.PARAMETER Repo
    Target repository in the form "owner/repo" (the newly created instance).

.PARAMETER Project
    Optional GitHub project name or number to add the dispatch issue to.

.PARAMETER Milestone
    Optional milestone name or number to assign to the dispatch issue.

.PARAMETER Template
    Optional issue template filename to use.

.PARAMETER Assignee
    Optional array of GitHub usernames to assign to the dispatch issue.

.PARAMETER DryRun
    Show what would be created without making any changes.

.EXAMPLE
    # Trigger project-setup on a newly created repo
    ./scripts/trigger-project-setup.ps1 -Repo "intel-agency/my-new-app"

.EXAMPLE
    # Preview only
    ./scripts/trigger-project-setup.ps1 -Repo "intel-agency/my-new-app" -DryRun

.NOTES
    Requires: GitHub CLI (gh) and authenticated session.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[^/]+/[^/]+$')]
    [string]$Repo,

    [Parameter()]
    [string]$BootstrapLabelsFile,

    [Parameter()]
    [string]$Project,

    [Parameter()]
    [string]$Milestone,

    [Parameter()]
    [string]$Template,

    [Parameter()]
    [string[]]$Assignee,

    [switch]$DryRun
)

$scriptDir = $PSScriptRoot
$createDispatch = Join-Path $scriptDir 'create-dispatch-issue.ps1'

function Get-BootstrapLabelDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LabelsFile,

        [Parameter(Mandatory = $true)]
        [string]$LabelName
    )

    if (-not (Test-Path -LiteralPath $LabelsFile)) {
        throw "Bootstrap labels file not found: $LabelsFile"
    }

    $labels = Get-Content -LiteralPath $LabelsFile -Raw | ConvertFrom-Json
    $label = $labels | Where-Object { $_.name -eq $LabelName } | Select-Object -First 1
    if (-not $label) {
        throw "Bootstrap label '$LabelName' not found in labels file '$LabelsFile'."
    }

    return $label
}

function Ensure-DispatchBootstrapLabel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetRepo,

        [Parameter(Mandatory = $true)]
        [string]$LabelsFile,

        [switch]$IsDryRun
    )

    $labelName = 'orchestration:dispatch'
    $label = Get-BootstrapLabelDefinition -LabelsFile $LabelsFile -LabelName $labelName
    $encodedLabelName = [uri]::EscapeDataString($labelName)

    if ($IsDryRun) {
        Write-Host "[dry-run] Would ensure bootstrap label '$labelName' exists on '$TargetRepo' using '$LabelsFile'." -ForegroundColor Yellow
        return
    }

    & gh api "repos/$TargetRepo/labels/$encodedLabelName" *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Verbose "Bootstrap label '$labelName' already exists on '$TargetRepo'."
        return
    }

    $color = ([string]$label.color).Trim().TrimStart('#')
    $description = if ($null -ne $label.description) { [string]$label.description } else { '' }

    Write-Host "Creating bootstrap label '$labelName' on '$TargetRepo'..." -ForegroundColor Cyan -NoNewline
    $ghArgs = @(
        'api', "repos/$TargetRepo/labels", '-X', 'POST',
        '-f', "name=$labelName",
        '-f', "color=$color"
    )
    if ($description -ne '') {
        $ghArgs += @('-f', "description=$description")
    }

    & gh @ghArgs *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create bootstrap label '$labelName' on '$TargetRepo'."
    }

    Write-Host ' done' -ForegroundColor Green
}

if (-not (Test-Path -LiteralPath $createDispatch)) {
    Write-Error "Required script not found: $createDispatch"
    exit 1
}

$body = @'
/orchestrate-dynamic-workflow
$workflow_name = project-setup
'@

$params = @{
    Repo   = $Repo
    Body   = $body
    Labels = @('orchestration:dispatch')
}
if ($Project) { $params['Project'] = $Project }
if ($Milestone) { $params['Milestone'] = $Milestone }
if ($Template) { $params['Template'] = $Template }
if ($Assignee) { $params['Assignee'] = $Assignee }
if ($DryRun) { $params['DryRun'] = $true }

if ($BootstrapLabelsFile) {
    Ensure-DispatchBootstrapLabel -TargetRepo $Repo -LabelsFile $BootstrapLabelsFile -IsDryRun:$DryRun
}

& $createDispatch @params
