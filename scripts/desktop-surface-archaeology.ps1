param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$OutDir,

    [string]$ToolPath = "target/release/holytools.exe"
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

function SurfaceAreaName {
    param([string]$Name)

    if ($Name -match '^(Menu|CMenu|DrawMenu)') { return "menu" }
    if ($Name -match '^(Win|CWin|WinMgr|CWinMgr|WIG_|WINMGR_|PopUp|Refresh|Kill)') { return "window-manager" }
    if ($Name -match '^(Doc|CDoc|DOC|DolDoc|Ed|CEd|CDolDoc)') { return "document-editor" }
    if ($Name -match '^(Ctrl|CCtrl|Slider|Check|Button|Grid)') { return "controls" }
    if ($Name -match '^(AutoComplete|AC|CAutoComplete)') { return "autocomplete" }
    if ($Name -match '^(WallPaper|Wallpaper|CWallPaper|CTaskWallPaperData|DrawTermBttn|LeftClickTermBttn)') { return "wallpaper" }
    if ($Name -match '^(Dbg|ADbg|Debug|Dump|ClassRep|ClassRepD|FunRep|Uf|U|UpdateRegVarImg)') { return "debug-ui" }
    if ($Name -match '^(Training|Tip|KeyMap|KMCompare|PostMsg)') { return "training-help" }
    if ($Name -match '^(Mouse|Ms|CMs|DrawMs|DrawGrabMs)') { return "mouse-input" }
    if ($Name -match '^(Lex|LexExcept)') { return "lexer-menu" }
    if ($Name -match '^(ProgressBars|PROGRESS_BAR|DrawProgressBars|CProgress)') { return "progress-bars" }
    if ($Name -match '^(DrawWinGrid)') { return "window-render" }
    if ($Name -match '^(TextPrint|ExtendedASCII)') { return "text-render" }
    if ($Name -match '^(MemCpy)') { return "memory-runtime" }
    if ($Name -match '^(Sprite)') { return "sprite-graphics" }
    return "other"
}

function Add-SurfaceFile {
    param(
        [array]$Html,
        [string]$Label,
        [string]$RelPath,
        [string]$Root
    )

    $path = Join-Path $Root $RelPath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $Html += "<section>"
        $Html += "  <h2>$(HtmlEscape $Label)</h2>"
        $Html += "  <pre>missing: $(HtmlEscape (RepoPath $path))</pre>"
        $Html += "</section>"
        return $Html
    }

    $jsonText = & $ToolPath outline $path --json
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $data = $jsonText | ConvertFrom-Json
    $items = @($data.items)
    $includes = @($items | Where-Object { $_.kind -eq "include" })
    $symbols = @($items | Where-Object { $_.kind -ne "include" })
    $areas = @($symbols | Group-Object { SurfaceAreaName $_.name } | Sort-Object Count -Descending)

    $Html += "<section>"
    $Html += "  <h2>$(HtmlEscape $Label)</h2>"
    $Html += "  <pre>file: $(HtmlEscape (RepoPath $path))"
    $Html += "items: $($items.Count)"
    $Html += "symbols: $($symbols.Count)"
    $Html += "includes: $($includes.Count)"
    $Html += "tokens: $($data.tokens)"
    $Html += "status: ok</pre>"
    $Html += "</section>"

    if ($areas.Count -gt 0) {
        $Html += "<section>"
        $Html += "  <h2>$(HtmlEscape $Label) Areas</h2>"
        $Html += "  <table>"
        foreach ($row in $areas) {
            $samples = @($row.Group | Sort-Object line,column | Select-Object -First 16 | ForEach-Object { $_.name }) -join ", "
            $Html += "    <tr><td>$(HtmlEscape $row.Name)</td><td>$($row.Count)</td><td>$(HtmlEscape $samples)</td></tr>"
        }
        $Html += "  </table>"
        $Html += "</section>"
    }

    return $Html
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
$files = @(
    @{ Label = "Menu"; Path = "Adam/Menu.HC" },
    @{ Label = "Window"; Path = "Adam/Win.HC" },
    @{ Label = "Window Manager"; Path = "Adam/WinMgr.HC" },
    @{ Label = "DolDoc Manifest"; Path = "Adam/DolDoc/MakeDoc.HC" },
    @{ Label = "Controls Manifest"; Path = "Adam/Ctrls/MakeCtrls.HC" },
    @{ Label = "Autocomplete Manifest"; Path = "Adam/AutoComplete/MakeAC.HC" },
    @{ Label = "Wallpaper"; Path = "Adam/WallPaper.HC" },
    @{ Label = "Adam Debug"; Path = "Adam/ADbg.HC" },
    @{ Label = "Training"; Path = "Adam/Training.HC" },
    @{ Label = "Mouse"; Path = "Adam/AMouse.HC" }
)

$html = @()
$html += "<h1>DESKTOP SURFACE ARCHAEOLOGY</h1>"
$html += "<section>"
$html += "  <h2>Root</h2>"
$html += "  <pre>$(HtmlEscape (RepoPath $root))</pre>"
$html += "</section>"
$html += "<section>"
$html += "  <h2>Reading Rule</h2>"
$html += "  <pre>Read this as the Adam desktop and UI surface."
$html += "Make files are manifests. Leaf files expose direct UI behavior."
$html += "Counts are outline pressure only, not runtime hotness.</pre>"
$html += "</section>"

foreach ($file in $files) {
    $html = Add-SurfaceFile $html $file.Label $file.Path $root
}

$html | Set-Content -Encoding utf8 (Join-Path $OutDir "DESKTOP-SURFACE.md")

Write-Host "desktop-surface: $OutDir"
