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

function CompilerAreaName {
    param([string]$Name)

    if ($Name -match '^(FSF_|FSG_)') { return "function-signature-flags" }
    if ($Name -match '^(CIntermediate|CIC|IC_|ICT_|ICF_)') { return "intermediate-code" }
    if ($Name -match '^(COpt|OPT|OPTF_|OPTf_|GetOption|Echo)') { return "optimizer-options" }
    if ($Name -match '^(CLex|Lex|LEX|TK_|CHashSrcSym|HTG_)') { return "lexer-symbols" }
    if ($Name -match '^(CPrs|Prs|PRS|IsLexExpression)') { return "parser-expression" }
    if ($Name -match '^(CAsm|Asm|AOT_|CAOT|CInst|OC_|MDG_)') { return "assembler-aot" }
    if ($Name -match '^(CCmp|Cmp|CMP|CInit|CmpCtrl)') { return "compiler-control" }
    if ($Name -match '^(CHash|Hash)') { return "hash-symbol-table" }
    if ($Name -match '^(CCode|Code|CStreamBlk|StreamDir)') { return "code-stream" }
    if ($Name -match '^(ExeFile|ExeFile2|RunFile|RunFile2|LastFun)$') { return "execution-entry" }
    if ($Name -match '^(ExePrint|ExePrint2|ExePutS|ExePutS2|StreamExePrint|StreamPrint)$') { return "output-stream" }
    if ($Name -match '^(PassTrace|Trace)$') { return "trace-debug" }
    if ($Name -match '^(ClassMemberLstDel|MemberLstDel|MemberMetaData)$') { return "class-metadata" }
    if ($Name -match '^(Ui|Un)$') { return "builtin-types" }
    return "other"
}

function Add-CompilerFile {
    param(
        [array]$Html,
        [string]$Title,
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $Html += "<section>"
        $Html += "  <h2>$(HtmlEscape $Title)</h2>"
        $Html += "  <pre>missing: $(HtmlEscape (RepoPath $Path))</pre>"
        $Html += "</section>"
        return $Html
    }

    $jsonText = & $ToolPath outline $Path --json
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $data = $jsonText | ConvertFrom-Json
    $items = @($data.items)
    $classes = @($items | Where-Object { $_.kind -eq "class" })
    $functions = @($items | Where-Object { $_.kind -eq "function" })
    $includes = @($items | Where-Object { $_.kind -eq "include" })
    $areas = @($items | Group-Object { CompilerAreaName $_.name } | Sort-Object Count -Descending)

    $Html += "<section>"
    $Html += "  <h2>$(HtmlEscape $Title)</h2>"
    $Html += "  <pre>file: $(HtmlEscape (RepoPath $Path))"
    $Html += "items: $($items.Count)"
    $Html += "classes: $($classes.Count)"
    $Html += "functions: $($functions.Count)"
    $Html += "includes: $($includes.Count)"
    $Html += "tokens: $($data.tokens)"
    $Html += "status: ok</pre>"
    $Html += "</section>"

    $Html += "<section>"
    $Html += "  <h2>$(HtmlEscape $Title) Areas</h2>"
    $Html += "  <table>"
    foreach ($row in $areas) {
        $samples = @($row.Group | Sort-Object line,column | Select-Object -First 18 | ForEach-Object { $_.name }) -join ", "
        $Html += "    <tr><td>$(HtmlEscape $row.Name)</td><td>$($row.Count)</td><td>$(HtmlEscape $samples)</td></tr>"
    }
    $Html += "  </table>"
    $Html += "</section>"

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
$compilerA = Join-Path $root "Compiler/CompilerA.HH"
$compilerB = Join-Path $root "Compiler/CompilerB.HH"

$html = @()
$html += "<h1>COMPILER CONTRACT ARCHAEOLOGY</h1>"
$html += "<section>"
$html += "  <h2>Root</h2>"
$html += "  <pre>$(HtmlEscape (RepoPath $root))</pre>"
$html += "</section>"
$html += "<section>"
$html += "  <h2>Reading Rule</h2>"
$html += "  <pre>CompilerA is the front contract loaded before KernelB/KernelC."
$html += "CompilerB is loaded after KernelC and completes the compiler contract surface."
$html += "Read this as declarations and compiler pressure, not implementation proof.</pre>"
$html += "</section>"

$html = Add-CompilerFile $html "CompilerA Contract" $compilerA
$html = Add-CompilerFile $html "CompilerB Contract" $compilerB

$html | Set-Content -Encoding utf8 (Join-Path $OutDir "COMPILER-CONTRACT.md")

Write-Host "compiler-contract: $OutDir"
