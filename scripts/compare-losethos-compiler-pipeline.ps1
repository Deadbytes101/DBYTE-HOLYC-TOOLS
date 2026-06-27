param(
    [string]$Root = "reports/archaeology",
    [string]$Out = "reports/archaeology/LOSETHOS-COMPILER-PIPELINE.md"
)

$ErrorActionPreference = "Stop"

function E {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function S {
    param([string]$Path)
    if ($null -eq $Path) { return "" }
    $Path.Replace([char]92, [char]47)
}

function Rows {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    $json = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($null -eq $json.rows) { return @() }
    return @($json.rows)
}

function OutEdges {
    param([array]$Rows, [string]$Anchor)
    $suffix = (S $Anchor).ToLowerInvariant()
    return @($Rows | Where-Object { (S ([string]$_.file)).ToLowerInvariant().EndsWith($suffix) } | Sort-Object line,column,target)
}

function InEdges {
    param([array]$Rows, [string]$Anchor)
    $suffix = (S $Anchor).ToLowerInvariant()
    return @($Rows | Where-Object { (S ([string]$_.resolved)).ToLowerInvariant().EndsWith($suffix) } | Sort-Object file,line,column,target)
}

$rows = @(Rows (Join-Path $Root "losethos/include-resolve.json"))
$anchors = @(
    "COMPILE/CMP.ASZ",
    "COMPILE/CODE.ASZ",
    "COMPILE/LEX.CPZ",
    "COMPILE/SPRINTF2.CPZ",
    "COMPILE/ASM.CPZ",
    "COMPILE/PARSE.CPZ",
    "COMPILE/OPT.CPZ",
    "COMPILE/COMPILE.CPZ",
    "COMPILE/CMP.HPZ",
    "COMPILE/CMP.MPZ"
)

New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null

$html = @()
$html += "<h1>LOSETHOS COMPILER PIPELINE</h1>"
$html += "<section><h2>Pipeline Pressure</h2><table>"
$html += "    <tr><th>anchor</th><th>outgoing</th><th>incoming</th><th>read</th></tr>"
foreach ($anchor in $anchors) {
    $outEdges = @(OutEdges $rows $anchor)
    $inEdges = @(InEdges $rows $anchor)
    $read = "component"
    if ($anchor -eq "COMPILE/CMP.ASZ") { $read = "manifest" }
    elseif ($anchor -eq "COMPILE/CMP.HPZ") { $read = "header" }
    elseif ($anchor -eq "COMPILE/CMP.MPZ") { $read = "macro or metadata surface" }
    $html += "    <tr><td>$(E $anchor)</td><td>$($outEdges.Count)</td><td>$($inEdges.Count)</td><td>$(E $read)</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>CMP.ASZ Load List</h2><table>"
$html += "    <tr><th>line</th><th>target</th><th>status</th><th>resolved</th></tr>"
foreach ($edge in @(OutEdges $rows "COMPILE/CMP.ASZ")) {
    $resolved = S ([string]$edge.resolved)
    $index = $resolved.IndexOf("LT/", [System.StringComparison]::OrdinalIgnoreCase)
    if ($index -ge 0) { $resolved = $resolved.Substring($index) }
    $html += "    <tr><td>$($edge.line)</td><td>$(E ([string]$edge.target))</td><td>$(E ([string]$edge.status))</td><td>$(E $resolved)</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Read Line</h2><pre>CMP.ASZ is the compiler load manifest."
$html += "The main pipeline visible from include evidence is CODE, LEX, SPRINTF2, ASM, PARSE, OPT, and COMPILE."
$html += "This report stays on generated include evidence only. It does not claim semantic equivalence or runtime order.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"

$html | Set-Content -Encoding utf8 $Out
Write-Host "compare-losethos-compiler-pipeline: $Out"
