# Changelog

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
- No `holytools` command behavior changes.

## v0.2.2

Include-check hardening release.

- Added `scripts/check-includes.ps1` for CI-style include validation.
- Added the include check script to `scripts/verify.ps1`.
- The script exits with failure when resolved include data reports missing includes.
- No `holytools` command behavior changes.

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
