param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-CMP-MAP.md"
)

$ErrorActionPreference = "Stop"

function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }

$path = Join-Path $LoseThos "COMPILE/CMP.MPZ"
if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Write-Error "missing CMP map: $path"
    exit 1
}

$lines = @(Get-Content -LiteralPath $path)
$entries = @()
foreach ($line in $lines) {
    $symbol = ""
    $source = ""
    $sourceLine = ""
    $kind = "unknown"
    if ($line -match '^\$LK(?:\s+\+BI)?\s*,?"([^"]+)"') { $symbol = $Matches[1].Trim() }
    elseif ($line -match '^\$LK\s+"([^"]+)"') { $symbol = $Matches[1].Trim() }
    if ($line -match 'FL:::/LT/([^",$]+),([0-9]+)') { $source = ($Matches[1]).Replace('\','/'); $sourceLine = $Matches[2] }
    if ($line -match 'Funct Export') { $kind = "Funct Export" }
    elseif ($line -match 'StrConst') { $kind = "StrConst" }
    elseif ($line -match 'Class Export') { $kind = "Class Export" }
    elseif ($line -match 'Export') { $kind = "Export" }
    $entries += [pscustomobject]@{ symbol = $symbol; source = $source; sourceLine = $sourceLine; kind = $kind; raw = $line }
}

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null

$html = @()
$html += "<h1>LOSETHOS CMP MAP</h1>"
$html += "<section><h2>Map Shape</h2><table>"
$html += "    <tr><th>metric</th><th>value</th></tr>"
$html += "    <tr><td>lines</td><td>$($lines.Count)</td></tr>"
$html += "    <tr><td>parsed entries</td><td>$($entries.Count)</td></tr>"
$html += "    <tr><td>function exports</td><td>$(@($entries | Where-Object { $_.kind -eq 'Funct Export' }).Count)</td></tr>"
$html += "    <tr><td>string constants</td><td>$(@($entries | Where-Object { $_.kind -eq 'StrConst' }).Count)</td></tr>"
$html += "    <tr><td>entries with source refs</td><td>$(@($entries | Where-Object { $_.source }).Count)</td></tr>"
$html += "  </table></section>"

$html += "<section><h2>Source Reference Pressure</h2><table>"
$html += "    <tr><th>source</th><th>entries</th><th>function exports</th><th>string constants</th></tr>"
foreach ($group in @($entries | Where-Object { $_.source } | Group-Object source | Sort-Object Count -Descending | Select-Object -First 16)) {
    $items = @($group.Group)
    $functs = @($items | Where-Object { $_.kind -eq 'Funct Export' }).Count
    $strings = @($items | Where-Object { $_.kind -eq 'StrConst' }).Count
    $html += "    <tr><td>$(E $group.Name)</td><td>$($group.Count)</td><td>$functs</td><td>$strings</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Sample Entries</h2><table>"
$html += "    <tr><th>symbol</th><th>kind</th><th>source</th><th>line</th></tr>"
foreach ($entry in @($entries | Where-Object { $_.source } | Select-Object -First 24)) {
    $html += "    <tr><td>$(E $entry.symbol)</td><td>$(E $entry.kind)</td><td>$(E $entry.source)</td><td>$(E ([string]$entry.sourceLine))</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Read Line</h2><pre>CMP.MPZ is parsed as a compiler/link map surface, not a normal source body."
$html += "Its rows map exported symbols and constants back to LT source locations."
$html += "Use source reference pressure to decide which compiler files deserve deeper outline review.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"

$html | Set-Content -Encoding utf8 $OutPath
Write-Host "inspect-losethos-cmp-map: $OutPath"
