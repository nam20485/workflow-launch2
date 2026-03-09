#!/usr/bin/env pwsh
#requires -Version 7.0
<#
.SYNOPSIS
Create a new GitHub repository with a random suffix, clone it locally, copy plan docs into plan_docs/, commit, and push.

.DESCRIPTION
This script creates one or more repositories named <RepoName>-<randomSuffix> (with letter suffixes when requested)
under the specified owner, clones each to the given destination directory, copies the contents of a plan docs directory
into a docs folder inside each repo, then commits and pushes the changes. It follows PowerShell best practices: approved
verbs, proper parameter validation, non-interactive design, and optional DryRun with ShouldProcess confirmation gating for
remote mutations.

.PARAMETER RepoName
Base repository name (prefix). A random suffix is appended to form the final repo name.

.PARAMETER Owner
GitHub organization or user that will own the repository. Default: intel-agency

.PARAMETER PlanDocsDir
Path to the directory containing plan docs to copy into the new repo's plan_docs/ folder.

.PARAMETER CloneParentDir
Path to the local parent directory where the repository will be cloned (final path will be <CloneParentDir>\<FullRepoName>).

.PARAMETER Visibility
Repository visibility. Must be 'public' or 'private'.

.PARAMETER DryRun
Simulate remote operations (repo create, git push) and local file copies without making changes. Logs actions only.

.PARAMETER Yes
Non-interactive mode. Assume 'yes' for the create confirmation and do not prompt. The editor will only be launched if -LaunchEditor is also provided.

.PARAMETER LaunchEditor
Launch editor with workspace from new repo after creation

.PARAMETER Count
Number of repositories to create from the specified slug and plan docs. Letter suffixes are appended to the repo names when more than one repo is requested.

.EXAMPLE
./scripts/create-repo-with-plan-docs.ps1 -RepoName planning -PlanDocsDirectory .\plan_docs\advanced_memory -CloneDestinationDirectory .\dynamic_workflows -Visibility public -DryRun -Verbose

.EXAMPLE
./scripts/create-repo-with-plan-docs.ps1 -RepoName planning -PlanDocsDirectory E:\plan_docs -CloneDestinationDirectory E:\work\dynamic_workflows -Owner myorg -Visibility private

.OUTPUTS
System.String. The absolute clone destination path of the created repository.

.NOTES
Requires GitHub CLI (`gh`) and Git. Authenticate with `gh auth login` before running.
#>

$DEFAULT_REPO_OWNER = 'intel-agency'
$DEFAULT_VISIBILITY = 'public'

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
	[Parameter(Mandatory, ParameterSetName = 'Create', HelpMessage = 'Base repository name (prefix).')]
	[Parameter(Mandatory, ParameterSetName = 'ReplaceOnly', HelpMessage = 'Final repository name to substitute for the template placeholder.')]
	[ValidatePattern('^[A-Za-z0-9_.-]+$')]
	[string]$RepoName,

	[Parameter(ParameterSetName = 'Create')]
	[ValidateNotNullOrEmpty()]
	[string]$Owner = $DEFAULT_REPO_OWNER,

	[Parameter(Mandatory, ParameterSetName = 'Create', HelpMessage = 'Directory containing plan docs to copy.')]
	[ValidateNotNullOrEmpty()]
	[string]$PlanDocsDir,

	[Parameter(Mandatory, ParameterSetName = 'Create', HelpMessage = 'Parent directory to clone into.')]
	[ValidateNotNullOrEmpty()]
	[string]$CloneParentDir,

	[Parameter(Mandatory, ParameterSetName = 'ReplaceOnly', HelpMessage = 'Existing repository root to update and validate locally.')]
	[ValidateNotNullOrEmpty()]
	[string]$ExistingRepoRoot,

	[Parameter(ParameterSetName = 'Create', HelpMessage = 'Repository visibility: public or private')]
	[ValidateSet('public', 'private')]
	[string]$Visibility = $DEFAULT_VISIBILITY,

	[Parameter(ParameterSetName = 'Create', HelpMessage = 'Dry run, don''t make any changes.')]
	[Parameter(ParameterSetName = 'ReplaceOnly', HelpMessage = 'Dry run, don''t make any changes.')]
	[switch]$DryRun,

	[Parameter(ParameterSetName = 'Create', HelpMessage = 'Assume yes for all prompts')]
	[switch]$Yes,

	[Parameter(ParameterSetName = 'Create', HelpMessage = 'Launch editor with workspace from new repo after creation')]
	[switch]$LaunchEditor,

	[Parameter(ParameterSetName = 'Create', HelpMessage = 'How many repositories to create from the slug and plan docs.')]
	[ValidateScript({ $_ -ge 1 })]
	[int]$Count = 1
)

