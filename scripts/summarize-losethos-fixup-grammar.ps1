param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-FIXUP-GRAMMAR.md"
)

$ErrorActionPreference = "Stop"
function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function CategoryOf {
    param([string]$Ec)
    if ($Ec -match 'SKIP|JMP') { return "branch/skip" }
    if ($Ec -match 'CALL') { return "call" }
    if ($Ec -match 'ENTER|LEAVE') { return "frame" }
    if ($Ec -match 'DISP32|DISP8|ABSOLUTE|LABEL|STRING|SWITCH') { return "address/immediate" }
    if ($Ec -match 'PUSH') { return "push/literal" }
    if ($Ec -match 'BT|BTS|BTR|BTC|SHL|SHR') { return "bit/shift" }
    if ($Ec -match 'ADD|SUB') { return "add/sub" }
    if ($Ec -match 'U8|U4|U2|U1|DOUBLE|TYPE') { return "type/literal" }
    return "other"
}

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
$map = @{ unsigned = @{}; signed = @{}; double = @{} }
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
$rows = @()
foreach ($ec in @($allEc | Sort-Object)) {
    $u = if ($map.unsigned.ContainsKey($ec)) { $map.unsigned[$ec] } else { "" }
    $s = if ($map.signed.ContainsKey($ec)) { $map.signed[$ec] } else { "" }
    $d = if ($map.double.ContainsKey($ec)) { $map.double[$ec] } else { "" }
    $present = @($u, $s, $d | Where-Object { $_ }).Count
    $unique = @($u, $s, $d | Where-Object { $_ } | Select-Object -Unique).Count
    $rows += [pscustomobject]@{ ec = $ec; category = CategoryOf $ec; unsigned = $u; signed = $s; double = $d; present = $present; uniqueFormats = $unique }
}

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null
$html = @()
$html += "<h1>LOSETHOS FIXUP GRAMMAR</h1>"
$html += "<section><h2>Category Pressure</h2><table>"
$html += "    <tr><th>category</th><th>EC codes</th><th>all three</th><th>format disagreements</th><th>unsigned only</th></tr>"
foreach ($group in @($rows | Group-Object category | Sort-Object Count -Descending)) {
    $items = @($group.Group)
    $allThree = @($items | Where-Object { $_.present -eq 3 }).Count
    $diff = @($items | Where-Object { $_.uniqueFormats -gt 1 }).Count
    $uOnly = @($items | Where-Object { $_.unsigned -and -not $_.signed -and -not $_.double }).Count
    $html += "    <tr><td>$(E $group.Name)</td><td>$($group.Count)</td><td>$allThree</td><td>$diff</td><td>$uOnly</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Shared All-Three Grammar</h2><table>"
$html += "    <tr><th>category</th><th>EC code</th><th>format</th></tr>"
foreach ($row in @($rows | Where-Object { $_.present -eq 3 } | Sort-Object category, ec)) {
    $fmt = if ($row.unsigned) { $row.unsigned } elseif ($row.signed) { $row.signed } else { $row.double }
    $html += "    <tr><td>$(E $row.category)</td><td>$(E $row.ec)</td><td>$(E $fmt)</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Type-Family Format Disagreements</h2><table>"
$html += "    <tr><th>category</th><th>EC code</th><th>unsigned</th><th>signed</th><th>double</th></tr>"
foreach ($row in @($rows | Where-Object { $_.uniqueFormats -gt 1 } | Sort-Object category, ec | Select-Object -First 96)) {
    $html += "    <tr><td>$(E $row.category)</td><td>$(E $row.ec)</td><td>$(E $row.unsigned)</td><td>$(E $row.signed)</td><td>$(E $row.double)</td></tr>"
}
$html += "  </table></section>"
$html += "<section><h2>Read Line</h2><pre>This report classifies fix-up EC_* to FUT_* mappings into lexical grammar categories. It is report evidence, not runtime proof.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"
$html | Set-Content -Encoding utf8 $OutPath
Write-Host "summarize-losethos-fixup-grammar: $OutPath"
