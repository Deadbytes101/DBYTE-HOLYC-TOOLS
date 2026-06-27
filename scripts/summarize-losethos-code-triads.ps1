param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-CODE-TRIAD-SUMMARY.md"
)

$ErrorActionPreference = "Stop"
function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function IsLabel { param([string]$Text) return $Text -match '^\s*[A-Za-z_.$][A-Za-z0-9_.$]*\s*:{1,2}' }
function Mnemonic { param([string]$Text) $t = $Text.Trim(); if ($t -match '^([A-Z][A-Z0-9]*)\b') { return $Matches[1] }; return "" }

$path = Join-Path $LoseThos "COMPILE/CODE.ASZ"
if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Write-Error "missing CODE table: $path"; exit 1 }

$lines = @(Get-Content -LiteralPath $path)
$rows = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -notmatch '^\s*(ICT|UCT|DCT)_([A-Za-z0-9_]+)\s*:{1,2}') { continue }
    $family = $Matches[1]
    $suffix = $Matches[2]
    $body = @()
    for ($j = $i + 1; $j -lt $lines.Count; $j++) {
        if (IsLabel $lines[$j]) { break }
        if (-not [string]::IsNullOrWhiteSpace($lines[$j])) { $body += $lines[$j].Trim() }
    }
    $rows += [pscustomobject]@{ family = $family; suffix = $suffix; bodyLines = $body.Count; mnemonics = @($body | ForEach-Object { Mnemonic $_ } | Where-Object { $_ }) }
}

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null
$html = @()
$html += "<h1>LOSETHOS CODE TRIAD SUMMARY</h1>"
$html += "<section><h2>Family Body Shape</h2><table>"
$html += "    <tr><th>family</th><th>labels</th><th>label-only</th><th>body labels</th><th>body lines</th><th>avg body lines</th></tr>"
foreach ($family in @("ICT", "UCT", "DCT")) {
    $items = @($rows | Where-Object { $_.family -eq $family })
    $bodyLines = ($items | Measure-Object -Property bodyLines -Sum).Sum
    if ($null -eq $bodyLines) { $bodyLines = 0 }
    $labelOnly = @($items | Where-Object { $_.bodyLines -eq 0 }).Count
    $bodyLabels = @($items | Where-Object { $_.bodyLines -gt 0 }).Count
    $avg = if ($items.Count -gt 0) { [math]::Round($bodyLines / $items.Count, 2) } else { 0 }
    $html += "    <tr><td>$(E $family)</td><td>$($items.Count)</td><td>$labelOnly</td><td>$bodyLabels</td><td>$bodyLines</td><td>$avg</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Top Mnemonics</h2><table>"
$html += "    <tr><th>family</th><th>mnemonic</th><th>count</th></tr>"
foreach ($family in @("ICT", "UCT", "DCT")) {
    $mnems = @($rows | Where-Object { $_.family -eq $family } | ForEach-Object { $_.mnemonics } | Where-Object { $_ })
    foreach ($group in @($mnems | Group-Object | Sort-Object Count -Descending | Select-Object -First 12)) {
        $html += "    <tr><td>$(E $family)</td><td>$(E $group.Name)</td><td>$($group.Count)</td></tr>"
    }
}
$html += "  </table></section>"

$html += "<section><h2>Largest Bodies</h2><table>"
$html += "    <tr><th>family</th><th>suffix</th><th>body lines</th></tr>"
foreach ($row in @($rows | Sort-Object bodyLines -Descending | Select-Object -First 32)) {
    $html += "    <tr><td>$(E $row.family)</td><td>$(E $row.suffix)</td><td>$($row.bodyLines)</td></tr>"
}
$html += "  </table></section>"
$html += "<section><h2>Read Line</h2><pre>This report summarizes all ICT/UCT/DCT bodies in CODE.ASZ. It is lexical and read-only.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No source-tree mutation.</pre></section>"
$html | Set-Content -Encoding utf8 $OutPath
Write-Host "summarize-losethos-code-triads: $OutPath"
