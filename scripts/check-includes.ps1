param(
    [string]$Path = "tests/fixtures/tiny"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$packagedTool = Join-Path $PSScriptRoot "../holytools.exe"
if (Test-Path $packagedTool) {
    $json = & $packagedTool resolve-includes $Path --json
} else {
    $json = cargo run -q -p holytools -- resolve-includes $Path --json
}

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$result = $json | ConvertFrom-Json
if ($result.missing -ne 0) {
    Write-Error "missing includes: $($result.missing)"
    exit 1
}

Write-Host "check-includes: ok"
