param(
    [string]$Root = "reports/archaeology",
    [string]$Out = "reports/archaeology/TEMPLEOS-LOSETHOS-COMPARE.md"
)

$ErrorActionPreference = "Stop"

function EscapeHtml {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function ReadJsonFile {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    return $null
}

function ValueOf {
    param([object]$Object, [string]$Name)
    if ($null -eq $Object) { return "unknown" }
    if ($Object.PSObject.Properties.Name -contains $Name) { return $Object.$Name }
    return "unknown"
}

function CountIncludes {
    param([string]$Dir)
    $path = Join-Path $Dir "include-resolve.json"
    $json = ReadJsonFile $path
    if ($null -eq $json -or $null -eq $json.rows) {
        return [pscustomobject]@{ total = "unknown"; resolved = "unknown"; missing = "unknown" }
    }
    $rows = @($json.rows)
    [pscustomobject]@{
        total = $rows.Count
        resolved = @($rows | Where-Object { $_.status -eq "resolved" }).Count
        missing = @($rows | Where-Object { $_.status -eq "missing" }).Count
    }
}

function ReportCell {
    param([string]$Dir, [string]$Name)
    if (Test-Path -LiteralPath (Join-Path $Dir $Name) -PathType Leaf) { return "present" }
    return "missing"
}

$templeDir = Join-Path $Root "templeos"
$loseDir = Join-Path $Root "losethos"
$templeMap = ReadJsonFile (Join-Path $templeDir "source-map.json")
$loseMap = ReadJsonFile (Join-Path $loseDir "source-map.json")
$templeInc = CountIncludes $templeDir
$loseInc = CountIncludes $loseDir

New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null

$html = @()
$html += "<h1>TEMPLEOS LOSETHOS COMPARE</h1>"
$html += "<section>"
$html += "  <h2>Shape</h2>"
$html += "  <table>"
$html += "    <tr><th>target</th><th>files</th><th>tokens</th><th>functions</th><th>classes</th><th>asm</th><th>includes</th><th>resolved</th><th>missing</th></tr>"
$html += "    <tr><td>templeos</td><td>$(ValueOf $templeMap 'holy_files')</td><td>$(ValueOf $templeMap 'tokens')</td><td>$(ValueOf $templeMap 'functions')</td><td>$(ValueOf $templeMap 'classes')</td><td>$(ValueOf $templeMap 'asm_blocks')</td><td>$($templeInc.total)</td><td>$($templeInc.resolved)</td><td>$($templeInc.missing)</td></tr>"
$html += "    <tr><td>losethos</td><td>$(ValueOf $loseMap 'holy_files')</td><td>$(ValueOf $loseMap 'tokens')</td><td>$(ValueOf $loseMap 'functions')</td><td>$(ValueOf $loseMap 'classes')</td><td>$(ValueOf $loseMap 'asm_blocks')</td><td>$($loseInc.total)</td><td>$($loseInc.resolved)</td><td>$($loseInc.missing)</td></tr>"
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Evidence Surface</h2>"
$html += "  <table>"
$html += "    <tr><th>report</th><th>templeos</th><th>losethos</th></tr>"
foreach ($name in @("BOOT-CHAIN.md", "SPINE.md", "KERNEL-CONTRACT.md", "COMPILER-CONTRACT.md", "ADAM-MANIFEST.md", "DESKTOP-SURFACE.md", "ADAM-SUBSYSTEMS.md", "LOSETHOS-CONTRACT.md", "ARCHAEOLOGY-FINDINGS.md")) {
    $html += "    <tr><td>$(EscapeHtml $name)</td><td>$(ReportCell $templeDir $name)</td><td>$(ReportCell $loseDir $name)</td></tr>"
}
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Read Line</h2>"
$html += "  <pre>TempleOS is read through StartOS, KernelA, CompilerA/B, Adam, desktop, and Adam subsystem reports."
$html += "LoseThos is read through OSMain, ADAMK, COMPILE, Adam, and boot media anchors."
$html += "Do not force TempleOS file names onto LoseThos. Use generated evidence first.</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Next Pressure Points</h2>"
$html += "  <pre>1. TempleOS StartOS versus LoseThos OSMain/OS.ASZ"
$html += "2. TempleOS KernelA versus LoseThos ADAMK headers"
$html += "3. TempleOS CompilerA/B versus LoseThos COMPILE/CMP files"
$html += "4. TempleOS Adam manifests versus LoseThos ADAM/ADAM2.CPZ"
$html += "5. Boot media gates and early disk surface</pre>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Boundary</h2>"
$html += "  <pre>Source archaeology only."
$html += "No compile. No execute. No rewrite. No source-tree mutation."
$html += "Report order is file evidence, not runtime proof.</pre>"
$html += "</section>"

$html | Set-Content -Encoding utf8 $Out
Write-Host "compare-templeos-losethos: $Out"
