param(
    [string]$TempleOS,
    [string]$LoseThos,
    [string]$SparrowOS,
    [string]$Out = "reports/archaeology"
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

function Invoke-Target {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )

    if (-not (Test-Path $SourcePath)) {
        Write-Error "missing source tree: $SourcePath"
        exit 1
    }

    $targetOut = Join-Path $Out $Name
    Invoke-Step { ./scripts/report.ps1 $SourcePath $targetOut }

    $notes = Join-Path $targetOut "NOTES.md"
    if (-not (Test-Path $notes)) {
        @(
            "# $Name",
            "",
            "## WHERE TO START",
            "",
            "## CORE FILES",
            "",
            "## BROKEN INCLUDES",
            "",
            "## ENTRYPOINT CANDIDATES",
            "",
            "## DEPENDENCY SHAPE",
            "",
            "## REVERSE INCLUDE HOTSPOTS",
            "",
            "## ODD SYMBOLS",
            "",
            "## WHAT THE TOOL CAN SEE",
            "",
            "## WHAT THE TOOL CANNOT SEE",
            ""
        ) | Set-Content -Encoding utf8 $notes
    }

    Write-Host "archaeology: $Name -> $targetOut"
}

if ($TempleOS) {
    Invoke-Target "templeos" $TempleOS
}

if ($LoseThos) {
    Invoke-Target "losethos" $LoseThos
}

if ($SparrowOS) {
    Invoke-Target "sparrowos" $SparrowOS
}

if (-not $TempleOS -and -not $LoseThos -and -not $SparrowOS) {
    Write-Error "provide at least one source path: -TempleOS, -LoseThos, or -SparrowOS"
    exit 1
}

Invoke-Step { ./scripts/summarize-archaeology.ps1 $Out }
Write-Host "archaeology: ok"
