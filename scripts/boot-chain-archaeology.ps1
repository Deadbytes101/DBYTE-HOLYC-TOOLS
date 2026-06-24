param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$OutDir,

    [int]$MaxDepth = 8
)

$ErrorActionPreference = "Stop"

function RepoPath {
    param([string]$Path)
    $Path.Replace('\\', '/')
}

function HtmlEscape {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function Write-Node {
    param(
        [string]$File,
        [int]$Depth
    )

    $indent = "  " * $Depth
    $script:lines += "$indent- $(RepoPath $File)"

    if ($Depth -ge $MaxDepth) {
        return
    }

    if ($script:visiting.ContainsKey($File)) {
        $script:lines += "$indent  - cycle"
        return
    }

    $script:visiting[$File] = $true

    $children = @($script:edges[$File] | Sort-Object -Unique)
    foreach ($child in $children) {
        Write-Node $child ($Depth + 1)
    }

    $script:visiting.Remove($File)
}

New-Item -ItemType Directory -Force $OutDir | Out-Null

$resolvePath = Join-Path $OutDir "include-resolve.json"
if (-not (Test-Path -LiteralPath $resolvePath)) {
    Write-Error "missing include-resolve.json"
    exit 1
}

$data = Get-Content -LiteralPath $resolvePath -Raw | ConvertFrom-Json
$root = (Resolve-Path -LiteralPath $SourcePath).Path
$start = Join-Path $root "StartOS.HC"
$start = RepoPath (Resolve-Path -LiteralPath $start).Path

$script:edges = @{}
foreach ($row in $data.rows) {
    if ($row.status -ne "resolved" -or -not $row.resolved) {
        continue
    }

    $from = RepoPath ([string]$row.file)
    $to = RepoPath ([string]$row.resolved)

    if (-not $script:edges.ContainsKey($from)) {
        $script:edges[$from] = @()
    }

    $script:edges[$from] += $to
}

$script:lines = @()
$script:visiting = @{}
Write-Node $start 0

$html = @()
$html += "<h1>BOOT CHAIN ARCHAEOLOGY</h1>"
$html += "<section>"
$html += "  <h2>Root</h2>"
$html += "  <pre>$(HtmlEscape (RepoPath $root))</pre>"
$html += "</section>"
$html += "<section>"
$html += "  <h2>Start</h2>"
$html += "  <pre>$(HtmlEscape $start)</pre>"
$html += "</section>"
$html += "<section>"
$html += "  <h2>Include Walk</h2>"
$html += "  <pre>$(HtmlEscape (($script:lines -join "`n")))</pre>"
$html += "</section>"
$html += "<section>"
$html += "  <h2>Reading Rule</h2>"
$html += "  <pre>Read top down.
When a branch fans out, inspect the Make file first.
Treat this as source order, not runtime proof.</pre>"
$html += "</section>"
$html | Set-Content -Encoding utf8 (Join-Path $OutDir "BOOT-CHAIN.md")

Write-Host "boot-chain: $OutDir"
