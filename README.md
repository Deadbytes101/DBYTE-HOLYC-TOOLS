# DBYTE HOLYC TOOLS

Windows-native read-only source navigator for HolyC, LoseThos, and TempleOS-style code.

This project does not fork TempleOS and does not rewrite source files. It reads HolyC-style source trees and emits deterministic text or JSON reports for inspection, indexing, source archaeology, and navigation.

## Status

`v1.6.0` is the current zip packaging release for the read-only source navigator line.

It provides:

- tokenizer output for a single HolyC file
- tree stats for HolyC source roots
- source-map summary output for source tree overview
- missing include listing for source tree repair
- entrypoint listing for files with no resolved incoming include
- source tree report generation into text and JSON files
- packaged support scripts for include checks and report generation
- local ZIP packaging with SHA256 sidecar output
- symbol listing and exact symbol lookup
- file outline for includes, classes, and functions
- include listing and include graph output
- include resolution with missing/resolved status
- dependency-first source ordering
- reverse include lookup
- include checking script for CI-style missing include failure
- Windows package output with manifest, version file, and SHA256 checksum
- CLI smoke tests for the shipped `holytools` binary

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

## Scripts

```powershell
./scripts/verify.ps1
./scripts/check-includes.ps1 tests/fixtures/tiny
./scripts/report.ps1 tests/fixtures/tiny reports/tiny
./scripts/package-windows.ps1
./scripts/verify-package.ps1
./scripts/package-zip.ps1
./scripts/release.ps1 v1.6.0
```

## Report

Generate a source tree report directory:

```powershell
./scripts/report.ps1 tests/fixtures/tiny reports/tiny
```

The report directory contains text and JSON outputs for version, source-map, missing-includes, entrypoints, dependency-order, and reverse-includes.

## Package

The Windows package is written to:

```txt
dist/dbyte-holyc-tools-windows
```

The ZIP package is written to:

```txt
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

Packaged scripts use the packaged `holytools.exe` when they are run from the package directory.

## Release

Run the full release gate and push a tag with one command:

```powershell
./scripts/release.ps1 v1.6.0
```

The release script verifies formatting, builds, tests, source reports, package output, package manifest, package version text, SHA256 checksum, creates the ZIP package, verifies clean working tree, and checks remote tag state before pushing a tag.

## Example workflow

```powershell
holytools source-map tests/fixtures/tiny
holytools missing-includes tests/fixtures/tiny
holytools entrypoints tests/fixtures/tiny
./scripts/report.ps1 tests/fixtures/tiny reports/tiny
./scripts/package-zip.ps1
./scripts/check-includes.ps1 tests/fixtures/tiny
```

## Rules

- Read-only by default.
- Original HolyC / LoseThos / TempleOS source compatibility comes first.
- Do not pretend HolyC is ordinary C.
- Keep output deterministic and easy to diff.
- Do not rewrite source files without an explicit future write mode.

## Verify

```powershell
./scripts/verify.ps1
```
