<h1>SOURCE ARCHAEOLOGY</h1>

<section>
  <h2>Purpose</h2>
  <pre>DBYTE HOLYC TOOLS maps HolyC-style source trees without touching them.
The source tree is input only.
Reports are the artifact.</pre>
</section>

<section>
  <h2>Targets</h2>
  <pre>TEMPLEOS
LOSETHOS
SPARROWOS</pre>
</section>

<section>
  <h2>Order</h2>
  <pre>1. TEMPLEOS
2. LOSETHOS
3. SPARROWOS</pre>
</section>

<section>
  <h2>Run</h2>
  <pre>./scripts/run-archaeology.ps1 -TempleOS D:/src/TempleOS
./scripts/run-archaeology.ps1 -TempleOS D:/src/TempleOS -LoseThos D:/src/LoseThos -SparrowOS D:/src/SparrowOS</pre>
</section>

<section>
  <h2>Report Layout</h2>
  <pre>reports/archaeology/SUMMARY.md
reports/archaeology/templeos/
reports/archaeology/losethos/
reports/archaeology/sparrowos/</pre>
</section>

<section>
  <h2>Base Report Files</h2>
  <table>
    <tr><td>version.txt</td><td>tool version</td></tr>
    <tr><td>source-map.txt</td><td>source tree counts</td></tr>
    <tr><td>source-map.json</td><td>machine-readable source tree counts</td></tr>
    <tr><td>missing-includes.txt</td><td>missing include scan</td></tr>
    <tr><td>missing-includes.json</td><td>machine-readable missing include scan</td></tr>
    <tr><td>entrypoints.txt</td><td>entrypoint candidates</td></tr>
    <tr><td>entrypoints.json</td><td>machine-readable entrypoint candidates</td></tr>
    <tr><td>dependency-order.txt</td><td>dependency order scan</td></tr>
    <tr><td>dependency-order.json</td><td>machine-readable dependency order scan</td></tr>
    <tr><td>reverse-includes.txt</td><td>reverse include scan</td></tr>
    <tr><td>reverse-includes.json</td><td>machine-readable reverse include scan</td></tr>
  </table>
</section>

<section>
  <h2>Archaeology Reports</h2>
  <table>
    <tr><td>include-resolve.md</td><td>include resolver proof</td></tr>
    <tr><td>REVERSE.md</td><td>reverse include pressure</td></tr>
    <tr><td>BOOT-CHAIN.md</td><td>StartOS source load chain</td></tr>
    <tr><td>SPINE.md</td><td>root outline checkpoints</td></tr>
    <tr><td>KERNEL-CONTRACT.md</td><td>KernelA public contract map</td></tr>
    <tr><td>COMPILER-CONTRACT.md</td><td>CompilerA/B contract map</td></tr>
    <tr><td>ADAM-MANIFEST.md</td><td>Adam top-level manifest</td></tr>
    <tr><td>DESKTOP-SURFACE.md</td><td>Adam desktop and UI surface</td></tr>
    <tr><td>ADAM-SUBSYSTEMS.md</td><td>second-level Adam subsystem manifests</td></tr>
    <tr><td>ARCHAEOLOGY-FINDINGS.md</td><td>single-page findings summary</td></tr>
  </table>
</section>

<section>
  <h2>Known TempleOS Proof Line</h2>
  <pre>includes: 229
resolved-includes: 229
missing-includes: 0
pipeline: ok</pre>
</section>

<section>
  <h2>Reading Order</h2>
  <pre>1. ARCHAEOLOGY-FINDINGS.md
2. BOOT-CHAIN.md
3. SPINE.md
4. KERNEL-CONTRACT.md
5. COMPILER-CONTRACT.md
6. ADAM-MANIFEST.md
7. DESKTOP-SURFACE.md
8. ADAM-SUBSYSTEMS.md
9. REVERSE.md
10. include-resolve.md</pre>
</section>

<section>
  <h2>What To Extract</h2>
  <pre>holy-files
functions
classes
includes
asm-blocks
resolved-includes
missing-includes
entrypoints
dependency-files
reverse-edges
contract pressure
manifest load order
subsystem fan-out</pre>
</section>

<section>
  <h2>Trust Boundary</h2>
  <pre>No compile.
No execute.
No emulate.
No source rewrite.
No source formatting.
No source-tree mutation.
Source load order is not runtime scheduling proof.
Outline pressure is not semantic proof.</pre>
</section>

<section>
  <h2>Comparison Pass</h2>
  <pre>Only compare trees after each target has a complete report directory.
TempleOS is the first full map.
LoseThos and SparrowOS should be mapped with the same pipeline before comparison.</pre>
</section>
