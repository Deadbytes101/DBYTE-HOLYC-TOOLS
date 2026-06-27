param(
    [string]$Root = "reports/archaeology",
    [string]$Out = "reports/archaeology/TEMPLEOS-LOSETHOS-BOOT-COMPARE.md"
)

$ErrorActionPreference = "Stop"

function EscapeHtml {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function SlashPath {
    param([string]$Path)
    if ($null -eq $Path) { return "" }
    $Path.Replace([char]92, [char]47)
}

function ReadRows {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    $json = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($null -eq $json.rows) { return @() }
    return @($json.rows)
}

function ShortPath {
    param([string]$Path, [string]$Marker)
    $value = SlashPath $Path
    $index = $value.IndexOf($Marker, [System.StringComparison]::OrdinalIgnoreCase)
    if ($index -ge 0) { return $value.Substring($index) }
    return $value
}

function EdgesForAnchor {
    param([array]$Rows, [string]$AnchorSuffix)
    $suffix = (SlashPath $AnchorSuffix).ToLowerInvariant()
    return @($Rows |
        Where-Object { (SlashPath ([string]$_.file)).ToLowerInvariant().EndsWith($suffix) } |
        Sort-Object line,column,target)
}

function AddEdgeTable {
    param(
        [array]$Html,
        [string]$Title,
        [array]$Rows,
        [string]$AnchorSuffix,
        [string]$RootMarker
    )

    $edges = EdgesForAnchor $Rows $AnchorSuffix
    $Html += "<section>"
    $Html += "  <h2>$(EscapeHtml $Title)</h2>"
    $Html += "  <pre>anchor: $(EscapeHtml $AnchorSuffix)"
    $Html += "outgoing-includes: $($edges.Count)</pre>"
    $Html += "  <table>"
    $Html += "    <tr><th>line</th><th>target</th><th>status</th><th>resolved</th></tr>"
    if ($edges.Count -eq 0) {
        $Html += "    <tr><td>-</td><td>-</td><td>no edges found</td><td>-</td></tr>"
    } else {
        foreach ($edge in $edges) {
            $resolved = ShortPath ([string]$edge.resolved) $RootMarker
            $Html += "    <tr><td>$($edge.line)</td><td>$(EscapeHtml ([string]$edge.target))</td><td>$(EscapeHtml ([string]$edge.status))</td><td>$(EscapeHtml $resolved)</td></tr>"
        }
    }
    $Html += "  </table>"
    $Html += "</section>"
    return $Html
}

$templeRows = ReadRows (Join-Path $Root "templeos/include-resolve.json")
$loseRows = ReadRows (Join-Path $Root "losethos/include-resolve.json")

New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null

$html = @()
$html += "<h1>TEMPLEOS LOSETHOS BOOT COMPARE</h1>"
$html += "<section>"
$html += "  <h2>Input</h2>"
$html += "  <pre>templeos-include-edges: $($templeRows.Count)"
$html += "losethos-include-edges: $($loseRows.Count)"
$html += "source: generated include-resolve.json reports only</pre>"
$html += "</section>"

$html = AddEdgeTable $html "TempleOS Root Load" $templeRows "StartOS.HC" "TempleOS/"
$html = AddEdgeTable $html "LoseThos Root Load" $loseRows "OSMain/OS.ASZ" "LT/"
$html = AddEdgeTable $html "LoseThos Kernel Adam Bridge" $loseRows "OSMain/ADAMK.CPZ" "LT/"
$html = AddEdgeTable $html "LoseThos Compiler Load" $loseRows "COMPILE/CMP.ASZ" "LT/"

$html += "<section>"
$html += "  <h2>Read Line</h2>"
$html += "  <pre>TempleOS root evidence starts at StartOS.HC."
$html += "LoseThos root evidence starts at OSMain/OS.ASZ."
$html += "LoseThos ADAMK.CPZ behaves like an early bridge between OSMain and higher layers."
$html += "LoseThos COMPILE/CMP.ASZ gives the compiler load surface separately."
$html += "This report compares file-level include evidence, not runtime scheduling.</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Boundary</h2>"
$html += "  <pre>No compile. No execute. No rewrite. No source-tree mutation."
$html += "Only generated include-resolve rows are read.</pre>"
$html += "</section>"

$html | Set-Content -Encoding utf8 $Out
Write-Host "compare-boot-chain: $Out"
