param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-CODE-FAMILIES.md"
)

$ErrorActionPreference = "Stop"

function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }

$path = Join-Path $LoseThos "COMPILE/CODE.ASZ"
if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Write-Error "missing CODE table: $path"
    exit 1
}

$families = @("ICT", "UCT", "DCT")
$byFamily = @{}
foreach ($family in $families) { $byFamily[$family] = @{} }
$cpLabels = @()
$lines = @(Get-Content -LiteralPath $path)

for ($i = 0; $i -lt $lines.Count; $i++) {
    $text = $lines[$i]
    if ($text -notmatch '^\s*([A-Za-z_.$][A-Za-z0-9_.$]*)\s*:{1,2}') { continue }
    $name = $Matches[1]
    foreach ($family in $families) {
        if ($name.StartsWith($family + "_")) {
            $suffix = $name.Substring($family.Length + 1)
            $byFamily[$family][$suffix] = [pscustomobject]@{ line = $i + 1; text = $text.Trim() }
        }
    }
    if ($name.StartsWith("CP_")) { $cpLabels += [pscustomobject]@{ line = $i + 1; name = $name; text = $text.Trim() } }
}

$allSuffixes = New-Object System.Collections.Generic.HashSet[string]
foreach ($family in $families) { foreach ($key in $byFamily[$family].Keys) { [void]$allSuffixes.Add([string]$key) } }
$orderedSuffixes = @($allSuffixes | Sort-Object)
$complete = @($orderedSuffixes | Where-Object { $byFamily["ICT"].ContainsKey($_) -and $byFamily["UCT"].ContainsKey($_) -and $byFamily["DCT"].ContainsKey($_) })

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null

$html = @()
$html += "<h1>LOSETHOS CODE FAMILIES</h1>"
$html += "<section><h2>Family Shape</h2><table>"
$html += "    <tr><th>family</th><th>labels</th><th>first line</th><th>last line</th></tr>"
foreach ($family in $families) {
    $items = @($byFamily[$family].Values | Sort-Object line)
    $firstLine = if ($items.Count -gt 0) { $items[0].line } else { "-" }
    $lastLine = if ($items.Count -gt 0) { $items[$items.Count - 1].line } else { "-" }
    $html += "    <tr><td>$(E $family)</td><td>$($items.Count)</td><td>$firstLine</td><td>$lastLine</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Triad Coverage</h2><table>"
$html += "    <tr><th>metric</th><th>value</th></tr>"
$html += "    <tr><td>unique suffixes</td><td>$($orderedSuffixes.Count)</td></tr>"
$html += "    <tr><td>complete ICT/UCT/DCT suffixes</td><td>$($complete.Count)</td></tr>"
foreach ($family in $families) {
    $missing = @($orderedSuffixes | Where-Object { -not $byFamily[$family].ContainsKey($_) }).Count
    $html += "    <tr><td>missing $family</td><td>$missing</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Suffix Samples</h2><table>"
$html += "    <tr><th>suffix</th><th>ICT line</th><th>UCT line</th><th>DCT line</th></tr>"
foreach ($suffix in @($orderedSuffixes | Select-Object -First 48)) {
    $ict = if ($byFamily["ICT"].ContainsKey($suffix)) { $byFamily["ICT"][$suffix].line } else { "-" }
    $uct = if ($byFamily["UCT"].ContainsKey($suffix)) { $byFamily["UCT"][$suffix].line } else { "-" }
    $dct = if ($byFamily["DCT"].ContainsKey($suffix)) { $byFamily["DCT"][$suffix].line } else { "-" }
    $html += "    <tr><td>$(E $suffix)</td><td>$ict</td><td>$uct</td><td>$dct</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>CP Labels</h2><table>"
$html += "    <tr><th>line</th><th>label</th><th>text</th></tr>"
foreach ($label in $cpLabels) {
    $html += "    <tr><td>$($label.line)</td><td>$(E $label.name)</td><td><pre>$(E $label.text)</pre></td></tr>"
}
if ($cpLabels.Count -eq 0) { $html += "    <tr><td>-</td><td>-</td><td><pre>none</pre></td></tr>" }
$html += "  </table></section>"

$html += "<section><h2>Read Line</h2><pre>CODE.ASZ is dominated by three parallel label families: ICT, UCT, and DCT."
$html += "This pass measures whether those families share the same suffix space."
$html += "CP labels are present but not the dominant code-table surface.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"

$html | Set-Content -Encoding utf8 $OutPath
Write-Host "inspect-losethos-code-families: $OutPath"
