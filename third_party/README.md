# Third-Party Source Snapshots

This directory is reserved for optional local snapshots of external research source trees such as TempleOS and LoseThos.

The main tool does not require these snapshots to be committed. The normal and preferred workflow is to keep target source trees outside this repository and pass their paths to the report scripts.

Use this directory only when you intentionally want a self-contained archival snapshot inside this repository.

## Boundary

Third-party source snapshots are research inputs, not project-owned source.

Do not rewrite, format, compile, execute, or mutate the imported target source trees as part of DBYTE HOLYC TOOLS.

## Suggested layout

```text
third_party/source/templeos/
third_party/source/losethos/
third_party/SOURCE-SNAPSHOT.md
```

## Import

Use:

```powershell
.\scripts\import-third-party-sources.ps1 \
  -TempleOS "D:\src\TempleOS" \
  -LoseThos "D:\TECHNICAL\LoseThos-extracted\LT_EXE\LT"
```

Then inspect the diff carefully before committing.
