Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
Push-Location $root
try {
  Write-Host "Generating plan (case1)..." -ForegroundColor Cyan
  $docs1 = @('docs\advanced_memory\Advanced Memory .NET - Dev Plan.md')
  ./scripts/workflow-resolution.ps1 -WorkflowName 'initiate-new-repo' -ContextRepoName 'sample-repo' -AppPlanDocs $docs1 -TraceOnly -CaseId 'case1'

  Write-Host "Compare plan JSON (case1)" -ForegroundColor Cyan
  ./scripts/plan-compare.ps1 -Expected './tests/goldens/initiate-new-repo/case1.plan.json' -Actual './run-plans/initiate-new-repo-sample-repo-case1.plan.json' -Kind json

  Write-Host "Generating plan (case2)..." -ForegroundColor Cyan
  $docs2 = @(
    'docs\advanced_memory\Advanced Memory .NET - Dev Plan.md',
    'docs\advanced_memory\index.html'
  )
  ./scripts/workflow-resolution.ps1 -WorkflowName 'initiate-new-repo' -ContextRepoName 'sample-repo-2' -AppPlanDocs $docs2 -TraceOnly -CaseId 'case2'

  Write-Host "Compare plan JSON (case2)" -ForegroundColor Cyan
  ./scripts/plan-compare.ps1 -Expected './tests/goldens/initiate-new-repo/case2.plan.json' -Actual './run-plans/initiate-new-repo-sample-repo-2-case2.plan.json' -Kind json

  Write-Host "All golden plan comparisons passed." -ForegroundColor Green
}
finally {
  Pop-Location
}
