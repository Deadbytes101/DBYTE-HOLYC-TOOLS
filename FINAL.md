# DBYTE HOLYC TOOLS FINAL

Version: `1.0.0`

This is the final stable release for the current read-only HolyC source navigator line.

## Artifact

```txt
dbyte-holyc-tools-windows
```

## Package contents

```txt
holytools.exe
README.md
CHANGELOG.md
VERSION.txt
SHA256SUMS.txt
MANIFEST.txt
```

## Required verification

```powershell
cargo fmt --check
cargo check --workspace
cargo test --workspace
./scripts/verify.ps1
./scripts/package-windows.ps1
./scripts/verify-package.ps1
```

## Guarantees

- Read-only operation by default.
- No source rewriting.
- Deterministic text and JSON reports.
- Include resolution reports missing/resolved status.
- Dependency ordering is dependency-first.
- Package includes a version file, manifest, and SHA256 checksum.
- Package verification checks binary execution, version text, manifest entries, and checksum.
