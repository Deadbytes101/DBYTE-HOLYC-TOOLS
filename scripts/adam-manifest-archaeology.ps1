param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$OutDir
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

function AdamAreaName {
    param([string]$Target)

    if ($Target -match '^Gr/') { return "graphics" }
    if ($Target -match '^ABlkDev/') { return "block-device" }
    if ($Target -match '^DolDoc/') { return "document-doldoc" }
    if ($Target -match '^God/') { return "god-layer" }
    if ($Target -match '^Ctrls/') { return "controls" }
    if ($Target -match '^AutoComplete/') { return "autocomplete" }
    if ($Target -match '^(Menu|Win|WinMgr)') { return "window-menu" }
    if ($Target -match '^(TaskRep|TaskSettings|CPURep|DevInfo|Host)') { return "task-host-system" }
    if ($Target -match '^(AMath|AMathODE)') { return "math" }
    if ($Target -match '^(AMem|AHash|ADefine|AExts|ARegistry|InsReg)') { return "runtime-registry" }
    if ($Target -match '^(ASnd|AMouse|InFile)') { return "device-io" }
    if ($Target -match '^(ADbg|Training|WallPaper)') { return "tools-desktop" }
    return "other"
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    Write-Error "missing source tree: $SourcePath"
    exit 1
}

New-Item -ItemType Directory -Force $OutDir | Out-Null

$root = RepoPath (Resolve-Path -LiteralPath $SourcePath).Path
$makeAdam = RepoPath (Join-Path $root "Adam/MakeAdam.HC")
$resolvePath = Join-Path $OutDir "include-resolve.json"

if (-not (Test-Path -LiteralPath $resolvePath -PathType Leaf)) {
    Write-Error "missing include-resolve.json"
    exit 1
}

$data = Get-Content -LiteralPath $resolvePath -Raw | ConvertFrom-Json
$rows = @($data.rows |
    Where-Object { (RepoPath ([string]$_.file)) -eq $makeAdam } |
    Sort-Object line,column)

$areaRows = @($rows |
    Group-Object { AdamAreaName ([string]$_.target) } |
    Sort-Object Count -Descending)

$html = @()
$html += "<h1>ADAM MANIFEST ARCHAEOLOGY</h1>"
$html += "<section>"
$html += "  <h2>File</h2>"
$html += "  <pre>$(HtmlEscape $makeAdam)</pre>"
$html += "</section>"
$html += "<section>"
$html += "  <h2>Counts</h2>"
$html += "  <pre>includes: $($rows.Count)"
$html += "resolved: $(@($rows | Where-Object { $_.status -eq 'resolved' }).Count)"
$html += "missing: $(@($rows | Where-Object { $_.status -eq 'missing' }).Count)"
$html += "status: ok</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Load Order</h2>"
$html += "  <table>"
foreach ($row in $rows) {
    $area = AdamAreaName ([string]$row.target)
    $html += "    <tr><td>$($row.line)</td><td>$(HtmlEscape $area)</td><td>$(HtmlEscape ([string]$row.target))</td><td>$(HtmlEscape (RepoPath ([string]$row.resolved)))</td></tr>"
}
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Subsystem Areas</h2>"
$html += "  <table>"
foreach ($row in $areaRows) {
    $samples = @($row.Group | Sort-Object line,column | ForEach-Object { $_.target }) -join ", "
    $html += "    <tr><td>$(HtmlEscape $row.Name)</td><td>$($row.Count)</td><td>$(HtmlEscape $samples)</td></tr>"
}
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Reading Rule</h2>"
$html += "  <pre>Read this as Adam source load order."
$html += "Inspect Make files before leaf files."
$html += "Treat this as include order, not runtime scheduling proof.</pre>"
$html += "</section>"

$html | Set-Content -Encoding utf8 (Join-Path $OutDir "ADAM-MANIFEST.md")

Write-Host "adam-manifest: $OutDir"