$ErrorActionPreference = 'Stop'

function Test-ToolExists
{
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$Name)
	if (-not (Get-Command $Name -ErrorAction SilentlyContinue))
	{
		throw "Required tool not found on PATH: $Name"
	}
}

# Dot-source common auth helper
$commonAuth = Join-Path $PSScriptRoot 'common-auth.ps1'
if (Test-Path -LiteralPath $commonAuth) { . $commonAuth } else { Write-Verbose 'common-auth.ps1 not found; proceeding without dot-sourcing' }
function Get-RandomSuffix
{
	[CmdletBinding()]
	param()
	$words = @('alpha', 'bravo', 'charlie', 'delta', 'echo', 'foxtrot', 'golf', 'hotel', 'india', 'juliet', 'kilo', 'lima', 'mike', 'november', 'oscar', 'papa', 'quebec', 'romeo', 'sierra', 'tango', 'uniform', 'victor', 'whiskey', 'xray', 'yankee', 'zulu')
	$word = Get-Random -InputObject $words
	$num = Get-Random -Minimum 10 -Maximum 100 # two digits 10-99
	return "$word$($num)"
}

function Get-LetterSuffix
{
	[CmdletBinding()]
	param([Parameter(Mandatory)][int]$Index)
	if ($Index -lt 1) { throw 'Index must be a positive integer.' }
	$letters = ''
	$remaining = $Index
	$alphabetStart = [int][char]'a'
	while ($remaining -gt 0)
	{
		$remaining--
		$charCode = $alphabetStart + ($remaining % 26)
		$letters = [char]$charCode + $letters
		$remaining = [math]::Floor($remaining / 26)
	}
	return $letters
}

function Get-RepoNamesForSuffix
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$RepoName,
		[Parameter(Mandatory)][string]$Suffix,
		[Parameter(Mandatory)][int]$Count
	)
	if ($Count -eq 1)
	{
		return @("$RepoName-$Suffix")
	}
	$names = New-Object System.Collections.Generic.List[string]
	for ($i = 1; $i -le $Count; $i++)
	{
		$letterSuffix = Get-LetterSuffix -Index $i
		$names.Add("$RepoName-$Suffix-$letterSuffix")
	}
	return $names.ToArray()
}

function Invoke-External
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$FilePath,
		[Parameter()][string[]]$ArgumentList = @(),
		[switch]$AllowFail
	)
	$cmd = "$FilePath $($ArgumentList -join ' ')"
	Write-Verbose ">> $cmd"
	if ($DryRun) { return @{ ExitCode = 0; Output = @('<dry-run>') } }
	$out = & $FilePath @ArgumentList 2>&1
	$code = $LASTEXITCODE
	if ($code -ne 0 -and -not $AllowFail)
	{
		# Include arguments to make failures easier to diagnose
		$full = "$FilePath $($ArgumentList -join ' ')"
		throw ("Command failed ({0}): {1}`n{2}" -f $code, $full, ($out -join "`n"))
	}
	return @{ ExitCode = $code; Output = $out }
}

function Test-RepoExists
{
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$Owner, [Parameter(Mandatory)][string]$Name)
	if ($DryRun) { return $false }
	$res = Invoke-External -FilePath 'gh' -ArgumentList @('repo', 'view', "$Owner/$Name") -AllowFail
	return ($res.ExitCode -eq 0)
}

function New-RepoSecret
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param(
		[Parameter(Mandatory)][string]$Owner,
		[Parameter(Mandatory)][string]$RepoName,
		[Parameter(Mandatory)][string]$SecretName
	)
	$secretBody = [System.Environment]::GetEnvironmentVariable($SecretName)
	if (-not $secretBody) { throw "Environment variable for secret '$SecretName' not found." }
	$ghArgs = @('secret', 'set', $SecretName, '--body', $secretBody, '--repo', "$Owner/$RepoName")
	Write-Verbose "Creating GitHub repo secret: $SecretName for $Owner/$RepoName"
	if ($PSCmdlet.ShouldProcess($SecretName, 'Create GitHub repo secret'))
	{
		Invoke-External -FilePath 'gh' -ArgumentList $ghArgs | Out-Null
	}
	else
	{
		Write-Verbose 'Creation skipped by ShouldProcess'
	}
}

