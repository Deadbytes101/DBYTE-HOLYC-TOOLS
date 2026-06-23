# DBYTE HOLYC TOOLS

Windows-native read-only source navigator for HolyC, LoseThos, and TempleOS-style trees.

Final line: `v1.6.0 FINAL`

No source rewrite. No formatter. No VM. No fake C parser.

It scans HolyC-style source, indexes symbols/includes, checks include resolution, finds likely entry files, and emits deterministic text/JSON reports.

## Build

```powershell
cargo build --release -p holytools
```

Binary:

```txt
target/release/holytools.exe
```

## Commands

```txt
holytools version
holytools scan <path> [--json]
holytools stats <path> [--json]
holytools source-map <path> [--json]
holytools missing-includes <path> [--json]
holytools entrypoints <path> [--json]
holytools tokens <file>
holytools outline <file> [--json]
holytools symbols <path> [--json]
holytools find-symbol <path> <name> [--json]
holytools includes <path> [--json]
holytools include-graph <path> [--json]
holytools resolve-includes <path> [--json]
holytools dependency-order <path> [--json]
holytools reverse-includes <path> [--json]
```

## Fast path

```powershell
holytools source-map tests/fixtures/tiny
holytools missing-includes tests/fixtures/tiny
holytools entrypoints tests/fixtures/tiny
```

## Report pack

```powershell
./scripts/report.ps1 tests/fixtures/tiny reports/tiny
```

The report directory contains text and JSON output for:

```txt
version
source-map
missing-includes
entrypoints
dependency-order
reverse-includes
```

## Package

```powershell
./scripts/package-windows.ps1
./scripts/verify-package.ps1
./scripts/package-zip.ps1
```

Output:

```txt
dist/dbyte-holyc-tools-windows/
dist/dbyte-holyc-tools-windows.zip
dist/dbyte-holyc-tools-windows.zip.sha256
```

Package contents:

```txt
holytools.exe
README.md
CHANGELOG.md
VERSION.txt
SHA256SUMS.txt
MANIFEST.txt
scripts/check-includes.ps1
scripts/report.ps1
```

## Release gate

```powershell
./scripts/release.ps1 v1.6.0
```

The gate runs format check, workspace check, tests, CLI verification, package verification, ZIP creation, clean tree check, and tag push.

## Verify

```powershell
./scripts/verify.ps1
```

Current smoke line:

```txt
10 cli smoke tests
```

## Rules

```txt
read-only by default
HolyC compatibility first
deterministic output
no source mutation
```
