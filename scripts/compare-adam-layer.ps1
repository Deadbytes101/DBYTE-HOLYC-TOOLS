param(
    [string]$Root = "reports/archaeology",
    [string]$Out = "reports/archaeology/TEMPLEOS-LOSETHOS-ADAM-LAYER-COMPARE.md"
)

$ErrorActionPreference = "Stop"

function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function S { param([string]$Path) if ($null -eq $Path) { return "" } $Path.Replace([char]92, [char]47) }
function Rows { param([string]$Path) if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() } $json = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json; if ($null -eq $json.rows) { return @() }; return @($json.rows) }
function OutEdges { param([array]$Rows, [string]$Anchor) $suffix = (S $Anchor).ToLowerInvariant(); return @($Rows | Where-Object { (S ([string]$_.file)).ToLowerInvariant().EndsWith($suffix) } | Sort-Object line,column,target) }
function InEdges { param([array]$Rows, [string]$Anchor) $suffix = (S $Anchor).ToLowerInvariant(); return @($Rows | Where-Object { (S ([string]$_.resolved)).ToLowerInvariant().EndsWith($suffix) } | Sort-Object file,line,column,target) }

function AddRow {
    param([array]$Html, [string]$Side, [array]$Rows, [string]$Anchor, [string]$Read)
    $o = @(OutEdges $Rows $Anchor)
    $i = @(InEdges $Rows $Anchor)
    $Html += "    <tr><td>$(E $Side)</td><td>$(E $Anchor)</td><td>$($o.Count)</td><td>$($i.Count)</td><td>$(E $Read)</td></tr>"
    return $Html
}

$templeRows = @(Rows (Join-Path $Root "templeos/include-resolve.json"))
$loseRows = @(Rows (Join-Path $Root "losethos/include-resolve.json"))
$templeAnchor = "Adam/MakeAdam.HC"
$loseAnchor = "ADAM/ADAM2.CPZ"

New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null

$html = @()
$html += "<h1>TEMPLEOS LOSETHOS ADAM LAYER COMPARE</h1>"
$html += "<section><h2>Adam Pressure</h2><table>"
$html += "    <tr><th>side</th><th>anchor</th><th>outgoing</th><th>incoming</th><th>read</th></tr>"
$html = AddRow $html "TempleOS" $templeRows $templeAnchor "later Adam build manifest"
$html = AddRow $html "LoseThos" $loseRows $loseAnchor "early Adam manifest"
$html += "  </table></section>"
$html += "<section><h2>LoseThos ADAM2 Load List</h2><table>"
$html += "    <tr><th>line</th><th>target</th><th>status</th></tr>"
foreach ($edge in @(OutEdges $loseRows $loseAnchor)) {
    $html += "    <tr><td>$($edge.line)</td><td>$(E ([string]$edge.target))</td><td>$(E ([string]$edge.status))</td></tr>"
}
$html += "  </table></section>"
$html += "<section><h2>Read Line</h2><pre>TempleOS reaches Adam through Adam/MakeAdam.HC."
$html += "LoseThos reaches Adam through ADAM/ADAM2.CPZ from the ADAMK bridge."
$html += "Compare pressure first, then inspect source outlines if needed.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>Reads generated include-resolve rows only. No source-tree mutation.</pre></section>"

$html | Set-Content -Encoding utf8 $Out
Write-Host "compare-adam-layer: $Out"
