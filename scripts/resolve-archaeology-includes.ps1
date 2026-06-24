param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$OutDir,

    [string]$ToolPath = "target/release/holytools.exe"
)

$ErrorActionPreference = "Stop"

function Convert-RepoPath {
    param([string]$Path)
    $Path.Replace([char]92, [char]47)
}

if (-not (Test-Path -LiteralPath $ToolPath -PathType Leaf)) {
    $ToolPath = "dist/dbyte-holyc-tools-windows/holytools.exe"
}

if (-not (Test-Path -LiteralPath $ToolPath -PathType Leaf)) {
    Write-Error "missing holytools.exe"
    exit 1
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    Write-Error "missing source tree: $SourcePath"
    exit 1
}

New-Item -ItemType Directory -Force $OutDir | Out-Null

$root = Convert-RepoPath (Resolve-Path -LiteralPath $SourcePath).Path
$jsonText = & $ToolPath resolve-includes $SourcePath --json
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$data = $jsonText | ConvertFrom-Json
$rows = @()

foreach ($include in $data.includes) {
    $rows += [pscustomobject]@{
        file = Convert-RepoPath ([string]$include.file)
        line = [int]$include.line
        column = [int]$include.column
        target = [string]$include.target
        status = [string]$include.status
        resolved = Convert-RepoPath ([string]$include.resolved)
    }
}

$resolvedCount = [int]$data.resolved
$missingCount = [int]$data.missing

[pscustomobject]@{
    source = $root
    includes = $rows.Count
    resolved = $resolvedCount
    missing = $missingCount
    rows = $rows
} | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $OutDir "include-resolve.json")

$text = @()
foreach ($row in $rows) {
    $text += ("{0}:{1}:{2}`t{3}`t{4}`t{5}" -f $row.file, $row.line, $row.column, $row.target, $row.status, $row.resolved)
}
$text += ("resolved: {0}" -f $resolvedCount)
$text += ("missing: {0}" -f $missingCount)
$text += "status: ok"
$text | Set-Content -Encoding utf8 (Join-Path $OutDir "include-resolve.txt")

$html = @()
$html += "<section>"
$html += "  <h2>Include Resolve</h2>"
$html += "  <pre>includes: $($rows.Count)"
$html += "resolved: $resolvedCount"
$html += "missing: $missingCount"
$html += "status: ok</pre>"
$html += "</section>"
$html | Set-Content -Encoding utf8 (Join-Path $OutDir "include-resolve.md")

Write-Host "include-resolve: $OutDir"
