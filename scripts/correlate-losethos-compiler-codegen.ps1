param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-COMPILER-CODEGEN-CORRELATE.md"
)

$ErrorActionPreference = "Stop"
function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function PrefixOf { param([string]$Name) if ($Name -match '^([A-Za-z]+)') { return $Matches[1] } return $Name }

$cmpMap = Join-Path $LoseThos "COMPILE/CMP.MPZ"
$codePath = Join-Path $LoseThos "COMPILE/CODE.ASZ"
$sources = @("COMPILE/LEX.CPZ", "COMPILE/COMPILE.CPZ")
if (-not (Test-Path -LiteralPath $cmpMap -PathType Leaf)) { Write-Error "missing CMP map: $cmpMap"; exit 1 }
if (-not (Test-Path -LiteralPath $codePath -PathType Leaf)) { Write-Error "missing CODE table: $codePath"; exit 1 }

$codeLines = @(Get-Content -LiteralPath $codePath)
$suffixSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($line in $codeLines) {
    if ($line -match '^\s*(ICT|UCT|DCT)_([A-Za-z0-9_]+)\s*:{1,2}') { [void]$suffixSet.Add($Matches[2]) }
}
$suffixes = @($suffixSet | Sort-Object)

$exports = @()
foreach ($line in @(Get-Content -LiteralPath $cmpMap)) {
    if ($line -notmatch 'FL:::/LT/([^",$]+),([0-9]+)') { continue }
    $source = ($Matches[1]).Replace('\','/')
    if ($sources -notcontains $source) { continue }
    $symbol = ""
    if ($line -match '^\$LK(?:\s+\+BI)?\s*,?"([^"]+)"') { $symbol = $Matches[1].Trim() }
    elseif ($line -match '^\$LK\s+"([^"]+)"') { $symbol = $Matches[1].Trim() }
    $kind = "unknown"
    if ($line -match 'Funct Export') { $kind = "Funct Export" }
    elseif ($line -match 'StrConst') { $kind = "StrConst" }
    elseif ($line -match 'Export') { $kind = "Export" }
    $exports += [pscustomobject]@{ source = $source; symbol = $symbol; line = [int]$Matches[2]; kind = $kind }
}

$directRefs = @()
foreach ($source in $sources) {
    $path = Join-Path $LoseThos $source
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $text = Get-Content -LiteralPath $path -Raw
    foreach ($family in @("ICT", "UCT", "DCT")) {
        foreach ($suffix in $suffixes) {
            $label = "$family`_$suffix"
            $count = ([regex]::Matches($text, [regex]::Escape($label))).Count
            if ($count -gt 0) { $directRefs += [pscustomobject]@{ source = $source; family = $family; suffix = $suffix; count = $count } }
        }
    }
}

$symbolHints = @()
foreach ($export in $exports) {
    $hits = @($suffixes | Where-Object { $export.symbol -and ($export.symbol.ToUpperInvariant().Contains($_) -or $_.Contains($export.symbol.ToUpperInvariant())) } | Select-Object -First 8)
    if ($hits.Count -gt 0) { $symbolHints += [pscustomobject]@{ source = $export.source; symbol = $export.symbol; kind = $export.kind; suffixHints = ($hits -join ", ") } }
}

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null
$html = @()
$html += "<h1>LOSETHOS COMPILER CODEGEN CORRELATE</h1>"
$html += "<section><h2>Export Pressure</h2><table>"
$html += "    <tr><th>source</th><th>exports</th><th>function exports</th><th>string constants</th></tr>"
foreach ($group in @($exports | Group-Object source | Sort-Object Count -Descending)) {
    $items = @($group.Group)
    $functs = @($items | Where-Object { $_.kind -eq "Funct Export" }).Count
    $strings = @($items | Where-Object { $_.kind -eq "StrConst" }).Count
    $html += "    <tr><td>$(E $group.Name)</td><td>$($group.Count)</td><td>$functs</td><td>$strings</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Export Prefix Pressure</h2><table>"
$html += "    <tr><th>source</th><th>prefix</th><th>exports</th></tr>"
foreach ($source in $sources) {
    foreach ($group in @($exports | Where-Object { $_.source -eq $source } | ForEach-Object { [pscustomobject]@{ prefix = PrefixOf $_.symbol } } | Group-Object prefix | Sort-Object Count -Descending | Select-Object -First 16)) {
        $html += "    <tr><td>$(E $source)</td><td>$(E $group.Name)</td><td>$($group.Count)</td></tr>"
    }
}
$html += "  </table></section>"

$html += "<section><h2>Direct CODE.ASZ Label References</h2><table>"
$html += "    <tr><th>source</th><th>family</th><th>suffix</th><th>refs</th></tr>"
foreach ($row in @($directRefs | Sort-Object count -Descending | Select-Object -First 64)) {
    $html += "    <tr><td>$(E $row.source)</td><td>$(E $row.family)</td><td>$(E $row.suffix)</td><td>$($row.count)</td></tr>"
}
if ($directRefs.Count -eq 0) { $html += "    <tr><td>-</td><td>-</td><td>-</td><td>0</td></tr>" }
$html += "  </table></section>"

$html += "<section><h2>Symbol Name Suffix Hints</h2><table>"
$html += "    <tr><th>source</th><th>symbol</th><th>kind</th><th>suffix hints</th></tr>"
foreach ($row in @($symbolHints | Select-Object -First 64)) {
    $html += "    <tr><td>$(E $row.source)</td><td>$(E $row.symbol)</td><td>$(E $row.kind)</td><td>$(E $row.suffixHints)</td></tr>"
}
if ($symbolHints.Count -eq 0) { $html += "    <tr><td>-</td><td>-</td><td>-</td><td>none</td></tr>" }
$html += "  </table></section>"

$html += "<section><h2>Read Line</h2><pre>This report correlates CMP.MPZ exports from LEX.CPZ and COMPILE.CPZ with CODE.ASZ triad labels."
$html += "Direct references are stronger evidence than symbol-name suffix hints."
$html += "This is lexical correlation only, not semantic or runtime proof.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"
$html | Set-Content -Encoding utf8 $OutPath
Write-Host "correlate-losethos-compiler-codegen: $OutPath"
