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

$rows = @()
foreach ($anchor in $anchors) {
    $path = Join-Path $LoseThos $anchor
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $rows += [pscustomobject]@{ file = $anchor; tokens = 0; includes = 0; functions = 0; classes = 0; status = "missing" }
        continue
    }
    $json = & $tool outline $path --json | ConvertFrom-Json
    $rows += [pscustomobject]@{
        file = $anchor
        tokens = [int]$json.tokens
        includes = [int](CountKind $json "include")
        functions = [int](CountKind $json "function")
        classes = [int](CountKind $json "class")
        status = "ok"
    }
}

$html = @()
$html += "<h1>LOSETHOS PRESSURE OUTLINE</h1>"
$html += "<section><h2>Outline Pressure</h2><table>"
$html += "    <tr><th>file</th><th>tokens</th><th>includes</th><th>functions</th><th>classes</th><th>status</th></tr>"
foreach ($row in $rows) {
    $tokens = if ($row.status -eq "ok") { $row.tokens } else { "-" }
    $includes = if ($row.status -eq "ok") { $row.includes } else { "-" }
    $functions = if ($row.status -eq "ok") { $row.functions } else { "-" }
    $classes = if ($row.status -eq "ok") { $row.classes } else { "-" }
    $html += "    <tr><td>$(E $row.file)</td><td>$tokens</td><td>$includes</td><td>$functions</td><td>$classes</td><td>$(E $row.status)</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Ranked Next Targets</h2><table>"
$html += "    <tr><th>rank</th><th>file</th><th>tokens</th><th>functions</th><th>classes</th><th>reason</th></tr>"
$rank = 1
foreach ($row in @($rows | Where-Object { $_.status -eq "ok" } | Sort-Object @{Expression = "tokens"; Descending = $true}, @{Expression = "functions"; Descending = $true} | Select-Object -First 8)) {
    $reason = "large token surface"
    if ($row.classes -gt 0) { $reason = "class-heavy header surface" }
    elseif ($row.functions -ge 50) { $reason = "function-heavy surface" }
    elseif ($row.includes -gt 0) { $reason = "manifest or bridge surface" }
    elseif ($row.functions -eq 0 -and $row.classes -eq 0) { $reason = "dense non-symbol surface" }
    $html += "    <tr><td>$rank</td><td>$(E $row.file)</td><td>$($row.tokens)</td><td>$($row.functions)</td><td>$($row.classes)</td><td>$(E $reason)</td></tr>"
    $rank += 1
}
$html += "  </table></section>"
$html += "<section><h2>Read Line</h2><pre>This report reads the real LoseThos source files through holytools outline --json."
$html += "It is still read-only: no compile, no execute, no source-tree mutation."
$html += "Ranked targets favor large token surfaces first, then function/class pressure."
$html += "Dense non-symbol rows such as CMP.MPZ and CODE.ASZ are not empty; they are scanner pressure points for manual archaeology.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"

$html | Set-Content -Encoding utf8 $OutPath
Write-Host "outline-losethos-pressure: $OutPath"
