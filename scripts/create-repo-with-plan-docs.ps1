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

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Create', HelpMessage = 'Base repository name (prefix).')]
    [Parameter(Mandatory, ParameterSetName = 'ReplaceOnly', HelpMessage = 'Final repository name to substitute for the template placeholder.')]
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$RepoName,

    [Parameter(ParameterSetName = 'Create')]
    [ValidateNotNullOrEmpty()]
    [string]$Owner = 'intel-agency',

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
    [string]$Visibility = 'public',

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
$TEMPLATE_OWNER = $TEMPLATE.Split('/')[0] # Template repository owner (extracted from $TEMPLATE)

function Get-TemplatePlaceholderMatches
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$TemplateText
    )

    $templatePattern = [regex]::Escape($TemplateText)
    Write-Verbose "[TRACE:Scan] Scanning for placeholder matches under: $RepoRoot"
    Write-Verbose "[TRACE:Scan] Template text: '$TemplateText' | Regex pattern: '$templatePattern'"
    $placeholderMatches = New-Object System.Collections.Generic.List[object]

    $allItems = @(Get-ChildItem -LiteralPath $RepoRoot -Recurse -Force | Where-Object {
        $_.FullName -notmatch '[/\\]\.git([/\\]|$)' -and $_.Name -match $templatePattern
    })
    Write-Verbose "[TRACE:Scan] Found $($allItems.Count) path(s) matching template pattern in name"
    foreach ($path in $allItems)
    {
        Write-Verbose "[TRACE:Scan]   Path match: $($path.FullName)"
        $placeholderMatches.Add([PSCustomObject]@{
            MatchType = 'Path'
            Path = $path.FullName
        })
    }

    $allFiles = @(Get-ChildItem -LiteralPath $RepoRoot -Recurse -Force -File | Where-Object {
        $_.FullName -notmatch '[/\\]\.git([/\\]|$)'
    })
    Write-Verbose "[TRACE:Scan] Scanning $($allFiles.Count) file(s) for content matches"
    foreach ($file in $allFiles)
    {
        try
        {
            $content = [System.IO.File]::ReadAllText($file.FullName)
        }
        catch
        {
            Write-Verbose "[TRACE:Scan] Skipping unreadable file: $($file.FullName) — $($_.Exception.Message)"
            continue
        }

        if ($content -match $templatePattern)
        {
            Write-Verbose "[TRACE:Scan]   Content match: $($file.FullName)"
            $placeholderMatches.Add([PSCustomObject]@{
                MatchType = 'Content'
                Path = $file.FullName
            })
        }
    }

    Write-Verbose "[TRACE:Scan] Total matches found: $($placeholderMatches.Count)"
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
    Write-Verbose "[TRACE:Replace] === Update-TemplatePlaceholders ==="
    Write-Verbose "[TRACE:Replace] RepoRoot: $RepoRoot"
    Write-Verbose "[TRACE:Replace] TemplateText: '$TemplateText' | ReplacementText: '$ReplacementText'"
    Write-Verbose "[TRACE:Replace] Regex pattern: '$templatePattern'"
    Write-Verbose "[TRACE:Replace] RepoRoot exists: $(Test-Path -LiteralPath $RepoRoot)"
    Write-Verbose "[TRACE:Replace] RepoRoot resolved: $(Resolve-Path -LiteralPath $RepoRoot -ErrorAction SilentlyContinue)"

    $templatePaths = @(Get-ChildItem -LiteralPath $RepoRoot -Recurse -Force | Where-Object {
        $_.FullName -notmatch '[/\\]\.git([/\\]|$)' -and $_.Name -match $templatePattern
    })
    Write-Verbose "[TRACE:Replace] Path matches (name contains template text): $($templatePaths.Count)"

    $allFiles = @(Get-ChildItem -LiteralPath $RepoRoot -Recurse -Force -File | Where-Object {
        $_.FullName -notmatch '[/\\]\.git([/\\]|$)'
    })
    Write-Verbose "[TRACE:Replace] Total files to scan for content: $($allFiles.Count)"

    $replacedCount = 0
    $skippedCount = 0
    $noMatchCount = 0
    foreach ($file in $allFiles)
    {
        try
        {
            $content = [System.IO.File]::ReadAllText($file.FullName)
        }
        catch
        {
            Write-Verbose "[TRACE:Replace] SKIP (unreadable): $($file.FullName) — $($_.Exception.Message)"
            $skippedCount++
            continue
        }

        if ($content -notmatch $templatePattern)
        {
            $noMatchCount++
            continue
        }

        $newContent = $content -replace $templatePattern, $ReplacementText
        $replacedCount++
        Write-Verbose "[TRACE:Replace] MATCH [$replacedCount]: $($file.FullName) (size: $($content.Length) bytes)"
        if ($DryRun)
        {
            Write-Verbose "[TRACE:Replace]   [dry-run] Would replace template text"
        }
        else
        {
            [System.IO.File]::WriteAllText($file.FullName, $newContent)
            # Verify the write persisted
            $verifyContent = [System.IO.File]::ReadAllText($file.FullName)
            if ($verifyContent -match $templatePattern)
            {
                Write-Verbose "[TRACE:Replace]   WARNING: File still contains template text after write! $($file.FullName)"
            }
            else
            {
                Write-Verbose "[TRACE:Replace]   Verified: template text removed after write"
            }
        }
    }

    Write-Verbose "[TRACE:Replace] Content replacement summary: $replacedCount replaced, $noMatchCount no-match, $skippedCount skipped (of $($allFiles.Count) total)"

    Write-Verbose "[TRACE:Replace] Renaming $($templatePaths.Count) path(s) matching template pattern"
    foreach ($path in ($templatePaths | Sort-Object { $_.FullName.Length } -Descending))
    {
        $newName = $path.Name -replace $templatePattern, $ReplacementText
        $newPath = Join-Path $path.DirectoryName $newName
        Write-Verbose "[TRACE:Replace] RENAME: $($path.FullName) -> $newPath"
        if ($DryRun)
        {
            Write-Verbose "[TRACE:Replace]   [dry-run] Would rename"
        }
        else
        {
            Rename-Item -LiteralPath $path.FullName -NewName $newName | Out-Null
        }
    }

    Write-Verbose "[TRACE:Replace] === Update-TemplatePlaceholders complete ==="
}

