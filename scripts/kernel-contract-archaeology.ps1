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

function AreaName {
    param([string]$Name)

    if ($Name -match '^(I8_MIN|I16_MIN|I32_MIN|I64_MIN|U64_F64_MAX|F64_MAX|F64_MIN|inf|pi|exp_1|log2_10|log2_e|log10_2|loge_2|sqrt2|eps|ToI64|ans|ansf)$') { return "base-math-constants" }
    if ($Name -match '^(CDate|CDateStruct)$') { return "time-date" }
    if ($Name -match '^(Complex|CD2|CD3|CD2I32|CD3I32|CD2I64|CD3I64|COrder|CMass|CSpring|CMathODE|CColor|CBGR)') { return "geometry-physics" }
    if ($Name -match '^(CQue|CFifo|CArray|CMember)') { return "queue-array-metadata" }
    if ($Name -match '^(CKernel|CSema|CCntsGlbls|CDevGlbls|CFreeLst|CInsReg)$') { return "kernel-core" }
    if ($Name -match '^(C?CPU|LAPIC|HPET|RFLAG|MP_|CGDT|CTSS|CSysFixedArea|CSysLimitBase|CAP16BitInit|CRAX|CPCIDev|Bsf$)') { return "cpu-platform" }
    if ($Name -match '^(CTask|CJob|Job|Task|SYS_TIMER|WINMGR|WIG_|RLf_|DISPLAY|CWin|Win|CViewAngles|CProgress)') { return "task-window-runtime" }
    if ($Name -match '^(CCtrl|CMenu|CMenuEntry|CTextGlbls)$') { return "ui-control-text" }
    if ($Name -match '^(CMem|MEM_|CHeap|Heap|CBlkPool)') { return "memory-heap" }
    if ($Name -match '^(CBinFile|CPatchTable|CATARep|INVALID_CLUS|CCacheBlk|CDrv|CBlkDev|CBlkDevGlbls|CDir|CFile|FAT|RS_|DVD_|BLK_|Dsk|File|FUG_|CDIR|CMBR|CMasterBoot|CRedSeaBoot|CFAT|CATAPI|CISO|CPalindrome)') { return "disk-file-system" }
    if ($Name -match '^(CDoc|Doc|DOC|CEd)') { return "document-doldoc" }
    if ($Name -match '^(CDC|CGr|Gr|CBGR|ROP_|SFG_|CColor|CScrn|Sprite|CGrid)') { return "graphics" }
    if ($Name -match '^(CHash|Hash|HTG_|CAOT|CIntermediate|CIC|CPrs|CCode|CLex|CCmp|CAsm|COpt|CInst|OC_|MDG_|FSF_|FSG_|CStreamBlk|CUAsm|OPTF_|AOT_|CAbsCnts|CFunSegCache|FUN_SEG_CACHE|CExternUsage|offset)') { return "compiler-runtime" }
    if ($Name -match '^(CArc|Arc)') { return "archive-compression" }
    if ($Name -match '^(CKbd|CMs|SCF_|CKey)') { return "input" }
    if ($Name -match '^(CAutoComplete|CHashAC)') { return "autocomplete" }
    if ($Name -match '^(CSnd|CAUData)') { return "sound" }
    if ($Name -match '^(CDbg|CBpt|CExcept|CFPU|PROGRESS|CMPCrash)') { return "debug-exception" }
    return "other"
}

function BandName {
    param([int]$Line)

    if ($Line -lt 400) { return "0000-0399 front declarations and math" }
    if ($Line -lt 800) { return "0400-0799 platform hash debug base" }
    if ($Line -lt 1400) { return "0800-1399 document metadata" }
    if ($Line -lt 1900) { return "1400-1899 window compiler asm bridge" }
    if ($Line -lt 2400) { return "1900-2399 compiler and block device" }
    if ($Line -lt 2900) { return "2400-2899 file system and memory" }
    if ($Line -lt 3400) { return "2900-3399 graphics input task" }
    return "3400-end fixed area input sound debug"
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
$kernelA = Join-Path $root "Kernel/KernelA.HH"
if (-not (Test-Path -LiteralPath $kernelA -PathType Leaf)) {
    Write-Error "missing Kernel/KernelA.HH"
    exit 1
}

$jsonText = & $ToolPath outline $kernelA --json
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$data = $jsonText | ConvertFrom-Json
$items = @($data.items)
$classItems = @($items | Where-Object { $_.kind -eq "class" })
$functionItems = @($items | Where-Object { $_.kind -eq "function" })

$areaRows = @($items |
    Group-Object { AreaName $_.name } |
    Sort-Object Count -Descending)

$bandRows = @($items |
    Group-Object { BandName ([int]$_.line) } |
    Sort-Object Name)

$html = @()
$html += "<h1>KERNEL CONTRACT ARCHAEOLOGY</h1>"
$html += "<section>"
$html += "  <h2>File</h2>"
$html += "  <pre>$(HtmlEscape (RepoPath $kernelA))</pre>"
$html += "</section>"
$html += "<section>"
$html += "  <h2>Counts</h2>"
$html += "  <pre>items: $($items.Count)"
$html += "classes: $($classItems.Count)"
$html += "functions: $($functionItems.Count)"
$html += "tokens: $($data.tokens)"
$html += "status: ok</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Line Bands</h2>"
$html += "  <table>"
foreach ($row in $bandRows) {
    $samples = @($row.Group | Sort-Object line,column | Select-Object -First 12 | ForEach-Object { $_.name }) -join ", "
    $html += "    <tr><td>$(HtmlEscape $row.Name)</td><td>$($row.Count)</td><td>$(HtmlEscape $samples)</td></tr>"
}
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Contract Areas</h2>"
$html += "  <table>"
foreach ($row in $areaRows) {
    $samples = @($row.Group | Sort-Object line,column | Select-Object -First 18 | ForEach-Object { $_.name }) -join ", "
    $html += "    <tr><td>$(HtmlEscape $row.Name)</td><td>$($row.Count)</td><td>$(HtmlEscape $samples)</td></tr>"
}
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Reading Rule</h2>"
$html += "  <pre>Read this as a contract map, not implementation proof."
$html += "Use line bands to choose where to inspect next."
$html += "Use contract areas to see which subsystem owns the pressure."
$html += "Large other bucket means classifier needs refinement, not source disorder.</pre>"
$html += "</section>"

$html | Set-Content -Encoding utf8 (Join-Path $OutDir "KERNEL-CONTRACT.md")

Write-Host "kernel-contract: $OutDir"
