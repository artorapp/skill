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
- **Slide deck project?** A project created via `artor init --slides` / `artor slides init` is
  static-only. `--node` (or an auto-detected node-server framework) fails immediately with "This
  is a slides project: only static bundles can be published. Remove --node or use a static
  build." — don't retry with `--node`, publish as static instead.

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

## 3. Small tweak? Consider overwriting instead of a new version

From the diff above, judge the size of the change. Full decision + permission-fallback details:
the skill's "Small tweaks: overwrite vs. new version" section. Short version:

- **Small** (copy/text-only, a single style tweak, a typo fix) → ask which is wanted: overwrite the
  current version in place (which alias — `latest` by default, confirm with the designer), or
  publish as a new version. Overwrite needs the project owner or an org admin; a 403 falls back to
  a normal new-version publish. Overwrite-in-place also requires the org's replace mode to be the
  default `overwrite` — an org set to `alias` mode publishes a new version and moves the alias
  instead; report exactly what the CLI returns either way.
  **Caution:** overwriting also turns off any public share pinned to that version — the designer
  would need to reshare to get a live link again. Mention this before overwriting if the version
  might be publicly shared.
- **Real** (new feature, new page/route, structural change) → skip this prompt and continue the
  normal flow (checkpoint, then publish as a new version).

## 4. Local safety checkpoint (if using git)

Full details: the skill's "Local safety checkpoint before publishing" section. Short version: if
this directory is a git repo with uncommitted changes, commit them locally first (reusing the
changelog text from step 2) so there's a rollback point:

```bash
git add -A && git commit -m "artor: <your changelog message>"
```

Local-only — never `git push`. Skip silently if git isn't installed or this isn't a repo. If the
commit fails, report it and stop — don't proceed to step 5.

## 5. Publish

```bash
artor publish --message "<your summary>"     # alias: artor push
# — or, if step 3 chose to overwrite —
artor publish -v <chosen-alias> --message "<your summary>"
rm -rf "$PREV"                                # clean up the temp snapshot
```

Useful flags: `--label "<name>"`, `-v <alias>` (move a named alias, e.g. `staging`, or overwrite it
in place — see step 3), `--no-build` (reuse a build), `--no-install`, `--static` / `--node` /
`--entry <s>` (artifact type/entry), `--dir <path>` (non-standard output dir), `--no-sdk-update`
(skip the `@artorapp/web-sdk` review-widget update check — see the skill's "Publishing notes").

**Boot-test failure.** Before upload, Artor starts the app (`node <entry>`) and waits for it to
listen. If it crashes, publish stops with the crash output. **Read it and fix the build.** Use
`--no-smoke` **only** if the app legitimately needs live secrets/services to boot — never as a reflex
to get past a real crash.

**Web-sdk update prompt.** If publish asks about updating `@artorapp/web-sdk` (the review widget),
recommend accepting it — see the skill's "Publishing notes" for why.

## 6. Report

State the assigned version number, the preview URL, and any aliases moved — exactly as printed. The
URL is **members-only**. A new version is immutable; an overwritten one (step 3) replaces the
previous content at that alias permanently — say clearly which happened. To expose this version
publicly, use `/artor:share`.
