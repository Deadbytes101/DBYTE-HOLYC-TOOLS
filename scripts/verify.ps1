$ErrorActionPreference = "Stop"

cargo check --workspace
cargo test --workspace
Write-Host "verify: ok"
