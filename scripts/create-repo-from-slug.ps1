#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory, HelpMessage = 'Slug to use for repo name and docs directory.')]
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$Slug,
    
    [Parameter(HelpMessage = 'Repository visibility: public or private')]
    [ValidateSet('public', 'private')]
    [string]$Visibility = 'public',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Owner = 'intel-agency',

    [Parameter()]
    [switch]$Yes,

    [Parameter()]
    [switch]$LaunchAgent,

    [Parameter(HelpMessage = 'Number of repositories to create from this slug.')]
    [ValidateScript({ $_ -ge 1 })]
    [int]$Count = 1,

    [Parameter(HelpMessage = 'Template repository name used for new repos. Used for placeholder replacement.')]
    [ValidateNotNullOrEmpty()]
    [string]$TemplateRepoName = 'ai-new-workflow-app-template'    
)

if ($Yes) {
    ./scripts/create-repo-with-plan-docs.ps1 -RepoName $Slug -PlanDocsDir "./plan_docs/$Slug" -CloneParentDir ../dynamic_workflows -Visibility $Visibility -Owner $Owner -TemplateRepoName $TemplateRepoName -Count $Count -Yes -LaunchEditor
}
else {
    ./scripts/create-repo-with-plan-docs.ps1 -RepoName $Slug -PlanDocsDir "./plan_docs/$Slug" -CloneParentDir ../dynamic_workflows -Visibility $Visibility -Owner $Owner -TemplateRepoName $TemplateRepoName -Count $Count
}


