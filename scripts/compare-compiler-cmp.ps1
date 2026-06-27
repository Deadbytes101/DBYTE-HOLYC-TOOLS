param(
    [string]$Root = "reports/archaeology",
    [string]$Out = "reports/archaeology/TEMPLEOS-LOSETHOS-COMPILER-CMP-COMPARE.md"
)

$ErrorActionPreference = "Stop"

function S {
    param([string]$Path)
    if ($null -eq $Path) { return "" }
    $Path.Replace([char]92, [char]47)
}

function E {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function Rows {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    $json = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($null -eq $json.rows) { return @() }
    return @($json.rows)
}

function OutCount {
    param([array]$Rows, [string]$Anchor)
    $suffix = (S $Anchor).ToLowerInvariant()
    return @($Rows | Where-Object { (S ([string]$_.file)).ToLowerInvariant().EndsWith($suffix) }).Count
}

function InCount {
    param([array]$Rows, [string]$Anchor)
    $suffix = (S $Anchor).ToLowerInvariant()
    return @($Rows | Where-Object { (S ([string]$_.resolved)).ToLowerInvariant().EndsWith($suffix) }).Count
}

function AddRows {
    param([array]$Html, [string]$Side, [array]$Rows, [string[]]$Anchors)
    foreach ($anchor in $Anchors) {
        $Html += "    <tr><td>$(E $Side)</td><td>$(E $anchor)</td><td>$(OutCount $Rows $anchor)</td><td>$(InCount $Rows $anchor)</td></tr>"
    }
    return $Html
}

$templeRows = @(Rows (Join-Path $Root "templeos/include-resolve.json"))
$loseRows = @(Rows (Join-Path $Root "losethos/include-resolve.json"))
$templeAnchors = @("Compiler/CompilerA.HH", "Compiler/CompilerB.HH")
$loseAnchors = @("COMPILE/CMP.ASZ", "COMPILE/CMP.HPZ", "COMPILE/CMP.MPZ")

New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null

$html = @()
$html += "<h1>TEMPLEOS COMPILER TO LOSETHOS CMP COMPARE</h1>"
$html += "<section><h2>Compiler Pressure</h2><table>"
$html += "    <tr><th>side</th><th>anchor</th><th>outgoing</th><th>incoming</th></tr>"
$html = AddRows $html "TempleOS" $templeRows $templeAnchors
$html = AddRows $html "LoseThos" $loseRows $loseAnchors
$html += "  </table></section>"
$html += "<section><h2>Read Line</h2><pre>TempleOS compiler evidence starts at CompilerA.HH and CompilerB.HH."
$html += "LoseThos compiler evidence starts at COMPILE/CMP.ASZ plus CMP.HPZ and CMP.MPZ."
$html += "Use this pressure table to choose the next deeper compiler archaeology target.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>Reads generated include-resolve rows only. No source-tree mutation.</pre></section>"

$html | Set-Content -Encoding utf8 $Out
Write-Host "compare-compiler-cmp: $Out"
