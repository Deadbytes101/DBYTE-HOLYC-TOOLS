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

function Invoke-Outline {
    param([string]$Path)

    $text = & $ToolPath outline $Path
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    $text -join "`n"
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
    [pscustomobject]@{ Name = "Boot Entry"; Path = Join-Path $root "StartOS.HC" },
    [pscustomobject]@{ Name = "Kernel Contract"; Path = Join-Path $root "Kernel/KernelA.HH" },
    [pscustomobject]@{ Name = "Compiler Contract"; Path = Join-Path $root "Compiler/CompilerA.HH" },
    [pscustomobject]@{ Name = "Adam Manifest"; Path = Join-Path $root "Adam/MakeAdam.HC" }
)

$html = @()
$html += "<h1>SOURCE SPINE</h1>"
$html += "<section>"
$html += "  <h2>Root</h2>"
$html += "  <pre>$(HtmlEscape (RepoPath $root))</pre>"
$html += "</section>"
$html += "<section>"
$html += "  <h2>Reading Order</h2>"
$html += "  <pre>StartOS.HC"
$html += "Kernel/KernelA.HH"
$html += "Compiler/CompilerA.HH"
$html += "Adam/MakeAdam.HC</pre>"
$html += "</section>"
$html += "<section>"
$html += "  <h2>Interpretation</h2>"
$html += "  <pre>StartOS is the boot script gate."
$html += "KernelA is the system type contract."
$html += "CompilerA is the compiler front contract."
$html += "MakeAdam is the Adam layer load manifest.</pre>"
$html += "</section>"

foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file.Path -PathType Leaf)) {
        continue
    }

    $outline = Invoke-Outline $file.Path
    $html += "<section>"
    $html += "  <h2>$(HtmlEscape $file.Name)</h2>"
    $html += "  <pre>$(HtmlEscape $outline)</pre>"
    $html += "</section>"
}

$html | Set-Content -Encoding utf8 (Join-Path $OutDir "SPINE.md")

Write-Host "spine: $OutDir"
