# Third-Party Source Snapshots

This repository uses a root-level archival layout for third-party research source snapshots:

```text
templeos/
losethos/
sparrowos/
SOURCE-SNAPSHOTS.md
```

The `third_party/` directory is kept only for notes and migration helpers.

## Boundary

Third-party source snapshots are research inputs, not project-owned source.

Do not rewrite, format, compile, execute, or mutate the imported target source trees as part of DBYTE HOLYC TOOLS.

## Move existing snapshots to root

Use:

```powershell
.\scripts\move-source-snapshots-to-root.ps1
```

Then inspect the diff carefully before committing.

## Import new snapshots

Use `scripts/import-third-party-sources.ps1` when importing or refreshing snapshots from external local source trees. If you keep the root-level layout, move or copy the refreshed snapshot into the root layout intentionally and review the diff before pushing.
