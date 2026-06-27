param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-FIXUP-COMPARE.md"
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
$map = @{
    unsigned = @{}
    signed = @{}
    double = @{}
}
for ($i = $start; $i -le $end; $i++) {
    $text = $lines[$i]
    if ($text -match '\bunsigned_fix_up_table\s*=\s*d\s*;') { $current = "unsigned"; continue }
    if ($text -match '\bsigned_fix_up_table\s*=\s*d\s*;') { $current = "signed"; continue }
    if ($text -match '\bdouble_fix_up_table\s*=\s*d\s*;') { $current = "double"; continue }
    if ($text -match '\bd\[(EC_[A-Za-z0-9_]+)\]\s*=\s*(FUT_[A-Za-z0-9_]+)\s*;') {
        if ($map.ContainsKey($current)) { $map[$current][$Matches[1]] = $Matches[2] }
    }
}

$allEc = New-Object System.Collections.Generic.HashSet[string]
foreach ($table in @("unsigned", "signed", "double")) { foreach ($key in $map[$table].Keys) { [void]$allEc.Add([string]$key) } }
$ecs = @($allEc | Sort-Object)

$rows = @()
foreach ($ec in $ecs) {
    $u = if ($map.unsigned.ContainsKey($ec)) { $map.unsigned[$ec] } else { "" }
    $s = if ($map.signed.ContainsKey($ec)) { $map.signed[$ec] } else { "" }
    $d = if ($map.double.ContainsKey($ec)) { $map.double[$ec] } else { "" }
    $present = @($u, $s, $d | Where-Object { $_ }).Count
    $formats = @($u, $s, $d | Where-Object { $_ } | Select-Object -Unique)
    $rows += [pscustomobject]@{ ec = $ec; unsigned = $u; signed = $s; double = $d; present = $present; uniqueFormats = $formats.Count }
}

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null
$html = @()
$html += "<h1>LOSETHOS FIXUP COMPARE</h1>"
$html += "<section><h2>Comparison Shape</h2><table>"
$html += "    <tr><th>metric</th><th>value</th></tr>"
$html += "    <tr><td>unique EC codes</td><td>$($rows.Count)</td></tr>"
$html += "    <tr><td>present in all three</td><td>$(@($rows | Where-Object { $_.present -eq 3 }).Count)</td></tr>"
$html += "    <tr><td>present in unsigned+signed only</td><td>$(@($rows | Where-Object { $_.unsigned -and $_.signed -and -not $_.double }).Count)</td></tr>"
$html += "    <tr><td>present in unsigned only</td><td>$(@($rows | Where-Object { $_.unsigned -and -not $_.signed -and -not $_.double }).Count)</td></tr>"
$html += "    <tr><td>format disagreements</td><td>$(@($rows | Where-Object { $_.uniqueFormats -gt 1 }).Count)</td></tr>"
$html += "  </table></section>"

$html += "<section><h2>Shared All Three</h2><table>"
$html += "    <tr><th>EC code</th><th>unsigned</th><th>signed</th><th>double</th></tr>"
foreach ($row in @($rows | Where-Object { $_.present -eq 3 } | Select-Object -First 64)) {
    $html += "    <tr><td>$(E $row.ec)</td><td>$(E $row.unsigned)</td><td>$(E $row.signed)</td><td>$(E $row.double)</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Format Disagreements</h2><table>"
$html += "    <tr><th>EC code</th><th>unsigned</th><th>signed</th><th>double</th></tr>"
foreach ($row in @($rows | Where-Object { $_.uniqueFormats -gt 1 } | Select-Object -First 96)) {
    $html += "    <tr><td>$(E $row.ec)</td><td>$(E $row.unsigned)</td><td>$(E $row.signed)</td><td>$(E $row.double)</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Unsigned Only</h2><table>"
$html += "    <tr><th>EC code</th><th>FUT format</th></tr>"
foreach ($row in @($rows | Where-Object { $_.unsigned -and -not $_.signed -and -not $_.double } | Select-Object -First 96)) {
    $html += "    <tr><td>$(E $row.ec)</td><td>$(E $row.unsigned)</td></tr>"
}
$html += "  </table></section>"
$html += "<section><h2>Read Line</h2><pre>This report compares unsigned, signed, and double fix-up table EC_* to FUT_* mappings. It is lexical evidence only.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"
$html | Set-Content -Encoding utf8 $OutPath
Write-Host "compare-losethos-fixup-tables: $OutPath"
