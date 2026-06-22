# DBYTE HOLYC TOOLS

Windows-native read-only source tools for HolyC, LoseThos, and TempleOS-style code.

This project starts as a scanner and indexer. It does not fork TempleOS and does not rewrite source files.

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
```

## Rules

- Read-only by default.
- Original HolyC / LoseThos / TempleOS source compatibility comes first.
- Do not pretend HolyC is ordinary C.
- Keep output deterministic and easy to diff.

## Verify

```powershell
./scripts/verify.ps1
```
