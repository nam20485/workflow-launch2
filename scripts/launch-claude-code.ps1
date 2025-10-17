#!/usr/bin/env pwsh
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Directory,

    [Parameter(Mandatory = $false)]
    [string]
    $model = 'claude-sonnet-4-5-20250929'
)

$originalLocation = Get-Location

try {
    
    $DirectoryPath = Join-Path (Join-Path $PSScriptRoot '../../dynamic_workflows') $Directory
    Start-ClaudeCode -Directory $DirectoryPath -model $model
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    Set-Location -Path $originalLocation
}

function Start-ClaudeCode {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Directory,

        [Parameter(Mandatory = $false)]
        [string]
        $model = 'claude-sonnet-4-5-20250929'
    )

    Set-Location -Path $Directory
    claude --permission-mode bypassPermissions --model $model --verbose
}