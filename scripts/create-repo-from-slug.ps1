param(
    [Parameter(Mandatory, HelpMessage = 'Slug to use for repo name and docs directory.')]
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$Slug,
    
    [Parameter(Mandatory, HelpMessage = 'Repository visibility: public or private')]
    [ValidateSet('public', 'private')]
    [string]$Visibility
)

./scripts/create-repo-with-plan-docs.ps1 -RepoName $Slug -PlanDocsDir "./docs/$Slug" -CloneParentDir ../dynamic_workflows -Visibility $Visibility
