# DBYTE HOLYC TOOLS DOCS

A small Windows-native read-only navigator for HolyC, LoseThos, and TempleOS-style source trees.

Final line: `v1.6.0 FINAL`

This tool does not compile HolyC. It does not modernize HolyC. It does not pretend HolyC is C. It reads the tree, extracts facts, and prints them in stable text or JSON.

The point is simple: old source trees deserve tools that do not touch them.

## Ground rules

```txt
read-only
no source rewrite
no formatter
no VM
no fake C parser
no hidden mutation
deterministic output
```

The source tree is the artifact. The tool is a lamp.

## What it is

`holytools.exe` is a command-line source archaeology tool.

It is built for reading unfamiliar HolyC-style trees without first loading an IDE, porting code, fixing include paths, or pretending the language is normal C.

It answers questions like:

```txt
How many HolyC files are here?
What symbols are declared?
Which includes resolve?
Which includes are missing?
Which file looks like the entry point?
What order should I read dependencies in?
Who includes this file?
Can I get a JSON report for other tools?
```

It is not a compiler. It is not a linter. It is not a style checker.

## What it ships

The final Windows package ships as:

```txt
dbyte-holyc-tools-windows.zip
dbyte-holyc-tools-windows.zip.sha256
```

Inside the ZIP:

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

The packaged scripts use the packaged `holytools.exe`. They do not need the Rust workspace when run from the release folder.

## Install from release ZIP

Extract the ZIP anywhere.

Example:

```powershell
Expand-Archive .\dbyte-holyc-tools-windows.zip .\dbyte-holyc-tools-windows -Force
cd .\dbyte-holyc-tools-windows
.\holytools.exe version
```

Expected:

```txt
holytools 1.6.0
writes: none
```

That `writes: none` line is part of the contract.

## Build from source

```powershell
cargo build --release -p holytools
```

Binary:

```txt
target/release/holytools.exe
```

Run the full local verification gate:

```powershell
./scripts/verify.ps1
```

The smoke line at final is:

```txt
10 cli smoke tests
```

## Command map

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

Every tree-level command is meant to be scriptable. Text is for eyes. JSON is for machines.

## First run

Use a small tree first.

```powershell
.\holytools.exe source-map .\some-holyc-tree
.\holytools.exe missing-includes .\some-holyc-tree
.\holytools.exe entrypoints .\some-holyc-tree
```

If all three commands make sense, generate the full report pack.

```powershell
.\scripts\report.ps1 .\some-holyc-tree .\reports\some-holyc-tree
```

The report directory will contain:

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
```

## Command details

### version

```powershell
holytools version
```

Prints the binary version and the read-only statement.

```txt
holytools 1.6.0
writes: none
```

Use this before trusting a report.

### scan

```powershell
holytools scan <path>
holytools scan <path> --json
```

Counts HolyC source files under a path.

Text output:

```txt
root: <path>
holy-files: <count>
status: ok
```

Use this to confirm the tool is looking at the right tree.

### stats

```powershell
holytools stats <path>
holytools stats <path> --json
```

Reports rough structural counts:

```txt
holy-files
tokens
functions
classes
includes
asm-blocks
```

This is a quick source size and shape check.

### source-map

```powershell
holytools source-map <path>
holytools source-map <path> --json
```

This is the one-shot overview command.

It reports:

```txt
holy-files
tokens
functions
classes
includes
asm-blocks
resolved-includes
missing-includes
dependency-files
reverse-edges
```

Run this first when opening a new tree.

### missing-includes

```powershell
holytools missing-includes <path>
holytools missing-includes <path> --json
```

Prints only include targets that could not be resolved.

Text output shape:

```txt
<file>:<line>:<column>    <target>
missing: <count>
status: ok
```

A clean tree reports:

```txt
missing: 0
status: ok
```

This command is useful before any deeper reading. Broken include paths poison every other source map.

### entrypoints

```powershell
holytools entrypoints <path>
holytools entrypoints <path> --json
```

Lists files with no resolved incoming include edge.

In plain terms: files that nobody else includes.

These are often good places to start reading.

Example:

```txt
1       ./tree/Main.HC
entrypoints: 1
status: ok
```

This does not prove runtime entry. It proves include-graph entry.

### tokens

```powershell
holytools tokens <file>
```

Prints non-trivia tokens from one source file.

This is for seeing what the lexer sees.

Use it when symbol extraction looks wrong.

### outline

```powershell
holytools outline <file>
holytools outline <file> --json
```

Prints the useful shape of a file:

```txt
include
class
function
```

It is a file-level table of contents.

### symbols

```powershell
holytools symbols <path>
holytools symbols <path> --json
```

Lists symbols found across the tree.

Symbol rows include:

```txt
file
line
column
kind
name
```

### find-symbol

```powershell
holytools find-symbol <path> <name>
holytools find-symbol <path> <name> --json
```

Finds exact symbol name matches.

It does not do fuzzy search. It does not guess.

### includes

```powershell
holytools includes <path>
holytools includes <path> --json
```

Lists raw include statements before resolution.

Use it when you want to see what the source claims directly.

### include-graph

```powershell
holytools include-graph <path>
holytools include-graph <path> --json
```

Prints include edges as source-to-target declarations.

This is raw graph shape, not a resolved dependency order.

### resolve-includes

```powershell
holytools resolve-includes <path>
holytools resolve-includes <path> --json
```

Attempts to resolve include targets to files.

Each include row is marked:

```txt
resolved
missing
```

This is the command behind the include checker.

### dependency-order

```powershell
holytools dependency-order <path>
holytools dependency-order <path> --json
```

Outputs files in dependency-first order.

Headers and included files appear before the files that depend on them.

This helps when reading unfamiliar trees by hand.

### reverse-includes

```powershell
holytools reverse-includes <path>
holytools reverse-includes <path> --json
```

Shows who includes what.

This is the inverse view of include resolution.

Use it to answer:

```txt
Who depends on this file?
What breaks if this include goes away?
```

## Report script

```powershell
./scripts/report.ps1 <path> <out-dir>
```

The report script is the standard proof run.

It writes the important commands into files so the terminal does not become the archive.

From source repo, it uses:

```txt
target/release/holytools.exe
```

From release package, it uses:

```txt
../holytools.exe
```

That means the same script works from source and from the shipped ZIP.

## Include check script

```powershell
./scripts/check-includes.ps1 <path>
```

Fails if resolved include data reports missing includes.

Clean output:

```txt
check-includes: ok
```

This is the closest thing to CI logic in the final line.

## Packaging

Build the Windows package directory:

```powershell
./scripts/package-windows.ps1
```

Verify it:

```powershell
./scripts/verify-package.ps1
```

Create the release ZIP and sidecar checksum:

```powershell
./scripts/package-zip.ps1
```

Output:

```txt
dist/dbyte-holyc-tools-windows/
dist/dbyte-holyc-tools-windows.zip
dist/dbyte-holyc-tools-windows.zip.sha256
```

## Release gate

```powershell
./scripts/release.ps1 v1.6.0
```

The release gate performs:

```txt
git fetch origin --tags
cargo fmt --check
cargo check --workspace
cargo test --workspace
scripts/verify.ps1
scripts/package-windows.ps1
scripts/verify-package.ps1
scripts/package-zip.ps1
clean working tree check
remote tag check
tag push
```

The final release was cut from this gate.

## Proof run from ZIP

This is the strongest test because it uses the release artifact, not the repo build.

```powershell
Remove-Item -Recurse -Force .\proof-run -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force .\proof-run\src | Out-Null
Expand-Archive .\dist\dbyte-holyc-tools-windows.zip .\proof-run\tool -Force

