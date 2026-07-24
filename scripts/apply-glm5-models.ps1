#!/usr/bin/env pwsh
#requires -Version 7.0

<#
.SYNOPSIS
    Normalize every agent model to zai-coding-plan/glm-5 on a freshly cloned
    orchestrator-dispatched instance.

.DESCRIPTION
    opencode resolves the effective model in precedence order: built-in <
    global config < project config (.opencode/opencode.jsonc) < session (--model)
    < AGENT FRONTMATTER model:. The agent-context template ships a per-tier model
    mix at BOTH layers — agent frontmatter (glm-5.2 for implementers/specialists;
    opencode-go/qwen3.7-max for coordinators) AND a project-config
    `model: glm-5.2`. Those are correct for INTERACTIVE use but they OVERRIDE the
    orchestrator-service dispatch defaults (`--model zai-coding-plan/glm-5
    --variant high`) on every headless dispatch: subagents run glm-5.2 and the
    orchestrator runs qwen3.7-max, defeating the single flat tier
    (glm-5 + variant high) the orchestrator-service image config intends.

    This script rewrites the cloned instance's model config so every headless
    dispatch runs glm-5:

      1. Agent frontmatter (.opencode/agents/*.md): set every `model:` value to
         `zai-coding-plan/glm-5`. The frontmatter line is KEPT and rewritten in
         place (not stripped) so the value is explicit, not inherited.
         Coordinators (orchestrator, planner, team-lead, team-orchestrator) ARE
         included — unlike permission relaxation (see apply-headless-permissions.ps1
         coordinator exemption): the qwen3.7-max override is removed for the same
         reason as the glm-5.2 overrides.

      2. Project config (.opencode/opencode.jsonc): set the top-level `"model"`
         value to `zai-coding-plan/glm-5` so the project-config default no longer
         overrides the global/dispatch default. `small_model` is left untouched.

    SCOPE: Only invoked from create-repo-agent-context.ps1 — the orchestrator-
    dispatch seeding path. Repos cloned for NON-orchestrator (interactive) use
    never run this script, so the template's per-tier models stay intact for
    them. The template itself is intentionally left unchanged (it seeds every
    repo, orchestrator or otherwise).

    Idempotent: an already-glm-5 value is left untouched. Safe to re-run.

.PARAMETER RepoRoot
    Absolute or relative path to the freshly cloned repository root.

.PARAMETER DryRun
    Log planned operations without touching the filesystem.

.EXAMPLE
    ./scripts/apply-glm5-models.ps1 -RepoRoot "/tmp/clones/my-app-delta12"

.EXAMPLE
    ./scripts/apply-glm5-models.ps1 -RepoRoot ".\my-app-delta12" -DryRun

.NOTES
    Runs AFTER clone + placeholder replacement + Class-2 cleanup + headless
    permissions but BEFORE the seed-commit amend, so the normalized models ship
    in the pushed seed commit. Sibling override to apply-headless-permissions.ps1.
    Root cause: opencode precedence makes agent frontmatter `model:` the decisive
    layer, so the dispatch `--model` and global `model` are both defeated by the
    workspace agent definitions cloned from the template.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'Path to the freshly cloned repository root.')]
    [ValidateNotNullOrEmpty()]
    [string]$RepoRoot,

    [Parameter(HelpMessage = 'Log planned operations without touching the filesystem.')]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# UTF-8 without BOM — these are committed repo files; never introduce a BOM.
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

# The single flat-tier model the orchestrator-service dispatch intends (paired
# with --variant high plumbed from webhook_receiver/config.py).
$TargetModel = 'zai-coding-plan/glm-5'

# Project-config top-level "model" value (NOT small_model). `"model"` as a literal
# quoted key never matches the `small_model` key: in `"small_model"` the opening
# quote precedes `small`, so there is no `"model"` substring at the key boundary.
$configModelRe = [regex]'"model"\s*:\s*"[^"]*"'

Write-Host '=== apply-glm5-models ===' -ForegroundColor Cyan
if ($DryRun) { Write-Host '[DRY-RUN MODE]' -ForegroundColor Yellow }

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    throw "RepoRoot not found: $RepoRoot"
}

$resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
Write-Host "RepoRoot: $resolvedRoot" -ForegroundColor DarkGray
Write-Host "Target model: $TargetModel" -ForegroundColor DarkGray

# ── 1. Agent frontmatter: model: -> zai-coding-plan/glm-5 ───────────────────

$agentsDir = Join-Path $resolvedRoot '.opencode/agents'
$totalRewritten = 0
$agentsTouched = 0

if (Test-Path -LiteralPath $agentsDir) {
    $agentFiles = @(Get-ChildItem -LiteralPath $agentsDir -File -Filter '*.md' -Force)
    foreach ($file in $agentFiles) {
        $path = $file.FullName
        $raw = [System.IO.File]::ReadAllText($path, $utf8NoBom)

        # Preserve the file's line ending (CRLF or LF) and trailing newline.
        $le = if ($raw.Contains("`r`n")) { "`r`n" } else { "`n" }
        $lines = $raw -split "\r?\n"

        $inFrontmatter = $false
        $fenceCount = 0
        $rewritesThisFile = 0
        $out = [System.Collections.Generic.List[string]]::new()

        foreach ($line in $lines) {
            if ($line -match '^---\s*$') {
                $fenceCount++
                if ($fenceCount -eq 1) {
                    $inFrontmatter = $true
                }
                elseif ($fenceCount -ge 2) {
                    $inFrontmatter = $false
                }
                $out.Add($line)
                continue
            }

            # A column-0 `model:` key (top-level frontmatter field). Rewrite the
            # value in place; keep the line (do not strip — explicit, not inherited).
            if ($inFrontmatter -and $line -match '^model:\s*(\S[^\r\n]*?)\s*$') {
                $currentVal = $Matches[1].Trim()
                if ($currentVal -ne $TargetModel) {
                    $line = "model: $TargetModel"
                    $rewritesThisFile++
                }
            }

            $out.Add($line)
        }

        if ($rewritesThisFile -gt 0) {
            $result = ($out -join $le)
            if ($DryRun) {
                Write-Host (" [dry-run] {0}: would set model -> {1}" -f $file.Name, $TargetModel) -ForegroundColor Yellow
            }
            else {
                [System.IO.File]::WriteAllText($path, $result, $utf8NoBom)
                Write-Host (" {0}: model -> {1}" -f $file.Name, $TargetModel) -ForegroundColor DarkGray
            }
            $totalRewritten += $rewritesThisFile
            $agentsTouched++
        }
        else {
            Write-Host " $($file.Name): model already $TargetModel (unchanged)" -ForegroundColor DarkGray
        }
    }
}
else {
    Write-Host ' .opencode/agents/ not found — skipping agent frontmatter' -ForegroundColor DarkGray
}

Write-Host ("Agent frontmatter: {0} file(s) rewritten to {1}" -f $agentsTouched, $TargetModel) -ForegroundColor Green

# ── 2. Project config opencode.jsonc/.json: top-level model -> glm-5 ─────────

$jsoncPath = Join-Path $resolvedRoot '.opencode/opencode.jsonc'
$jsonPath = Join-Path $resolvedRoot '.opencode/opencode.json'
$configTouched = $false

foreach ($cfgPath in @($jsoncPath, $jsonPath)) {
    if (-not (Test-Path -LiteralPath $cfgPath)) { continue }

    $raw = [System.IO.File]::ReadAllText($cfgPath, $utf8NoBom)
    if ($configModelRe.IsMatch($raw)) {
        $alreadyRe = [regex]('"model"\s*:\s*"{0}"' -f [regex]::Escape($TargetModel))
        if ($alreadyRe.IsMatch($raw)) {
            Write-Host " $(Split-Path -Leaf $cfgPath): top-level model already $TargetModel (unchanged)" -ForegroundColor DarkGray
        }
        else {
            $newRaw = $configModelRe.Replace($raw, ('"model": "{0}"' -f $TargetModel), 1)
            if ($DryRun) {
                Write-Host (" [dry-run] {0}: would set top-level model -> {1}" -f (Split-Path -Leaf $cfgPath), $TargetModel) -ForegroundColor Yellow
            }
            else {
                [System.IO.File]::WriteAllText($cfgPath, $newRaw, $utf8NoBom)
                Write-Host (" {0}: top-level model -> {1}" -f (Split-Path -Leaf $cfgPath), $TargetModel) -ForegroundColor DarkGray
            }
            $configTouched = $true
        }
    }
    else {
        Write-Host " $(Split-Path -Leaf $cfgPath): no top-level model key (unchanged)" -ForegroundColor DarkGray
    }
    break  # only one of .jsonc / .json exists
}

if (-not $configTouched -and -not (Test-Path -LiteralPath $jsoncPath) -and -not (Test-Path -LiteralPath $jsonPath)) {
    Write-Host ' .opencode/opencode.json(c) not found — skipping project config' -ForegroundColor DarkGray
}

Write-Host '=== apply-glm5-models complete ===' -ForegroundColor Green
