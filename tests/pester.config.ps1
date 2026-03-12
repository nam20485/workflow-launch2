#!/usr/bin/env pwsh
<#
.SYNOPSIS
Pester 5 configuration for the workflow-launch2 test suite.
Includes JaCoCo code-coverage output for ReportGenerator integration.
#>

$config = New-PesterConfiguration

# Test discovery
$config.Run.Path = @("$PSScriptRoot")
$config.Run.PassThru = $true

# Output
$config.Output.Verbosity = 'Detailed'

# Test results (JUnit XML for CI reporters)
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'JUnitXml'
$config.TestResult.OutputPath = Join-Path $PSScriptRoot '..' 'TestResults' 'test-results.xml'

# Code coverage — targets all three scripts including create-repo-from-slug.ps1
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = Join-Path $PSScriptRoot '..' 'TestResults' 'coverage.xml'
$config.CodeCoverage.Path = @(
    (Join-Path $PSScriptRoot '..' 'scripts' 'create-repo-with-plan-docs.ps1'),
    (Join-Path $PSScriptRoot '..' 'scripts' 'create-repo-from-slug.ps1'),
    (Join-Path $PSScriptRoot '..' 'scripts' 'repo-functions.ps1'),
    (Join-Path $PSScriptRoot '..' 'scripts' 'logging.ps1'),
    (Join-Path $PSScriptRoot '..' 'scripts' 'common-auth.ps1')
)
$config.CodeCoverage.CoveragePercentTarget = 55

$config
