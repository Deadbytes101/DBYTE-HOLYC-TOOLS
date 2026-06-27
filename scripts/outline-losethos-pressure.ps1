param(
    [Parameter(Mandatory = $true)]
    [string]$LoseThos,
    [string]$OutPath = "reports/archaeology/LOSETHOS-PRESSURE-OUTLINE.md"
)

$ErrorActionPreference = "Stop"

function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function CountKind { param([object]$Json, [string]$Kind) return @($Json.items | Where-Object { $_.kind -eq $Kind }).Count }

$packagedTool = Join-Path $PSScriptRoot "../holytools.exe"
$repoTool = Join-Path $PSScriptRoot "../target/release/holytools.exe"
if (Test-Path $packagedTool) { $tool = $packagedTool } else { cargo build --release -p holytools; $tool = $repoTool }

$anchors = @(
    "OSMain/ADAMK.CPZ",
    "OSMain/ADAMK.HPZ",
    "OSMain/ADAMK2.HPZ",
    "OSMain/ADAMK3.HPZ",
    "COMPILE/CMP.ASZ",
    "COMPILE/CMP.HPZ",
    "COMPILE/CMP.MPZ",
    "COMPILE/CODE.ASZ",
    "COMPILE/LEX.CPZ",
    "COMPILE/SPRINTF2.CPZ",
    "COMPILE/ASM.CPZ",
    "COMPILE/PARSE.CPZ",
    "COMPILE/OPT.CPZ",
    "COMPILE/COMPILE.CPZ",
    "ADAM/ADAM2.CPZ",
    "ADAM/ADAMASM.ASZ"
)

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null

$html = @()
$html += "<h1>LOSETHOS PRESSURE OUTLINE</h1>"
$html += "<section><h2>Outline Pressure</h2><table>"
$html += "    <tr><th>file</th><th>tokens</th><th>includes</th><th>functions</th><th>classes</th><th>status</th></tr>"
foreach ($anchor in $anchors) {
    $path = Join-Path $LoseThos $anchor
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $html += "    <tr><td>$(E $anchor)</td><td>-</td><td>-</td><td>-</td><td>-</td><td>missing</td></tr>"
        continue
    }
    $json = & $tool outline $path --json | ConvertFrom-Json
    $includes = CountKind $json "include"
    $functions = CountKind $json "function"
    $classes = CountKind $json "class"
    $html += "    <tr><td>$(E $anchor)</td><td>$($json.tokens)</td><td>$includes</td><td>$functions</td><td>$classes</td><td>ok</td></tr>"
}
$html += "  </table></section>"
$html += "<section><h2>Read Line</h2><pre>This report reads the real LoseThos source files through holytools outline --json."
$html += "It is still read-only: no compile, no execute, no source-tree mutation."
$html += "Use high token/function rows as the next manual archaeology targets.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"

$html | Set-Content -Encoding utf8 $OutPath
Write-Host "outline-losethos-pressure: $OutPath"
