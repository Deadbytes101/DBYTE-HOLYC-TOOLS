param(
    [string]$OutDir = "dist/dbyte-holyc-tools-windows"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

cargo build --release -p holytools

if (Test-Path $OutDir) {
    Remove-Item -Recurse -Force $OutDir
}

$scriptsDir = Join-Path $OutDir "scripts"
New-Item -ItemType Directory -Force $OutDir | Out-Null
New-Item -ItemType Directory -Force $scriptsDir | Out-Null

Copy-Item target/release/holytools.exe "$OutDir/holytools.exe"
Copy-Item README.md "$OutDir/README.md"
Copy-Item CHANGELOG.md "$OutDir/CHANGELOG.md"
Copy-Item scripts/check-includes.ps1 "$scriptsDir/check-includes.ps1"
Copy-Item scripts/report.ps1 "$scriptsDir/report.ps1"

$version = & "$OutDir/holytools.exe" version
$version | Set-Content -Encoding UTF8 "$OutDir/VERSION.txt"

$hash = Get-FileHash "$OutDir/holytools.exe" -Algorithm SHA256
"$($hash.Hash.ToLowerInvariant())  holytools.exe" | Set-Content -Encoding UTF8 "$OutDir/SHA256SUMS.txt"

@(
    "holytools.exe",
    "README.md",
    "CHANGELOG.md",
    "VERSION.txt",
    "SHA256SUMS.txt",
    "MANIFEST.txt",
    "scripts/check-includes.ps1",
    "scripts/report.ps1"
) | Set-Content -Encoding UTF8 "$OutDir/MANIFEST.txt"

Write-Host "package: $OutDir"
