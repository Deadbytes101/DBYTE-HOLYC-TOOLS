param(
    [Parameter(Mandatory = $true)]
    [string]$SparrowOS,
    [string]$OutPath = "reports/archaeology/sparrowos-deep/SPARROWOS-SURFACE.md"
)

$ErrorActionPreference = "Stop"
function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }

$extensions = @("*.HC", "*.HH", "*.DD", "*.PRJ", "*.ASM", "*.ASZ", "*.HCZ", "*.HHZ", "*.CPZ", "*.HPZ")
$files = @()
foreach ($ext in $extensions) {
    $files += @(Get-ChildItem -LiteralPath $SparrowOS -Recurse -File -Filter $ext -ErrorAction SilentlyContinue)
}

$rows = @()
foreach ($file in $files) {
    $relative = [System.IO.Path]::GetRelativePath((Resolve-Path -LiteralPath $SparrowOS).Path, $file.FullName).Replace('\', '/')
    $top = ($relative -split '/')[0]
    $text = ""
    try { $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop } catch { $text = "" }
    $lineCount = if ($text.Length -eq 0) { 0 } else { @($text -split "`r?`n").Count }
    $includeCount = ([regex]::Matches($text, '#include|#help_index|#exe|#define')).Count
    $asmCount = ([regex]::Matches($text, '\basm\b|\bASM\b|\bU0\s+_')).Count
    $rows += [pscustomobject]@{ file = $relative; top = $top; bytes = $file.Length; lines = $lineCount; directives = $includeCount; asmHints = $asmCount }
}

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null
$html = @()
$html += "<h1>SPARROWOS SURFACE</h1>"
$html += "<section><h2>Directory Pressure</h2><table>"
$html += "    <tr><th>top directory</th><th>files</th><th>bytes</th><th>lines</th><th>directives</th><th>asm hints</th></tr>"
foreach ($group in @($rows | Group-Object top | Sort-Object Count -Descending)) {
    $items = @($group.Group)
    $html += "    <tr><td>$(E $group.Name)</td><td>$($items.Count)</td><td>$(@($items | Measure-Object bytes -Sum).Sum)</td><td>$(@($items | Measure-Object lines -Sum).Sum)</td><td>$(@($items | Measure-Object directives -Sum).Sum)</td><td>$(@($items | Measure-Object asmHints -Sum).Sum)</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Largest Files</h2><table>"
$html += "    <tr><th>file</th><th>bytes</th><th>lines</th><th>directives</th><th>asm hints</th></tr>"
foreach ($row in @($rows | Sort-Object bytes -Descending | Select-Object -First 32)) {
    $html += "    <tr><td>$(E $row.file)</td><td>$($row.bytes)</td><td>$($row.lines)</td><td>$($row.directives)</td><td>$($row.asmHints)</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Directive / Assembly Pressure</h2><table>"
$html += "    <tr><th>file</th><th>directives</th><th>asm hints</th><th>lines</th></tr>"
foreach ($row in @($rows | Sort-Object @{Expression = "directives"; Descending = $true}, @{Expression = "asmHints"; Descending = $true}, @{Expression = "lines"; Descending = $true} | Select-Object -First 32)) {
    $html += "    <tr><td>$(E $row.file)</td><td>$($row.directives)</td><td>$($row.asmHints)</td><td>$($row.lines)</td></tr>"
}
$html += "  </table></section>"
$html += "<section><h2>Read Line</h2><pre>This report measures broad SparrowOS source shape before target-specific claims are made."
$html += "It favors directory pressure, largest files, directives, and assembly hints as next archaeology anchors.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"
$html | Set-Content -Encoding utf8 $OutPath
Write-Host "inspect-sparrowos-surface: $OutPath"
