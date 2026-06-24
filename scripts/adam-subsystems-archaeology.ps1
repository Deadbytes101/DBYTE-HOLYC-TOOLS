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

function AreaName {
    param([string]$Target)

    if ($Target -match '^(GrInitA|GrInitB|GrEnd)') { return "graphics-init-end" }
    if ($Target -match '^(Gr\.HH|GrExt|GrGlbls)') { return "graphics-core" }
    if ($Target -match '^(GrTextBase)') { return "graphics-text" }
    if ($Target -match '^(GrAsm)') { return "graphics-asm" }
    if ($Target -match '^(GrPalette)') { return "graphics-palette" }
    if ($Target -match '^(GrDC)') { return "graphics-dc" }
    if ($Target -match '^(GrMath)') { return "graphics-math" }
    if ($Target -match '^(GrScrn|ScrnCast)') { return "graphics-screen" }
    if ($Target -match '^(GrBitMap)') { return "graphics-bitmap" }
    if ($Target -match '^(GrPrimatives|GrComposites)') { return "graphics-primitives" }
    if ($Target -match '^(Sprite|GrSpritePlot)') { return "sprite-editor" }

    if ($Target -match '^(ADskA|ADskB)') { return "disk-core" }
    if ($Target -match '^(DskPrt)') { return "disk-partition" }
    if ($Target -match '^(Mount)') { return "disk-mount" }
    if ($Target -match '^(DskChk)') { return "disk-check" }
    if ($Target -match '^(FileMgr)') { return "file-manager" }

    if ($Target -match '^(DocExt|DocNew|DocInit|DocPlain)') { return "doc-core" }
    if ($Target -match '^(DocBin|DocForm|DocDblBuf)') { return "doc-binary-buffer" }
    if ($Target -match '^(DocHighlight|DocRecalc|DocRecalcLib)') { return "doc-highlight-recalc" }
    if ($Target -match '^(DocFile|DocClipBoard)') { return "doc-file-clipboard" }
    if ($Target -match '^(DocRun|DocMacro|DocCodeTools)') { return "doc-runtime-code" }
    if ($Target -match '^(DocGet|DocChar|DocFind|DocLink|DocEd|DocPopUp|DocWidgetWiz|DocPutKey|DocPutS|DocTree)') { return "doc-edit-navigation" }
    if ($Target -match '^(DocGr)') { return "doc-graphics" }
    if ($Target -match '^(DocTerm)') { return "doc-terminal" }

    if ($Target -match '^(CtrlsA)') { return "controls-core" }
    if ($Target -match '^(CtrlsBttn)') { return "controls-button" }
    if ($Target -match '^(CtrlsSlider)') { return "controls-slider" }

    if ($Target -match '^(ACFill)') { return "autocomplete-fill" }
    if ($Target -match '^(ACTask)') { return "autocomplete-task" }
    if ($Target -match '^(ACInit)') { return "autocomplete-init" }

    if ($Target -match '^(GodBible)') { return "god-bible" }
    if ($Target -match '^(HolySpirit)') { return "god-runtime" }
    if ($Target -match '^(GodSong)') { return "god-song" }
    if ($Target -match '^(GodDoodle)') { return "god-doodle" }

    if ($Target -match '(^|/)Gr/') { return "graphics" }
    if ($Target -match '(^|/)ABlkDev/') { return "block-device" }
    if ($Target -match '(^|/)DolDoc/') { return "document-doldoc" }
    if ($Target -match '(^|/)Ctrls/') { return "controls" }
    if ($Target -match '(^|/)AutoComplete/') { return "autocomplete" }
    if ($Target -match '(^|/)God/') { return "god-layer" }
    if ($Target -match '^(Menu|Win|WinMgr)') { return "window-menu" }
    if ($Target -match '^(AMath|AMathODE)') { return "math" }
    if ($Target -match '^(ASnd|AMouse|InFile)') { return "device-io" }
    if ($Target -match '^(ARegistry|InsReg|AHash|ADefine|AExts|AMem)') { return "runtime-registry" }
    if ($Target -match '^(TaskRep|TaskSettings|CPURep|DevInfo|Host)') { return "task-host-system" }
    return "other"
}

