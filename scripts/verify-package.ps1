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

foreach ($path in @($exe, $readme, $changelog, $version, $checksums)) {
    if (!(Test-Path $path)) {
        Write-Error "missing package file: $path"
        exit 1
    }
}

& $exe version
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$actual = (Get-FileHash $exe -Algorithm SHA256).Hash.ToLowerInvariant()
$expectedLine = Get-Content $checksums | Select-Object -First 1
$expected = ($expectedLine -split "\s+")[0]

if ($actual -ne $expected) {
    Write-Error "checksum mismatch for holytools.exe"
    exit 1
}

Write-Host "verify-package: ok"
