#requires -Version 7.0
<#
.SYNOPSIS
Create a new GitHub repository with a random suffix, clone it locally, copy plan docs into docs/, commit, and push.

.DESCRIPTION
This script creates a new repository named <RepoName>-<randomWord><twoDigits> under the specified owner, clones it
to the given destination directory, copies the contents of a plan docs directory into a docs folder inside the repo,
then commits and pushes the changes. It follows PowerShell best practices: approved verbs, proper parameter validation,
non-interactive design, and optional DryRun with ShouldProcess confirmation gating for remote mutations.

.PARAMETER RepoName
Base repository name (prefix). A random suffix is appended to form the final repo name.

.PARAMETER Owner
GitHub organization or user that will own the repository. Default: nam20485

.PARAMETER PlanDocsDirectory
Path to the directory containing plan docs to copy into the new repo's docs/ folder.

.PARAMETER CloneDestinationDirectory
Path to the local parent directory where the repository will be cloned (final path will be <CloneDestinationDirectory>\<FullRepoName>).

.PARAMETER Visibility
Repository visibility. Must be 'public' or 'private'.

.PARAMETER DryRun
Simulate remote operations (repo create, git push) and local file copies without making changes. Logs actions only.

.EXAMPLE
./scripts/create-repo-with-plan-docs.ps1 -RepoName planning -PlanDocsDirectory .\docs\advanced_memory -CloneDestinationDirectory .\dynamic_workflows -Visibility public -DryRun -Verbose

.EXAMPLE
./scripts/create-repo-with-plan-docs.ps1 -RepoName planning -PlanDocsDirectory E:\docs\plans -CloneDestinationDirectory E:\work\dynamic_workflows -Owner myorg -Visibility private

.OUTPUTS
System.String. The absolute clone destination path of the created repository.

