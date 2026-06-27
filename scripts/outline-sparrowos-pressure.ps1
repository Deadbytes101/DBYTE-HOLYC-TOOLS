param(
    [Parameter(Mandatory = $true)]
    [string]$SparrowOS,
    [string]$OutPath = "reports/archaeology/sparrowos-deep/SPARROWOS-PRESSURE-OUTLINE.md"
)

$ErrorActionPreference = "Stop"

function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function CountKind { param([object]$Json, [string]$Kind) return @($Json.items | Where-Object { $_.kind -eq $Kind }).Count }

$packagedTool = Join-Path $PSScriptRoot "../holytools.exe"
$repoTool = Join-Path $PSScriptRoot "../target/release/holytools.exe"
if (Test-Path $packagedTool) { $tool = $packagedTool } else { cargo build --release -p holytools; $tool = $repoTool }

$patterns = @(
    "StartOS.HC",
    "MakeOS.HC",
    "KernelA.HH",
    "KernelB.HH",
    "CompilerA.HH",
    "CompilerB.HH",
    "AdamA.HC",
    "Make*.HC",
    "*Kernel*.HC",
    "*Compiler*.HC",
    "*Adam*.HC",
    "*Boot*.HC",
    "*Start*.HC"
)

$files = New-Object System.Collections.Generic.HashSet[string]
foreach ($pattern in $patterns) {
    foreach ($file in @(Get-ChildItem -LiteralPath $SparrowOS -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue | Select-Object -First 80)) {
        [void]$files.Add($file.FullName)
    }
}

$rows = @()
foreach ($file in @($files | Sort-Object)) {
    $relative = [System.IO.Path]::GetRelativePath((Resolve-Path -LiteralPath $SparrowOS).Path, $file).Replace('\', '/')
    try {
        $json = & $tool outline $file --json | ConvertFrom-Json
        $rows += [pscustomobject]@{
            file = $relative
            tokens = [int]$json.tokens
            includes = [int](CountKind $json "include")
            functions = [int](CountKind $json "function")
            classes = [int](CountKind $json "class")
            status = "ok"
        }
    } catch {
        $rows += [pscustomobject]@{ file = $relative; tokens = 0; includes = 0; functions = 0; classes = 0; status = "outline-error" }
    }
}

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null
$html = @()
$html += "<h1>SPARROWOS PRESSURE OUTLINE</h1>"
$html += "<section><h2>Candidate Surface</h2><table>"
$html += "    <tr><th>file</th><th>tokens</th><th>includes</th><th>functions</th><th>classes</th><th>status</th></tr>"
foreach ($row in $rows) {
    $html += "    <tr><td>$(E $row.file)</td><td>$($row.tokens)</td><td>$($row.includes)</td><td>$($row.functions)</td><td>$($row.classes)</td><td>$(E $row.status)</td></tr>"
}
$html += "  </table></section>"

$html += "<section><h2>Ranked Next Targets</h2><table>"
$html += "    <tr><th>rank</th><th>file</th><th>tokens</th><th>functions</th><th>classes</th><th>reason</th></tr>"
$rank = 1
foreach ($row in @($rows | Where-Object { $_.status -eq "ok" } | Sort-Object @{Expression = "tokens"; Descending = $true}, @{Expression = "functions"; Descending = $true} | Select-Object -First 16)) {
    $reason = "large token surface"
    if ($row.classes -gt 0) { $reason = "class-heavy header surface" }
    elseif ($row.functions -ge 50) { $reason = "function-heavy surface" }
    elseif ($row.includes -gt 0) { $reason = "manifest or bridge surface" }
    elseif ($row.functions -eq 0 -and $row.classes -eq 0) { $reason = "dense non-symbol surface" }
    $html += "    <tr><td>$rank</td><td>$(E $row.file)</td><td>$($row.tokens)</td><td>$($row.functions)</td><td>$($row.classes)</td><td>$(E $reason)</td></tr>"
    $rank += 1
}
$html += "  </table></section>"
$html += "<section><h2>Read Line</h2><pre>This report discovers SparrowOS candidate boot/kernel/compiler/Adam-like source surfaces by filename pressure."
$html += "It is read-only and does not assume SparrowOS has the same topology as TempleOS or LoseThos.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"
$html | Set-Content -Encoding utf8 $OutPath
Write-Host "outline-sparrowos-pressure: $OutPath"
