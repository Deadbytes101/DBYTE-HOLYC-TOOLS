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

function ReadJson {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
    }
    return $null
}

function Get-RootRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $rootValue = RepoPath $Root
    $pathValue = RepoPath $Path
    if ($pathValue.StartsWith($rootValue + "/", [System.StringComparison]::OrdinalIgnoreCase)) {
        return $pathValue.Substring($rootValue.Length + 1)
    }
    return $pathValue
}

function Resolve-AnchorPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $path = Join-Path $Root $RelativePath
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        return (Resolve-Path -LiteralPath $path).Path
    }
    return ""
}

function Get-EdgesForFile {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Rows,

        [Parameter(Mandatory = $true)]
        [string]$File
    )

    $fileValue = RepoPath $File
    return @($Rows | Where-Object { (RepoPath ([string]$_.file)).Equals($fileValue, [System.StringComparison]::OrdinalIgnoreCase) } | Sort-Object line,column,target)
}

function Add-AnchorTable {
    param(
        [array]$Html,
        [string]$Root,
        [array]$Rows,
        [array]$Anchors
    )

    $Html += "<section>"
    $Html += "  <h2>Candidate Contract Anchors</h2>"
    $Html += "  <table>"
    $Html += "    <tr><th>role</th><th>file</th><th>status</th><th>outgoing-includes</th></tr>"
    foreach ($anchor in $Anchors) {
        $path = Resolve-AnchorPath $Root $anchor.Path
        if ([string]::IsNullOrWhiteSpace($path)) {
            $Html += "    <tr><td>$(HtmlEscape $anchor.Role)</td><td>$(HtmlEscape $anchor.Path)</td><td>missing</td><td>0</td></tr>"
            continue
        }

        $edges = Get-EdgesForFile $Rows $path
        $Html += "    <tr><td>$(HtmlEscape $anchor.Role)</td><td>$(HtmlEscape $anchor.Path)</td><td>present</td><td>$($edges.Count)</td></tr>"
    }
    $Html += "  </table>"
    $Html += "</section>"
    return $Html
}

function Add-EdgeSection {
    param(
        [array]$Html,
        [string]$Title,
        [string]$Root,
        [array]$Rows,
        [string[]]$RelativePaths
    )

    $Html += "<section>"
    $Html += "  <h2>$(HtmlEscape $Title)</h2>"
    $Html += "  <table>"
    $Html += "    <tr><th>from</th><th>line</th><th>target</th><th>status</th><th>resolved</th></tr>"

    foreach ($relativePath in $RelativePaths) {
        $path = Resolve-AnchorPath $Root $relativePath
        if ([string]::IsNullOrWhiteSpace($path)) {
            $Html += "    <tr><td>$(HtmlEscape $relativePath)</td><td>-</td><td>-</td><td>missing anchor</td><td>-</td></tr>"
            continue
        }

        $edges = Get-EdgesForFile $Rows $path
        if ($edges.Count -eq 0) {
            $Html += "    <tr><td>$(HtmlEscape $relativePath)</td><td>-</td><td>-</td><td>no outgoing include</td><td>-</td></tr>"
            continue
        }

        foreach ($edge in $edges) {
            $resolved = [string]$edge.resolved
            if (-not [string]::IsNullOrWhiteSpace($resolved)) {
                $resolved = Get-RootRelativePath $Root $resolved
            }
            $Html += "    <tr><td>$(HtmlEscape $relativePath)</td><td>$($edge.line)</td><td>$(HtmlEscape ([string]$edge.target))</td><td>$(HtmlEscape ([string]$edge.status))</td><td>$(HtmlEscape $resolved)</td></tr>"
        }
    }

    $Html += "  </table>"
    $Html += "</section>"
    return $Html
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    Write-Error "missing source tree: $SourcePath"
    exit 1
}

New-Item -ItemType Directory -Force $OutDir | Out-Null

$root = (Resolve-Path -LiteralPath $SourcePath).Path
$sourceMap = ReadJson (Join-Path $OutDir "source-map.json")
$includeResolve = ReadJson (Join-Path $OutDir "include-resolve.json")
$includeRows = @()
if ($includeResolve -and $includeResolve.rows) {
    $includeRows = @($includeResolve.rows)
}

