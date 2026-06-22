# DBYTE HOLYC TOOLS

Windows-native read-only source navigator for HolyC, LoseThos, and TempleOS-style code.

This project does not fork TempleOS and does not rewrite source files. It reads HolyC-style source trees and emits deterministic text or JSON reports for inspection, indexing, source archaeology, and navigation.

## Status

`v0.2.0` is the first source-navigator milestone.

It provides:

- tokenizer output for a single HolyC file
- tree stats for HolyC source roots
- symbol listing and exact symbol lookup
- file outline for includes, classes, and functions
- include listing and include graph output
- include resolution with missing/resolved status
- dependency-first source ordering
- reverse include lookup
- include checking script for CI-style missing include failure

## Commands

```txt
holytools version
holytools scan <path> [--json]
holytools stats <path> [--json]
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
./scripts/check-includes.ps1 tests/fixtures/tiny
./scripts/verify.ps1
```

## Example workflow

```powershell
holytools stats tests/fixtures/tiny
holytools outline tests/fixtures/tiny/hello.HC
holytools find-symbol tests/fixtures/tiny Add
holytools resolve-includes tests/fixtures/tiny
holytools dependency-order tests/fixtures/tiny
holytools reverse-includes tests/fixtures/tiny
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
