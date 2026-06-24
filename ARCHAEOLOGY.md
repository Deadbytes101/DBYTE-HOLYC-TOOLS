# SOURCE ARCHAEOLOGY

This repo ships the tool and keeps the dig site next to it.

`holytools` is frozen at `v1.6.0 FINAL`.

The archaeology work can grow after the binary line stops.

## Targets

```txt
TEMPLEOS
LOSETHOS
SPARROWOS
```

## Order

```txt
1. TEMPLEOS
2. LOSETHOS
3. SPARROWOS
```

TempleOS is the final tree to map first.

LoseThos is the middle layer.

SparrowOS is the older layer.

Do not compare everything before the first full map exists.

## Report layout

```txt
reports/archaeology/SUMMARY.md
reports/archaeology/templeos/
reports/archaeology/losethos/
reports/archaeology/sparrowos/
```

Each target report should contain:

```txt
version.txt
source-map.txt
source-map.json
missing-includes.txt
missing-includes.json
entrypoints.txt
entrypoints.json
dependency-order.txt
dependency-order.json
reverse-includes.txt
reverse-includes.json
NOTES.md
```

## First pass

Run the report script against each source tree.

```powershell
./scripts/run-archaeology.ps1 `
  -TempleOS D:/src/TempleOS `
  -LoseThos D:/src/LoseThos `
  -SparrowOS D:/src/SparrowOS
```

Run one target at a time if the trees are not all ready.

```powershell
./scripts/run-archaeology.ps1 -TempleOS D:/src/TempleOS
```

The runner writes target reports and refreshes:

```txt
reports/archaeology/SUMMARY.md
```

## Reading order

For every target:

```txt
1. source-map.txt
2. missing-includes.txt
3. entrypoints.txt
4. dependency-order.txt
5. reverse-includes.txt
6. NOTES.md
```

Then read the summary table.

```txt
reports/archaeology/SUMMARY.md
```

Do not start with opinions. Start with counts.

## What to extract

For each tree:

```txt
holy-files
functions
classes
includes
asm-blocks
resolved-includes
missing-includes
entrypoints
dependency-files
reverse-edges
```

Then write notes:

```txt
WHERE TO START
CORE FILES
BROKEN INCLUDES
ENTRYPOINT CANDIDATES
DEPENDENCY SHAPE
REVERSE INCLUDE HOTSPOTS
ODD SYMBOLS
WHAT THE TOOL CAN SEE
WHAT THE TOOL CANNOT SEE
```

## Comparison pass

Only after all three report directories exist:

```txt
TempleOS vs LoseThos
LoseThos vs SparrowOS
SparrowOS to TempleOS line
```

Compare:

```txt
file count
function count
class count
include count
missing include count
entrypoints
dependency shape
symbol names
source organization
```

## Rule

The source remains untouched.

The report is the artifact.

The tool reads. The notes explain. The tree stays still.
