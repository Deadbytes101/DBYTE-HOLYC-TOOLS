# LoseThos Codegen Archaeology Milestone

This milestone records the current evidence-backed model for the LoseThos compiler codegen surface.

## Boundary

This project does not compile, execute, rewrite, or mutate the LoseThos source tree. All claims here are generated-report evidence from read-only lexical archaeology.

## Evidence chain

The codegen path currently resolves as:

```text
COMPILE/CMP.MPZ
  -> exported compiler/link map surface
COMPILE/CODE.ASZ
  -> code-template substrate
ICT / UCT / DCT
  -> complete 285-suffix parallel code-template triad
COMPILE/LEX.CPZ
  -> exported table symbols and fix-up format constants
COMPILE/COMPILE.CPZ::FillCompilerTables
  -> fix-up table assignment and EC_* to FUT_* grammar mapping
```

## Main findings

`CMP.MPZ` is treated as a compiler/link map surface, not as a normal code body.

`CODE.ASZ` is table-shaped and contains three complete parallel families:

```text
ICT: 285 labels
UCT: 285 labels
DCT: 285 labels
shared suffix space: 285
missing ICT/UCT/DCT suffixes: 0
```

`UCT` is the primary body-heavy family. `ICT` carries signed/integer-special bodies. `DCT` carries sparse double/FPU bodies.

`LEX.CPZ` exposes table symbols such as:

```text
code_table
unsigned_code_table
double_code_table
internal_types_table
signed_fix_up_table
unsigned_fix_up_table
double_fix_up_table
```

`COMPILE.CPZ::FillCompilerTables` assigns unsigned, signed, and double fix-up table regions and maps `EC_*` entries to `FUT_*` fix-up formats.

## Fix-up grammar model

The generated fix-up comparison currently shows:

```text
unique EC codes: 116
present in all three tables: 8
present in unsigned+signed only: 50
present in unsigned only: 57
format disagreements: 28
```

The all-three shared grammar is branch/skip oriented. The shared entries are comparison skip forms that map consistently to `FUT_8_JMP_1` or `FUT_32_JMP_4`.

The largest divergence is in address/immediate encoding. Signed and unsigned lanes disagree mostly on displacement/immediate formats such as `FUT_8_1` versus `FUT_8_2`, and `FUT_32_4` versus `FUT_32_5`.

Unsigned-only grammar contains broad generic compiler machinery such as call, frame, push/literal, U8/double literal, string/type, bit/shift, and selected branch forms.

## Generated reports

The deep archaeology runner is expected to generate these codegen reports:

```text
LOSETHOS-PRESSURE-OUTLINE.md
LOSETHOS-DENSE-SURFACE.md
LOSETHOS-CMP-MAP.md
LOSETHOS-CODE-TABLE.md
LOSETHOS-CODE-FAMILIES.md
LOSETHOS-CODE-TRIADS.md
LOSETHOS-CODE-TRIAD-SUMMARY.md
LOSETHOS-COMPILER-CODEGEN-CORRELATE.md
LOSETHOS-COMPILER-EXPORT-CONTEXT.md
LOSETHOS-FILL-TABLES.md
LOSETHOS-FIXUP-TABLES.md
LOSETHOS-FIXUP-COMPARE.md
LOSETHOS-FIXUP-GRAMMAR.md
LOSETHOS-CODEGEN-STATE.md
```

Run:

```powershell
.\scripts\run-losethos-deep-archaeology.ps1 -LoseThos "D:\TECHNICAL\LoseThos-extracted\LT_EXE\LT"
```

or through the main archaeology workflow:

```powershell
.\scripts\run-archaeology.ps1 -LoseThos "D:\TECHNICAL\LoseThos-extracted\LT_EXE\LT" -DeepLoseThos
```

## Current milestone state

The codegen/fix-up archaeology milestone is considered evidence-complete at the lexical level.

Useful future work should avoid adding more broad scans unless a specific question arises. Good next steps are:

1. Add verification coverage for the deep runner scripts.
2. Keep generated reports out of source unless intentionally archived.
3. Split `unsigned_code_table` patching into a focused report only if that patching path becomes a research target.
4. Compare this LoseThos codegen model against TempleOS only after a complete TempleOS source tree is available.
