param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-FILL-TABLES.md"
)

$ErrorActionPreference = "Stop"
function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function SymbolPattern { param([string]$Symbol) return "(?<![A-Za-z0-9_])$([regex]::Escape($Symbol))(?![A-Za-z0-9_])" }
function HasSymbol { param([string]$Text, [string]$Symbol) return $Text -match (SymbolPattern $Symbol) }

$path = Join-Path $LoseThos "COMPILE/COMPILE.CPZ"
if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Write-Error "missing source: $path"; exit 1 }
$lines = @(Get-Content -LiteralPath $path)

$start = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*void\s+FillCompilerTables\s*\(') { $start = $i; break }
}
if ($start -lt 0) { Write-Error "FillCompilerTables not found"; exit 1 }

$end = [math]::Min($lines.Count - 1, $start + 420)
$window = for ($i = $start; $i -le $end; $i++) { [pscustomobject]@{ line = $i + 1; text = $lines[$i] } }
$symbols = @("code_table", "unsigned_code_table", "double_code_table", "internal_types_table", "signed_fix_up_table", "unsigned_fix_up_table", "double_fix_up_table", "sys_internal_types", "it_to_ec_offset", "FUT_NULL", "FUT_32_4_CALL", "FUT_32_JMP_4", "FUT_ENTER1", "FUT_ENTER2")

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null
$html = @()
$html += "<h1>LOSETHOS FILL TABLES</h1>"
$html += "<section><h2>Window</h2><table>"
$html += "    <tr><th>metric</th><th>value</th></tr>"
$html += "    <tr><td>source</td><td>COMPILE/COMPILE.CPZ</td></tr>"
$html += "    <tr><td>start line</td><td>$($start + 1)</td></tr>"
$html += "    <tr><td>window lines</td><td>$($window.Count)</td></tr>"
$html += "  </table></section>"
$html += "<section><h2>Focused Symbol References</h2><table>"
$html += "    <tr><th>symbol</th><th>refs</th></tr>"
$text = ($window | ForEach-Object { $_.text }) -join "`n"
foreach ($symbol in $symbols) {
    $count = ([regex]::Matches($text, (SymbolPattern $symbol))).Count
    $html += "    <tr><td>$(E $symbol)</td><td>$count</td></tr>"
}
$html += "  </table></section>"
$html += "<section><h2>Hit Lines</h2><table>"
$html += "    <tr><th>line</th><th>symbols</th><th>text</th></tr>"
foreach ($row in $window) {
    $hits = @($symbols | Where-Object { HasSymbol $row.text $_ })
    if ($hits.Count -gt 0) { $html += "    <tr><td>$($row.line)</td><td>$(E ($hits -join ', '))</td><td><pre>$(E $row.text.Trim())</pre></td></tr>" }
}
$html += "  </table></section>"
$html += "<section><h2>Read Line</h2><pre>This report inspects the FillCompilerTables source window with exact lexical symbol reference counts only."
$html += "Symbol matching uses identifier boundaries, so code_table is not counted inside unsigned_code_table.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No source-tree mutation.</pre></section>"
$html | Set-Content -Encoding utf8 $OutPath
Write-Host "inspect-losethos-fill-tables: $OutPath"
