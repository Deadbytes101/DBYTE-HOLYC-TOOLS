param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $true
}

if ($Version -notmatch '^v\d+\.\d+\.\d+$') {
    Write-Error "version must look like v1.0.0"
    exit 1
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

Invoke-Step { git fetch origin --tags }
Invoke-Step { cargo fmt --check }
Invoke-Step { cargo check --workspace }
Invoke-Step { cargo test --workspace }
Invoke-Step { ./scripts/verify.ps1 }
Invoke-Step { ./scripts/package-windows.ps1 }
Invoke-Step { ./scripts/verify-package.ps1 }

$status = git status --short
if ($status) {
    Write-Host $status
    Write-Error "working tree is not clean"
    exit 1
}

$remoteTag = git ls-remote --tags origin "refs/tags/$Version"
if ($remoteTag) {
    Write-Host "$Version already exists on origin"
    exit 0
}

Invoke-Step { git tag $Version }
Invoke-Step { git push origin $Version }

Write-Host "release: $Version"
