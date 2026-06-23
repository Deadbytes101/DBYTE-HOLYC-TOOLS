# Changelog

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

## v1.0.0 FINAL

Final stable release for the current read-only HolyC source navigator line.

- Fixed `holytools` CLI smoke tests to resolve fixtures from the workspace root.
- Hardened `scripts/verify.ps1` so native command failures stop the script immediately.
- Documents the final Windows package shape and verification flow.
- Keeps the package manifest, version file, and SHA256 checksum checks.
- No `holytools` command behavior changes.

## v0.3.0

CLI smoke test milestone.

- Added integration smoke tests for the `holytools` binary.
- The smoke tests cover `version`, `stats`, `resolve-includes --json`, and `dependency-order`.
- No `holytools` command behavior changes.

## v0.2.9

Package version verification release.

- `scripts/verify-package.ps1` now verifies `VERSION.txt` against `holytools.exe version` output.
- No `holytools` command behavior changes.

## v0.2.8

Package manifest verification release.

- Packaged Windows artifacts now include `MANIFEST.txt`.
- `scripts/verify-package.ps1` verifies required manifest entries.
- No `holytools` command behavior changes.

## v0.2.7

Package manifest release.

- Packaged Windows artifacts now include `VERSION.txt`.
- Packaged Windows artifacts now include `SHA256SUMS.txt`.
- `scripts/verify-package.ps1` verifies the packaged checksum for `holytools.exe`.
- No `holytools` command behavior changes.

## v0.2.6

Package verification release.

- Added `scripts/verify-package.ps1` for packaged artifact checks.
- The release workflow verifies package contents before artifact upload.
- The package verifier checks `holytools.exe`, `README.md`, and `CHANGELOG.md`.
- The package verifier runs `holytools.exe version`.
- No `holytools` command behavior changes.

## v0.2.5

Packaging script release.

- Added `scripts/package-windows.ps1` for local Windows release packaging.
- The release workflow now uses the same packaging script.
- Ignored local `dist/` package output.
- Artifact output remains `dbyte-holyc-tools-windows`.
- No `holytools` command behavior changes.

## v0.2.4

Release artifact workflow.

- Added a Windows release workflow for version tags.
- The workflow builds `holytools.exe` in release mode.
- The workflow uploads `dbyte-holyc-tools-windows` with the binary, README, and changelog.
- No `holytools` command behavior changes.

## v0.2.3

Repository verification release.

- Added a Windows verification workflow for push and pull request checks.
- The workflow runs `./scripts/verify.ps1`.
- No command behavior changes.

## v0.2.2

Include-check hardening release.

- Added `scripts/check-includes.ps1` for CI-style include validation.
- Added the include check script to `scripts/verify.ps1`.
- The script exits with failure when resolved include data reports missing includes.
- No command behavior changes.

## v0.2.1

Hardening release after the first source-navigator milestone.

- Synced rustfmt output for the source tree.
- Ignored local `webhook.json` payload files.
- No command behavior changes.

## v0.2.0

First source-navigator milestone.

- Ships the `holytools` Windows CLI binary.
- Keeps all commands read-only.
- Provides tokenizer output for single HolyC files.
- Provides tree stats for HolyC source roots.
- Provides symbol listing and exact symbol lookup.
- Provides file outline for includes, classes, and functions.
- Provides include listing and include graph output.
- Provides include resolution with resolved/missing status.
- Provides dependency-first source ordering.
- Provides reverse include lookup.
- Keeps deterministic text and JSON output paths.

## v0.1.9

- Added `reverse-includes`.

## v0.1.8

- Added `dependency-order`.

## v0.1.7

- Added `resolve-includes`.
- Hardened verify script behavior for native command failures.

## v0.1.6

- Added `include-graph`.

## v0.1.5

- Added `find-symbol`.

## v0.1.4

- Added `outline`.

## v0.1.3

- Renamed the CLI package and binary to `holytools`.

## v0.1.2

- Added JSON output for source reports.

## v0.1.1

- Added source index reports for symbols and includes.

## v0.1.0

- Initial read-only HolyC tools workspace.
