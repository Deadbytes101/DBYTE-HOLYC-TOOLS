param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$OutDir,

    [string]$TargetName = "source"
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

function Add-Section {
    param(
        [array]$Html,
        [string]$Title,
        [string[]]$Lines
    )

    $Html += "<section>"
    $Html += "  <h2>$(HtmlEscape $Title)</h2>"
    $Html += "  <pre>$(HtmlEscape ($Lines -join [Environment]::NewLine))</pre>"
    $Html += "</section>"
    return $Html
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    Write-Error "missing source tree: $SourcePath"
    exit 1
}

New-Item -ItemType Directory -Force $OutDir | Out-Null

$target = $TargetName.ToLowerInvariant()
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
$html = Add-Section $html "Target" @(
    "target: $target",
    "root: $root"
)

$html = Add-Section $html "Pipeline Status" @(
    "includes: $includeCount",
    "resolved-includes: $resolvedCount",
    "missing-includes: $missingCount",
    "status: ok"
)

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
$html = Add-ReportRow $html "BOOT-CHAIN.md" "source load-chain checkpoints"
$html = Add-ReportRow $html "SPINE.md" "root outline checkpoints"
$html = Add-ReportRow $html "LOSETHOS-CONTRACT.md" "LoseThos-specific source-contract map when visible"
$html = Add-ReportRow $html "KERNEL-CONTRACT.md" "kernel contract map when visible"
$html = Add-ReportRow $html "COMPILER-CONTRACT.md" "compiler contract map when visible"
$html = Add-ReportRow $html "ADAM-MANIFEST.md" "Adam manifest when visible"
$html = Add-ReportRow $html "DESKTOP-SURFACE.md" "desktop/UI surface when visible"
$html = Add-ReportRow $html "ADAM-SUBSYSTEMS.md" "second-level Adam subsystem manifests when visible"
$html += "  </table>"
$html += "</section>"

