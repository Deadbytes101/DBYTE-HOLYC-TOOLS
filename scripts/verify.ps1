$ErrorActionPreference = "Stop"

cargo fmt --check
cargo check --workspace
cargo test --workspace
cargo run -q -p holytools -- version
cargo run -q -p holytools -- scan tests/fixtures/tiny
cargo run -q -p holytools -- scan tests/fixtures/tiny --json
cargo run -q -p holytools -- stats tests/fixtures/tiny
cargo run -q -p holytools -- stats tests/fixtures/tiny --json
cargo run -q -p holytools -- tokens tests/fixtures/tiny/hello.HC
cargo run -q -p holytools -- symbols tests/fixtures/tiny
cargo run -q -p holytools -- symbols tests/fixtures/tiny --json
cargo run -q -p holytools -- includes tests/fixtures/tiny
cargo run -q -p holytools -- includes tests/fixtures/tiny --json

Write-Host "verify: ok"