$anchors = @(
    [pscustomobject]@{ Role = "OS load manifest"; Path = "OSMain/OS.ASZ" },
    [pscustomobject]@{ Role = "OS map"; Path = "OSMain/OS.MPZ" },
    [pscustomobject]@{ Role = "kernel/Adam bridge"; Path = "OSMain/ADAMK.CPZ" },
    [pscustomobject]@{ Role = "kernel header A"; Path = "OSMain/ADAMK.HPZ" },
    [pscustomobject]@{ Role = "kernel header B"; Path = "OSMain/ADAMK2.HPZ" },
    [pscustomobject]@{ Role = "kernel header C"; Path = "OSMain/ADAMK3.HPZ" },
    [pscustomobject]@{ Role = "Adam manifest"; Path = "ADAM/ADAM2.CPZ" },
    [pscustomobject]@{ Role = "compiler manifest"; Path = "COMPILE/CMP.ASZ" },
    [pscustomobject]@{ Role = "compiler header"; Path = "COMPILE/CMP.HPZ" },
    [pscustomobject]@{ Role = "compiler map"; Path = "COMPILE/CMP.MPZ" },
    [pscustomobject]@{ Role = "hard-disk boot"; Path = "UTILS/BOOTHD.ASZ" },
    [pscustomobject]@{ Role = "CD boot"; Path = "UTILS/BOOTCD2.ASZ" },
    [pscustomobject]@{ Role = "RAM boot"; Path = "UTILS/BOOTRAM.CPZ" }
)

$hotspots = @()
if ($includeRows.Count -gt 0) {
    $hotspots = @($includeRows |
        Where-Object { $_.status -eq "resolved" -and -not [string]::IsNullOrWhiteSpace([string]$_.resolved) } |
        Group-Object resolved |
        Sort-Object Count -Descending |
        Select-Object -First 30)
}

$html = @()
$html += "<h1>LOSETHOS CONTRACT ARCHAEOLOGY</h1>"
$html += "<section>"
$html += "  <h2>Root</h2>"
$html += "  <pre>$(HtmlEscape (RepoPath $root))</pre>"
$html += "</section>"

if ($sourceMap) {
    $html += "<section>"
    $html += "  <h2>Source Shape</h2>"
    $html += "  <pre>holy-files: $($sourceMap.holy_files)"
    $html += "tokens: $($sourceMap.tokens)"
    $html += "functions: $($sourceMap.functions)"
    $html += "classes: $($sourceMap.classes)"
    $html += "includes: $($sourceMap.includes)"
    $html += "asm-blocks: $($sourceMap.asm_blocks)</pre>"
    $html += "</section>"
}

$html = Add-AnchorTable $html $root $includeRows $anchors
$html = Add-EdgeSection $html "OSMain Load Chain" $root $includeRows @("OSMain/OS.ASZ", "OSMain/ADAMK.CPZ")
$html = Add-EdgeSection $html "Compiler Load Chain" $root $includeRows @("COMPILE/CMP.ASZ")
$html = Add-EdgeSection $html "Adam Load Chain" $root $includeRows @("ADAM/ADAM2.CPZ", "ADAM/ADAMASM.ASZ")
$html = Add-EdgeSection $html "Boot Media Gates" $root $includeRows @("UTILS/BOOTHD.ASZ", "UTILS/BOOTCD2.ASZ", "UTILS/BOOTRAM.CPZ", "UTILS/BOOTFD.ASZ")

$html += "<section>"
$html += "  <h2>Resolved Include Hotspots</h2>"
$html += "  <table>"
$html += "    <tr><th>file</th><th>incoming-includes</th></tr>"
foreach ($row in $hotspots) {
    $relative = Get-RootRelativePath $root $row.Name
    $html += "    <tr><td>$(HtmlEscape $relative)</td><td>$($row.Count)</td></tr>"
}
$html += "  </table>"
$html += "</section>"

$html += "<section>"
$html += "  <h2>Reading Rule</h2>"
$html += "  <pre>Read this as a source-contract map, not runtime proof."
$html += "LoseThos legacy includes may use .HC names while files on disk use .CPZ, .ASZ, .HPZ, or .MPZ."
$html += "Resolved include edges prove file-level source references only."
$html += "Do not project TempleOS KernelA/CompilerA/MakeAdam names onto LoseThos.</pre>"
$html += "</section>"

$html | Set-Content -Encoding utf8 (Join-Path $OutDir "LOSETHOS-CONTRACT.md")

Write-Host "losethos-contract: $OutDir"
