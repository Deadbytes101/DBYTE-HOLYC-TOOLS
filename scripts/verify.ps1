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

Invoke-Step { cargo fmt --check }
Invoke-Step { cargo check --workspace }
Invoke-Step { cargo test --workspace }
Invoke-Step { cargo run -q -p holytools -- version }
Invoke-Step { cargo run -q -p holytools -- scan tests/fixtures/tiny }
Invoke-Step { cargo run -q -p holytools -- stats tests/fixtures/tiny }
Invoke-Step { cargo run -q -p holytools -- source-map tests/fixtures/tiny }
Invoke-Step { cargo run -q -p holytools -- source-map tests/fixtures/tiny --json }
Invoke-Step { cargo run -q -p holytools -- missing-includes tests/fixtures/tiny }
Invoke-Step { cargo run -q -p holytools -- missing-includes tests/fixtures/tiny --json }
Invoke-Step { cargo run -q -p holytools -- missing-includes tests/fixtures/missing }
Invoke-Step { cargo run -q -p holytools -- missing-includes tests/fixtures/missing --json }
Invoke-Step { cargo run -q -p holytools -- entrypoints tests/fixtures/tiny }
Invoke-Step { cargo run -q -p holytools -- entrypoints tests/fixtures/tiny --json }
Invoke-Step { cargo run -q -p holytools -- tokens tests/fixtures/tiny/hello.HC }
Invoke-Step { cargo run -q -p holytools -- outline tests/fixtures/tiny/hello.HC }
Invoke-Step { cargo run -q -p holytools -- symbols tests/fixtures/tiny }
Invoke-Step { cargo run -q -p holytools -- find-symbol tests/fixtures/tiny Add }
Invoke-Step { cargo run -q -p holytools -- includes tests/fixtures/tiny }
Invoke-Step { cargo run -q -p holytools -- include-graph tests/fixtures/tiny }
Invoke-Step { cargo run -q -p holytools -- resolve-includes tests/fixtures/tiny }
Invoke-Step { cargo run -q -p holytools -- resolve-includes tests/fixtures/tiny --json }
Invoke-Step { cargo run -q -p holytools -- dependency-order tests/fixtures/tiny }
Invoke-Step { cargo run -q -p holytools -- dependency-order tests/fixtures/tiny --json }
Invoke-Step { cargo run -q -p holytools -- reverse-includes tests/fixtures/tiny }
Invoke-Step { cargo run -q -p holytools -- reverse-includes tests/fixtures/tiny --json }
Invoke-Step { ./scripts/check-includes.ps1 tests/fixtures/tiny }

Write-Host "verify: ok"
