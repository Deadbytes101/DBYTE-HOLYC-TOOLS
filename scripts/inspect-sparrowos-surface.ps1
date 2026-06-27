param(
    [Parameter(Mandatory = $true)]
    [string]$SparrowOS,
    [string]$OutPath = "reports/archaeology/sparrowos-deep/SPARROWOS-SURFACE.md"
)

$ErrorActionPreference = "Stop"
function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function Get-RelativeSourcePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $rootPath = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\', '/')
    $fullPath = (Resolve-Path -LiteralPath $Path).Path

    if ($fullPath.StartsWith($rootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $fullPath.Substring($rootPath.Length).TrimStart('\', '/').Replace('\', '/')
    }

    return $fullPath.Replace('\', '/')
}

$extensions = @(
    "*.HC", "*.HH", "*.DD", "*.PRJ", "*.ASM", "*.ASZ", "*.C", "*.CPP", "*.HPP", "*.TXT",
    "*.HCZ", "*.HHZ", "*.CPZ", "*.HPZ",
    "*.HC.Z", "*.HH.Z", "*.CPP.Z", "*.HPP.Z", "*.TXT.Z", "*.PRJ.Z", "*.DAT.Z", "*.AUT.Z"
)
$files = @()
foreach ($ext in $extensions) {
    $files += @(Get-ChildItem -LiteralPath $SparrowOS -Recurse -File -Filter $ext -ErrorAction SilentlyContinue)
}

$rows = @()
foreach ($file in @($files | Sort-Object FullName -Unique)) {
    $relative = Get-RelativeSourcePath -Root $SparrowOS -Path $file.FullName
    $top = ($relative -split '/')[0]
    $text = ""
    try { $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop } catch { $text = "" }
    $lineCount = if ($text.Length -eq 0) { 0 } else { @($text -split "`r?`n").Count }
    $includeCount = ([regex]::Matches($text, '#include|#help_index|#exe|#define|#define_str|#exe\{|#help_file')).Count
    $asmCount = ([regex]::Matches($text, '\basm\b|\bASM\b|\bU0\s+_|\bAX\b|\bRAX\b|\bPUSH\b|\bPOP\b')).Count
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
$html += "It includes SparrowOS zipped text source extensions such as .CPP.Z, .HPP.Z, .TXT.Z, and .PRJ.Z."
$html += "It favors directory pressure, largest files, directives, and assembly hints as next archaeology anchors.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"
$html | Set-Content -Encoding utf8 $OutPath
Write-Host "inspect-sparrowos-surface: $OutPath"
