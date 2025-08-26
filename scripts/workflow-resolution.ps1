param(
    [Parameter(Mandatory=$true)][string]$WorkflowName,
    [Parameter(Mandatory=$true)][string]$ContextRepoName,
    [string[]]$AppPlanDocs = @(),
    [switch]$TraceOnly,
    [string]$Owner = "nam20485",
    [string]$OutputDir = "run-plans",
    [string]$CaseId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-DirectoryIfMissing {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null }
}

# -- Authoritative resolution helpers (no index mode) --

$CanonicalOwner = 'nam20485'
$CanonicalRepo  = 'agent-instructions'
$CanonicalRef   = 'main'

function Get-RawGitHubUrl {
    param([Parameter(Mandatory=$true)][string]$RelativePath)
    # Build raw.githubusercontent URL for canonical file
    return "https://raw.githubusercontent.com/$CanonicalOwner/$CanonicalRepo/$CanonicalRef/$RelativePath"
}

function Get-RepoRoot {
    return (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "..\")).Path
}

function Get-AuthoritativeMirrorPath {
    param([Parameter(Mandatory=$true)][string]$RelativePath)
    $root = Get-RepoRoot
    return (Join-Path $root (Join-Path 'local_ai_instructions/authoritative-mirror' $RelativePath))
}

function Get-CanonicalContent {
    param([Parameter(Mandatory=$true)][string]$RelativePath)
    # Try remote fetch first
    $rawUrl = Get-RawGitHubUrl -RelativePath $RelativePath
    try {
        $wcParams = @{ Uri = $rawUrl; UseBasicParsing = $true }
        $resp = Invoke-WebRequest @wcParams -ErrorAction Stop
        if ($resp -and $resp.Content -and ($resp.Content.Trim().Length -gt 0)) {
            return [pscustomobject]@{ Source = 'remote'; Url = $rawUrl; Content = $resp.Content }
        }
    } catch {
        # swallow and fall back
    }
    # Fallback to local mirror
    $mirrorPath = Get-AuthoritativeMirrorPath -RelativePath $RelativePath
    if (-not (Test-Path $mirrorPath)) {
        throw "Canonical file not available remotely and local mirror missing: $RelativePath (attempted $rawUrl and $mirrorPath)"
    }
    $text = Get-Content -Path $mirrorPath -Raw -ErrorAction Stop
    return [pscustomobject]@{ Source = 'mirror'; Url = $mirrorPath; Content = $text }
}

function Parse-FirstJsonBlock {
    param([Parameter(Mandatory=$true)][string]$Markdown)
    # Look for a fenced JSON block ```json ... ``` and parse the first one
    $regex = [regex]'```json\s*([\s\S]*?)\s*```'
    $m = $regex.Match($Markdown)
    if ($m.Success) {
        $jsonText = $m.Groups[1].Value
        try { return ($jsonText | ConvertFrom-Json) } catch { throw "Failed to parse JSON block from markdown: $($_.Exception.Message)" }
    }
    throw "No JSON block found in authoritative markdown"
}

function Resolve-DynamicWorkflowAuthoritative {
    param([Parameter(Mandatory=$true)][string]$WorkflowName)
    $rel = "ai-workflow-assignments/dynamic-workflows/$WorkflowName.md"
    $doc = Get-CanonicalContent -RelativePath $rel
    $payload = Parse-FirstJsonBlock -Markdown $doc.Content
    if (-not $payload.assignments) { throw "Authoritative dynamic workflow missing 'assignments' JSON array: $rel" }
    # Add trace info on each assignment for later reference
    $assignments = @()
    foreach ($a in $payload.assignments) {
        $assignments += [pscustomobject]@{ shortId=$a.shortId; passContext=[bool]$a.passContext; _source=$doc.Source; _url=$doc.Url }
    }
    return ,$assignments
}

function Get-AssignmentSpecAuthoritative {
    param([Parameter(Mandatory=$true)][string]$ShortId)
    $rel = "ai-workflow-assignments/$ShortId.md"
    $doc = Get-CanonicalContent -RelativePath $rel
    $payload = Parse-FirstJsonBlock -Markdown $doc.Content
    # Ensure required fields
    foreach ($req in @('title','acceptanceCriteria','detailedSteps')) {
        if (-not ($payload.PSObject.Properties.Name -contains $req)) { throw "Authoritative assignment missing '$req': $rel" }
    }
    # Stamp source on output
    $payload | Add-Member -NotePropertyName _source -NotePropertyValue $doc.Source
    $payload | Add-Member -NotePropertyName _url -NotePropertyValue $doc.Url
    return $payload
}

# Resolve workflow → assignments (authoritative)
$resolvedAssignments = Resolve-DynamicWorkflowAuthoritative -WorkflowName $WorkflowName

# Build trace and plan
$trace = @()
$planSteps = @()
foreach ($a in $resolvedAssignments) {
    $shortId = $a.shortId
    $spec = Get-AssignmentSpecAuthoritative -ShortId $shortId

    $trace += [pscustomobject]@{
        WorkflowName = $WorkflowName
        Assignment   = $shortId
        PassedContext= [bool]$a.passContext
        Title        = $spec.title
        Source       = $spec._source
        SpecUrl      = $spec._url
    }

    # Expand command templates with placeholders
    foreach ($step in $spec.detailedSteps) {
        $cmdTemplate = $step.commandTemplate
        if ($null -ne $cmdTemplate) {
            $cmdTemplate = $cmdTemplate.Replace('{repo_name}', $ContextRepoName)
            $cmdTemplate = $cmdTemplate.Replace('{owner}', $Owner)
        }

        # Expand per-document copy steps if {doc} placeholder appears
        if ($cmdTemplate -and $cmdTemplate.Contains('{doc}')) {
            foreach ($doc in $AppPlanDocs) {
                $expanded = $cmdTemplate.Replace('{doc}', $doc)
                $planSteps += [pscustomobject]@{
                    assignment    = $shortId
                    stepId        = "$($step.id):$([System.IO.Path]::GetFileName($doc))"
                    description   = "$($step.description) ($doc)"
                    kind          = $step.kind
                    command       = $expanded
                }
            }
        }
        else {
            $planSteps += [pscustomobject]@{
                assignment    = $shortId
                stepId        = $step.id
                description   = $step.description
                kind          = $step.kind
                command       = $cmdTemplate
            }
        }
    }
}

# Emit artifacts
$root = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "..\")).Path
$outDir = Join-Path $root $OutputDir
New-DirectoryIfMissing -Path $outDir
$base = if ($CaseId) { "$($WorkflowName)-$($ContextRepoName)-$CaseId" } else { "$($WorkflowName)-$($ContextRepoName)-" + (Get-Date -Format "yyyyMMdd-HHmmss") }

$tracePath = Join-Path $outDir "$base.trace.json"
$planPath  = Join-Path $outDir "$base.plan.json"
$mdPath    = Join-Path $outDir "$base.plan.md"

$trace | ConvertTo-Json -Depth 6 | Out-File -FilePath $tracePath -Encoding UTF8
$planSteps | ConvertTo-Json -Depth 6 | Out-File -FilePath $planPath -Encoding UTF8

# Markdown summary (authoritative)
$specs = $resolvedAssignments | ForEach-Object { Get-AssignmentSpecAuthoritative -ShortId $_.shortId }
$ac = @()
foreach ($s in $specs) { $ac += $s.acceptanceCriteria }

$md = @()
$md += "# Execution Plan (dry)"
$md += ""
$md += "- Workflow: `$WorkflowName = $WorkflowName"
$md += "- Terminal assignments: " + ((($trace | ForEach-Object { $_.Assignment } | Select-Object -Unique)) -join ", ")
$md += "- Repo name: $ContextRepoName"
$md += "- Owner: $Owner"
$md += "- App plan docs: " + ($AppPlanDocs -join ", ")
$md += ""
$md += "## Resolution trace"
$trace | ForEach-Object {
    $src = if ($_.SpecUrl) { $_.SpecUrl } else { '' }
    $md += "- $($_.WorkflowName) → $($_.Assignment) (title: $($_.Title); passContext: $($_.PassedContext); source: $($_.Source); spec: $src)"
}
$md += ""
$md += "## Acceptance criteria (Definition of Done)"
foreach ($line in $ac) { $md += "- $line" }
$md += ""
$md += "## Planned steps"
$planSteps | ForEach-Object {
    $md += "- [$($_.assignment)/$($_.stepId)] $($_.description)"
    if ($_.command) { $md += "  - kind: $($_.kind)"; $md += "  - command: `$ $_.command" }
}
$md -join "`n" | Out-File -FilePath $mdPath -Encoding UTF8

Write-Host "Trace written: $tracePath" -ForegroundColor Green
Write-Host "Plan written:  $planPath" -ForegroundColor Green
Write-Host "Markdown:      $mdPath" -ForegroundColor Green

if ($TraceOnly.IsPresent) {
    Write-Host "Trace-only mode: no actions executed." -ForegroundColor Yellow
}
