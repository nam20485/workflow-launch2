#!/usr/bin/env pwsh
#requires -Version 7.0

<#
.SYNOPSIS
    Remove Class-2 template state from a freshly cloned agent-context instance.

.DESCRIPTION
    Idempotent post-clone cleanup script that removes the template's own
    project-specific state (memory.md contents, completed/deferred plans,
    foreign run-reviews) while preserving the lifecycle directory structure
    for the clone's own plans.

    - `.agents/memory.md` is reset to a blank skeleton (section headers only,
      empty Current Activity).
    - `docs/plans/.completed/*.md` and `docs/plans/.deferred/*.md` are deleted
      (lifecycle directories preserved).
    - `docs/plans/.completed/run-issues-review/` subtree is removed entirely
      (downstream-specific run reports that leaked into the template).

    Idempotent: missing paths are skipped. Safe to run multiple times on the
    same clone.

.PARAMETER RepoRoot
    Absolute path to the freshly cloned repository working directory.

.PARAMETER DryRun
    Log planned operations without touching the filesystem.

.EXAMPLE
    ./scripts/cleanup-template-state.ps1 -RepoRoot "/tmp/clones/my-app-delta12"

.EXAMPLE
    ./scripts/cleanup-template-state.ps1 -RepoRoot ".\my-app-delta12" -DryRun

.NOTES
    Class-2 cleanup step (W1.1–W1.3) from the template-content-strategy plan.
    Should run AFTER clone + placeholder replacement but BEFORE Copy-PlanDocs,
    so Update-TemplatePlaceholders doesn't substitute into files we're about to
    delete. See docs/plans/workflow-launch2-clone-pipeline-class2-cleanup.md.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'Absolute or relative path to the freshly cloned repository root.')]
    [ValidateNotNullOrEmpty()]
    [string]$RepoRoot,

    [Parameter(HelpMessage = 'Log planned operations without touching the filesystem.')]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Minimal skeleton memory content: section headers only, empty activity.
$MemorySkeleton = @'
# Project Memory

## Current Activity

*Current activity for this project instance will be recorded here.*

## Completed Work Items

*Finished work will be logged here.*

## Decisions

*Design decisions and their rationale will be recorded here.*

## Remember To Do

*Deferred tasks and future changes will be tracked here.*
'@

Write-Host '=== cleanup-template-state ===' -ForegroundColor Cyan
if ($DryRun) { Write-Host '[DRY-RUN MODE]' -ForegroundColor Yellow }

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    throw "RepoRoot not found: $RepoRoot"
}

$resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
Write-Host "RepoRoot: $resolvedRoot" -ForegroundColor DarkGray

$memoryPath = Join-Path $resolvedRoot '.agents/memory.md'

# --- Memory reset ---
Write-Host 'Resetting memory.md...' -ForegroundColor Cyan -NoNewline
if (Test-Path -LiteralPath $memoryPath) {
    if ($DryRun) {
        Write-Host " [dry-run] would overwrite $memoryPath with skeleton" -ForegroundColor Yellow
    }
    else {
        Set-Content -LiteralPath $memoryPath -Value $MemorySkeleton -NoNewline -Encoding utf8NoBOM
    }
    Write-Host ' done' -ForegroundColor Green
}
else {
    Write-Host ' skipped (memory.md not present)' -ForegroundColor DarkGray
}

# --- Clear template plans (completed / deferred) ---
function Remove-WildcardFiles {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string]$Pattern
    )

    if (-not (Test-Path -LiteralPath $Directory)) {
        Write-Verbose "Directory not present, skipping: $Directory"
        return , @()
    }

    $matches = @(Get-ChildItem -LiteralPath $Directory -File -Force -Filter $Pattern)
    foreach ($m in $matches) {
        if ($DryRun) {
            Write-Host " [dry-run] would remove: $($m.FullName)" -ForegroundColor Yellow
        }
        else {
            Remove-Item -LiteralPath $m.FullName -Force
        }
        Write-Verbose "Removed: $($m.FullName)"
    }

    return , $matches
}

$completedDir = Join-Path $resolvedRoot 'docs/plans/.completed'
$deferredDir   = Join-Path $resolvedRoot 'docs/plans/.deferred'

Write-Host 'Clearing template completed plans...' -ForegroundColor Cyan -NoNewline
$removedCompleted = Remove-WildcardFiles -Directory $completedDir -Pattern '*.md'
Write-Host " done ($($removedCompleted.Count) removed)" -ForegroundColor Green

Write-Host 'Clearing template deferred plans...' -ForegroundColor Cyan -NoNewline
$removedDeferred = Remove-WildcardFiles -Directory $deferredDir -Pattern '*.md'
Write-Host " done ($($removedDeferred.Count) removed)" -ForegroundColor Green

# --- Remove foreign artifacts (run-issues-review/) ---
$runReviewDir = Join-Path $resolvedRoot 'docs/plans/.completed/run-issues-review'
Write-Host 'Removing foreign run-review artifacts...' -ForegroundColor Cyan -NoNewline
if (Test-Path -LiteralPath $runReviewDir) {
    if ($DryRun) {
        Write-Host " [dry-run] would remove tree: $runReviewDir" -ForegroundColor Yellow
    }
    else {
        Remove-Item -LiteralPath $runReviewDir -Recurse -Force
    }
    Write-Host ' done' -ForegroundColor Green
}
else {
    Write-Host ' skipped (not present)' -ForegroundColor DarkGray
}

Write-Host '=== cleanup complete ===' -ForegroundColor Green
