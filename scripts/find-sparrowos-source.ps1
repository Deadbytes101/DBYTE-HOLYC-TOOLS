param(
    [string[]]$Roots = @("D:\TECHNICAL", "D:\src", "D:\Downloads", "D:\", "C:\"),
    [int]$MaxResults = 30
)

$ErrorActionPreference = "Stop"

function Is-IgnoredPath {
    param([string]$Path)
    $lower = $Path.ToLowerInvariant()
    return (
        $lower -like "*\dbbyte-holyc-tools\third_party\source\templeos*" -or
        $lower -like "*\dbyte-holyc-tools\third_party\source\templeos*" -or
        $lower -like "*\third_party\source\templeos*" -or
        $lower -like "*\templeos*"
    )
}

function Add-Candidate {
    param(
        [hashtable]$Candidates,
        [string]$Path,
        [string]$Hit,
        [int]$Score,
        [string]$Reason
    )

    if (Is-IgnoredPath $Path) {
        return
    }

    $key = $Path.ToLowerInvariant()
    if (-not $Candidates.ContainsKey($key) -or $Candidates[$key].score -lt $Score) {
        $Candidates[$key] = [pscustomobject]@{
            score = $Score
            path = $Path
            hit = $Hit
            reason = $Reason
        }
    }
}

$candidates = @{}

foreach ($root in $Roots) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        continue
    }

    Write-Host "scan root: $root"

    $nameMatches = @(Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '(?i)sparrow' } |
        Select-Object -First ($MaxResults * 4))

    foreach ($match in $nameMatches) {
        $dir = if ($match.PSIsContainer) { $match.FullName } else { $match.Directory.FullName }
        $score = 20
        if ($dir -match '(?i)sparrow') { $score += 10 }
        foreach ($child in @("Kernel", "Compiler", "Adam", "Apps", "Demo", "System", "OSMain", "COMPILE", "ADAM")) {
            if (Test-Path -LiteralPath (Join-Path $dir $child) -PathType Container) {
                $score += 2
            }
        }
        foreach ($sentinel in @("StartOS.HC", "MakeOS.HC", "KernelA.HH", "CompilerA.HH", "AdamA.HC")) {
            if (Test-Path -LiteralPath (Join-Path $dir $sentinel) -PathType Leaf) {
                $score += 2
            }
        }
        Add-Candidate -Candidates $candidates -Path $dir -Hit $match.FullName -Score $score -Reason "sparrow-name-match"
    }
}

$results = @(
    $candidates.Values |
        Sort-Object -Property @{ Expression = "score"; Descending = $true }, @{ Expression = "path"; Ascending = $true } |
        Select-Object -First $MaxResults
)

if ($results.Count -eq 0) {
    Write-Host "no SparrowOS source candidates found"
    Write-Host "TempleOS-looking paths are intentionally ignored to avoid false positives."
    Write-Host "Try roots where the SparrowOS archive/source was extracted, for example:"
    Write-Host '.\scripts\find-sparrowos-source.ps1 -Roots D:\TECHNICAL,D:\src,D:\Downloads'
    Write-Host "If you only have an archive, extract it first, then rerun this finder."
    exit 0
}

Write-Host "SparrowOS source candidates:"
foreach ($result in $results) {
    Write-Host ("score={0} path={1}" -f $result.score, $result.path)
    Write-Host ("  reason={0}" -f $result.reason)
    Write-Host ("  hit={0}" -f $result.hit)
}

Write-Host ""
Write-Host "Import with:"
Write-Host '.\scripts\import-third-party-sources.ps1 -SparrowOS "<candidate-path>" -Force'
