#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory, HelpMessage = 'Slug to use for repo name and docs directory.')]
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$Slug,
    
    [Parameter(HelpMessage = 'Repository visibility: public or private')]
    [ValidateSet('public', 'private')]
    [string]$Visibility = 'private',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Owner = 'nam20485',

    [Parameter()]
    [switch]$Yes,

    [Parameter()]
    [switch]$LaunchAgent,

    [Parameter(HelpMessage = 'Number of repositories to create from this slug.')]
    [ValidateScript({ $_ -ge 1 })]
    [int]$Count = 1
)

if ($Yes) {
    ./scripts/create-repo-with-plan-docs.ps1 -RepoName $Slug -PlanDocsDir "./plan_docs/$Slug" -CloneParentDir ../dynamic_workflows -Visibility $Visibility -Owner $Owner -Count $Count -Yes -LaunchEditor
}
else {
    ./scripts/create-repo-with-plan-docs.ps1 -RepoName $Slug -PlanDocsDir "./plan_docs/$Slug" -CloneParentDir ../dynamic_workflows -Visibility $Visibility -Owner $Owner -Count $Count
}


