param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-COMPILER-EXPORT-CONTEXT.md",
    [int]$Radius = 3
)

$ErrorActionPreference = "Stop"
function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }

$cmpMap = Join-Path $LoseThos "COMPILE/CMP.MPZ"
$sources = @("COMPILE/LEX.CPZ", "COMPILE/COMPILE.CPZ")
$focus = @("double_code_table", "double_fix_up_table", "internal_types_table", "sys_internal_types", "lex_zeros", "FillCompilerTables", "InitCompiler", "CompileBuf", "CompileFile", "CompileStatement", "FUT_NULL", "FUT_32_4_CALL", "FUT_32_JMP_4", "FUT_ENTER1", "FUT_ENTER2")
if (-not (Test-Path -LiteralPath $cmpMap -PathType Leaf)) { Write-Error "missing CMP map: $cmpMap"; exit 1 }

$exports = @()
foreach ($line in @(Get-Content -LiteralPath $cmpMap)) {
    if ($line -notmatch 'FL:::/LT/([^",$]+),([0-9]+)') { continue }
    $source = ($Matches[1]).Replace('\','/')
    $lineNo = [int]$Matches[2]
    if ($sources -notcontains $source) { continue }
    $symbol = ""
    if ($line -match '^\$LK(?:\s+\+BI)?\s*,?"([^"]+)"') { $symbol = $Matches[1].Trim() }
    elseif ($line -match '^\$LK\s+"([^"]+)"') { $symbol = $Matches[1].Trim() }
    if ($focus -notcontains $symbol) { continue }
    $kind = "unknown"
    if ($line -match 'Funct Export') { $kind = "Funct Export" }
    elseif ($line -match 'StrConst') { $kind = "StrConst" }
    elseif ($line -match 'Export') { $kind = "Export" }
    $exports += [pscustomobject]@{ source = $source; symbol = $symbol; line = $lineNo; kind = $kind }
}

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null
$html = @()
$html += "<h1>LOSETHOS COMPILER EXPORT CONTEXT</h1>"
$html += "<section><h2>Focused Export Context</h2>"
foreach ($export in $exports) {
    $path = Join-Path $LoseThos $export.source
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $lines = @(Get-Content -LiteralPath $path)
    $start = [math]::Max(1, $export.line - $Radius)
    $end = [math]::Min($lines.Count, $export.line + $Radius)
    $html += "<h3>$(E $export.symbol) — $(E $export.source):$($export.line) — $(E $export.kind)</h3><table>"
    $html += "    <tr><th>line</th><th>text</th></tr>"
    for ($i = $start; $i -le $end; $i++) {
        $html += "    <tr><td>$i</td><td><pre>$(E $lines[$i - 1].Trim())</pre></td></tr>"
    }
    $html += "  </table>"
}
if ($exports.Count -eq 0) { $html += "<pre>no focused exports found</pre>" }
$html += "</section>"
$html += "<section><h2>Read Line</h2><pre>This report shows small source context windows around focused exports from CMP.MPZ."
$html += "It is for manual archaeology and remains read-only.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"
$html | Set-Content -Encoding utf8 $OutPath
Write-Host "inspect-losethos-export-context: $OutPath"
