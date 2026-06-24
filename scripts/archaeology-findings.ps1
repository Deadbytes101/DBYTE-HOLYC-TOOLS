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

function ReportState {
    param([string]$Name)
    $path = Join-Path $OutDir $Name
    if (Test-Path -LiteralPath $path -PathType Leaf) { return "present" }
    return "missing"
}

function Add-ReportRow {
    param(
        [array]$Html,
        [string]$Name,
        [string]$Role
    )

    $Html += "    <tr><td>$(HtmlEscape $Name)</td><td>$(HtmlEscape (ReportState $Name))</td><td>$(HtmlEscape $Role)</td></tr>"
    return $Html
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    Write-Error "missing source tree: $SourcePath"
    exit 1
}

New-Item -ItemType Directory -Force $OutDir | Out-Null

$root = RepoPath (Resolve-Path -LiteralPath $SourcePath).Path
$resolvePath = Join-Path $OutDir "include-resolve.json"
$includeCount = "unknown"
$resolvedCount = "unknown"
$missingCount = "unknown"

if (Test-Path -LiteralPath $resolvePath -PathType Leaf) {
    $includeData = Get-Content -LiteralPath $resolvePath -Raw | ConvertFrom-Json
    $includeRows = @($includeData.rows)
    $includeCount = $includeRows.Count
    $resolvedCount = @($includeRows | Where-Object { $_.status -eq "resolved" }).Count
    $missingCount = @($includeRows | Where-Object { $_.status -eq "missing" }).Count
}

$html = @()
$html += "<h1>SOURCE ARCHAEOLOGY FINDINGS</h1>"
$html += "<section>"
$html += "  <h2>Root</h2>"
$html += "  <pre>$(HtmlEscape $root)</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Pipeline Status</h2>"
$html += "  <pre>includes: $includeCount"
$html += "resolved-includes: $resolvedCount"
$html += "missing-includes: $missingCount"
$html += "status: ok</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Evidence Map</h2>"
$html += "  <table>"
$html = Add-ReportRow $html "source-map.txt" "top-level scanner counts"
$html = Add-ReportRow $html "source-map.json" "machine-readable source map"
$html = Add-ReportRow $html "missing-includes.txt" "missing include scan"
$html = Add-ReportRow $html "entrypoints.txt" "entrypoint candidates"
$html = Add-ReportRow $html "dependency-order.txt" "dependency order scan"
$html = Add-ReportRow $html "reverse-includes.txt" "reverse include scan"
$html = Add-ReportRow $html "include-resolve.md" "include resolver proof"
$html = Add-ReportRow $html "REVERSE.md" "reverse include pressure"
$html = Add-ReportRow $html "BOOT-CHAIN.md" "StartOS source load chain"
$html = Add-ReportRow $html "SPINE.md" "root outline checkpoints"
$html = Add-ReportRow $html "KERNEL-CONTRACT.md" "KernelA public contract map"
$html = Add-ReportRow $html "COMPILER-CONTRACT.md" "CompilerA/B contract map"
$html = Add-ReportRow $html "ADAM-MANIFEST.md" "Adam top-level manifest"
$html = Add-ReportRow $html "DESKTOP-SURFACE.md" "Adam desktop and UI surface"
$html = Add-ReportRow $html "ADAM-SUBSYSTEMS.md" "second-level Adam subsystem manifests"
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>System Shape</h2>"
$html += "  <pre>StartOS.HC is the source root."
$html += "Kernel and compiler contracts load before Adam user/system layer."
$html += "Adam/MakeAdam.HC is the source manifest for graphics, block devices, windows, documents, controls, autocomplete, God layer, and host-facing reports."
$html += "Adam subsystem Make files expand the second-level source map.</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Kernel Contract Finding</h2>"
$html += "  <pre>KernelA.HH is not only CPU and memory contract surface."
$html += "It also exposes compiler-runtime, disk-file-system, task-window-runtime, input, DolDoc, graphics, debug, sound, autocomplete, and UI text/control contracts."
$html += "The compiler runtime has heavy pressure inside the kernel contract map.</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Compiler Contract Finding</h2>"
$html += "  <pre>CompilerA.HH is the shape contract: function flags, optimizer register state, and intermediate struct."
$html += "CompilerB.HH is the callable surface: lexer, execution entry, output stream, compiler control, class metadata, hash table sizing, builtin types, trace, parser-expression, and code stream."
$html += "The compiler is treated as an operating-system surface, not an external build tool.</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Adam Finding</h2>"
$html += "  <pre>Adam/MakeAdam.HC loads runtime-registry and task-host-system first."
$html += "Graphics, sound, and block devices appear before menu/window/window-manager."
$html += "DolDoc, controls, autocomplete, God layer, wallpaper, mouse, and host reports complete the user/system layer."
$html += "This makes Adam the bridge from kernel/compiler contracts into interactive desktop behavior.</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Desktop Surface Finding</h2>"
$html += "  <pre>Menu is menu plus lexer-menu behavior."
$html += "Win and WinMgr contain the main window-manager surface."
$html += "ADbg is DocPrint-heavy debug UI."
$html += "Training is keymap/help surface."
$html += "Wallpaper and Mouse are small but direct UI behavior surfaces.</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Adam Subsystem Finding</h2>"
$html += "  <pre>Graphics fans out into graphics core, palette, DC, math, screen, bitmap, primitives, and sprite editor."
$html += "Block device fans out into disk core, partition, mount, check, and file manager."
$html += "DolDoc fans out into core, binary/buffer, highlight/recalc, file/clipboard, runtime/code, edit/navigation, graphics, and terminal."
$html += "Controls, autocomplete, and God layer are smaller manifest surfaces with clear source load order.</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Trust Boundary</h2>"
$html += "  <pre>This report is source archaeology only."
$html += "It does not compile, rewrite, modernize, format, execute, emulate, or mutate the source tree."
$html += "Source load order is not runtime scheduling proof."
$html += "Outline pressure is not semantic proof."
$html += "Use the linked reports for exact file-level evidence before making implementation claims.</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Next Inspection Targets</h2>"
$html += "  <pre>1. Adam/DolDoc/MakeDoc.HC because it is the largest second-level UI/document manifest."
$html += "2. Adam/Gr/MakeGr.HC because sprite-editor pressure dominates graphics."
$html += "3. Adam/WinMgr.HC because it is the direct window-manager task surface."
$html += "4. Compiler/CompilerB.HH because it exposes execution and lexer surfaces."
$html += "5. Kernel/KernelA.HH because it is the public kernel contract spine.</pre>"
$html += "</section>"

$html | Set-Content -Encoding utf8 (Join-Path $OutDir "ARCHAEOLOGY-FINDINGS.md")

Write-Host "archaeology-findings: $OutDir"
