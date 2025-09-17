[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
	[Parameter(Mandatory, HelpMessage = 'Directory containing plan docs; each subfolder is one plan.')]
	[ValidateNotNullOrEmpty()]
	[string]$PlanDocsDir,

	[Parameter(Mandatory, HelpMessage = 'Parent directory to clone into.')]
	[ValidateNotNullOrEmpty()]
	[string]$CloneParentDir,

	[Parameter(Mandatory, HelpMessage = 'Repository visibility: public or private')]
	[ValidateSet('public', 'private')]
	[string]$Visibility
)

$ErrorActionPreference = 'Stop'

# Default repo owner for newly created repositories
$owner = 'nam20485'

# Helper script path (use script root so CWD doesn’t matter)
$helperScript = Join-Path $PSScriptRoot 'create-repo-with-plan-docs.ps1'
if (-not (Test-Path -LiteralPath $helperScript)) {
	throw "Required helper not found: $helperScript"
}

# Resolve and validate plan docs root
if (-not (Test-Path -LiteralPath $PlanDocsDir)) {
	throw "PlanDocsDir not found: $PlanDocsDir"
}
$plansRoot = (Resolve-Path -LiteralPath $PlanDocsDir).Path

# Find plan subdirectories
$planDirs = Get-ChildItem -LiteralPath $plansRoot -Directory | Sort-Object Name
if (-not $planDirs -or $planDirs.Count -eq 0) {
	Write-Warning "No plan subdirectories found under: $plansRoot"
	return
}

function ConvertTo-RepoSafeName {
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$Name)
	# Match child script's RepoName validation: only letters, digits, underscore, dot, dash
	$safe = ($Name -replace "[^A-Za-z0-9_.-]", '-')
	# Trim leading/trailing dashes that can arise from replacement
	return $safe.Trim('-')
}

foreach ($dir in $planDirs) {
	$planNameRaw = $dir.Name
	$repoBase = ConvertTo-RepoSafeName -Name $planNameRaw
	if (-not $repoBase) {
		Write-Warning "Skipping '$planNameRaw' — no valid characters for repository name after sanitization"
		continue
	}

	$target = "$owner/$repoBase"
	$action = 'Create repo and populate from plan docs'

	# High-level confirmation; with -WhatIf this will print a WhatIf message and return $false
	if ($PSCmdlet.ShouldProcess($target, $action)) {
		Write-Host "Creating repo for plan: $planNameRaw -> $target..."

		# Forward verbosity/debug flags to helper if enabled
		$common = @{}
		if ($VerbosePreference -eq 'Continue') { $common['Verbose'] = $true }
		if ($DebugPreference -eq 'Continue')   { $common['Debug']   = $true }

		& $helperScript \
			-RepoName $repoBase \
			-PlanDocsDir $dir.FullName \
			-CloneParentDir $CloneParentDir \
			-Visibility $Visibility \
			-Owner $owner \
			-Yes @common
	}
}