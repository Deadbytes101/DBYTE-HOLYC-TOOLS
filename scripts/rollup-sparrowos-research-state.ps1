param(
    [string]$Root = "reports/archaeology/sparrowos-deep",
    [string]$OutPath = "reports/archaeology/sparrowos-deep/SPARROWOS-RESEARCH-STATE.md"
)

$ErrorActionPreference = "Stop"
function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function HasReport { param([string]$Name) return (Test-Path -LiteralPath (Join-Path $Root $Name) -PathType Leaf) }

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null

$required = @(
    "SPARROWOS-PRESSURE-OUTLINE.md",
    "SPARROWOS-SURFACE.md"
)

$html = @()
$html += "<h1>SPARROWOS RESEARCH STATE</h1>"
$html += "<section><h2>Generated Evidence</h2><table>"
$html += "    <tr><th>report</th><th>status</th></tr>"
foreach ($name in $required) {
    $status = if (HasReport $name) { "present" } else { "missing" }
    $html += "    <tr><td>$(E $name)</td><td>$status</td></tr>"
}
$html += "  </table></section>"
$html += "<section><h2>Research State</h2><pre>SparrowOS archaeology is in phase 1: source-shape discovery."
$html += "Do not assume TempleOS or LoseThos topology until SparrowOS reports show boot, kernel, compiler, and Adam-like anchors."
$html += "Next useful work is reading SPARROWOS-PRESSURE-OUTLINE.md and SPARROWOS-SURFACE.md, then adding focused reports only for confirmed surfaces.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"
$html | Set-Content -Encoding utf8 $OutPath
Write-Host "rollup-sparrowos-research-state: $OutPath"
