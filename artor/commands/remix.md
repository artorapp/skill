---
description: Fork someone else's Artor prototype into a brand-new project you own, then install and ship its first version.
---

Fork an existing Artor prototype into a **new project you own** (like `git clone`), recording what it
was forked from. Full semantics: the artor skill's "`pull` vs `remix`" section (auto-loaded as
`/artor:artor`).

Remix is **not** pull: pull stays linked to the *same* project; remix creates a *new* one. Remix
does **not** install dependencies and does **not** build — you do that after.

## 1. Remix the project

```bash
artor remix <project> [name] [--org <slug>] [--ref <r>] [--dir <p>]
```

- `<project>` is the source project's slug/id. `name` is the new project's name; if you omit it,
  a TTY prompts (default `<slug>-remix`), but **non-interactive runs must pass a name** (positional
  or `--name`) or the command errors.
- `--ref` defaults to `latest` (records fork lineage). Destination dir defaults to a slug of the name
  unless you pass `--dir`; it must be an **empty** directory.
- The CLI fetches the source, creates the new project, unpacks it, writes a fresh `.artor` link, and
  re-derives the org registry `.npmrc` best-effort (so private packages install without the upstream
  credential). It prints `✓ Remixed <src>[ v<n>] → <slug> (./<dir>/).`

## 2. Install dependencies

`cd` into the new dir and install with the project's detected package manager (check the lockfile:
`pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lock*` → bun, else npm):

```bash
cd <dir>
npm install        # or pnpm / yarn / bun install
```

## 3. Ship the fork's first version

```bash
artor publish
```

This ships v1 of *your* fork. Generate a changelog and report the version + preview URL as usual
(see `/artor:publish`).

## Wrap up

Report: the new project slug + dir, that dependencies were installed, and the first published
version number + members-only preview URL.