function Add-Manifest {
    param(
        [array]$Html,
        [array]$Rows,
        [string]$Label,
        [string]$File
    )

    $manifestRows = @($Rows |
        Where-Object { (RepoPath ([string]$_.file)) -eq $File } |
        Sort-Object line,column)

    $resolvedCount = @($manifestRows | Where-Object { $_.status -eq "resolved" }).Count
    $missingCount = @($manifestRows | Where-Object { $_.status -eq "missing" }).Count
    $areaRows = @($manifestRows |
        Group-Object { AreaName ([string]$_.target) } |
        Sort-Object Count -Descending)

    $Html += "<section>"
    $Html += "  <h2>$(HtmlEscape $Label)</h2>"
    $Html += "  <pre>file: $(HtmlEscape $File)"
    $Html += "includes: $($manifestRows.Count)"
    $Html += "resolved: $resolvedCount"
    $Html += "missing: $missingCount"
    $Html += "status: ok</pre>"
    $Html += "</section>"

    if ($manifestRows.Count -gt 0) {
        $Html += "<section>"
        $Html += "  <h2>$(HtmlEscape $Label) Load Order</h2>"
        $Html += "  <table>"
        foreach ($row in $manifestRows) {
            $area = AreaName ([string]$row.target)
            $Html += "    <tr><td>$($row.line)</td><td>$(HtmlEscape $area)</td><td>$(HtmlEscape ([string]$row.target))</td><td>$(HtmlEscape (RepoPath ([string]$row.resolved)))</td></tr>"
        }
        $Html += "  </table>"
        $Html += "</section>"

        $Html += "<section>"
        $Html += "  <h2>$(HtmlEscape $Label) Areas</h2>"
        $Html += "  <table>"
        foreach ($row in $areaRows) {
            $samples = @($row.Group | Sort-Object line,column | ForEach-Object { $_.target }) -join ", "
            $Html += "    <tr><td>$(HtmlEscape $row.Name)</td><td>$($row.Count)</td><td>$(HtmlEscape $samples)</td></tr>"
        }
        $Html += "  </table>"
        $Html += "</section>"
    }

    return $Html
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    Write-Error "missing source tree: $SourcePath"
    exit 1
}

New-Item -ItemType Directory -Force $OutDir | Out-Null

$root = RepoPath (Resolve-Path -LiteralPath $SourcePath).Path
$resolvePath = Join-Path $OutDir "include-resolve.json"

if (-not (Test-Path -LiteralPath $resolvePath -PathType Leaf)) {
    Write-Error "missing include-resolve.json"
    exit 1
}

$data = Get-Content -LiteralPath $resolvePath -Raw | ConvertFrom-Json
$rows = @($data.rows)

$manifests = @(
    @{ Label = "Graphics Manifest"; File = "$root/Adam/Gr/MakeGr.HC" },
    @{ Label = "Block Device Manifest"; File = "$root/Adam/ABlkDev/MakeABlkDev.HC" },
    @{ Label = "DolDoc Manifest"; File = "$root/Adam/DolDoc/MakeDoc.HC" },
    @{ Label = "Controls Manifest"; File = "$root/Adam/Ctrls/MakeCtrls.HC" },
    @{ Label = "Autocomplete Manifest"; File = "$root/Adam/AutoComplete/MakeAC.HC" },
    @{ Label = "God Manifest"; File = "$root/Adam/God/MakeGod.HC" }
)

$html = @()
$html += "<h1>ADAM SUBSYSTEMS ARCHAEOLOGY</h1>"
$html += "<section>"
$html += "  <h2>Root</h2>"
$html += "  <pre>$(HtmlEscape $root)</pre>"
$html += "</section>"
$html += "<section>"
$html += "  <h2>Reading Rule</h2>"
$html += "  <pre>Read this as second-level Adam subsystem include order."
$html += "These Make files fan out from Adam/MakeAdam.HC."
$html += "This is source load order, not runtime scheduling proof.</pre>"
$html += "</section>"

foreach ($manifest in $manifests) {
    $html = Add-Manifest $html $rows $manifest.Label $manifest.File
}

$html | Set-Content -Encoding utf8 (Join-Path $OutDir "ADAM-SUBSYSTEMS.md")

Write-Host "adam-subsystems: $OutDir"
