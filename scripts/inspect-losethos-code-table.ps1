param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-CODE-TABLE.md"
)

$ErrorActionPreference = "Stop"

function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function PrefixOf { param([string]$Name) if ($Name -match '^([A-Za-z0-9]+)_') { return $Matches[1] } return $Name }

$path = Join-Path $LoseThos "COMPILE/CODE.ASZ"
if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Write-Error "missing CODE table: $path"
    exit 1
}

$lines = @(Get-Content -LiteralPath $path)
$labels = @()
$duRows = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    $text = $lines[$i]
    if ($text -match '^\s*([A-Za-z_.$][A-Za-z0-9_.$]*)\s*:{1,2}') {
        $labels += [pscustomobject]@{ line = $i + 1; name = $Matches[1]; text = $text.Trim() }
    }
    if ($text -match '^\s*(DU[0-9]+)\s+(.*)') {
        $duRows += [pscustomobject]@{ line = $i + 1; op = $Matches[1]; value = $Matches[2].Trim() }
    }
}

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null

$html = @()
$html += "<h1>LOSETHOS CODE TABLE</h1>"
$html += "<section><h2>CODE.ASZ Shape</h2><table>"
$html += "    <tr><th>metric</th><th>value</th></tr>"
$html += "    <tr><td>lines</td><td>$($lines.Count)</td></tr>"
$html += "    <tr><td>nonblank</td><td>$(@($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count)</td></tr>"
$html += "    <tr><td>labels</td><td>$($labels.Count)</td></tr>"
$html += "    <tr><td>DU rows</td><td>$($duRows.Count)</td></tr>"
$html += "    <tr><td>DU string rows</td><td>$(@($duRows | Where-Object { $_.value -match '"' }).Count)</td></tr>"
$html += "  </table></section>"

$html += "<section><h2>Label Prefix Pressure</h2><table>"
$html += "    <tr><th>prefix</th><th>labels</th></tr>"
foreach ($group in @($labels | ForEach-Object { [pscustomobject]@{ prefix = PrefixOf $_.name } } | Group-Object prefix | Sort-Object Count -Descending | Select-Object -First 24)) {
    $html += "    <tr><td>$(E $group.Name)</td><td>$($group.Count)</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>First Labels</h2><table>"
$html += "    <tr><th>line</th><th>label</th><th>text</th></tr>"
foreach ($label in @($labels | Select-Object -First 32)) {
    $html += "    <tr><td>$($label.line)</td><td>$(E $label.name)</td><td><pre>$(E $label.text)</pre></td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>DU String Samples</h2><table>"
$html += "    <tr><th>line</th><th>op</th><th>value</th></tr>"
foreach ($row in @($duRows | Where-Object { $_.value -match '"' } | Select-Object -First 32)) {
    $html += "    <tr><td>$($row.line)</td><td>$(E $row.op)</td><td><pre>$(E $row.value)</pre></td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Read Line</h2><pre>CODE.ASZ is inspected as a table and label surface."
$html += "Large label pressure plus DU rows indicate compiler data tables, not ordinary function source."
$html += "Prefix pressure is a lexical map for choosing the next code-table archaeology pass.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"

$html | Set-Content -Encoding utf8 $OutPath
Write-Host "inspect-losethos-code-table: $OutPath"
