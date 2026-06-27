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

function NormalizePathSegments {
    param([string]$Path)

    $value = SlashPath $Path
    if ([string]::IsNullOrWhiteSpace($value)) { return "" }

    $prefix = ""
    if ($value -match '^[A-Za-z]:/') {
        $prefix = $value.Substring(0, 3)
        $value = $value.Substring(3)
    } elseif ($value.StartsWith('/')) {
        $prefix = "/"
        $value = $value.TrimStart('/')
    }

    $stack = New-Object System.Collections.Generic.List[string]
    foreach ($part in ($value -split '/')) {
        if ([string]::IsNullOrWhiteSpace($part) -or $part -eq '.') {
            continue
        }
        if ($part -eq '..') {
            if ($stack.Count -gt 0) {
                $stack.RemoveAt($stack.Count - 1)
            }
            continue
        }
        $stack.Add($part)
    }

    return $prefix + ($stack -join '/')
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
    $value = NormalizePathSegments $Path
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

function EdgeCount {
    param([array]$Rows, [string]$AnchorSuffix)
    return (EdgesForAnchor $Rows $AnchorSuffix).Count
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

$templeRootCount = EdgeCount $templeRows "StartOS.HC"
$loseRootCount = EdgeCount $loseRows "OSMain/OS.ASZ"
$loseBridgeCount = EdgeCount $loseRows "OSMain/ADAMK.CPZ"
$loseCompilerCount = EdgeCount $loseRows "COMPILE/CMP.ASZ"

New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null

$html = @()
$html += "<h1>TEMPLEOS LOSETHOS BOOT COMPARE</h1>"
$html += "<section>"
$html += "  <h2>Input</h2>"
$html += "  <pre>templeos-include-edges: $($templeRows.Count)"
$html += "losethos-include-edges: $($loseRows.Count)"
$html += "source: generated include-resolve.json reports only</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Boot Shape</h2>"
$html += "  <table>"
$html += "    <tr><th>anchor</th><th>outgoing-includes</th><th>read</th></tr>"
$html += "    <tr><td>TempleOS StartOS.HC</td><td>$templeRootCount</td><td>small root manifest into kernel, compiler, Adam, home</td></tr>"
$html += "    <tr><td>LoseThos OSMain/OS.ASZ</td><td>$loseRootCount</td><td>wide root manifest across OSMain, IRQ, memory, scheduler, command, disk</td></tr>"
$html += "    <tr><td>LoseThos OSMain/ADAMK.CPZ</td><td>$loseBridgeCount</td><td>bridge into ADAMK headers, compiler header, Adam</td></tr>"
$html += "    <tr><td>LoseThos COMPILE/CMP.ASZ</td><td>$loseCompilerCount</td><td>compiler load surface tied back to OSMain headers</td></tr>"
$html += "  </table>"
$html += "</section>"

$html = AddEdgeTable $html "TempleOS Root Load" $templeRows "StartOS.HC" "TempleOS/"
$html = AddEdgeTable $html "LoseThos Root Load" $loseRows "OSMain/OS.ASZ" "LT/"
$html = AddEdgeTable $html "LoseThos Kernel Adam Bridge" $loseRows "OSMain/ADAMK.CPZ" "LT/"
$html = AddEdgeTable $html "LoseThos Compiler Load" $loseRows "COMPILE/CMP.ASZ" "LT/"

$html += "<section>"
$html += "  <h2>Read Line</h2>"
$html += "  <pre>TempleOS root evidence starts at StartOS.HC. It is a small root manifest into kernel, compiler, Adam, and home."
$html += "LoseThos root evidence starts at OSMain/OS.ASZ. It is a wider root manifest that directly fans into OSMain, IRQ, memory, scheduler, command, and disk layers."
$html += "LoseThos ADAMK.CPZ behaves like an early bridge between OSMain headers, compiler header, and Adam."
$html += "LoseThos COMPILE/CMP.ASZ gives the compiler load surface separately while still tying back into OSMain headers."
$html += "This report compares file-level include evidence, not runtime scheduling.</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Boundary</h2>"
$html += "  <pre>No compile. No execute. No rewrite. No source-tree mutation."
$html += "Only generated include-resolve rows are read.</pre>"
$html += "</section>"

$html | Set-Content -Encoding utf8 $Out
Write-Host "compare-boot-chain: $Out"
