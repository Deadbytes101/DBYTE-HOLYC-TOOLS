param(
    [string]$PackageDir = "dist/dbyte-holyc-tools-windows"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$exe = Join-Path $PackageDir "holytools.exe"
$readme = Join-Path $PackageDir "README.md"
$changelog = Join-Path $PackageDir "CHANGELOG.md"

foreach ($path in @($exe, $readme, $changelog)) {
    if (!(Test-Path $path)) {
        Write-Error "missing package file: $path"
        exit 1
    }
}

& $exe version
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "verify-package: ok"
