param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$OutDir,

    [string]$ToolPath = "target/release/holytools.exe"
)

$ErrorActionPreference = "Stop"

function HtmlEscape {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function RepoPath {
    param([string]$Path)
    $Path.Replace('\\', '/')
}

function TreeName {
    param([string]$Path)
    $value = RepoPath $Path
    $parts = $value.Split('/')
    foreach ($name in @('TempleOS', 'LoseThos', 'SparrowOS')) {
        $idx = [Array]::IndexOf($parts, $name)
        if ($idx -ge 0 -and $parts.Length -gt ($idx + 1)) {
            return $parts[$idx + 1]
        }
    }
    if ($parts.Length -gt 1) { return $parts[$parts.Length - 2] }
    $value
}

function ReadJson {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
    }
    $null
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

$symbolsText = & $ToolPath symbols $SourcePath --json
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$symbols = @(($symbolsText | ConvertFrom-Json).symbols)

$includesText = & $ToolPath includes $SourcePath --json
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$includes = @(($includesText | ConvertFrom-Json).includes)

$sourceMap = ReadJson (Join-Path $OutDir "source-map.json")
$includeResolve = ReadJson (Join-Path $OutDir "include-resolve.json")

$kindRows = @($symbols | Group-Object kind | Sort-Object Count -Descending)
$dirRows = @($symbols | Group-Object { TreeName $_.file } | Sort-Object Count -Descending | Select-Object -First 30)
$fileRows = @($symbols | Group-Object file | Sort-Object Count -Descending | Select-Object -First 30)

$gateSymbols = @(
    $symbols |
        Where-Object { $_.name -match '^(Make|Load|Run|Start|Init|Boot|God|Doc|Gr|Cmp|Lex|Prs|Asm|K|Dsk)' } |
        Sort-Object file,line,column |
        Select-Object -First 160
)

$includeHotspots = @()
$missingIncludes = @()
if ($includeResolve -and $includeResolve.rows) {
    $includeHotspots = @($includeResolve.rows |
        Where-Object { $_.status -eq 'resolved' -and $_.resolved -ne '' } |
        Group-Object resolved |
        Sort-Object Count -Descending |
        Select-Object -First 40)

    $missingIncludes = @($includeResolve.rows |
        Where-Object { $_.status -eq 'missing' } |
        Select-Object -First 100)
}

$html = @()
$html += "<h1>SOURCE REVERSE ARCHAEOLOGY</h1>"
$html += ""
$html += "<section>"
$html += "  <h2>Root</h2>"
$html += "  <pre>$(HtmlEscape $SourcePath)</pre>"
$html += "</section>"

if ($sourceMap) {
    $html += "<section>"
    $html += "  <h2>Counts</h2>"
    $html += "  <table>"
    $html += "    <tr><td>holy-files</td><td>$($sourceMap.holy_files)</td></tr>"
    $html += "    <tr><td>tokens</td><td>$($sourceMap.tokens)</td></tr>"
    $html += "    <tr><td>functions</td><td>$($sourceMap.functions)</td></tr>"
    $html += "    <tr><td>classes</td><td>$($sourceMap.classes)</td></tr>"
    $html += "    <tr><td>includes</td><td>$($sourceMap.includes)</td></tr>"
    $html += "    <tr><td>asm-blocks</td><td>$($sourceMap.asm_blocks)</td></tr>"
    $html += "  </table>"
    $html += "</section>"
}

if ($includeResolve) {
    $html += "<section>"
    $html += "  <h2>Include Resolve</h2>"
    $html += "  <pre>"
    $html += "includes: $($includeResolve.includes)"
    $html += "resolved: $($includeResolve.resolved)"
    $html += "missing: $($includeResolve.missing)"
    $html += "  </pre>"
    $html += "</section>"
}

$html += "<section>"
$html += "  <h2>Symbol Kinds</h2>"
$html += "  <table>"
foreach ($row in $kindRows) {
    $html += "    <tr><td>$(HtmlEscape $row.Name)</td><td>$($row.Count)</td></tr>"
}
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Directory Pressure</h2>"
$html += "  <table>"
foreach ($row in $dirRows) {
    $html += "    <tr><td>$(HtmlEscape $row.Name)</td><td>$($row.Count)</td></tr>"
}
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>File Pressure</h2>"
$html += "  <table>"
foreach ($row in $fileRows) {
    $html += "    <tr><td>$(HtmlEscape (RepoPath $row.Name))</td><td>$($row.Count)</td></tr>"
}
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Resolved Include Hotspots</h2>"
$html += "  <table>"
foreach ($row in $includeHotspots) {
    $html += "    <tr><td>$(HtmlEscape (RepoPath $row.Name))</td><td>$($row.Count)</td></tr>"
}
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Gate Symbols</h2>"
$html += "  <table>"
foreach ($row in $gateSymbols) {
    $html += "    <tr><td>$(HtmlEscape (RepoPath $row.file))</td><td>$($row.line)</td><td>$(HtmlEscape $row.kind)</td><td>$(HtmlEscape $row.name)</td></tr>"
}
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Missing Include Samples</h2>"
$html += "  <table>"
foreach ($row in $missingIncludes) {
    $html += "    <tr><td>$(HtmlEscape (RepoPath $row.file))</td><td>$($row.line)</td><td>$(HtmlEscape $row.target)</td></tr>"
}
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Research Notes</h2>"
$html += "  <pre>Start with counts.
Then inspect pressure.
Then inspect gates.
Then inspect missing include grammar.
Do not claim secrets without source evidence.</pre>"
$html += "</section>"

$html | Set-Content -Encoding utf8 (Join-Path $OutDir "REVERSE.html")

$txt = @()
$txt += "SOURCE REVERSE ARCHAEOLOGY"
$txt += "root: $SourcePath"
if ($sourceMap) {
    $txt += "holy-files: $($sourceMap.holy_files)"
    $txt += "tokens: $($sourceMap.tokens)"
    $txt += "functions: $($sourceMap.functions)"
    $txt += "classes: $($sourceMap.classes)"
    $txt += "includes: $($sourceMap.includes)"
    $txt += "asm-blocks: $($sourceMap.asm_blocks)"
}
if ($includeResolve) {
    $txt += "resolved-includes: $($includeResolve.resolved)"
    $txt += "missing-includes: $($includeResolve.missing)"
}
$txt += "status: ok"
$txt | Set-Content -Encoding utf8 (Join-Path $OutDir "REVERSE.txt")

Write-Host "reverse: $OutDir"
