param(
    [Parameter(Mandatory = $true)]
    [string]$SparrowOS,
    [string]$Out = "reports/archaeology/sparrowos-deep"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SparrowOS -PathType Container)) {
    Write-Error "missing SparrowOS source tree: $SparrowOS"
    exit 1
}

New-Item -ItemType Directory -Force $Out | Out-Null

./scripts/outline-sparrowos-pressure.ps1 -SparrowOS $SparrowOS -OutPath (Join-Path $Out "SPARROWOS-PRESSURE-OUTLINE.md")
./scripts/inspect-sparrowos-surface.ps1 -SparrowOS $SparrowOS -OutPath (Join-Path $Out "SPARROWOS-SURFACE.md")
./scripts/rollup-sparrowos-research-state.ps1 -Root $Out -OutPath (Join-Path $Out "SPARROWOS-RESEARCH-STATE.md")

Write-Host "sparrowos deep archaeology: ok"
