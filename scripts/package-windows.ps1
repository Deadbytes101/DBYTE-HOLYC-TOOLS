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

$packageScripts = @(
    "check-includes.ps1",
    "report.ps1",
    "resolve-archaeology-includes.ps1",
    "reverse-archaeology.ps1",
    "boot-chain-archaeology.ps1",
    "spine-archaeology.ps1",
    "kernel-contract-archaeology.ps1",
    "compiler-contract-archaeology.ps1",
    "adam-manifest-archaeology.ps1",
    "desktop-surface-archaeology.ps1",
    "adam-subsystems-archaeology.ps1",
    "archaeology-findings.ps1",
    "summarize-archaeology.ps1",
    "run-archaeology.ps1"
)

Copy-Item target/release/holytools.exe "$OutDir/holytools.exe"
Copy-Item README.md "$OutDir/README.md"
Copy-Item CHANGELOG.md "$OutDir/CHANGELOG.md"

foreach ($script in $packageScripts) {
    Copy-Item "scripts/$script" (Join-Path $scriptsDir $script)
}

$version = & "$OutDir/holytools.exe" version
$version | Set-Content -Encoding UTF8 "$OutDir/VERSION.txt"

$hash = Get-FileHash "$OutDir/holytools.exe" -Algorithm SHA256
"$($hash.Hash.ToLowerInvariant())  holytools.exe" | Set-Content -Encoding UTF8 "$OutDir/SHA256SUMS.txt"

$manifestEntries = @(
    "holytools.exe",
    "README.md",
    "CHANGELOG.md",
    "VERSION.txt",
    "SHA256SUMS.txt",
    "MANIFEST.txt"
)

foreach ($script in $packageScripts) {
    $manifestEntries += "scripts/$script"
}

$manifestEntries | Set-Content -Encoding UTF8 "$OutDir/MANIFEST.txt"

Write-Host "package: $OutDir"
