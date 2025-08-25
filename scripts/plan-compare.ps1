param(
    [Parameter(Mandatory=$true)][string]$Expected,
    [Parameter(Mandatory=$true)][string]$Actual,
    [ValidateSet('json','md','text')][string]$Kind = 'json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Expected)) { throw "Expected file not found: $Expected" }
if (-not (Test-Path $Actual)) { throw "Actual file not found: $Actual" }

function Get-NormalizedContent {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Kind
    )
    $raw = Get-Content -Raw -Path $Path -Encoding UTF8
    switch ($Kind) {
        'json' { return ($raw | ConvertFrom-Json | ConvertTo-Json -Depth 10) }
        default { return ($raw -replace "\r\n","\n") }
    }
}

$exp = Get-NormalizedContent -Path $Expected -Kind $Kind
$act = Get-NormalizedContent -Path $Actual -Kind $Kind

if ($exp -ne $act) {
    Write-Host "Plans differ:" -ForegroundColor Red
    # crude diff: write temp files for fc-compatible compare on Windows
    $tmp1 = New-TemporaryFile
    $tmp2 = New-TemporaryFile
    Set-Content -Path $tmp1 -Value $exp -Encoding UTF8
    Set-Content -Path $tmp2 -Value $act -Encoding UTF8
    Write-Host "Expected: $Expected" -ForegroundColor Yellow
    Write-Host "Actual:   $Actual" -ForegroundColor Yellow
    if ($IsWindows) {
        cmd /c fc "$tmp1" "$tmp2" | Out-Host
    } else {
        Compare-Object (Get-Content -Raw $tmp1) (Get-Content -Raw $tmp2) | Out-Host
    }
    exit 1
}

Write-Host "Plans are equivalent" -ForegroundColor Green
