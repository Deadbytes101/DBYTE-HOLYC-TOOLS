$ErrorActionPreference = "Stop"

cargo fmt --check
cargo check --workspace
cargo test --workspace
cargo run -q -p holycli -- version
cargo run -q -p holycli -- scan tests/fixtures/tiny
cargo run -q -p holycli -- tokens tests/fixtures/tiny/hello.HC

Write-Host "verify: ok"