switch ($target) {
    "templeos" {
        $html = Add-Section $html "System Shape" @(
            "StartOS.HC is the source root.",
            "Kernel and compiler contracts load before Adam user/system layer.",
            "Adam/MakeAdam.HC is the source manifest for graphics, block devices, windows, documents, controls, autocomplete, God layer, and host-facing reports.",
            "Adam subsystem Make files expand the second-level source map."
        )

        $html = Add-Section $html "Kernel Contract Finding" @(
            "KernelA.HH is not only CPU and memory contract surface.",
            "It also exposes compiler-runtime, disk-file-system, task-window-runtime, input, DolDoc, graphics, debug, sound, autocomplete, and UI text/control contracts.",
            "The compiler runtime has heavy pressure inside the kernel contract map."
        )

        $html = Add-Section $html "Compiler Contract Finding" @(
            "CompilerA.HH is the shape contract: function flags, optimizer register state, and intermediate struct.",
            "CompilerB.HH is the callable surface: lexer, execution entry, output stream, compiler control, class metadata, hash table sizing, builtin types, trace, parser-expression, and code stream.",
            "The compiler is treated as an operating-system surface, not an external build tool."
        )

        $html = Add-Section $html "Adam Finding" @(
            "Adam/MakeAdam.HC loads runtime-registry and task-host-system first.",
            "Graphics, sound, and block devices appear before menu/window/window-manager.",
            "DolDoc, controls, autocomplete, God layer, wallpaper, mouse, and host reports complete the user/system layer.",
            "This makes Adam the bridge from kernel/compiler contracts into interactive desktop behavior."
        )

        $html = Add-Section $html "Desktop Surface Finding" @(
            "Menu is menu plus lexer-menu behavior.",
            "Win and WinMgr contain the main window-manager surface.",
            "ADbg is DocPrint-heavy debug UI.",
            "Training is keymap/help surface.",
            "Wallpaper and Mouse are small but direct UI behavior surfaces."
        )

        $html = Add-Section $html "Adam Subsystem Finding" @(
            "Graphics fans out into graphics core, palette, DC, math, screen, bitmap, primitives, and sprite editor.",
            "Block device fans out into disk core, partition, mount, check, and file manager.",
            "DolDoc fans out into core, binary/buffer, highlight/recalc, file/clipboard, runtime/code, edit/navigation, graphics, and terminal.",
            "Controls, autocomplete, and God layer are smaller manifest surfaces with clear source load order."
        )

        $html = Add-Section $html "Next Inspection Targets" @(
            "1. Adam/DolDoc/MakeDoc.HC because it is the largest second-level UI/document manifest.",
            "2. Adam/Gr/MakeGr.HC because sprite-editor pressure dominates graphics.",
            "3. Adam/WinMgr.HC because it is the direct window-manager task surface.",
            "4. Compiler/CompilerB.HH because it exposes execution and lexer surfaces.",
            "5. Kernel/KernelA.HH because it is the public kernel contract spine."
        )
    }

    "losethos" {
        $html = Add-Section $html "LoseThos Research Stance" @(
            "LoseThos is analyzed as a HolyC-family source tree, not as a clone of the later TempleOS layout.",
            "Do not project TempleOS-specific findings onto LoseThos until the generated reports prove the same files, includes, and contracts exist.",
            "The first pass should compare boot/load chain, include resolution, contract headers, compiler surface, UI/document surface, and reverse include pressure."
        )

        $html = Add-Section $html "Comparative Questions" @(
            "1. What file acts as the load-chain root?",
            "2. Which headers behave as kernel/compiler contract surfaces?",
            "3. Does an Adam-like layer exist, and what does it load first?",
            "4. Which UI, document, graphics, sound, disk, and shell surfaces are already visible?",
            "5. Which TempleOS surfaces are absent, renamed, smaller, or structurally earlier?",
            "6. Which files have the strongest reverse-include pressure?"
        )

        $html = Add-Section $html "Next Inspection Targets" @(
            "1. losethos/LOSETHOS-CONTRACT.md for OSMain, compiler, Adam, and boot-media source-contract anchors.",
            "2. losethos/source-map.txt for total shape and scanner counts.",
            "3. losethos/include-resolve.md for include health and broken edges.",
            "4. losethos/entrypoints.txt for source roots and standalone candidates.",
            "5. losethos/dependency-order.txt for first-pass load ordering.",
            "6. losethos/REVERSE.md for pressure points."
        )
    }

    "sparrowos" {
        $html = Add-Section $html "SparrowOS Research Stance" @(
            "SparrowOS is analyzed as a related source tree with its own structure.",
            "Do not assume TempleOS file names or subsystem boundaries without file-level evidence.",
            "Use this target mainly for contrast against TempleOS and LoseThos."
        )

        $html = Add-Section $html "Next Inspection Targets" @(
            "1. sparrowos/source-map.txt for total shape.",
            "2. sparrowos/include-resolve.md for include health.",
            "3. sparrowos/entrypoints.txt for source roots.",
            "4. sparrowos/REVERSE.md for reverse include pressure."
        )
    }

    default {
        $html = Add-Section $html "Research Stance" @(
            "This target is source archaeology only.",
            "No target-specific structure is assumed.",
            "Use source-map, include-resolve, entrypoints, dependency-order, and reverse-includes as the first evidence layer."
        )
    }
}

$html = Add-Section $html "Trust Boundary" @(
    "This report is source archaeology only.",
    "It does not compile, rewrite, modernize, format, execute, emulate, or mutate the source tree.",
    "Source load order is not runtime scheduling proof.",
    "Outline pressure is not semantic proof.",
    "Use the linked reports for exact file-level evidence before making implementation claims."
)

$html | Set-Content -Encoding utf8 (Join-Path $OutDir "ARCHAEOLOGY-FINDINGS.md")

Write-Host "archaeology-findings: $OutDir"
