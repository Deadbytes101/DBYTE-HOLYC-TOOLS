param(
    [string]$Root = "reports/archaeology",
    [string]$OutPath = "reports/archaeology/LOSETHOS-RESEARCH-STATE.md"
)

$ErrorActionPreference = "Stop"

function E { param([string]$Text) if ($null -eq $Text) { return "" } $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function ReadJson { param([string]$Path) if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null } return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
function V { param([object]$Obj, [string]$Name) if ($null -eq $Obj) { return "unknown" } if ($Obj.PSObject.Properties.Name -contains $Name) { return $Obj.$Name } return "unknown" }
function Rows { param([string]$Path) $json = ReadJson $Path; if ($null -eq $json -or $null -eq $json.rows) { return @() } return @($json.rows) }
function ReportStatus { param([string]$Name) if (Test-Path -LiteralPath (Join-Path $Root $Name) -PathType Leaf) { return "present" } return "missing" }

$templeMap = ReadJson (Join-Path $Root "templeos/source-map.json")
$loseMap = ReadJson (Join-Path $Root "losethos/source-map.json")
$templeInc = @(Rows (Join-Path $Root "templeos/include-resolve.json"))
$loseInc = @(Rows (Join-Path $Root "losethos/include-resolve.json"))
$codegenPresent = (ReportStatus "LOSETHOS-CODEGEN-STATE.md") -eq "present"

New-Item -ItemType Directory -Force (Split-Path -Parent $OutPath) | Out-Null

$html = @()
$html += "<h1>LOSETHOS RESEARCH STATE</h1>"
$html += "<section><h2>Source Shape</h2><table>"
$html += "    <tr><th>target</th><th>files</th><th>tokens</th><th>functions</th><th>classes</th><th>asm</th><th>include-edges</th></tr>"
$html += "    <tr><td>TempleOS</td><td>$(V $templeMap 'holy_files')</td><td>$(V $templeMap 'tokens')</td><td>$(V $templeMap 'functions')</td><td>$(V $templeMap 'classes')</td><td>$(V $templeMap 'asm_blocks')</td><td>$($templeInc.Count)</td></tr>"
$html += "    <tr><td>LoseThos</td><td>$(V $loseMap 'holy_files')</td><td>$(V $loseMap 'tokens')</td><td>$(V $loseMap 'functions')</td><td>$(V $loseMap 'classes')</td><td>$(V $loseMap 'asm_blocks')</td><td>$($loseInc.Count)</td></tr>"
$html += "  </table></section>"

$html += "<section><h2>Evidence Chain</h2><pre>Boot: OSMain/OS.ASZ fans into OSMain, IRQ, memory, scheduler, command, and disk layers."
$html += "Bridge: OSMain/ADAMK.CPZ pulls ADAMK headers, compiler header, and ADAM/ADAM2.CPZ."
$html += "Compiler: COMPILE/CMP.ASZ pulls CODE, LEX, SPRINTF2, ASM, PARSE, OPT, and COMPILE."
$html += "Adam: ADAM/ADAM2.CPZ pulls math, ODE, graphics, disk, comm, input, window, edit, login, and wordstat surfaces."
if ($codegenPresent) {
    $html += "Codegen: CMP.MPZ maps exported compiler symbols to source refs; CODE.ASZ holds complete ICT/UCT/DCT code-template triads.</pre></section>"
} else {
    $html += "Codegen: deep LoseThos codegen archaeology has not been generated yet.</pre></section>"
}

$html += "<section><h2>Generated Reports</h2><table>"
$html += "    <tr><th>report</th><th>status</th></tr>"
foreach ($name in @(
    "TEMPLEOS-LOSETHOS-COMPARE.md",
    "TEMPLEOS-LOSETHOS-BOOT-COMPARE.md",
    "TEMPLEOS-LOSETHOS-KERNEL-ADAMK-COMPARE.md",
    "TEMPLEOS-LOSETHOS-COMPILER-CMP-COMPARE.md",
    "LOSETHOS-COMPILER-PIPELINE.md",
    "LOSETHOS-ADAM-SURFACE.md",
    "TEMPLEOS-LOSETHOS-ADAM-LAYER-COMPARE.md",
    "LOSETHOS-CODEGEN-STATE.md"
)) { $html += "    <tr><td>$(E $name)</td><td>$(ReportStatus $name)</td></tr>" }
$html += "  </table></section>"

$html += "<section><h2>Research State</h2><pre>LoseThos is a compact early system, not a thin fragment."
if ($codegenPresent) {
    $html += "The include evidence shows boot, kernel/Adam bridge, compiler manifest, compiler pipeline, Adam-layer manifest, and compiler codegen triads."
    $html += "Next useful work is correlating LEX.CPZ and COMPILE.CPZ exports with CODE.ASZ suffix usage."
} else {
    $html += "The include evidence shows boot, kernel/Adam bridge, compiler manifest, compiler pipeline, and Adam-layer manifest."
    $html += "Next useful work is source outline inspection for CMP.MPZ, ADAM2.CPZ, and the compiler component files."
}
$html += "All claims here are generated-report evidence, not runtime proof.</pre></section>"
$html += "<section><h2>Boundary</h2><pre>No compile. No execute. No rewrite. No source-tree mutation.</pre></section>"

$html | Set-Content -Encoding utf8 $OutPath
Write-Host "rollup-losethos-research-state: $OutPath"
