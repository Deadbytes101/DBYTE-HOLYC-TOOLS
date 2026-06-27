param(
    [string]$Root = "reports/archaeology",
    [string]$Out = "reports/archaeology/LOSETHOS-ADAM-SURFACE.md"
)

$ErrorActionPreference = "Stop"

function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function S { param([string]$Path) if ($null -eq $Path) { return "" } $Path.Replace([char]92, [char]47) }
function Rows { param([string]$Path) if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() } $json = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json; if ($null -eq $json.rows) { return @() }; return @($json.rows) }
function OutEdges { param([array]$Rows, [string]$Anchor) $suffix = (S $Anchor).ToLowerInvariant(); return @($Rows | Where-Object { (S ([string]$_.file)).ToLowerInvariant().EndsWith($suffix) } | Sort-Object line,column,target) }
function InEdges { param([array]$Rows, [string]$Anchor) $suffix = (S $Anchor).ToLowerInvariant(); return @($Rows | Where-Object { (S ([string]$_.resolved)).ToLowerInvariant().EndsWith($suffix) } | Sort-Object file,line,column,target) }

$rows = @(Rows (Join-Path $Root "losethos/include-resolve.json"))
$anchors = @(
    "ADAM/ADAM2.CPZ",
    "ADAM/ADAMASM.ASZ",
    "OSMain/ADAMK.CPZ",
    "OSMain/ADAMK.HPZ",
    "OSMain/ADAMK2.HPZ",
    "OSMain/ADAMK3.HPZ"
)

New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null

$html = @()
$html += "<h1>LOSETHOS ADAM SURFACE</h1>"
$html += "<section><h2>Adam Pressure</h2><table>"
$html += "    <tr><th>anchor</th><th>outgoing</th><th>incoming</th><th>read</th></tr>"
foreach ($anchor in $anchors) {
    $outEdges = @(OutEdges $rows $anchor)
    $inEdges = @(InEdges $rows $anchor)
    $read = "support"
    if ($anchor -eq "ADAM/ADAM2.CPZ") { $read = "adam manifest" }
    elseif ($anchor -eq "ADAM/ADAMASM.ASZ") { $read = "adam asm surface" }
    elseif ($anchor -eq "OSMain/ADAMK.CPZ") { $read = "bridge" }
    elseif ($anchor -like "OSMain/ADAMK*.HPZ") { $read = "header pressure" }
    $html += "    <tr><td>$(E $anchor)</td><td>$($outEdges.Count)</td><td>$($inEdges.Count)</td><td>$(E $read)</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>ADAM2 Load List</h2><table>"
$html += "    <tr><th>line</th><th>target</th><th>status</th><th>resolved</th></tr>"
foreach ($edge in @(OutEdges $rows "ADAM/ADAM2.CPZ")) {
    $resolved = S ([string]$edge.resolved)
    $index = $resolved.IndexOf("LT/", [System.StringComparison]::OrdinalIgnoreCase)
    if ($index -ge 0) { $resolved = $resolved.Substring($index) }
    $html += "    <tr><td>$($edge.line)</td><td>$(E ([string]$edge.target))</td><td>$(E ([string]$edge.status))</td><td>$(E $resolved)</td></tr>"
}
$html += "  </table></section>"
$html += "<section><h2>Read Line</h2><pre>ADAMK.CPZ bridges OSMain, compiler headers, and ADAM2.CPZ."
$html += "ADAM2.CPZ is the next Adam-layer manifest to inspect from generated include evidence."
$html += "This report is structural include archaeology only.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"

$html | Set-Content -Encoding utf8 $Out
Write-Host "compare-losethos-adam-surface: $Out"
