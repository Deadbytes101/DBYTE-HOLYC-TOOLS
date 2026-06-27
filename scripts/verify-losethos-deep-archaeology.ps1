$ErrorActionPreference = "Stop"

function Assert-Path {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Error "missing required file: $Path"
        exit 1
    }
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $body = Get-Content -LiteralPath $Path -Raw
    if (-not $body.Contains($Text)) {
        Write-Error "missing expected text in ${Path}: $Text"
        exit 1
    }
}

$deepScripts = @(
    "scripts/run-losethos-deep-archaeology.ps1",
    "scripts/outline-losethos-pressure.ps1",
    "scripts/inspect-losethos-dense-surface.ps1",
    "scripts/inspect-losethos-cmp-map.ps1",
    "scripts/inspect-losethos-code-table.ps1",
    "scripts/inspect-losethos-code-families.ps1",
    "scripts/inspect-losethos-code-triads.ps1",
    "scripts/summarize-losethos-code-triads.ps1",
    "scripts/correlate-losethos-compiler-codegen.ps1",
    "scripts/inspect-losethos-export-context.ps1",
    "scripts/inspect-losethos-fill-tables.ps1",
    "scripts/inspect-losethos-fixup-tables.ps1",
    "scripts/compare-losethos-fixup-tables.ps1",
    "scripts/summarize-losethos-fixup-grammar.ps1",
    "scripts/rollup-losethos-codegen-state.ps1"
)

$expectedReports = @(
    "LOSETHOS-PRESSURE-OUTLINE.md",
    "LOSETHOS-DENSE-SURFACE.md",
    "LOSETHOS-CMP-MAP.md",
    "LOSETHOS-CODE-TABLE.md",
    "LOSETHOS-CODE-FAMILIES.md",
    "LOSETHOS-CODE-TRIADS.md",
    "LOSETHOS-CODE-TRIAD-SUMMARY.md",
    "LOSETHOS-COMPILER-CODEGEN-CORRELATE.md",
    "LOSETHOS-COMPILER-EXPORT-CONTEXT.md",
    "LOSETHOS-FILL-TABLES.md",
    "LOSETHOS-FIXUP-TABLES.md",
    "LOSETHOS-FIXUP-COMPARE.md",
    "LOSETHOS-FIXUP-GRAMMAR.md",
    "LOSETHOS-CODEGEN-STATE.md"
)

foreach ($script in $deepScripts) {
    Assert-Path $script
}
Assert-Path "docs/LOSETHOS-CODEGEN-MILESTONE.md"
Assert-Path "README.md"
Assert-Path "scripts/run-archaeology.ps1"

foreach ($report in $expectedReports) {
    Assert-Contains "scripts/run-losethos-deep-archaeology.ps1" $report
    Assert-Contains "docs/LOSETHOS-CODEGEN-MILESTONE.md" $report
}

Assert-Contains "scripts/run-archaeology.ps1" "DeepLoseThos"
Assert-Contains "README.md" "-DeepLoseThos"
Assert-Contains "README.md" "docs/LOSETHOS-CODEGEN-MILESTONE.md"
Assert-Contains "docs/LOSETHOS-CODEGEN-MILESTONE.md" "codegen/fix-up archaeology milestone is considered evidence-complete at the lexical level"

Write-Host "verify-losethos-deep-archaeology: ok"
