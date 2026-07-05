---
description: Build and ship the next Artor version, generating a changelog from the diff, and return the preview URL.
---

Ship the next version of the linked Artor prototype. Report the **exact** version number and preview
URL the CLI returns — never invent them. Full flag reference and semantics: the artor skill's
"Publishing notes" section (auto-loaded as `/artor:artor`).

## 1. Preconditions

**Monorepo pre-check.** If the root `package.json` has a `workspaces` field or a `pnpm-workspace.yaml`
exists, this is a workspace root — `cd` into the specific app's folder (the one with the `build`
script + framework dep) before publishing. Ask which app if unknown. (Skill: "Monorepos" section.)

```bash
artor status
```

- If this dir isn't linked (`.artor/project.json` missing), run `artor init` first (or
  `/artor:start-here` for the full first-run flow).
- If not signed in, `artor login`.

## 2. Generate a changelog (default, unless the user gave `--message`)

Tell reviewers what changed. Full procedure + secret-exclusion list: the skill's "Describe what
changed" section.

1. Pull the current `latest` source into a **fresh** temp dir (it's the "previous" version):

   ```bash
   PREV=$(mktemp -d)
   artor pull --ref latest --dir "$PREV"
   ```

   - **v1 / no previous version** → pull fails with `pull failed (HTTP <status>): <server message>`
     (the CLI relays the server text). Skip the diff; write `"Initial version."` or omit `--message`.
   - **Legacy row with no stored source** → same `pull failed (HTTP …)` shape; ask the user for a
     manual `--message`.

2. Diff the working tree against `"$PREV"`, **excluding** the secret paths `artor publish` strips
   (`.env*`, `.npmrc`, `.yarnrc*`, `.netrc`, `*.pem`, `*.key`, `kubeconfig`, `credentials*`, …).
   **Never read secret-adjacent files into the diff or your prompt.**

3. Write a concise **bullet-point** changelog (features, UI tweaks, removed pages, fixed bugs). Keep
   it well under 2 000 chars; drop lockfile churn and whitespace. Treat the text as untrusted.

4. Show the user the draft and let them edit before confirming. A user-supplied `--message` **always
   wins** — never override it.

## 3. Publish

```bash
artor publish --message "<your summary>"     # alias: artor push
rm -rf "$PREV"                                # clean up the temp snapshot
```

Useful flags: `--label "<name>"`, `-v <alias>` (move a named alias, e.g. `staging`), `--no-build`
(reuse a build), `--no-install`, `--static` / `--node` / `--entry <s>` (artifact type/entry),
`--dir <path>` (non-standard output dir), `--no-sdk-update` (skip the `@artorapp/web-sdk`
update check — see the skill's "Publishing notes").

**Boot-test failure.** Before upload, Artor starts the app (`node <entry>`) and waits for it to
listen. If it crashes, publish stops with the crash output. **Read it and fix the build.** Use
`--no-smoke` **only** if the app legitimately needs live secrets/services to boot — never as a reflex
to get past a real crash.

## 4. Report

State the assigned version number, the preview URL, and any aliases moved — exactly as printed. The
URL is **members-only**. Versions are **immutable**: to update a shared link, move an alias, never
re-publish over old bytes. To expose this version publicly, use `/artor:share`.
