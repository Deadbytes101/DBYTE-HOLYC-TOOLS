param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-DENSE-SURFACE.md"
)

$ErrorActionPreference = "Stop"

function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function RelPath { param([string]$Root, [string]$Path) $r = $Root.TrimEnd('\','/'); return $Path.Substring($r.Length).TrimStart('\','/').Replace('\','/') }

$targets = @(
    "COMPILE/CMP.MPZ",
    "COMPILE/CODE.ASZ",
    "COMPILE/OPT.CPZ",
    "OSMain/ADAMK.HPZ",
    "COMPILE/LEX.CPZ",
    "COMPILE/ASM.CPZ"
)

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null

$rows = @()
$samples = @{}
foreach ($target in $targets) {
    $path = Join-Path $LoseThos $target
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $rows += [pscustomobject]@{ file = $target; lines = 0; nonblank = 0; labels = 0; directives = 0; strings = 0; comments = 0; status = "missing" }
        continue
    }

    $lines = @(Get-Content -LiteralPath $path)
    $nonblank = @($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
    $labels = @($lines | Where-Object { $_ -match '^\s*[A-Za-z_.$][A-Za-z0-9_.$]*\s*:' }).Count
    $directives = @($lines | Where-Object { $_ -match '^\s*(#|\.|DU8|DU16|DU32|DU64|I8|I16|I32|I64|U8|U16|U32|U64)\b' }).Count
    $strings = @($lines | Where-Object { $_ -match '"' }).Count
    $comments = @($lines | Where-Object { $_ -match '^\s*(//|/\*|\*)' }).Count
    $rows += [pscustomobject]@{ file = $target; lines = $lines.Count; nonblank = $nonblank; labels = $labels; directives = $directives; strings = $strings; comments = $comments; status = "ok" }

    $sampleRows = @()
    for ($i = 0; $i -lt $lines.Count -and $sampleRows.Count -lt 12; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*[A-Za-z_.$][A-Za-z0-9_.$]*\s*:' -or $line -match '^\s*(#|\.|DU8|DU16|DU32|DU64|I8|I16|I32|I64|U8|U16|U32|U64)\b' -or $line -match '"') {
            $sampleRows += [pscustomobject]@{ line = $i + 1; text = $line.Trim() }
        }
    }
    $samples[$target] = $sampleRows
}

$html = @()
$html += "<h1>LOSETHOS DENSE SURFACE</h1>"
$html += "<section><h2>Dense Surface Metrics</h2><table>"
$html += "    <tr><th>file</th><th>lines</th><th>nonblank</th><th>label-candidates</th><th>directive-candidates</th><th>string-lines</th><th>comment-lines</th><th>status</th></tr>"
foreach ($row in $rows) {
    $html += "    <tr><td>$(E $row.file)</td><td>$($row.lines)</td><td>$($row.nonblank)</td><td>$($row.labels)</td><td>$($row.directives)</td><td>$($row.strings)</td><td>$($row.comments)</td><td>$(E $row.status)</td></tr>"
}
$html += "  </table></section>"

foreach ($target in $targets) {
    if (-not $samples.ContainsKey($target)) { continue }
    $html += "<section><h2>$(E $target) Sample Anchors</h2><table>"
    $html += "    <tr><th>line</th><th>text</th></tr>"
    foreach ($sample in $samples[$target]) {
        $html += "    <tr><td>$($sample.line)</td><td><pre>$(E $sample.text)</pre></td></tr>"
    }
    if ($samples[$target].Count -eq 0) { $html += "    <tr><td>-</td><td><pre>no anchors matched</pre></td></tr>" }
    $html += "  </table></section>"
}

$html += "<section><h2>Read Line</h2><pre>This report inspects dense LoseThos pressure files as raw text."
$html += "Label/directive/string counts are lexical pressure hints, not semantic proof."
$html += "Use the sample anchors to choose the next file-specific archaeology pass.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"

$html | Set-Content -Encoding utf8 $OutPath
Write-Host "inspect-losethos-dense-surface: $OutPath"
