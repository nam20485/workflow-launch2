#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Create one or more GitHub repos from an app-plan slug, seeded with the
    plan docs in ./plan_docs/<slug>.

.DESCRIPTION
    Thin wrapper over create-repo-with-plan-docs.ps1. Derives the plan docs
    directory (./plan_docs/<slug>) and clone parent (../dynamic_workflows)
    from the slug and forwards all other parameters. When -Yes is given, the
    editor is launched after creation.

    Note: must be run from the launcher repo root (invokes
    ./scripts/create-repo-with-plan-docs.ps1 by relative path).

.PARAMETER Slug
    Slug to use for repo name and docs directory.

.PARAMETER Visibility
    Repository visibility: public or private. Default: public.

.PARAMETER Owner
    Repository owner. Default: intel-agency.

.PARAMETER Yes
    Non-interactive mode. Assume yes for all confirmations and launch the editor.

.PARAMETER LaunchAgent
    Reserved (currently unused).

.PARAMETER Count
    Number of repositories to create from this slug. Default: 1.

.PARAMETER TemplateRepoName
    Template repository name used for new repos. Used for placeholder
    replacement. Default: ai-new-workflow-app-template.

.PARAMETER TriggerProjectSetup
    Trigger the project-setup workflow on the new repo after creation.
    Default: $true.

.PARAMETER Help
    Show this usage information and exit. Alias: -h.

.EXAMPLE
    ./scripts/create-repo-from-slug.ps1 -Slug "my-app" -Visibility public -Yes

.EXAMPLE
    ./scripts/create-repo-from-slug.ps1 -Slug "my-app" -Count 2 -Yes
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Slug to use for repo name and docs directory.')]
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
    [string]$TemplateRepoName = 'ai-new-workflow-app-template',

    [Parameter(HelpMessage = 'Trigger the project-setup workflow on the new repo after creation.')]
    [bool]$TriggerProjectSetup = $true,

    [Parameter()]
    [Alias('h')]
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

function Show-Usage {
    Get-Help -Name $PSCommandPath -Detailed | Out-String | Write-Host
}

if ($Help) {
    Show-Usage
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Slug)) {
    Write-Host 'Error: -Slug is required.' -ForegroundColor Red
    Write-Host ''
    Show-Usage
    exit 1
}

if ($Yes) {
    ./scripts/create-repo-with-plan-docs.ps1 -RepoName $Slug -PlanDocsDir "./plan_docs/$Slug" -CloneParentDir ../dynamic_workflows -Visibility $Visibility -Owner $Owner -TemplateRepoName $TemplateRepoName -Count $Count -TriggerProjectSetup $TriggerProjectSetup -Yes -LaunchEditor
}
else {
    ./scripts/create-repo-with-plan-docs.ps1 -RepoName $Slug -PlanDocsDir "./plan_docs/$Slug" -CloneParentDir ../dynamic_workflows -Visibility $Visibility -Owner $Owner -TemplateRepoName $TemplateRepoName -Count $Count -TriggerProjectSetup $TriggerProjectSetup
}


