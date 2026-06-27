param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$Out = "reports/archaeology"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $LoseThos -PathType Container)) {
    Write-Error "missing LoseThos source tree: $LoseThos"
    exit 1
}

New-Item -ItemType Directory -Force $Out | Out-Null

./scripts/outline-losethos-pressure.ps1 -LoseThos $LoseThos -OutPath (Join-Path $Out "LOSETHOS-PRESSURE-OUTLINE.md")
./scripts/inspect-losethos-dense-surface.ps1 -LoseThos $LoseThos -OutPath (Join-Path $Out "LOSETHOS-DENSE-SURFACE.md")
./scripts/inspect-losethos-cmp-map.ps1 -LoseThos $LoseThos -OutPath (Join-Path $Out "LOSETHOS-CMP-MAP.md")
./scripts/inspect-losethos-code-table.ps1 -LoseThos $LoseThos -OutPath (Join-Path $Out "LOSETHOS-CODE-TABLE.md")
./scripts/inspect-losethos-code-families.ps1 -LoseThos $LoseThos -OutPath (Join-Path $Out "LOSETHOS-CODE-FAMILIES.md")
./scripts/inspect-losethos-code-triads.ps1 -LoseThos $LoseThos -OutPath (Join-Path $Out "LOSETHOS-CODE-TRIADS.md")
./scripts/summarize-losethos-code-triads.ps1 -LoseThos $LoseThos -OutPath (Join-Path $Out "LOSETHOS-CODE-TRIAD-SUMMARY.md")
./scripts/correlate-losethos-compiler-codegen.ps1 -LoseThos $LoseThos -OutPath (Join-Path $Out "LOSETHOS-COMPILER-CODEGEN-CORRELATE.md")
./scripts/inspect-losethos-export-context.ps1 -LoseThos $LoseThos -OutPath (Join-Path $Out "LOSETHOS-COMPILER-EXPORT-CONTEXT.md")
./scripts/inspect-losethos-fill-tables.ps1 -LoseThos $LoseThos -OutPath (Join-Path $Out "LOSETHOS-FILL-TABLES.md")
./scripts/rollup-losethos-codegen-state.ps1 -Root $Out -OutPath (Join-Path $Out "LOSETHOS-CODEGEN-STATE.md")

Write-Host "losethos deep archaeology: ok"
