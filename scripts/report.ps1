param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [string]$Out = "reports/holyc-report"
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $true
}

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command
    )

    & $Command
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$tool = Join-Path $PSScriptRoot "../target/release/holytools.exe"
if (-not (Test-Path $tool)) {
    Invoke-Step { cargo build --release -p holytools }
}

New-Item -ItemType Directory -Force -Path $Out | Out-Null

$versionFile = Join-Path $Out "version.txt"
$sourceMapText = Join-Path $Out "source-map.txt"
$sourceMapJson = Join-Path $Out "source-map.json"
$missingText = Join-Path $Out "missing-includes.txt"
$missingJson = Join-Path $Out "missing-includes.json"
$entryText = Join-Path $Out "entrypoints.txt"
$entryJson = Join-Path $Out "entrypoints.json"
$orderText = Join-Path $Out "dependency-order.txt"
$orderJson = Join-Path $Out "dependency-order.json"
$reverseText = Join-Path $Out "reverse-includes.txt"
$reverseJson = Join-Path $Out "reverse-includes.json"

Invoke-Step { & $tool version | Set-Content -Encoding utf8 $versionFile }
Invoke-Step { & $tool source-map $Path | Set-Content -Encoding utf8 $sourceMapText }
Invoke-Step { & $tool source-map $Path --json | Set-Content -Encoding utf8 $sourceMapJson }
Invoke-Step { & $tool missing-includes $Path | Set-Content -Encoding utf8 $missingText }
Invoke-Step { & $tool missing-includes $Path --json | Set-Content -Encoding utf8 $missingJson }
Invoke-Step { & $tool entrypoints $Path | Set-Content -Encoding utf8 $entryText }
Invoke-Step { & $tool entrypoints $Path --json | Set-Content -Encoding utf8 $entryJson }
Invoke-Step { & $tool dependency-order $Path | Set-Content -Encoding utf8 $orderText }
Invoke-Step { & $tool dependency-order $Path --json | Set-Content -Encoding utf8 $orderJson }
Invoke-Step { & $tool reverse-includes $Path | Set-Content -Encoding utf8 $reverseText }
Invoke-Step { & $tool reverse-includes $Path --json | Set-Content -Encoding utf8 $reverseJson }

Write-Host "report: $Out"
