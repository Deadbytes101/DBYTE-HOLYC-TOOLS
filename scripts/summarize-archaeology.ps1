param(
    [string]$Root = "reports/archaeology",
    [string]$Out = "reports/archaeology/SUMMARY.md"
)

$ErrorActionPreference = "Stop"

$targets = @("templeos", "losethos", "sparrowos")
$rows = @()

foreach ($target in $targets) {
    $map = Join-Path $Root "$target/source-map.json"
    if (Test-Path $map) {
        $json = Get-Content $map -Raw | ConvertFrom-Json
        $rows += [pscustomobject]@{
            Name = $target
            Files = $json.holy_files
            Tokens = $json.tokens
            Functions = $json.functions
            Classes = $json.classes
            Includes = $json.includes
            AsmBlocks = $json.asm_blocks
            Resolved = $json.resolved_includes
            Missing = $json.missing_includes
            DependencyFiles = $json.dependency_files
            ReverseEdges = $json.reverse_edges
        }
    }
}

New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null

$lines = @()
$lines += "# SOURCE ARCHAEOLOGY SUMMARY"
$lines += ""
$lines += "| target | files | tokens | funcs | classes | includes | asm | resolved | missing | deps | reverse |"
$lines += "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|"

foreach ($row in $rows) {
    $lines += "| $($row.Name) | $($row.Files) | $($row.Tokens) | $($row.Functions) | $($row.Classes) | $($row.Includes) | $($row.AsmBlocks) | $($row.Resolved) | $($row.Missing) | $($row.DependencyFiles) | $($row.ReverseEdges) |"
}

$lines += ""
$lines += "## READ THIS FIRST"
$lines += ""
$lines += "Start with the tree that has the cleanest include graph."
$lines += "If missing includes are high, fix the source root path before making theories."
$lines += "If entrypoints are high, the tree may be split into many independent programs."
$lines += "If reverse edges are high, the tree has shared pressure points."
$lines += ""
$lines += "## NEXT FILES"
$lines += ""
$lines += "templeos/source-map.txt"
$lines += "templeos/entrypoints.txt"
$lines += "templeos/reverse-includes.txt"
$lines += "losethos/source-map.txt"
$lines += "sparrowos/source-map.txt"

$lines | Set-Content -Encoding utf8 $Out
Write-Host "summary: $Out"
