# LOSETHOS RESEARCH NEXT PASS

This branch starts from `2bb357b`, after the LoseThos contract report was surfaced in findings.

Architecture image experiments are not part of this branch.

## Current evidence

LoseThos source archaeology is now visible as its own target, not as a TempleOS clone.

Known line from the generated reports:

```txt
holy-files: 119
tokens: 408900
functions: 1461
classes: 118
includes: 81
resolved-includes: 81
missing-includes: 0
```

## Read order

1. `reports/archaeology/losethos/source-map.txt`
2. `reports/archaeology/losethos/include-resolve.md`
3. `reports/archaeology/losethos/REVERSE.md`
4. `reports/archaeology/losethos/LOSETHOS-CONTRACT.md`
5. `reports/archaeology/losethos/ARCHAEOLOGY-FINDINGS.md`

## Main comparison line

TempleOS has its later `StartOS`, `KernelA`, `CompilerA/B`, `Adam`, desktop, and subsystem reports.

LoseThos must be read through its own anchors:

```txt
OSMain/OS.ASZ
OSMain/ADAMK.CPZ
OSMain/ADAMK.HPZ
OSMain/ADAMK2.HPZ
OSMain/ADAMK3.HPZ
ADAM/ADAM2.CPZ
COMPILE/CMP.ASZ
COMPILE/CMP.HPZ
COMPILE/CMP.MPZ
UTILS/BOOTHD.ASZ
UTILS/BOOTCD2.ASZ
UTILS/BOOTRAM.CPZ
```

## Next work

1. Compare TempleOS boot chain with LoseThos `OSMain/OS.ASZ`.
2. Compare TempleOS kernel contract pressure with LoseThos `ADAMK` headers.
3. Compare TempleOS compiler contract with LoseThos `COMPILE/CMP.ASZ` and `COMPILE/CMP.HPZ`.
4. Compare Adam layer shape through `ADAM/ADAM2.CPZ`.
5. Mark renamed, absent, smaller, or structurally earlier surfaces.

## Boundary

This is source archaeology.

Reports are evidence maps.

No target source tree should be rewritten by this project.