function Assert-NoTemplatePlaceholdersRemaining
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$TemplateText
    )

    Write-Verbose "[TRACE:Assert] Checking for remaining placeholders: '$TemplateText' under $RepoRoot"
    $remainingMatches = @(Get-TemplatePlaceholderMatches -RepoRoot $RepoRoot -TemplateText $TemplateText)
    Write-Verbose "[TRACE:Assert] Remaining matches: $($remainingMatches.Count)"
    if ($remainingMatches.Count -eq 0)
    {
        Write-Verbose "[TRACE:Assert] PASS: No remaining template placeholders"
        return
    }

    $matchSummary = $remainingMatches |
        Select-Object -First 20 |
        ForEach-Object { "- [$($_.MatchType)] $($_.Path)" }

    Write-Verbose "[TRACE:Assert] FAIL: $($remainingMatches.Count) remaining match(es)"
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
        # Validate the existing clone has a .git directory and a valid HEAD
        $gitDir = Join-Path $Dest '.git'
        if (-not (Test-Path -LiteralPath $gitDir -PathType Container))
        {
            throw "Clone destination exists but is not a git repo (no .git/): $Dest"
        }
        $headCheck = Invoke-External -FilePath 'git' -ArgumentList @('-C', $Dest, 'rev-parse', '--verify', 'HEAD') -AllowFail
        if ($headCheck.ExitCode -ne 0)
        {
            throw "Clone destination exists but has no valid HEAD: $Dest"
        }
        Write-Verbose "Clone destination exists and is valid: $Dest (skipping clone)"
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
    Copy-Item "$srcResolved/*" -Destination $docs -Recurse -Force
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
            Write-Warning "Nothing to commit — expected replacement changes but working tree is clean. Possible template race."
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
    $rebased = $false
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
                Write-Warning "Push rejected (template race detected). Rebasing onto origin/$branch and retrying..."
                # Pull with rebase to integrate remote commits without a merge commit
                Invoke-External -FilePath 'git' -ArgumentList @('-C', $RepoRoot, 'pull', '--rebase', 'origin', $branch) | Out-Null
                $rebased = $true
            }
            else
            {
                throw ('git push failed: {0}' -f $pushMsg)
            }
        }
    }
    # Return whether a rebase occurred so callers can re-run replacements
    return $rebased
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

    # Derive the owner to use for image/registry references
    $TEMPLATE_OWNER_LOWER = $TEMPLATE_OWNER.ToLower()

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
        Write-Verbose "Plan docs copied: $PlanDocsDir -> $clonePath/$docsDir"

        # Snapshot file list before replacement
        $preFiles = @(Get-ChildItem -LiteralPath $clonePath -Recurse -Force -File | Where-Object { $_.FullName -notmatch '[/\\]\.git([/\\]|$)' })
        Write-Verbose "[TRACE:Main] Pre-replacement file count: $($preFiles.Count)"
        Write-Verbose "[TRACE:Main] Clone path: $clonePath"
        Write-Verbose "[TRACE:Main] Clone path exists: $(Test-Path -LiteralPath $clonePath)"
        Write-Verbose "[TRACE:Main] TEMPLATE_REPO_NAME: '$TEMPLATE_REPO_NAME'"
        Write-Verbose "[TRACE:Main] repoName: '$repoName'"
        Write-Verbose "[TRACE:Main] TEMPLATE_OWNER: '$TEMPLATE_OWNER' | Owner: '$Owner'"

        # Replace template placeholders in file contents and path names
        Write-Verbose "[TRACE:Main] --- Step 1: Replace repo name ---"
        Update-TemplatePlaceholders -RepoRoot $clonePath -TemplateText $TEMPLATE_REPO_NAME -ReplacementText $repoName
        Assert-NoTemplatePlaceholdersRemaining -RepoRoot $clonePath -TemplateText $TEMPLATE_REPO_NAME

        # Replace template owner in image/registry references (e.g. ghcr.io/intel-agency/... -> ghcr.io/nam20485/...)
        $ownerLower = $Owner.ToLower()
        if ($ownerLower -ne $TEMPLATE_OWNER_LOWER)
        {
            Write-Verbose "[TRACE:Main] --- Step 2: Replace owner ---"
            Write-Verbose "Replacing template owner '$TEMPLATE_OWNER' -> '$Owner' in file contents"
            Update-TemplatePlaceholders -RepoRoot $clonePath -TemplateText $TEMPLATE_OWNER -ReplacementText $Owner
            Assert-NoTemplatePlaceholdersRemaining -RepoRoot $clonePath -TemplateText $TEMPLATE_OWNER
        }
        else
        {
            Write-Verbose "[TRACE:Main] --- Step 2: SKIPPED (owner unchanged: '$Owner' == '$TEMPLATE_OWNER_LOWER') ---"
        }

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
        $rebased = Invoke-GitCommitAndPush -RepoRoot $clonePath -CommitMessage $seedCommitMessage

        if ($rebased)
        {
            # Template race: rebase pulled in un-replaced template files.
            # Re-run all replacements on the rebased tree.
            Write-Warning "Template race detected — re-running placeholder replacements after rebase..."

            Write-Verbose "[TRACE:Main] --- Post-rebase Step 1: Re-replace repo name ---"
            Update-TemplatePlaceholders -RepoRoot $clonePath -TemplateText $TEMPLATE_REPO_NAME -ReplacementText $repoName
            Assert-NoTemplatePlaceholdersRemaining -RepoRoot $clonePath -TemplateText $TEMPLATE_REPO_NAME

            $ownerLower = $Owner.ToLower()
            if ($ownerLower -ne $TEMPLATE_OWNER_LOWER)
            {
                Write-Verbose "[TRACE:Main] --- Post-rebase Step 2: Re-replace owner ---"
                Update-TemplatePlaceholders -RepoRoot $clonePath -TemplateText $TEMPLATE_OWNER -ReplacementText $Owner
                Assert-NoTemplatePlaceholdersRemaining -RepoRoot $clonePath -TemplateText $TEMPLATE_OWNER
            }

            # Amend the seed commit with the post-rebase replacements and force push
            Invoke-External -FilePath 'git' -ArgumentList @('-C', $clonePath, 'add', '.') | Out-Null
            $amendCommit = Invoke-External -FilePath 'git' -ArgumentList @('-C', $clonePath, 'commit', '--amend', '--no-edit') -AllowFail
            if ($amendCommit.ExitCode -ne 0)
            {
                $amendMsg = ($amendCommit.Output -join ' ')
                if ($amendMsg -notmatch 'nothing to commit') { throw "git commit --amend failed: $amendMsg" }
            }
            Invoke-External -FilePath 'git' -ArgumentList @('-C', $clonePath, 'push', '--force-with-lease', 'origin', 'main') | Out-Null
            Write-Verbose 'Post-rebase replacements committed and pushed'
        }
        else
        {
            Write-Verbose 'Changes committed and pushed (no rebase needed)'
        }

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
