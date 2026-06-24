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
        $resolvePath = Join-Path $Root "$target/include-resolve.json"
        $resolved = $json.resolved_includes
        $missing = $json.missing_includes

        if (Test-Path $resolvePath) {
            $resolve = Get-Content $resolvePath -Raw | ConvertFrom-Json
            $resolved = $resolve.resolved
            $missing = $resolve.missing
        }

        $rows += [pscustomobject]@{
            Name = $target
            Files = $json.holy_files
            Tokens = $json.tokens
            Functions = $json.functions
            Classes = $json.classes
            Includes = $json.includes
            AsmBlocks = $json.asm_blocks
            Resolved = $resolved
            Missing = $missing
            DependencyFiles = $json.dependency_files
            ReverseEdges = $json.reverse_edges
        }
    }
}

New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null

$lines = @()
$lines += "<h1>SOURCE ARCHAEOLOGY SUMMARY</h1>"
$lines += "<section>"
$lines += "  <h2>Counts</h2>"
$lines += "  <table>"
$lines += "    <tr><th>target</th><th>files</th><th>tokens</th><th>funcs</th><th>classes</th><th>includes</th><th>asm</th><th>resolved</th><th>missing</th><th>deps</th><th>reverse</th></tr>"

foreach ($row in $rows) {
    $lines += "    <tr><td>$($row.Name)</td><td>$($row.Files)</td><td>$($row.Tokens)</td><td>$($row.Functions)</td><td>$($row.Classes)</td><td>$($row.Includes)</td><td>$($row.AsmBlocks)</td><td>$($row.Resolved)</td><td>$($row.Missing)</td><td>$($row.DependencyFiles)</td><td>$($row.ReverseEdges)</td></tr>"
}

$lines += "  </table>"
$lines += "</section>"
$lines += "<section>"
$lines += "  <h2>Next</h2>"
$lines += "  <pre>templeos/source-map.txt"
$lines += "templeos/include-resolve.md"
$lines += "templeos/REVERSE.md"
$lines += "losethos/source-map.txt"
$lines += "sparrowos/source-map.txt</pre>"
$lines += "</section>"

$lines | Set-Content -Encoding utf8 $Out
Write-Host "summary: $Out"
