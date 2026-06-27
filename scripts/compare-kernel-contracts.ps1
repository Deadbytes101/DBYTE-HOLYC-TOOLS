param(
    [string]$Root = "reports/archaeology",
    [string]$Out = "reports/archaeology/TEMPLEOS-LOSETHOS-KERNEL-COMPARE.md"
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

function IncomingForAnchor {
    param([array]$Rows, [string]$AnchorSuffix)
    $suffix = (SlashPath $AnchorSuffix).ToLowerInvariant()
    return @($Rows |
        Where-Object { (SlashPath ([string]$_.resolved)).ToLowerInvariant().EndsWith($suffix) } |
        Sort-Object file,line,column,target)
}

function AddIncomingTable {
    param(
        [array]$Html,
        [string]$Title,
        [array]$Rows,
        [string[]]$Anchors,
        [string]$RootMarker
    )

    $Html += "<section>"
    $Html += "  <h2>$(EscapeHtml $Title)</h2>"
    $Html += "  <table>"
    $Html += "    <tr><th>anchor</th><th>incoming</th><th>from</th></tr>"

    foreach ($anchor in $Anchors) {
        $incoming = IncomingForAnchor $Rows $anchor
        if ($incoming.Count -eq 0) {
            $Html += "    <tr><td>$(EscapeHtml $anchor)</td><td>0</td><td>-</td></tr>"
            continue
        }

        $first = $true
        foreach ($edge in $incoming) {
            $from = ShortPath ([string]$edge.file) $RootMarker
            if ($first) {
                $Html += "    <tr><td>$(EscapeHtml $anchor)</td><td>$($incoming.Count)</td><td>$(EscapeHtml $from)</td></tr>"
                $first = $false
            } else {
                $Html += "    <tr><td></td><td></td><td>$(EscapeHtml $from)</td></tr>"
            }
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
$html += "<h1>TEMPLEOS LOSETHOS KERNEL CONTRACT COMPARE</h1>"
$html += "<section>"
$html += "  <h2>Input</h2>"
$html += "  <pre>templeos-include-edges: $($templeRows.Count)"
$html += "losethos-include-edges: $($loseRows.Count)"
$html += "source: generated include-resolve.json reports only</pre>"
$html += "</section>"

$html = AddIncomingTable $html "TempleOS Kernel Header Pressure" $templeRows @(
    "Kernel/KernelA.HH",
    "Kernel/KernelB.HH",
    "Kernel/KernelC.HH"
) "TempleOS/"

$html = AddIncomingTable $html "LoseThos ADAMK Header Pressure" $loseRows @(
    "OSMain/ADAMK.HPZ",
    "OSMain/ADAMK2.HPZ",
    "OSMain/ADAMK3.HPZ",
    "OSMain/OSINC.ASZ"
) "LT/"

$html += "<section>"
$html += "  <h2>Read Line</h2>"
$html += "  <pre>TempleOS exposes kernel contract pressure through KernelA, KernelB, and KernelC."
$html += "LoseThos exposes early contract pressure through ADAMK, ADAMK2, ADAMK3, and OSINC."
$html += "Incoming include count marks structural pressure only. It is not semantic proof."
$html += "Use this report to pick the next file to inspect, not to claim runtime behavior.</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Boundary</h2>"
$html += "  <pre>No compile. No execute. No rewrite. No source-tree mutation."
$html += "Only generated include-resolve rows are read.</pre>"
$html += "</section>"

$html | Set-Content -Encoding utf8 $Out
Write-Host "compare-kernel-contracts: $Out"
