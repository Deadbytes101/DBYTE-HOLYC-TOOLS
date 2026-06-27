param(
    [string]$Root = "reports/archaeology",
    [string]$OutPath = "reports/archaeology/LOSETHOS-CODEGEN-STATE.md"
)

$ErrorActionPreference = "Stop"
function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function HasReport { param([string]$Name) return (Test-Path -LiteralPath (Join-Path $Root $Name) -PathType Leaf) }

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null

$required = @(
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
    "LOSETHOS-FIXUP-COMPARE.md"
)

$html = @()
$html += "<h1>LOSETHOS CODEGEN STATE</h1>"
$html += "<section><h2>Generated Evidence</h2><table>"
$html += "    <tr><th>report</th><th>status</th></tr>"
foreach ($name in $required) {
    $status = if (HasReport $name) { "present" } else { "missing" }
    $html += "    <tr><td>$(E $name)</td><td>$status</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Evidence Chain</h2><pre>CMP.MPZ is a compiler/link map surface, not a normal code body."
$html += "CODE.ASZ is the dominant source reference inside CMP.MPZ and is table-shaped."
$html += "CODE.ASZ contains three complete parallel code-template families: ICT, UCT, and DCT."
$html += "Each family has 285 labels and the same 285 suffixes; no ICT/UCT/DCT suffix is missing."
$html += "UCT is the primary body-heavy family; ICT carries signed/integer-special bodies; DCT carries sparse double/FPU bodies."
$html += "LEX.CPZ exports table pointers such as code_table, unsigned_code_table, double_code_table, and internal_types_table."
$html += "COMPILE.CPZ FillCompilerTables assigns signed, unsigned, and double fix-up table regions and maps EC_* entries to FUT_* formats."
$html += "Fix-up comparison separates shared grammar, unsigned-only grammar, and format disagreements across type families.</pre></section>"

$html += "<section><h2>Working Model</h2><pre>LoseThos compiler codegen is not a loose blob: it has an exported map plus a triad code-template table."
$html += "CMP.MPZ points outward to source locations. CODE.ASZ holds the code-template substrate."
$html += "LEX.CPZ exposes the table symbols; COMPILE.CPZ owns initialization, fix-up table assignment, selected unsigned table patching, and type-family fix-up grammar."
$html += "ICT/UCT/DCT appear to represent integer/signed-ish, unsigned/generic, and double/FPU code paths, respectively."
$html += "This is a lexical archaeology model, not runtime proof.</pre></section>"

$html += "<section><h2>Next Targets</h2><pre>1. Inspect LOSETHOS-FIXUP-COMPARE.md for shared and divergent EC_* mappings."
$html += "2. Split unsigned_code_table patching from fix-up table assignment if more detail is needed."
$html += "3. Keep all claims report-grounded; do not execute or rewrite LoseThos sources.</pre></section>"

$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"
$html | Set-Content -Encoding utf8 $OutPath
Write-Host "rollup-losethos-codegen-state: $OutPath"