function New-RepoVariable
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param(
		[Parameter(Mandatory)][string]$Owner,
		[Parameter(Mandatory)][string]$RepoName,
		[Parameter(Mandatory)][string]$VariableName,
		[Parameter(Mandatory)][string]$VariableValue
	)	
	$ghArgs = @('variable', 'set', $VariableName, '--body', $VariableValue, '--repo', "$Owner/$RepoName")
	Write-Verbose "Creating GitHub repo variable: $VariableName for $Owner/$RepoName"
	if ($PSCmdlet.ShouldProcess($VariableName, 'Create GitHub repo variable'))
	{
		Invoke-External -FilePath 'gh' -ArgumentList $ghArgs | Out-Null
	}
	else
	{
		Write-Verbose 'Creation skipped by ShouldProcess'
	}
}

#$TEMPLATE = 'nam20485/ai-new-app-template' # Template repository for new repos
$TEMPLATE = 'intel-agency/ai-new-workflow-app-template' # Template repository for new repos
$TEMPLATE_REPO_NAME = 'ai-new-workflow-app-template' # Template repository name for new repos

function Get-TemplatePlaceholderMatches
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$RepoRoot,
		[Parameter(Mandatory)][string]$TemplateText
	)

	$templatePattern = [regex]::Escape($TemplateText)
	$placeholderMatches = New-Object System.Collections.Generic.List[object]

	foreach ($path in (Get-ChildItem -LiteralPath $RepoRoot -Recurse -Force | Where-Object {
		$_.FullName -notmatch '[/\\]\.git([/\\]|$)' -and $_.Name -match $templatePattern
	}))
	{
		$placeholderMatches.Add([PSCustomObject]@{
			MatchType = 'Path'
			Path = $path.FullName
		})
	}

	foreach ($file in (Get-ChildItem -LiteralPath $RepoRoot -Recurse -Force -File | Where-Object {
		$_.FullName -notmatch '[/\\]\.git([/\\]|$)'
	}))
	{
		try
		{
			$content = [System.IO.File]::ReadAllText($file.FullName)
		}
		catch
		{
			Write-Verbose "Skipping unreadable file during placeholder scan: $($file.FullName)"
			continue
		}

		if ($content -match $templatePattern)
		{
			$placeholderMatches.Add([PSCustomObject]@{
				MatchType = 'Content'
				Path = $file.FullName
			})
		}
	}

	return $placeholderMatches.ToArray()
}

function Update-TemplatePlaceholders
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$RepoRoot,
		[Parameter(Mandatory)][string]$TemplateText,
		[Parameter(Mandatory)][string]$ReplacementText
	)

	$templatePattern = [regex]::Escape($TemplateText)
	$templatePaths = Get-ChildItem -LiteralPath $RepoRoot -Recurse -Force | Where-Object {
		$_.FullName -notmatch '[/\\]\.git([/\\]|$)' -and $_.Name -match $templatePattern
	}

	foreach ($file in (Get-ChildItem -LiteralPath $RepoRoot -Recurse -Force -File | Where-Object {
		$_.FullName -notmatch '[/\\]\.git([/\\]|$)'
	}))
	{
		try
		{
			$content = [System.IO.File]::ReadAllText($file.FullName)
		}
		catch
		{
			Write-Verbose "Skipping unreadable file during placeholder replacement: $($file.FullName)"
			continue
		}

		if ($content -notmatch $templatePattern)
		{
			continue
		}

		$newContent = $content -replace $templatePattern, $ReplacementText
		Write-Verbose "Updating template text in file: $($file.FullName)"
		if ($DryRun)
		{
			Write-Verbose "[dry-run] Would replace template text in: $($file.FullName)"
		}
		else
		{
			[System.IO.File]::WriteAllText($file.FullName, $newContent)
		}
	}

	foreach ($path in ($templatePaths | Sort-Object { $_.FullName.Length } -Descending))
	{
		$newName = $path.Name -replace $templatePattern, $ReplacementText
		$newPath = Join-Path $path.DirectoryName $newName
		Write-Verbose "Renaming template path: $($path.FullName) -> $newPath"
		if ($DryRun)
		{
			Write-Verbose "[dry-run] Would rename: $($path.FullName) -> $newPath"
		}
		else
		{
			Rename-Item -LiteralPath $path.FullName -NewName $newName | Out-Null
		}
	}
}

