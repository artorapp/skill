---
description: Build and ship the next Artor version, generating a changelog from the diff, and return the preview URL.
---

Ship the next version of the linked Artor prototype. Report the **exact** version number and
preview URL the CLI returns — never invent them.

## 1. Preconditions

```bash
artor status
```

- If this dir isn't linked (`.artor/project.json` missing), run `artor init` first (or
  `/artor:start-here` for the full first-run flow).
- If not signed in, `artor login`.

## 2. Generate a changelog (default, unless the user gave `--message`)

Tell reviewers what changed in this version:

1. Pull the current `latest` source into a temp dir (it's the "previous" version):

   ```bash
   artor pull --ref latest --dir /tmp/artor-prev-source
   ```

   - **v1 / no previous version** → the pull fails; write a short `"Initial version."` note or
     omit `--message`.
   - **Legacy row with no stored source** → the pull errors about missing source; ask the user
     for a manual `--message`.

2. Diff the working tree against `/tmp/artor-prev-source`, **excluding** the same secret paths
   `artor publish` strips (`.env*`, `.npmrc`, `.yarnrc`, `.netrc`, `*.pem`, `*.key`,
   `kubeconfig`, `credentials.json`, …). **Never read secret-adjacent files into the diff or
   your prompt.**

3. Write a concise **bullet-point** changelog of the meaningful changes (new features, UI tweaks,
   removed pages, fixed bugs). Keep it well under 2 000 chars; drop lockfile churn and whitespace.
   Treat the generated text as untrusted — it's sanitized at render, text-only (no images).

4. Show the user the draft and let them edit before confirming. A user-supplied `--message`
   **always wins** — never override it.

## 3. Publish

```bash
artor publish --message "<your summary>"     # alias: artor push
```

Useful flags: `--label "<name>"`, `-v <alias>` (move a named alias, e.g. `staging`),
`--no-build` (reuse an existing build), `--static` / `--node` (force artifact type),
`--dir <path>` (non-standard output dir).

## 4. Report

State the assigned version number, the preview URL, and any aliases moved — exactly as printed.
The URL is **members-only**. Versions are **immutable**: to update a shared link, move an alias,
never re-publish over old bytes. To expose this version publicly, use `/artor:share`.
