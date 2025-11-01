
param (
    [Parameter(Mandatory, HelpMessage = 'Slug to use for repo name and docs directory.')]
    [string]
    $PrefixSlug = '',

    [Parameter()]
    [string]
    $Visibility = 'private'
)

function Get-MatchingRepos {
    param (
        [string]$PrefixSlug,
        [string]$Visibility
    )
    
    # Check if gh is authenticated
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "GitHub CLI not authenticated. Run 'gh auth login' to authenticate."
        return @()
    }
    
    # Get all repos and filter by prefix and visibility
    $allRepos = gh repo list --json "name,visibility" --limit 1000 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'Fetching repositories command failed.'
        return @()
    }
    
    $matchingRepos = $allRepos | Where-Object {
        $_.name -like "*$PrefixSlug*" -and $_.visibility -eq $Visibility
    }
    
    return $matchingRepos
}

$reposToDelete = Get-MatchingRepos -PrefixSlug $PrefixSlug -Visibility $Visibility
if ($reposToDelete.Count -eq 0) {
    Write-Host "No repositories found with prefix '$PrefixSlug' and visibility '$Visibility'."
    exit 0
}
else {
    Write-Host "Found $($reposToDelete.Count) repositories to delete:"
    $reposToDelete | ForEach-Object { Write-Host "- $($_.name) ($($_.visibility))" }
    
    $confirmation = Read-Host "Are you sure you want to delete these repositories? Type 'YES' to confirm"
    if ($confirmation -eq 'YES') {
        foreach ($repo in $reposToDelete) {
            Write-Host "Deleting repository: $($repo.name)"
            gh repo delete $repo.name --confirm
        }
        Write-Host 'Deletion process completed.'
    }
    else {
        Write-Host 'Deletion cancelled by user.'
    }
}
