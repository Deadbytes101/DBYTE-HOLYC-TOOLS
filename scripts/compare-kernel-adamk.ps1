param(
    [string]$Root = "reports/archaeology",
    [string]$Out = "reports/archaeology/TEMPLEOS-LOSETHOS-KERNEL-ADAMK-COMPARE.md"
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
        if ([string]::IsNullOrWhiteSpace($part) -or $part -eq '.') { continue }
        if ($part -eq '..') {
            if ($stack.Count -gt 0) { $stack.RemoveAt($stack.Count - 1) }
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

function IncomingForAnchor {
    param([array]$Rows, [string]$AnchorSuffix)
    $suffix = (SlashPath $AnchorSuffix).ToLowerInvariant()
    return @($Rows |
        Where-Object { (SlashPath ([string]$_.resolved)).ToLowerInvariant().EndsWith($suffix) } |
        Sort-Object file,line,column,target)
}

function AddAnchorBlock {
    param(
        [array]$Html,
        [string]$Title,
        [array]$Rows,
        [string]$AnchorSuffix,
        [string]$RootMarker
    )

    $outgoing = EdgesForAnchor $Rows $AnchorSuffix
    $incoming = IncomingForAnchor $Rows $AnchorSuffix

    $Html += "<section>"
    $Html += "  <h2>$(EscapeHtml $Title)</h2>"
    $Html += "  <pre>anchor: $(EscapeHtml $AnchorSuffix)"
    $Html += "outgoing-includes: $($outgoing.Count)"
    $Html += "incoming-includes: $($incoming.Count)</pre>"

    $Html += "  <h3>Outgoing</h3>"
    $Html += "  <table>"
    $Html += "    <tr><th>line</th><th>target</th><th>status</th><th>resolved</th></tr>"
    if ($outgoing.Count -eq 0) {
        $Html += "    <tr><td>-</td><td>-</td><td>no edges found</td><td>-</td></tr>"
    } else {
        foreach ($edge in $outgoing) {
            $resolved = ShortPath ([string]$edge.resolved) $RootMarker
            $Html += "    <tr><td>$($edge.line)</td><td>$(EscapeHtml ([string]$edge.target))</td><td>$(EscapeHtml ([string]$edge.status))</td><td>$(EscapeHtml $resolved)</td></tr>"
        }
    }
    $Html += "  </table>"

    $Html += "  <h3>Incoming</h3>"
    $Html += "  <table>"
    $Html += "    <tr><th>from</th><th>line</th><th>target</th><th>status</th></tr>"
    if ($incoming.Count -eq 0) {
        $Html += "    <tr><td>-</td><td>-</td><td>-</td><td>no incoming edges found</td></tr>"
    } else {
        foreach ($edge in $incoming) {
            $from = ShortPath ([string]$edge.file) $RootMarker
            $Html += "    <tr><td>$(EscapeHtml $from)</td><td>$($edge.line)</td><td>$(EscapeHtml ([string]$edge.target))</td><td>$(EscapeHtml ([string]$edge.status))</td></tr>"
        }
    }
    $Html += "  </table>"
    $Html += "</section>"
    return $Html
}

$templeRows = ReadRows (Join-Path $Root "templeos/include-resolve.json")
$loseRows = ReadRows (Join-Path $Root "losethos/include-resolve.json")

$templeAnchors = @("Kernel/KernelA.HH", "Kernel/KernelB.HH", "Kernel/KernelC.HH")
$loseAnchors = @("OSMain/ADAMK.HPZ", "OSMain/ADAMK2.HPZ", "OSMain/ADAMK3.HPZ", "OSMain/ADAMK.CPZ")

New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null

$html = @()
$html += "<h1>TEMPLEOS KERNEL TO LOSETHOS ADAMK COMPARE</h1>"
$html += "<section>"
$html += "  <h2>Input</h2>"
$html += "  <pre>templeos-include-edges: $($templeRows.Count)"
$html += "losethos-include-edges: $($loseRows.Count)"
$html += "source: generated include-resolve.json reports only</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Anchor Set</h2>"
$html += "  <table>"
$html += "    <tr><th>side</th><th>anchors</th><th>read</th></tr>"
$html += "    <tr><td>TempleOS</td><td>KernelA.HH, KernelB.HH, KernelC.HH</td><td>later split kernel header surface</td></tr>"
$html += "    <tr><td>LoseThos</td><td>ADAMK.HPZ, ADAMK2.HPZ, ADAMK3.HPZ, ADAMK.CPZ</td><td>early ADAMK bridge and header surface</td></tr>"
$html += "  </table>"
$html += "</section>"

foreach ($anchor in $templeAnchors) {
    $html = AddAnchorBlock $html "TempleOS $anchor" $templeRows $anchor "TempleOS/"
}

foreach ($anchor in $loseAnchors) {
    $html = AddAnchorBlock $html "LoseThos $anchor" $loseRows $anchor "LT/"
}

$html += "<section>"
$html += "  <h2>Read Line</h2>"
$html += "  <pre>TempleOS exposes a later split kernel header surface through KernelA, KernelB, and KernelC."
$html += "LoseThos exposes an earlier ADAMK surface where ADAMK.CPZ bridges OSMain headers, compiler header, and Adam."
$html += "Incoming edges show who depends on the anchor. Outgoing edges show what the anchor pulls in."
$html += "This is structural include evidence only, not semantic equivalence.</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Boundary</h2>"
$html += "  <pre>No compile. No execute. No rewrite. No source-tree mutation."
$html += "Only generated include-resolve rows are read.</pre>"
$html += "</section>"

$html | Set-Content -Encoding utf8 $Out
Write-Host "compare-kernel-adamk: $Out"
