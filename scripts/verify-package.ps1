param(
    [string]$PackageDir = "dist/dbyte-holyc-tools-windows"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$requiredFiles = @(
    "holytools.exe",
    "README.md",
    "CHANGELOG.md",
    "VERSION.txt",
    "SHA256SUMS.txt",
    "MANIFEST.txt",
    "scripts/check-includes.ps1",
    "scripts/report.ps1",
    "scripts/resolve-archaeology-includes.ps1",
    "scripts/reverse-archaeology.ps1",
    "scripts/boot-chain-archaeology.ps1",
    "scripts/spine-archaeology.ps1",
    "scripts/kernel-contract-archaeology.ps1",
    "scripts/compiler-contract-archaeology.ps1",
    "scripts/adam-manifest-archaeology.ps1",
    "scripts/desktop-surface-archaeology.ps1",
    "scripts/adam-subsystems-archaeology.ps1",
    "scripts/archaeology-findings.ps1",
    "scripts/summarize-archaeology.ps1",
    "scripts/run-archaeology.ps1"
)

foreach ($file in $requiredFiles) {
    $path = Join-Path $PackageDir $file
    if (!(Test-Path $path)) {
        Write-Error "missing package file: $path"
        exit 1
    }
}

$exe = Join-Path $PackageDir "holytools.exe"
$version = Join-Path $PackageDir "VERSION.txt"
$checksums = Join-Path $PackageDir "SHA256SUMS.txt"
$manifest = Join-Path $PackageDir "MANIFEST.txt"
$checkIncludes = Join-Path $PackageDir "scripts/check-includes.ps1"
$report = Join-Path $PackageDir "scripts/report.ps1"

$manifestFiles = Get-Content $manifest
foreach ($file in $requiredFiles) {
    if ($manifestFiles -notcontains $file) {
        Write-Error "manifest missing entry: $file"
        exit 1
    }
}

$actualVersion = & $exe version
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$expectedVersion = Get-Content $version
if (($actualVersion -join "`n") -ne ($expectedVersion -join "`n")) {
    Write-Error "version file mismatch"
    exit 1
}

$actual = (Get-FileHash $exe -Algorithm SHA256).Hash.ToLowerInvariant()
$expectedLine = Get-Content $checksums | Select-Object -First 1
$expected = ($expectedLine -split "\s+")[0]

if ($actual -ne $expected) {
    Write-Error "checksum mismatch for holytools.exe"
    exit 1
}

& $checkIncludes tests/fixtures/tiny
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $report tests/fixtures/tiny reports/package-verify
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $exe oracle --seed 7 --count 2
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $exe oracle --preset after-egypt --seed 7 --count 1 --json
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "verify-package: ok"
