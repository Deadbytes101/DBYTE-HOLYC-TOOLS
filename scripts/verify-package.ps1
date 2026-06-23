param(
    [string]$PackageDir = "dist/dbyte-holyc-tools-windows"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$exe = Join-Path $PackageDir "holytools.exe"
$readme = Join-Path $PackageDir "README.md"
$changelog = Join-Path $PackageDir "CHANGELOG.md"
$version = Join-Path $PackageDir "VERSION.txt"
$checksums = Join-Path $PackageDir "SHA256SUMS.txt"
$manifest = Join-Path $PackageDir "MANIFEST.txt"
$checkIncludes = Join-Path $PackageDir "scripts/check-includes.ps1"
$report = Join-Path $PackageDir "scripts/report.ps1"
$requiredFiles = @(
    "holytools.exe",
    "README.md",
    "CHANGELOG.md",
    "VERSION.txt",
    "SHA256SUMS.txt",
    "MANIFEST.txt",
    "scripts/check-includes.ps1",
    "scripts/report.ps1"
)

foreach ($path in @($exe, $readme, $changelog, $version, $checksums, $manifest, $checkIncludes, $report)) {
    if (!(Test-Path $path)) {
        Write-Error "missing package file: $path"
        exit 1
    }
}

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

Write-Host "verify-package: ok"
