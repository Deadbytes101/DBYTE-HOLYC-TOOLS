# Changelog

## v1.7.0

Source archaeology map release.

- Added TempleOS archaeology report pipeline pages:
  - `BOOT-CHAIN.md`
  - `SPINE.md`
  - `KERNEL-CONTRACT.md`
  - `COMPILER-CONTRACT.md`
  - `ADAM-MANIFEST.md`
  - `DESKTOP-SURFACE.md`
  - `ADAM-SUBSYSTEMS.md`
  - `ARCHAEOLOGY-FINDINGS.md`
- Added include resolver backed archaeology reports.
- Added kernel, compiler, Adam, desktop, and subsystem contract/manifest classifiers.
- Packaged the archaeology support scripts with the Windows artifact.
- Updated package verification to require the archaeology support scripts.
- Refreshed `README.md` and `ARCHAEOLOGY.md` for the archaeology map line.
- Kept the source archaeology boundary read-only: no compile, no execute, no emulation, no source rewrite, no source-tree mutation.
- No `holytools` command behavior changes.

## v1.6.0 FINAL

Final package line.

- Added `scripts/package-zip.ps1`.
- Release gate now creates `dist/dbyte-holyc-tools-windows.zip`.
- Release gate now creates `dist/dbyte-holyc-tools-windows.zip.sha256`.
- GitHub tag workflow now uploads the full `dist/` output.
- No `holytools` command behavior changes.

## v1.5.0

Packaged support scripts release.

- Packaged `scripts/check-includes.ps1` and `scripts/report.ps1` with the Windows artifact.
- Updated the package manifest to list packaged support scripts.
- Updated package verification to require packaged support scripts.
- Updated packaged support scripts to use the packaged `holytools.exe` when run from the package.
- Package verification now runs the packaged include check and report script.
- No `holytools` command behavior changes.

## v1.4.0

Source tree report release.

- Added `scripts/report.ps1` for generating source tree report files.
- Report output includes version, source-map, missing-includes, entrypoints, dependency-order, and reverse-includes outputs.
- Added `/reports/` to `.gitignore`.
- No `holytools` command behavior changes.

## v1.3.0

Entrypoint inspection release.

- Added `holytools entrypoints <path> [--json]` for files with no resolved incoming include.
- Added CLI smoke tests for text and JSON entrypoint output.
- Added entrypoint checks to `scripts/verify.ps1`.

## v1.2.0

Missing-include inspection release.

- Added `holytools missing-includes <path> [--json]` for focused missing include reports.
- Added a fixture with a real missing include target.
- Added CLI smoke tests for text and JSON missing-include output.
- Added missing-include checks to `scripts/verify.ps1`.

## v1.1.0

Source-map release.

- Added `holytools source-map <path> [--json]` for one-shot source tree summary output.
- Source-map reports file, token, function, class, include, resolved include, missing include, dependency file, and reverse include edge counts.
- Added CLI smoke tests for text and JSON source-map output.
- Added source-map checks to `scripts/verify.ps1`.

## v1.0.1

Release automation patch.

- Added `scripts/release.ps1` for one-shot release verification and tag publishing.
- Documented the one-shot release flow in `README.md`.
- No `holytools` command behavior changes.

## v1.0.0

First stable line.

- Fixed CLI smoke tests to resolve fixtures from the workspace root.
- Hardened `scripts/verify.ps1` so native command failures stop the script immediately.
- Kept package manifest, version file, and SHA256 checksum checks.

## v0.3.0

CLI smoke test milestone.

- Added integration smoke tests for the `holytools` binary.
- The smoke tests cover `version`, `stats`, `resolve-includes --json`, and `dependency-order`.

## v0.2.9

Package version verification release.

- `scripts/verify-package.ps1` now verifies `VERSION.txt` against `holytools.exe version` output.
