<h1>DBYTE HOLYC TOOLS</h1>

<p>
  Windows-native read-only source navigator for HolyC, LoseThos, and TempleOS-style trees.
</p>

<p>
  <strong>Final line:</strong> <code>v1.6.0 FINAL</code>
</p>

<img width="1196" height="623" alt="SHOT" src="https://github.com/user-attachments/assets/7d34edc9-882b-4bb5-bc66-4da6049aaa4f" />

<section>
  <h2>Rule</h2>
  <pre>No source rewrite.
No formatter.
No VM.
No fake C parser.</pre>
</section>

<section>
  <h2>What it does</h2>
  <p>
    It scans HolyC-style source, indexes symbols/includes, checks include resolution,
    finds likely entry files, and emits deterministic text/JSON reports.
  </p>
</section>

<section>
  <h2>Docs</h2>
  <table>
    <tr>
      <td><a href="DOCS.md">DOCS.md</a></td>
      <td>full manual</td>
    </tr>
    <tr>
      <td><a href="ARCHAEOLOGY.md">ARCHAEOLOGY.md</a></td>
      <td>TempleOS / LoseThos / SparrowOS dig site</td>
    </tr>
  </table>
</section>

<section>
  <h2>Build</h2>
  <pre>cargo build --release -p holytools</pre>
  <p>Binary:</p>
  <pre>target/release/holytools.exe</pre>
</section>

<section>
  <h2>Commands</h2>
  <pre>holytools version
holytools scan &lt;path&gt; [--json]
holytools stats &lt;path&gt; [--json]
holytools source-map &lt;path&gt; [--json]
holytools missing-includes &lt;path&gt; [--json]
holytools entrypoints &lt;path&gt; [--json]
holytools tokens &lt;file&gt;
holytools outline &lt;file&gt; [--json]
holytools symbols &lt;path&gt; [--json]
holytools find-symbol &lt;path&gt; &lt;name&gt; [--json]
holytools includes &lt;path&gt; [--json]
holytools include-graph &lt;path&gt; [--json]
holytools resolve-includes &lt;path&gt; [--json]
holytools dependency-order &lt;path&gt; [--json]
holytools reverse-includes &lt;path&gt; [--json]</pre>
</section>

<section>
  <h2>Fast path</h2>
  <pre>holytools source-map tests/fixtures/tiny
holytools missing-includes tests/fixtures/tiny
holytools entrypoints tests/fixtures/tiny</pre>
</section>

<section>
  <h2>Report pack</h2>
  <pre>./scripts/report.ps1 tests/fixtures/tiny reports/tiny</pre>
  <table>
    <tr><td>version</td></tr>
    <tr><td>source-map</td></tr>
    <tr><td>missing-includes</td></tr>
    <tr><td>entrypoints</td></tr>
    <tr><td>dependency-order</td></tr>
    <tr><td>reverse-includes</td></tr>
  </table>
</section>

<section>
  <h2>Source archaeology</h2>
  <pre>./scripts/run-archaeology.ps1 -TempleOS D:/src/TempleOS
./scripts/run-archaeology.ps1 -TempleOS D:/src/TempleOS -LoseThos D:/src/LoseThos -SparrowOS D:/src/SparrowOS</pre>
  <p>Output:</p>
  <pre>reports/archaeology/SUMMARY.md
reports/archaeology/templeos/
reports/archaeology/losethos/
reports/archaeology/sparrowos/</pre>
</section>

<section>
  <h2>Package</h2>
  <pre>./scripts/package-windows.ps1
./scripts/verify-package.ps1
./scripts/package-zip.ps1</pre>
  <p>Output:</p>
  <pre>dist/dbyte-holyc-tools-windows/
dist/dbyte-holyc-tools-windows.zip
dist/dbyte-holyc-tools-windows.zip.sha256</pre>
</section>

<section>
  <h2>Package contents</h2>
  <pre>holytools.exe
README.md
CHANGELOG.md
VERSION.txt
SHA256SUMS.txt
MANIFEST.txt
scripts/check-includes.ps1
scripts/report.ps1</pre>
</section>

<section>
  <h2>Release gate</h2>
  <pre>./scripts/release.ps1 v1.6.0</pre>
  <p>
    The gate runs format check, workspace check, tests, CLI verification,
    package verification, ZIP creation, clean tree check, and tag push.
  </p>
</section>

<section>
  <h2>Verify</h2>
  <pre>./scripts/verify.ps1</pre>
  <p>Current smoke line:</p>
  <pre>10 cli smoke tests</pre>
</section>

<section>
  <h2>Final stance</h2>
  <pre>read-only by default
HolyC compatibility first
deterministic output
no source mutation</pre>
</section>
