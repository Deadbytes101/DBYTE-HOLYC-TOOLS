param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-CODE-TRIADS.md",
    [int]$MaxBodyLines = 8
)

$ErrorActionPreference = "Stop"

function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function IsLabel { param([string]$Text) return $Text -match '^\s*[A-Za-z_.$][A-Za-z0-9_.$]*\s*:{1,2}' }
function FindLabelLine { param([string[]]$Lines, [string]$Label) for ($i = 0; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match ('^\s*' + [regex]::Escape($Label) + '\s*:{1,2}')) { return $i } } return -1 }
function BodyOf {
    param([string[]]$Lines, [string]$Label, [int]$Limit)
    $index = FindLabelLine $Lines $Label
    if ($index -lt 0) { return @() }
    $body = @()
    for ($i = $index; $i -lt $Lines.Count -and $body.Count -lt $Limit; $i++) {
        if ($i -gt $index -and (IsLabel $Lines[$i])) { break }
        if (-not [string]::IsNullOrWhiteSpace($Lines[$i])) {
            $body += [pscustomobject]@{ line = $i + 1; text = $Lines[$i].Trim() }
        }
    }
    return $body
}

$path = Join-Path $LoseThos "COMPILE/CODE.ASZ"
if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Write-Error "missing CODE table: $path"
    exit 1
}

$lines = @(Get-Content -LiteralPath $path)
$families = @("ICT", "UCT", "DCT")
$suffixes = @(
    "NULL", "NOP", "END_EXP", "ZERO", "U8", "U4", "U2", "U1", "DOUBLE", "STRING_CONSTANT",
    "ADDRESS", "DEREF_U8", "DEREF_U4", "ASSIGN_U8", "ADDITION", "SUBTRACTION", "MULTIPLICATION", "DIVISION",
    "AND", "OR", "XOR", "CALL", "CALL_INDIRECT", "ADD64", "ADD32", "ADD8", "JMP", "RET"
)

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null

$html = @()
$html += "<h1>LOSETHOS CODE TRIADS</h1>"
$html += "<section><h2>Triad Body Samples</h2>"
foreach ($suffix in $suffixes) {
    $html += "<h3>$(E $suffix)</h3><table>"
    $html += "    <tr><th>family</th><th>line</th><th>text</th></tr>"
    foreach ($family in $families) {
        $label = "$family`_$suffix"
        $body = @(BodyOf $lines $label $MaxBodyLines)
        if ($body.Count -eq 0) {
            $html += "    <tr><td>$(E $family)</td><td>-</td><td><pre>missing</pre></td></tr>"
            continue
        }
        foreach ($row in $body) {
            $html += "    <tr><td>$(E $family)</td><td>$($row.line)</td><td><pre>$(E $row.text)</pre></td></tr>"
        }
    }
    $html += "  </table>"
}
$html += "</section>"
$html += "<section><h2>Read Line</h2><pre>This report compares body snippets under matching ICT/UCT/DCT labels."
$html += "It is intended to reveal table-body shape, not to execute or validate semantics."
$html += "Use it to identify whether each suffix maps to metadata, encoded instruction rows, or compiled helper bodies.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"

$html | Set-Content -Encoding utf8 $OutPath
Write-Host "inspect-losethos-code-triads: $OutPath"
