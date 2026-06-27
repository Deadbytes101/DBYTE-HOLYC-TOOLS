param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-FIXUP-TABLES.md"
)

$ErrorActionPreference = "Stop"
function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }

$path = Join-Path $LoseThos "COMPILE/COMPILE.CPZ"
if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Write-Error "missing source: $path"; exit 1 }
$lines = @(Get-Content -LiteralPath $path)

$start = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*void\s+FillCompilerTables\s*\(') { $start = $i; break }
}
if ($start -lt 0) { Write-Error "FillCompilerTables not found"; exit 1 }

$end = [math]::Min($lines.Count - 1, $start + 420)
$current = "unknown"
$rows = @()
for ($i = $start; $i -le $end; $i++) {
    $text = $lines[$i]
    if ($text -match '\bunsigned_fix_up_table\s*=\s*d\s*;') { $current = "unsigned_fix_up_table"; continue }
    if ($text -match '\bsigned_fix_up_table\s*=\s*d\s*;') { $current = "signed_fix_up_table"; continue }
    if ($text -match '\bdouble_fix_up_table\s*=\s*d\s*;') { $current = "double_fix_up_table"; continue }
    if ($text -match '\bd\[(EC_[A-Za-z0-9_]+)\]\s*=\s*(FUT_[A-Za-z0-9_]+)\s*;') {
        $rows += [pscustomobject]@{ table = $current; ec = $Matches[1]; fut = $Matches[2]; line = $i + 1; text = $text.Trim() }
    }
}

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null
$html = @()
$html += "<h1>LOSETHOS FIXUP TABLES</h1>"
$html += "<section><h2>Fixup Table Shape</h2><table>"
$html += "    <tr><th>table</th><th>entries</th><th>unique FUT formats</th></tr>"
foreach ($group in @($rows | Group-Object table | Sort-Object Name)) {
    $unique = @($group.Group | Select-Object -ExpandProperty fut -Unique).Count
    $html += "    <tr><td>$(E $group.Name)</td><td>$($group.Count)</td><td>$unique</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>FUT Format Pressure</h2><table>"
$html += "    <tr><th>table</th><th>FUT format</th><th>entries</th></tr>"
foreach ($table in @($rows | Select-Object -ExpandProperty table -Unique | Sort-Object)) {
    foreach ($group in @($rows | Where-Object { $_.table -eq $table } | Group-Object fut | Sort-Object Count -Descending)) {
        $html += "    <tr><td>$(E $table)</td><td>$(E $group.Name)</td><td>$($group.Count)</td></tr>"
    }
}
$html += "  </table></section>"

$html += "<section><h2>Entries</h2><table>"
$html += "    <tr><th>table</th><th>EC code</th><th>FUT format</th><th>line</th></tr>"
foreach ($row in $rows) {
    $html += "    <tr><td>$(E $row.table)</td><td>$(E $row.ec)</td><td>$(E $row.fut)</td><td>$($row.line)</td></tr>"
}
$html += "  </table></section>"
$html += "<section><h2>Read Line</h2><pre>This report parses FillCompilerTables fix-up assignments as EC_* to FUT_* lexical mappings."
$html += "It separates unsigned, signed, and double fix-up table regions by assignment to *_fix_up_table=d.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"
$html | Set-Content -Encoding utf8 $OutPath
Write-Host "inspect-losethos-fixup-tables: $OutPath"