.NOTES
Requires GitHub CLI (`gh`) and Git. Authenticate with `gh auth login` before running.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
	[Parameter(Mandatory, HelpMessage = 'Base repository name (prefix).')]
	[ValidatePattern('^[A-Za-z0-9_.-]+$')]
	[string]$RepoName,

	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$Owner = 'nam20485',

	[Parameter(Mandatory, HelpMessage = 'Directory containing plan docs to copy.')]
	[ValidateNotNullOrEmpty()]
	[string]$PlanDocsDirectory,

	[Parameter(Mandatory, HelpMessage = 'Parent directory to clone into.')]
	[ValidateNotNullOrEmpty()]
	[string]$CloneDestinationDirectory,

	[Parameter(Mandatory, HelpMessage = 'Repository visibility: public or private')]
	[ValidateSet('public','private')]
	[string]$Visibility,

	[Parameter()]
	[switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Test-ToolExists {
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$Name)
	if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
		throw "Required tool not found on PATH: $Name"
	}
}`

function Get-RandomSuffix {
	[CmdletBinding()]
	param()
	$words = @('alpha','bravo','charlie','delta','echo','foxtrot','golf','hotel','india','juliet','kilo','lima','mike','november','oscar','papa','quebec','romeo','sierra','tango','uniform','victor','whiskey','xray','yankee','zulu')
	$word = Get-Random -InputObject $words
	$num = Get-Random -Minimum 10 -Maximum 100 # two digits 10-99
	return "$word$($num)"
}

function Invoke-External {
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
	if ($code -ne 0 -and -not $AllowFail) {
		throw ("Command failed ({0}): {1}`n{2}" -f $code, $FilePath, ($out -join "`n"))
	}
	return @{ ExitCode = $code; Output = $out }
}

function Test-RepoExists {
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$Owner,[Parameter(Mandatory)][string]$Name)
	if ($DryRun) { return $false }
	$res = Invoke-External -FilePath 'gh' -ArgumentList @('repo','view',"$Owner/$Name") -AllowFail
	return ($res.ExitCode -eq 0)
}

$TEMPLATE = 'nam20485/ai-new-app-template' # Template repository for new repos
function New-GitHubRepository {
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param(
		[Parameter(Mandatory)][string]$Owner,
		[Parameter(Mandatory)][string]$Name,
		[Parameter(Mandatory)][ValidateSet('public','private')][string]$Visibility
		)
	$ghArgs = @('repo','create',"$Owner/$Name")
	if ($Visibility -eq 'private') { $ghArgs += '--private' } else { $ghArgs += '--public' }
	# Create from template repo explicitly
	$ghArgs += @('--template', $TEMPLATE)
	Write-Verbose "Creating GitHub repository: $Owner/$Name"
	if ($PSCmdlet.ShouldProcess("$Owner/$Name", 'Create GitHub repository')) {
		Invoke-External -FilePath 'gh' -ArgumentList $ghArgs | Out-Null
	} else {
		Write-Verbose "Creation skipped by ShouldProcess"
	}
}

function Get-ClonePath {
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$Parent,[Parameter(Mandatory)][string]$Name)
	if (-not (Test-Path -LiteralPath $Parent)) {
		New-Item -ItemType Directory -Path $Parent | Out-Null
	}
	$parentResolved = (Resolve-Path -LiteralPath $Parent).Path
	$dest = Join-Path $parentResolved $Name
	return $dest
}

function Invoke-GitClone {
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$Owner,[Parameter(Mandatory)][string]$Name,[Parameter(Mandatory)][string]$Dest)
	if (Test-Path -LiteralPath $Dest) {
		Write-Verbose "Clone destination exists: $Dest (skipping clone)"
		return
	}
	New-Item -ItemType Directory -Path $Dest | Out-Null
	Invoke-External -FilePath 'git' -ArgumentList @('clone',"https://github.com/$Owner/$Name.git", $Dest) | Out-Null
}

function Copy-PlanDocs {
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$SourceDir,[Parameter(Mandatory)][string]$RepoRoot)
	$docs = Join-Path $RepoRoot 'docs'
	if ($DryRun) {
		Write-Verbose "[dry-run] Would copy plan docs: $SourceDir -> $docs"
		return
	}
	if (-not (Test-Path -LiteralPath $SourceDir)) { throw "Plan docs directory not found: $SourceDir" }
	if (-not (Test-Path -LiteralPath $docs)) { New-Item -ItemType Directory -Path $docs | Out-Null }
	$srcResolved = (Resolve-Path -LiteralPath $SourceDir).Path
	Write-Verbose "Copying plan docs: $srcResolved -> $docs"
	Copy-Item "$srcResolved\*" -Destination $docs -Recurse -Force
}

function Invoke-GitCommitAndPush {
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param([Parameter(Mandatory)][string]$RepoRoot)
	Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'checkout') | Out-Null
	Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'add','.') | Out-Null
	$commit = Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'commit','-m','Add plan docs') -AllowFail
	if ($commit.ExitCode -ne 0) {
		$msg = ($commit.Output -join ' ')
		if ($msg -match 'nothing to commit') {
			Write-Verbose 'Nothing to commit (working tree clean)'
		} else {
			throw 'git commit failed: $msg'
		}
	}
	if ($PSCmdlet.ShouldProcess($RepoRoot, "Push changes")) {
		Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'push') | Out-Null
	}
}

#
# Main execution
#
try
{

Write-Output ""
$continue = Read-Host "Ready. Create repo with name: $RepoName with plan docs from $PlanDocsDirectory at \'$CloneDestinationDirectory\'? (y/N)"

if ($continue -ne ('y'.ToLower())) { throw 'User aborted' }

# Preconditions
Test-ToolExists 'git'
Test-ToolExists 'gh'
Invoke-External -FilePath 'gh' -ArgumentList @('auth','status') | Out-Null

# Determine final repo name (ensure not colliding; try up to 5 suffixes)
$finalName = $null
for ($i=0; $i -lt 5 -and -not $finalName; $i++) {
	$suffix = Get-RandomSuffix
	$candidate = "$RepoName-$suffix"
	if (-not (Test-RepoExists -Owner $Owner -Name $candidate)) {
		$finalName = $candidate
	}
}
if (-not $finalName) { throw "Unable to find an available repo name after multiple attempts for base '$RepoName'" }

Write-Verbose "Chosen repository name: $Owner/$finalName"

# Create repository
New-GitHubRepository -Owner $Owner -Name $finalName -Visibility $Visibility
Write-Verbose "Repository created: $Owner/$finalName"

# Clone locally
$clonePath = Get-ClonePath -Parent $CloneDestinationDirectory -Name $finalName
Invoke-GitClone -Owner $Owner -Name $finalName -Dest $clonePath
Write-Verbose "Repository cloned: $clonePath"

# Copy plan docs
Copy-PlanDocs -SourceDir $PlanDocsDirectory -RepoRoot $clonePath
Write-Verbose "Plan docs copied: $PlanDocsDirectory -> $clonePath\docs"

# Commit and push
Invoke-GitCommitAndPush -RepoRoot $clonePath
Write-Verbose "Changes committed and pushed"

# Output clone destination path
Write-Output "SUCCESS: \'$clonePath\' created and checkd in"

} 
catch
{
	"FAILED: Exception! $($_.Exception.Message)"	
	exit 1
}

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
