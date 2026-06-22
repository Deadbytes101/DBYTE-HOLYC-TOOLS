param(
    [string]$OutDir = "dist/dbyte-holyc-tools-windows"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

cargo build --release -p holytools

if (Test-Path $OutDir) {
    Remove-Item -Recurse -Force $OutDir
}

New-Item -ItemType Directory -Force $OutDir | Out-Null
Copy-Item target/release/holytools.exe "$OutDir/holytools.exe"
Copy-Item README.md "$OutDir/README.md"
Copy-Item CHANGELOG.md "$OutDir/CHANGELOG.md"

Write-Host "package: $OutDir"
