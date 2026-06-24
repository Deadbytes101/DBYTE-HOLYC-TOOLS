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
    $Path.Replace('\\', '/')
}

function Expand-Candidates {
    param(
        [string]$Base,
        [string]$Target
    )

    $baseTarget = Join-Path $Base $Target
    $items = @($baseTarget)

    if ([System.IO.Path]::GetExtension($Target) -eq "") {
        $items += "$baseTarget.HC"
        $items += "$baseTarget.HH"
        $items += "$baseTarget.ZC"
        $items += "$baseTarget.ZH"
    }

    $items
}

function Normalize-Target {
    param([string]$Target)

    $value = $Target.Trim().Trim('"').Replace('\\', '/')
    $rooted = $false
    $home = $false

    if ($value.StartsWith('~/')) {
        $value = $value.Substring(2)
        $home = $true
    } elseif ($value.StartsWith('::/')) {
        $value = $value.Substring(3)
        $rooted = $true
    } elseif ($value.StartsWith('/')) {
        $value = $value.TrimStart('/')
        $rooted = $true
    }

    [pscustomobject]@{
        Target = $value
        Rooted = $rooted
        Home = $home
    }
}

function Resolve-Target {
    param(
        [string]$Root,
        [string]$From,
        [string]$Target
    )

    $norm = Normalize-Target $Target
    $fromPath = $From.Replace('/', '\\')
    $parent = Split-Path $fromPath -Parent
    $candidates = @()

    if ($norm.Home) {
        $candidates += Expand-Candidates $parent $norm.Target
        $candidates += Expand-Candidates $Root $norm.Target
    } elseif ($norm.Rooted) {
        $candidates += Expand-Candidates $Root $norm.Target
    } else {
        $candidates += Expand-Candidates $parent $norm.Target
        $candidates += Expand-Candidates $Root $norm.Target
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Convert-RepoPath (Resolve-Path -LiteralPath $candidate).Path)
        }
    }

    ""
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

$root = (Resolve-Path -LiteralPath $SourcePath).Path
$jsonText = & $ToolPath includes $SourcePath --json
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$data = $jsonText | ConvertFrom-Json
$rows = @()

foreach ($include in $data.includes) {
    $target = ([string]$include.target).Trim()
    $resolved = Resolve-Target $root ([string]$include.file) $target
    $status = if ($resolved) { "resolved" } else { "missing" }

    $rows += [pscustomobject]@{
        file = [string]$include.file
        line = [int]$include.line
        column = [int]$include.column
        target = $target
        status = $status
        resolved = $resolved
    }
}

$resolvedCount = @($rows | Where-Object { $_.status -eq "resolved" }).Count
$missingCount = @($rows | Where-Object { $_.status -eq "missing" }).Count

[pscustomobject]@{
    source = (Convert-RepoPath $root)
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
