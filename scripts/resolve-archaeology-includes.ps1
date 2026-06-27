param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$OutDir,

    [string]$ToolPath = "target/release/holytools.exe"
)

$ErrorActionPreference = "Stop"

function Convert-RepoPath {
    param([string]$Path)
    $Path.Replace([char]92, [char]47)
}

function Get-RootRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $rootValue = Convert-RepoPath $Root
    $pathValue = Convert-RepoPath $Path
    if ($pathValue.StartsWith($rootValue + "/")) {
        return $pathValue.Substring($rootValue.Length + 1)
    }
    return $pathValue
}

function Get-TargetVariants {
    param([string]$Target)

    $value = (Convert-RepoPath $Target).Trim().TrimStart('/')
    $variants = New-Object System.Collections.Generic.List[string]

    function Add-Variant {
        param([string]$Variant)
        if ([string]::IsNullOrWhiteSpace($Variant)) { return }
        $normalized = (Convert-RepoPath $Variant).Trim().TrimStart('/')
        if (-not $variants.Contains($normalized)) {
            $variants.Add($normalized)
        }
    }

    Add-Variant $value

    $extension = [System.IO.Path]::GetExtension($value)
    $withoutExtension = if ($extension) { $value.Substring(0, $value.Length - $extension.Length) } else { $value }
    $legacyExtensions = @('.HC', '.CPZ', '.HPZ', '.ASZ', '.MPZ')

    if ([string]::IsNullOrWhiteSpace($extension)) {
        foreach ($legacy in $legacyExtensions) {
            Add-Variant ($withoutExtension + $legacy)
        }
    } elseif ($extension.Equals('.HC', [System.StringComparison]::OrdinalIgnoreCase)) {
        foreach ($legacy in $legacyExtensions) {
            Add-Variant ($withoutExtension + $legacy)
        }
    }

    return @($variants)
}

function Resolve-LegacyInclude {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$SourceFile,

        [Parameter(Mandatory = $true)]
        [string]$Target,

        [Parameter(Mandatory = $true)]
        [hashtable]$RelativeIndex,

        [Parameter(Mandatory = $true)]
        [hashtable]$NameIndex
    )

    $rootValue = Convert-RepoPath $Root
    $rootName = Split-Path -Leaf $Root
    $sourceParent = Split-Path -Parent $SourceFile
    $candidateTargets = New-Object System.Collections.Generic.List[string]

    foreach ($variant in (Get-TargetVariants $Target)) {
        if (-not $candidateTargets.Contains($variant)) {
            $candidateTargets.Add($variant)
        }

        if ($rootName -and $variant.StartsWith($rootName + '/', [System.StringComparison]::OrdinalIgnoreCase)) {
            $stripped = $variant.Substring($rootName.Length + 1)
            if (-not $candidateTargets.Contains($stripped)) {
                $candidateTargets.Add($stripped)
            }
        }
    }

    foreach ($candidate in $candidateTargets) {
        $paths = @(
            (Join-Path $sourceParent $candidate),
            (Join-Path $rootValue $candidate)
        )

        foreach ($path in $paths) {
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                return Convert-RepoPath (Resolve-Path -LiteralPath $path).Path
            }
        }

        $relativeKey = $candidate.ToLowerInvariant()
        if ($RelativeIndex.ContainsKey($relativeKey)) {
            return $RelativeIndex[$relativeKey]
        }
    }

    foreach ($candidate in $candidateTargets) {
        $fileName = [System.IO.Path]::GetFileName($candidate).ToLowerInvariant()
        if ($NameIndex.ContainsKey($fileName)) {
            $matches = @($NameIndex[$fileName])
            if ($matches.Count -eq 1) {
                return $matches[0]
            }
        }
    }

    return ""
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

$root = Convert-RepoPath (Resolve-Path -LiteralPath $SourcePath).Path
$sourceFiles = @(Get-ChildItem -LiteralPath $SourcePath -Recurse -File -Include *.HC,*.HH,*.ZC,*.ZH,*.CPZ,*.HPZ,*.ASZ,*.MPZ)
$relativeIndex = @{}
$nameIndex = @{}

foreach ($file in $sourceFiles) {
    $full = Convert-RepoPath (Resolve-Path -LiteralPath $file.FullName).Path
    $relative = (Get-RootRelativePath $root $full).ToLowerInvariant()
    $relativeIndex[$relative] = $full

    $fileName = $file.Name.ToLowerInvariant()
    if (-not $nameIndex.ContainsKey($fileName)) {
        $nameIndex[$fileName] = @()
    }
    $nameIndex[$fileName] = @($nameIndex[$fileName]) + $full
}

$jsonText = & $ToolPath resolve-includes $SourcePath --json
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$data = $jsonText | ConvertFrom-Json
$rows = @()

foreach ($include in $data.includes) {
    $file = Convert-RepoPath ([string]$include.file)
    $target = [string]$include.target
    $status = [string]$include.status
    $resolved = Convert-RepoPath ([string]$include.resolved)

    if ($status -ne "resolved" -or [string]::IsNullOrWhiteSpace($resolved)) {
        $legacyResolved = Resolve-LegacyInclude $root $file $target $relativeIndex $nameIndex
        if (-not [string]::IsNullOrWhiteSpace($legacyResolved)) {
            $status = "resolved"
            $resolved = $legacyResolved
        } else {
            $status = "missing"
            $resolved = ""
        }
    }

    $rows += [pscustomobject]@{
        file = $file
        line = [int]$include.line
        column = [int]$include.column
        target = $target
        status = $status
        resolved = $resolved
    }
}

$resolvedCount = @($rows | Where-Object { $_.status -eq "resolved" }).Count
$missingCount = @($rows | Where-Object { $_.status -eq "missing" }).Count

[pscustomobject]@{
    source = $root
    includes = $rows.Count
    resolved = $resolvedCount
    missing = $missingCount
    rows = $rows
} | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $OutDir "include-resolve.json")

$text = @()
foreach ($row in $rows) {
    $text += ("{0}:{1}:{2}`t{3}`t{4}`t{5}" -f $row.file, $row.line, $row.column, $row.target, $row.status, $row.resolved)
}
$text += ("resolved: {0}" -f $resolvedCount)
$text += ("missing: {0}" -f $missingCount)
$text += "status: ok"
$text | Set-Content -Encoding utf8 (Join-Path $OutDir "include-resolve.txt")

$html = @()
$html += "<section>"
$html += "  <h2>Include Resolve</h2>"
$html += "  <pre>includes: $($rows.Count)"
$html += "resolved: $resolvedCount"
$html += "missing: $missingCount"
$html += "status: ok</pre>"
$html += "</section>"
$html | Set-Content -Encoding utf8 (Join-Path $OutDir "include-resolve.md")

Write-Host "include-resolve: $OutDir"
