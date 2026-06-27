param(
    [string]$Root = "reports/archaeology",
    [string]$Out = "reports/archaeology/TEMPLEOS-LOSETHOS-KERNEL-ADAMK-COMPARE.md"
)

$ErrorActionPreference = "Stop"

function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function S { param([string]$Path) if ($null -eq $Path) { return "" } $Path.Replace([char]92, [char]47) }

function N {
    param([string]$Path)
    $value = S $Path
    if ([string]::IsNullOrWhiteSpace($value)) { return "" }
    $prefix = ""
    if ($value -match '^[A-Za-z]:/') { $prefix = $value.Substring(0, 3); $value = $value.Substring(3) }
    elseif ($value.StartsWith('/')) { $prefix = "/"; $value = $value.TrimStart('/') }
    $stack = New-Object System.Collections.Generic.List[string]
    foreach ($part in ($value -split '/')) {
        if ([string]::IsNullOrWhiteSpace($part) -or $part -eq '.') { continue }
        if ($part -eq '..') { if ($stack.Count -gt 0) { $stack.RemoveAt($stack.Count - 1) }; continue }
        $stack.Add($part)
    }
    return $prefix + ($stack -join '/')
}

function Rows {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    $json = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($null -eq $json.rows) { return @() }
    return @($json.rows)
}

function Short { param([string]$Path, [string]$Marker) $value = N $Path; $i = $value.IndexOf($Marker, [System.StringComparison]::OrdinalIgnoreCase); if ($i -ge 0) { return $value.Substring($i) }; return $value }
function OutEdges { param([array]$Rows, [string]$Anchor) $suf = (S $Anchor).ToLowerInvariant(); return @($Rows | Where-Object { (S ([string]$_.file)).ToLowerInvariant().EndsWith($suf) } | Sort-Object line,column,target) }
function InEdges { param([array]$Rows, [string]$Anchor) $suf = (S $Anchor).ToLowerInvariant(); return @($Rows | Where-Object { (S ([string]$_.resolved)).ToLowerInvariant().EndsWith($suf) } | Sort-Object file,line,column,target) }

function AddAnchor {
    param([array]$Html, [string]$Title, [array]$Rows, [string]$Anchor, [string]$RootMarker)
    $outgoing = @(OutEdges $Rows $Anchor)
    $incoming = @(InEdges $Rows $Anchor)
    $Html += "<section>"
    $Html += "  <h2>$(E $Title)</h2>"
    $Html += "  <pre>anchor: $(E $Anchor)"
    $Html += "outgoing-includes: $($outgoing.Count)"
    $Html += "incoming-includes: $($incoming.Count)</pre>"
    $Html += "  <h3>Outgoing</h3>"
    $Html += "  <table>"
    $Html += "    <tr><th>line</th><th>target</th><th>status</th><th>resolved</th></tr>"
    if ($outgoing.Count -eq 0) { $Html += "    <tr><td>-</td><td>-</td><td>no edges found</td><td>-</td></tr>" }
    foreach ($edge in $outgoing) { $Html += "    <tr><td>$($edge.line)</td><td>$(E ([string]$edge.target))</td><td>$(E ([string]$edge.status))</td><td>$(E (Short ([string]$edge.resolved) $RootMarker))</td></tr>" }
    $Html += "  </table>"
    $Html += "  <h3>Incoming</h3>"
    $Html += "  <table>"
    $Html += "    <tr><th>from</th><th>line</th><th>target</th><th>status</th></tr>"
    if ($incoming.Count -eq 0) { $Html += "    <tr><td>-</td><td>-</td><td>-</td><td>no incoming edges found</td></tr>" }
    foreach ($edge in $incoming) { $Html += "    <tr><td>$(E (Short ([string]$edge.file) $RootMarker))</td><td>$($edge.line)</td><td>$(E ([string]$edge.target))</td><td>$(E ([string]$edge.status))</td></tr>" }
    $Html += "  </table>"
    $Html += "</section>"
    return $Html
}

function AddPressure {
    param([array]$Html, [string]$Side, [array]$Rows, [string[]]$Anchors)
    foreach ($anchor in $Anchors) {
        $outgoing = @(OutEdges $Rows $anchor)
        $incoming = @(InEdges $Rows $anchor)
        $Html += "    <tr><td>$(E $Side)</td><td>$(E $anchor)</td><td>$($outgoing.Count)</td><td>$($incoming.Count)</td></tr>"
    }
    return $Html
}

$templeRows = @(Rows (Join-Path $Root "templeos/include-resolve.json"))
$loseRows = @(Rows (Join-Path $Root "losethos/include-resolve.json"))
$templeAnchors = @("Kernel/KernelA.HH", "Kernel/KernelB.HH", "Kernel/KernelC.HH")
$loseAnchors = @("OSMain/ADAMK.HPZ", "OSMain/ADAMK2.HPZ", "OSMain/ADAMK3.HPZ", "OSMain/ADAMK.CPZ")

New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null

$html = @()
$html += "<h1>TEMPLEOS KERNEL TO LOSETHOS ADAMK COMPARE</h1>"
$html += "<section><h2>Input</h2><pre>templeos-include-edges: $($templeRows.Count)"
$html += "losethos-include-edges: $($loseRows.Count)"
$html += "source: generated include-resolve.json reports only</pre></section>"
$html += "<section><h2>Anchor Set</h2><table>"
$html += "    <tr><th>side</th><th>anchors</th><th>read</th></tr>"
$html += "    <tr><td>TempleOS</td><td>KernelA.HH, KernelB.HH, KernelC.HH</td><td>later split kernel header surface</td></tr>"
$html += "    <tr><td>LoseThos</td><td>ADAMK.HPZ, ADAMK2.HPZ, ADAMK3.HPZ, ADAMK.CPZ</td><td>early ADAMK bridge and header surface</td></tr>"
$html += "  </table></section>"
$html += "<section><h2>Header Pressure</h2><table>"
$html += "    <tr><th>side</th><th>anchor</th><th>outgoing</th><th>incoming</th></tr>"
$html = AddPressure $html "TempleOS" $templeRows $templeAnchors
$html = AddPressure $html "LoseThos" $loseRows $loseAnchors
$html += "  </table></section>"
foreach ($anchor in $templeAnchors) { $html = AddAnchor $html "TempleOS $anchor" $templeRows $anchor "TempleOS/" }
foreach ($anchor in $loseAnchors) { $html = AddAnchor $html "LoseThos $anchor" $loseRows $anchor "LT/" }
$html += "<section><h2>Read Line</h2><pre>TempleOS exposes a later split kernel header surface through KernelA, KernelB, and KernelC."
$html += "LoseThos exposes an earlier ADAMK surface where ADAMK.CPZ bridges OSMain headers, compiler header, and Adam."
$html += "Incoming edges show who depends on the anchor. Outgoing edges show what the anchor pulls in."
$html += "This is structural include evidence only, not semantic equivalence.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation."
$html += "Only generated include-resolve rows are read.</pre></section>"

$html | Set-Content -Encoding utf8 $Out
Write-Host "compare-kernel-adamk: $Out"