.\proof-run\tool\holytools.exe version
.\proof-run\tool\holytools.exe source-map .\proof-run\src
.\proof-run\tool\holytools.exe missing-includes .\proof-run\src
.\proof-run\tool\holytools.exe entrypoints .\proof-run\src
.\proof-run\tool\scripts\report.ps1 .\proof-run\src .\proof-run\report
```

A valid run proves:

```txt
binary starts
version is correct
writes are none
source-map works
include check works
entrypoint scan works
packaged report script works
report files are written
```

## Output contract

The text output is meant to be easy to read and diff.

The JSON output is meant to be boring and stable.

The tool prefers explicit counts and `status: ok` over clever output.

If a command succeeds, it says so. If a command fails, it exits non-zero.

## Language handling

The repository uses `.gitattributes` to keep GitHub language stats clean.

```gitattributes
*.HC linguist-language=HolyC
*.HH linguist-language=HolyC
*.hc linguist-language=HolyC
*.hh linguist-language=HolyC
*.ps1 text eol=crlf linguist-vendored
*.psm1 text eol=crlf linguist-vendored
*.psd1 text eol=crlf linguist-vendored
```

HolyC gets shown as HolyC. PowerShell support scripts do not dominate the language bar.

## Design notes

The tool stays small on purpose.

The design is closer to a source survey instrument than an IDE.

The stack is split into simple layers:

```txt
holylex     tokenizes HolyC-style text
holyindex   scans files and extracts source facts
holytools   command-line interface and report formatting
scripts     release, package, report, include check
```

The CLI is the public surface. The reports are the artifact.

## Limits

The final line does not provide:

```txt
full HolyC semantic analysis
macro expansion
real compiler diagnostics
call graph
control-flow graph
type checker
formatter
source rewriting
LSP server
GUI
```

Those belong in another project or a later major line.

Do not stretch this tool into pretending to be a compiler.

## Good next projects

This repo is done.

Good follow-up projects should build on its JSON output instead of bloating this line.

Possible next repos:

```txt
DBYTE-HOLYC-VIEWER      TUI/GUI source browser
DBYTE-HOLYC-LAB         experiments, graphs, reports
DBYTE-HOLYC-HTML        static HTML report generator
DBYTE-HOLYC-XREF        cross-reference and call graph index
```

If a next project needs to mutate source, it must not be this tool.

## Final stance

`DBYTE-HOLYC-TOOLS v1.6.0 FINAL` is a finished read-only source navigator.

It does not try to own the source tree.

It reads. It reports. It stops.
