param(
    [string]$PackageDir = "dist/dbyte-holyc-tools-windows",
    [string]$ZipPath = "dist/dbyte-holyc-tools-windows.zip"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

if (!(Test-Path $PackageDir)) {
    ./scripts/package-windows.ps1 $PackageDir
}

./scripts/verify-package.ps1 $PackageDir

if (Test-Path $ZipPath) {
    Remove-Item -Force $ZipPath
}

Compress-Archive -Path "$PackageDir/*" -DestinationPath $ZipPath -Force

$hash = Get-FileHash $ZipPath -Algorithm SHA256
"$($hash.Hash.ToLowerInvariant())  $(Split-Path -Leaf $ZipPath)" | Set-Content -Encoding UTF8 "$ZipPath.sha256"

Write-Host "zip: $ZipPath"
Write-Host "sha256: $ZipPath.sha256"