function Assert-NoTemplatePlaceholdersRemaining
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)][string]$RepoRoot,
		[Parameter(Mandatory)][string]$TemplateText
	)

	$remainingMatches = @(Get-TemplatePlaceholderMatches -RepoRoot $RepoRoot -TemplateText $TemplateText)
	if ($remainingMatches.Count -eq 0)
	{
		Write-Verbose "Verified no remaining template placeholders under: $RepoRoot"
		return
	}

	$matchSummary = $remainingMatches |
		Select-Object -First 20 |
		ForEach-Object { "- [$($_.MatchType)] $($_.Path)" }

	throw "Template placeholder replacement incomplete. Remaining matches:`n$($matchSummary -join "`n")"
}

function New-GitHubRepository
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param(
		[Parameter(Mandatory)][string]$Owner,
		[Parameter(Mandatory)][string]$Name,
		[Parameter(Mandatory)][ValidateSet('public', 'private')][string]$Visibility
	)
	$ghArgs = @('repo', 'create', "$Owner/$Name")
	if ($Visibility -eq 'private') { $ghArgs += '--private' } else { $ghArgs += '--public' }
	# Create from template repo explicitly
	$ghArgs += @('--template', $TEMPLATE)
	Write-Verbose "Creating GitHub repository: $Owner/$Name"
	if ($PSCmdlet.ShouldProcess("$Owner/$Name", 'Create GitHub repository'))
	{
		Invoke-External -FilePath 'gh' -ArgumentList $ghArgs | Out-Null
	}
 else
	{
		Write-Verbose 'Creation skipped by ShouldProcess'
	}
}

function Get-ClonePath
{
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$Parent, [Parameter(Mandatory)][string]$Name)
	if (-not (Test-Path -LiteralPath $Parent))
	{
		New-Item -ItemType Directory -Path $Parent | Out-Null
	}
	$parentResolved = (Resolve-Path -LiteralPath $Parent).Path
	$dest = Join-Path $parentResolved $Name
	return $dest
}

function Invoke-GitClone
{
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$Owner, [Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Dest)
	if (Test-Path -LiteralPath $Dest)
	{
		Write-Verbose "Clone destination exists: $Dest (skipping clone)"
		return
	}
	New-Item -ItemType Directory -Path $Dest | Out-Null
	Invoke-External -FilePath 'git' -ArgumentList @('clone', "git@github.com:$Owner/$Name.git", $Dest) | Out-Null
}

function Copy-PlanDocs
{
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$SourceDir, [Parameter(Mandatory)][string]$RepoRoot)
	$docs = Join-Path $RepoRoot $docsDir
	if ($DryRun)
	{
		Write-Verbose "[dry-run] Would copy plan docs: $SourceDir -> $docs"
		return
	}
	if (-not (Test-Path -LiteralPath $SourceDir)) { throw "Plan docs directory not found: $SourceDir" }
	if (-not (Test-Path -LiteralPath $docs)) { New-Item -ItemType Directory -Path $docs | Out-Null }
	$srcResolved = (Resolve-Path -LiteralPath $SourceDir).Path
	Write-Verbose "Copying plan docs: $srcResolved -> $docs"
	Copy-Item "$srcResolved\*" -Destination $docs -Recurse -Force
}

function Invoke-GitCommitAndPush
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param(
		[Parameter(Mandatory)][string]$RepoRoot,
		[Parameter(Mandatory)][string]$CommitMessage
	)
	# Ensure we're on a valid branch (handle unborn HEAD in freshly created repos)
	$hasHead = Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'rev-parse', '--verify', 'HEAD') -AllowFail
	if ($hasHead.ExitCode -ne 0)
	{
		# No commits yet; create/switch to main branch explicitly
		$sw = Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'switch', '-c', 'main') -AllowFail
		if ($sw.ExitCode -ne 0)
		{
			# Fallback for older Git
			Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'checkout', '-b', 'main') | Out-Null
		}
	}

	Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'add', '.') | Out-Null
	$commit = Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'commit', '-m', $CommitMessage) -AllowFail
	if ($commit.ExitCode -ne 0)
	{
		$msg = ($commit.Output -join ' ')
		if ($msg -match 'nothing to commit')
		{
			Write-Verbose 'Nothing to commit (working tree clean)'
		}
		else
		{
			throw "git commit failed: $msg"
		}
	}
	# Determine current branch and push explicitly (handles fresh repos)
	$branch = (Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'branch', '--show-current')).Output | Select-Object -First 1
	$branch = $branch.Trim()
	if (-not $branch) { $branch = 'main' }
	if ($PSCmdlet.ShouldProcess($RepoRoot, "Push changes to origin/$branch"))
	{
		# Use -u to set upstream on first push
		$push = Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'push', '-u', 'origin', $branch) -AllowFail
		if ($push.ExitCode -ne 0)
		{
			# Handle non-fast-forward race when GitHub finishes templating after our clone
			$pushMsg = ($push.Output -join ' ')
			if ($pushMsg -match 'fetch first' -or $pushMsg -match 'non-fast-forward' -or $pushMsg -match 'failed to push some refs')
			{
				Write-Verbose "Push rejected (likely template race). Rebasing onto origin/$branch and retrying..."
				# Pull with rebase to integrate remote commits without a merge commit
				Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'pull', '--rebase', 'origin', $branch) | Out-Null
				# Retry push
				Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'push', '-u', 'origin', $branch) | Out-Null
			}
			else
			{
				throw ('git push failed: {0}' -f $pushMsg)
			}
		}
	}
}

$docsDir = 'plan_docs'

#
# Main execution
#

try
{
	if ($PSCmdlet.ParameterSetName -eq 'ReplaceOnly')
	{
		$resolvedRepoRoot = (Resolve-Path -LiteralPath $ExistingRepoRoot).Path
		Update-TemplatePlaceholders -RepoRoot $resolvedRepoRoot -TemplateText $TEMPLATE_REPO_NAME -ReplacementText $RepoName
		Assert-NoTemplatePlaceholdersRemaining -RepoRoot $resolvedRepoRoot -TemplateText $TEMPLATE_REPO_NAME
		Write-Output "SUCCESS: template placeholders replaced and validated in '$resolvedRepoRoot'"
		return
	}

	# Preconditions
	Test-ToolExists 'git'
	Test-ToolExists 'gh'
	if (Get-Command Initialize-GitHubAuth -ErrorAction SilentlyContinue) { Initialize-GitHubAuth -DryRun:$DryRun } else
	{
		# Fallback local check if helper not available
		$st = Invoke-External -FilePath 'gh' -ArgumentList @('auth', 'status') -AllowFail
		if ($st.ExitCode -ne 0)
		{
			Write-Verbose 'GitHub CLI not authenticated. Initiating gh auth login...'
			if ($DryRun) { Write-Warning '[dry-run] Would run: gh auth login' } else { Invoke-External -FilePath 'gh' -ArgumentList @('auth', 'login') | Out-Null }
		}
	}

	# Determine final repo names (ensure not colliding; try up to 5 suffixes)
	$repoNames = @()
	for ($i = 0; $i -lt 5 -and -not $repoNames; $i++)
	{
		$suffix = Get-RandomSuffix
		$candidates = Get-RepoNamesForSuffix -RepoName $RepoName -Suffix $suffix -Count $Count
		$collision = $false
		foreach ($candidate in $candidates)
		{
			if (Test-RepoExists -Owner $Owner -Name $candidate)
			{
				$collision = $true
				break
			}
		}
		if (-not $collision)
		{
			$repoNames = $candidates
		}
	}
	if (-not $repoNames) { throw "Unable to find an available set of repo names after multiple attempts for base '$RepoName'" }

	Write-Output ''
	if (-not $Yes)
	{
		if ($Count -gt 1)
		{
			$confirm = Read-Host "You have specified to create $Count repos from the $RepoName plans. Are you sure? (y/N):"
			if (($confirm ?? '').Trim().ToLower() -ne 'y') { throw 'User aborted' }
		}
		else
		{
			$continue = Read-Host "Ready. Create repo with name: '$Owner/$($repoNames[0])' with plan docs from '$PlanDocsDir' at '$CloneParentDir'? (y/N)"
			$continueNorm = ($continue ?? '').Trim().ToLower()
			if ($continueNorm -ne 'y') { throw 'User aborted' }
		}
	}
	else
	{
		Write-Verbose '-Yes specified: proceeding without confirmation'
	}

	Write-Verbose "Chosen repository names: $($repoNames -join ', ')"

	$lastEditorTarget = $null
	foreach ($repoName in $repoNames)
	{
		Write-Verbose "Creating repository: $Owner/$repoName"

		# Create repository
		New-GitHubRepository -Owner $Owner -Name $repoName -Visibility $Visibility
		Write-Verbose "Repository created: $Owner/$repoName"

		# Create repo secrets needed for agent auth
		#New-RepoSecret 'CLAUDE_CODE_OAUTH_TOKEN'
		New-RepoSecret -Owner $Owner -RepoName $repoName -SecretName 'GEMINI_API_KEY'
		# New-RepoSecret -Owner $Owner -RepoName $repoName -SecretName 'ZHIPU_API_KEY'
		# need to add repository variables
		#VERSION_PREFIX = '0.0.1'
		New-RepoVariable -Owner $Owner -RepoName $repoName -VariableName 'VERSION_PREFIX' -VariableValue '0.0.1'
		Write-Verbose "Repository secrets and variables created for $Owner/$repoName"

		$clonePath = Get-ClonePath -Parent $CloneParentDir -Name $repoName
		Invoke-GitClone -Owner $Owner -Name $repoName -Dest $clonePath
		Write-Verbose "Repository cloned: $clonePath"

		# Copy plan docs
		Copy-PlanDocs -SourceDir $PlanDocsDir -RepoRoot $clonePath
		Write-Verbose "Plan docs copied: $PlanDocsDir -> $clonePath\$docsDir"

		# Replace template placeholders in file contents and path names
		Update-TemplatePlaceholders -RepoRoot $clonePath -TemplateText $TEMPLATE_REPO_NAME -ReplacementText $repoName
		Assert-NoTemplatePlaceholdersRemaining -RepoRoot $clonePath -TemplateText $TEMPLATE_REPO_NAME

		$workspacePath = Join-Path $clonePath "$repoName.code-workspace"
		if (Test-Path -LiteralPath $workspacePath -PathType Leaf)
		{
			$lastEditorTarget = $workspacePath
		}
		else
		{
			Write-Verbose "Expected workspace file not found, opening repo folder instead: $workspacePath"
			$lastEditorTarget = $clonePath
		}

		# Commit and push
		$seedCommitMessage = "Seed $repoName from template with plan docs and placeholder replacements"
		Invoke-GitCommitAndPush -RepoRoot $clonePath -CommitMessage $seedCommitMessage
		Write-Verbose 'Changes committed and pushed'

		# Output clone destination path
		Write-Output "SUCCESS: '$clonePath' created and checked in"
	}

	if (-not $Yes)
	{
		$launch = Read-Host 'Launch editor? (y/N)'
		if ( ($launch ?? '').Trim().ToLower() -eq 'y' -or $LaunchEditor )
		{
			code-insiders $lastEditorTarget
		}
	}
	else
	{
		if ($LaunchEditor -and $lastEditorTarget) { code-insiders $lastEditorTarget }
	}

}
catch
{
	"FAILED: Exception! $($_.Exception.Message)"	
	exit 1
}

# function Start-VsCode {
# 	param (
# 		$StartLocation
# 	)
	
# }

#
#	Original Plan
#

#params
# $repo-name
# $plan docs directory
# $clone-destination-directory

# get random word and 2 digit number
# $repo-suffix = random-word-2digit-number


# create new repo
# $full-repo-name = $repo-name-$repo-suffix
# $full-repo-name = $repo-name-$repo-suffix

# clone new repo to destination directory
# $clone-destination = $clone-destination-directory/$full-repo-name

# copy plan docs to new repo
# copy $plan-docs-directory to $clone-destination/docs
# (create dir if !exists)

# commit and push
# git add .
# git commit -m "Add plan docs"

# return string $clone-destination
