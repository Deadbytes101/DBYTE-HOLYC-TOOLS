# DBYTE HOLYC TOOLS

Windows-native read-only source tools for HolyC, LoseThos, and TempleOS-style code.

This project starts as a scanner and indexer. It does not fork TempleOS and does not rewrite source files.

## Commands

```txt
holytools version
holytools scan <path>
holytools stats <path>
holytools tokens <file>
holytools symbols <path>
holytools includes <path>
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
