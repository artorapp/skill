---
description: Fetch a specific Artor version's exact source safely, staying linked to the same project.
---

Download a published version's exact source. `pull` **stays linked to the same project** — a later
`artor publish` ships that project's *next* version (this is the sibling of remix, which forks into a
new project). Full semantics: the artor skill's "`pull` vs `remix`" section (auto-loaded as
`/artor:artor`).

## 1. Protect the working tree first

Pulling writes into the target dir (default `.`). Before overwriting:

- If the working tree is **dirty**, warn the user. Commit/stash first, pull onto a fresh **branch**,
  or pull into a **separate directory** with `--dir`:

  ```bash
  artor pull --ref <version> --dir ./_review-v<version>
  ```

## 2. Pull the version

```bash
artor pull --ref <version> [--dir <p>] [--project <slug>] [--force]
```

- `--ref` defaults to `latest`; pass an alias, version number, or sha to get an exact version (e.g.
  the one reviewers commented on).
- If the pull fails with `pull failed (HTTP <status>): <server message>`, read the relayed server
  message — typically no such version, or a legacy row with no stored source snapshot.

## 3. Install & continue

`.npmrc` is re-derived automatically for private packages (org proxy + your own Artor token — never
the upstream credential), so scoped packages install right away:

```bash
npm install        # or pnpm / yarn / bun install, per the lockfile
```

You remain linked to the same project. When you publish, it ships the **next** version of that
project (versions are immutable — old ones keep their bytes and their comments).

## Wrap up

Report: which version/ref you pulled, where (dir/branch), and that the tree is ready to run.
