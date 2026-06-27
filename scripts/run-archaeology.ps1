param(
    [string]$TempleOS,
    [string]$LoseThos,
    [string]$SparrowOS,
    [string]$Out = "reports/archaeology"
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $true
}

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command
    )

    & $Command
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

function Write-NotesTemplate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$TargetOut
    )

    $notes = Join-Path $TargetOut "NOTES.md"
    if (-not (Test-Path $notes)) {
        @(
            "<h1>$Name NOTES</h1>",
            "<section>",
            "  <h2>Where To Start</h2>",
            "  <pre></pre>",
            "</section>",
            "<section>",
            "  <h2>Core Files</h2>",
            "  <pre></pre>",
            "</section>",
            "<section>",
            "  <h2>Broken Includes</h2>",
            "  <pre></pre>",
            "</section>",
            "<section>",
            "  <h2>Entrypoint Candidates</h2>",
            "  <pre></pre>",
            "</section>",
            "<section>",
            "  <h2>Dependency Shape</h2>",
            "  <pre></pre>",
            "</section>",
            "<section>",
            "  <h2>Reverse Include Hotspots</h2>",
            "  <pre></pre>",
            "</section>",
            "<section>",
            "  <h2>Odd Symbols</h2>",
            "  <pre></pre>",
            "</section>",
            "<section>",
            "  <h2>What The Tool Can See</h2>",
            "  <pre></pre>",
            "</section>",
            "<section>",
            "  <h2>What The Tool Cannot See</h2>",
            "  <pre></pre>",
            "</section>"
        ) | Set-Content -Encoding utf8 $notes
    }
}

function Get-HolyFileCount {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetOut
    )

    $sourceMap = Join-Path $TargetOut "source-map.json"
    if (-not (Test-Path -LiteralPath $sourceMap -PathType Leaf)) {
        return $null
    }

    $json = Get-Content -LiteralPath $sourceMap -Raw | ConvertFrom-Json
    return [int]$json.holy_files
}

function Invoke-Target {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )

    if (-not (Test-Path $SourcePath)) {
        Write-Error "missing source tree: $SourcePath"
        exit 1
    }

    $targetOut = Join-Path $Out $Name
    Invoke-Step { ./scripts/report.ps1 $SourcePath $targetOut }
    Invoke-Step { ./scripts/resolve-archaeology-includes.ps1 -SourcePath $SourcePath -OutDir $targetOut }
    Invoke-Step { ./scripts/reverse-archaeology.ps1 -SourcePath $SourcePath -OutDir $targetOut }

    $holyFiles = Get-HolyFileCount $targetOut
    if ($null -ne $holyFiles -and $holyFiles -eq 0) {
        Invoke-Step { ./scripts/archaeology-findings.ps1 -SourcePath $SourcePath -OutDir $targetOut -TargetName $Name }
        Write-NotesTemplate $Name $targetOut
        Write-Host "archaeology: $Name -> $targetOut"
        Write-Host "archaeology: $Name has no supported HolyC source files; target-specific reports skipped"
        return
    }

    Invoke-Step { ./scripts/boot-chain-archaeology.ps1 -SourcePath $SourcePath -OutDir $targetOut }
    Invoke-Step { ./scripts/spine-archaeology.ps1 -SourcePath $SourcePath -OutDir $targetOut }

    if ($Name -eq "templeos") {
        Invoke-Step { ./scripts/kernel-contract-archaeology.ps1 -SourcePath $SourcePath -OutDir $targetOut }
        Invoke-Step { ./scripts/compiler-contract-archaeology.ps1 -SourcePath $SourcePath -OutDir $targetOut }
        Invoke-Step { ./scripts/adam-manifest-archaeology.ps1 -SourcePath $SourcePath -OutDir $targetOut }
        Invoke-Step { ./scripts/desktop-surface-archaeology.ps1 -SourcePath $SourcePath -OutDir $targetOut }
        Invoke-Step { ./scripts/adam-subsystems-archaeology.ps1 -SourcePath $SourcePath -OutDir $targetOut }
    } else {
        Write-Host "archaeology: $Name target-specific TempleOS reports skipped"
    }

    Invoke-Step { ./scripts/archaeology-findings.ps1 -SourcePath $SourcePath -OutDir $targetOut -TargetName $Name }

    Write-NotesTemplate $Name $targetOut

    Write-Host "archaeology: $Name -> $targetOut"
}

if ($TempleOS) {
    Invoke-Target "templeos" $TempleOS
}

if ($LoseThos) {
    Invoke-Target "losethos" $LoseThos
}

if ($SparrowOS) {
    Invoke-Target "sparrowos" $SparrowOS
}

if (-not $TempleOS -and -not $LoseThos -and -not $SparrowOS) {
    Write-Error "provide at least one source path: -TempleOS, -LoseThos, or -SparrowOS"
    exit 1
}

Invoke-Step { ./scripts/summarize-archaeology.ps1 $Out }
Write-Host "archaeology: ok"
