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
    $Path.Replace([char]92, [char]47)
}

function HtmlEscape {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function Write-Node {
    param(
        [string]$File,
        [int]$Depth,
        [string]$FromTarget = "",
        [int]$FromLine = 0
    )

    $indent = "  " * $Depth
    if ($FromLine -gt 0) {
        $script:lines += "$indent- line $FromLine $FromTarget -> $(RepoPath $File)"
    } else {
        $script:lines += "$indent- $(RepoPath $File)"
    }

    if ($Depth -ge $MaxDepth) {
        return
    }

    if ($script:visiting.ContainsKey($File)) {
        $script:lines += "$indent  - cycle"
        return
    }

    $script:visiting[$File] = $true

    $children = @($script:edges[$File] | Sort-Object line,column,target,resolved)
    $seen = @{}
    foreach ($child in $children) {
        if ($seen.ContainsKey($child.resolved)) {
            continue
        }
        $seen[$child.resolved] = $true
        Write-Node $child.resolved ($Depth + 1) $child.target $child.line
    }

    $script:visiting.Remove($File)
}

function Write-SkippedReport {
    param(
        [string]$Root,
        [string]$Reason
    )

    $html = @()
    $html += "<h1>BOOT CHAIN ARCHAEOLOGY</h1>"
    $html += "<section>"
    $html += "  <h2>Root</h2>"
    $html += "  <pre>$(HtmlEscape (RepoPath $Root))</pre>"
    $html += "</section>"
    $html += "<section>"
    $html += "  <h2>Status</h2>"
    $html += "  <pre>skipped: $(HtmlEscape $Reason)"
    $html += "status: ok</pre>"
    $html += "</section>"
    $html += "<section>"
    $html += "  <h2>Reading Rule</h2>"
    $html += "  <pre>No TempleOS StartOS.HC assumption is made for this target."
    $html += "Inspect source-map, entrypoints, dependency-order, and include-resolve before naming a load-chain root.</pre>"
    $html += "</section>"
    $html | Set-Content -Encoding utf8 (Join-Path $OutDir "BOOT-CHAIN.md")
}

New-Item -ItemType Directory -Force $OutDir | Out-Null

$resolvePath = Join-Path $OutDir "include-resolve.json"
if (-not (Test-Path -LiteralPath $resolvePath)) {
    Write-Error "missing include-resolve.json"
    exit 1
}

$data = Get-Content -LiteralPath $resolvePath -Raw | ConvertFrom-Json
$root = RepoPath (Resolve-Path -LiteralPath $SourcePath).Path
$startCandidate = Join-Path $root "StartOS.HC"

if (-not (Test-Path -LiteralPath $startCandidate -PathType Leaf)) {
    Write-SkippedReport $root "StartOS.HC not found"
    Write-Host "boot-chain: $OutDir"
    return
}

$start = RepoPath (Resolve-Path -LiteralPath $startCandidate).Path

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

    $script:edges[$from] += [pscustomobject]@{
        line = [int]$row.line
        column = [int]$row.column
        target = [string]$row.target
        resolved = $to
    }
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
$html += "  <pre>Read top down by source include line.
When a branch fans out, inspect the Make file first.
Treat this as source include order, not runtime proof.</pre>"
$html += "</section>"
$html | Set-Content -Encoding utf8 (Join-Path $OutDir "BOOT-CHAIN.md")

Write-Host "boot-chain: $OutDir"
