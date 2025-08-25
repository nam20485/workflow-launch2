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

function Read-AssignmentIndex {
    $repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "..\")).Path
    $candidates = @(
        (Join-Path $repoRoot "local_ai_instructions\assignment-index.json"),
        (Join-Path $repoRoot ".ai\assignment-index.json")
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) {
            return (Get-Content $p -Raw | ConvertFrom-Json)
        }
    }
    throw "Assignment index not found. Looked for: `n - $($candidates -join "`n - ")"
}

function Resolve-DynamicWorkflow {
    param(
        [pscustomobject]$Index,
        [string]$WorkflowName
    )
    if (-not ($Index.dynamicWorkflows.PSObject.Properties.Name -contains $WorkflowName)) {
        throw "Dynamic workflow '$WorkflowName' not found in local index. Consult agent-instructions repo for canonical definition."
    }
    $Index.dynamicWorkflows.$WorkflowName.assignments
}

function Get-AssignmentSpec {
    param(
        [pscustomobject]$Index,
        [string]$ShortId
    )
    if (-not ($Index.assignments.PSObject.Properties.Name -contains $ShortId)) {
        throw "Assignment '$ShortId' not found in local index. Consult agent-instructions repo for canonical definition."
    }
    $Index.assignments.$ShortId
}

function New-DirectoryIfMissing {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null }
}

# Load index
$index = Read-AssignmentIndex

# Resolve workflow → assignments
$resolvedAssignments = Resolve-DynamicWorkflow -Index $index -WorkflowName $WorkflowName

# Build trace and plan
$trace = @()
$planSteps = @()
foreach ($a in $resolvedAssignments) {
    $shortId = $a.shortId
    $spec = Get-AssignmentSpec -Index $index -ShortId $shortId

    $trace += [pscustomobject]@{
        WorkflowName = $WorkflowName
        Assignment   = $shortId
        PassedContext= [bool]$a.passContext
        Title        = $spec.title
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

# Markdown summary
$specs = $resolvedAssignments | ForEach-Object { Get-AssignmentSpec -Index $index -ShortId $_.shortId }
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
    $md += "- $($_.WorkflowName) → $($_.Assignment) (title: $($_.Title); passContext: $($_.PassedContext))"
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
