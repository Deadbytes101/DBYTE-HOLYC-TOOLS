param(
    [string[]]$Roots = @("D:\TECHNICAL", "D:\src", "D:\", "C:\"),
    [int]$MaxResults = 30
)

$ErrorActionPreference = "Stop"

$sentinels = @(
    "StartOS.HC",
    "MakeOS.HC",
    "KernelA.HH",
    "CompilerA.HH",
    "AdamA.HC",
    "SparrowOS.HC",
    "SparrowOS.PRJ"
)

$candidates = @{}

foreach ($root in $Roots) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        continue
    }

    Write-Host "scan root: $root"

    foreach ($name in $sentinels) {
        $matches = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter $name -ErrorAction SilentlyContinue | Select-Object -First $MaxResults)
        foreach ($match in $matches) {
            $dir = $match.Directory.FullName
            $score = 1

            foreach ($sentinel in $sentinels) {
                if (Test-Path -LiteralPath (Join-Path $dir $sentinel) -PathType Leaf) {
                    $score += 3
                }
            }

            foreach ($child in @("Kernel", "Compiler", "Adam", "Apps", "Demo", "System", "OSMain", "COMPILE", "ADAM")) {
                if (Test-Path -LiteralPath (Join-Path $dir $child) -PathType Container) {
                    $score += 2
                }
            }

            $parent = Split-Path -Parent $dir
            if ($parent) {
                foreach ($sentinel in $sentinels) {
                    if (Test-Path -LiteralPath (Join-Path $parent $sentinel) -PathType Leaf) {
                        $score += 2
                    }
                }
                foreach ($child in @("Kernel", "Compiler", "Adam", "Apps", "Demo", "System", "OSMain", "COMPILE", "ADAM")) {
                    if (Test-Path -LiteralPath (Join-Path $parent $child) -PathType Container) {
                        $score += 1
                    }
                }
            }

            $key = $dir.ToLowerInvariant()
            if (-not $candidates.ContainsKey($key) -or $candidates[$key].score -lt $score) {
                $candidates[$key] = [pscustomobject]@{
                    score = $score
                    path = $dir
                    hit = $match.FullName
                }
            }
        }
    }
}

$results = @(
    $candidates.Values |
        Sort-Object -Property @{ Expression = "score"; Descending = $true }, @{ Expression = "path"; Ascending = $true } |
        Select-Object -First $MaxResults
)

if ($results.Count -eq 0) {
    Write-Host "no SparrowOS source candidates found"
    Write-Host "try passing narrower roots, for example:"
    Write-Host '.\scripts\find-sparrowos-source.ps1 -Roots D:\TECHNICAL,D:\src,D:\Downloads'
    exit 0
}

Write-Host "SparrowOS source candidates:"
foreach ($result in $results) {
    Write-Host ("score={0} path={1}" -f $result.score, $result.path)
    Write-Host ("  hit={0}" -f $result.hit)
}

Write-Host ""
Write-Host "Import with:"
Write-Host '.\scripts\import-third-party-sources.ps1 -SparrowOS "<candidate-path>" -Force'
