---
description: Build and ship the next Artor version, generating a changelog from the diff, and return the preview URL.
---

Ship the next version of the linked Artor prototype. Report the **exact** version number and preview
URL the CLI returns — never invent them. Full flag reference and semantics: the artor skill's
"Publishing notes" section (auto-loaded as `/artor:artor`).

## 1. Preconditions

**Monorepo pre-check.** If the root `package.json` has a `workspaces` field or a `pnpm-workspace.yaml`
exists, this is a workspace root, which usually holds orchestration rather than an app. To publish a
member app, `cd` into its folder (the one with the `build` script + framework dep) first; an actual
app at the root can still publish from there. Ask which app if unknown. (Skill: "Monorepos" section.)
With artor-cli 0.34.0 or later (check `artor --version`), a listed workspace app with no lockfile
of its own installs at the workspace root, and a Next app's nested standalone server is found on its
own: the manual recipe is unnecessary for usual layouts; see the skill's "Monorepos" limits.

```bash
artor status
```

Read the **active org** off that output (or `artor status --json` → `activeOrg` / `role`) rather
than assuming one - it is what `publish` will ship to, resolved as linked folder org → saved
default → token home org.

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
artor publish --alias <chosen-alias> --message "<your summary>"
rm -rf "$PREV"                                # clean up the temp snapshot
```

Useful flags: `--label "<name>"`, `--alias <name>` (short `-v`; move a named alias, e.g. `staging`,
or overwrite it in place - see step 3), `--no-build` (reuse a build), `--no-install`, `--static` /
`--node` / `--entry <s>` (artifact type/entry), `--dir <path>` (non-standard output dir),
`--no-sdk-update` (skip the `@artorapp/web-sdk` review-widget update check - see the skill's
"Publishing notes").

**`--alias`, not `--version`.** `--version <name>` still sets the alias here but is **deprecated
and warns on stderr** - the same spelling means a version NUMBER on `artor open` and the CLI's own
version at `-V`. Write `--alias`; if both are passed, `--alias` wins.

**`--json` for a scripted run.** `artor publish --json` prints one object on stdout
(`{ version, url, aliases, artifactType, usage }`, `usage` being `null` against an older
server, plus `replaced` on an overwrite, and `replayed: true` (artor-cli 0.35.0+) when an earlier
attempt of the same run had already made the version live) and puts every
progress line, warning, and build subprocess transcript on stderr. It never prompts: a
`next.config` patch fails loud asking for `--yes`, a real mock conflict fails loud asking for
`--mocks=local|server`. Read `version`/`url` from the object rather than parsing prose.

**Boot-test failure.** Before upload, Artor starts the app (`node <entry>`) and waits for it to
listen. If it crashes, publish stops with the crash output. **Read it and fix the build.** Use
`--no-smoke` **only** if the app legitimately needs live secrets/services to boot — never as a reflex
to get past a real crash.

**Publish failed but "may already be live"? Do not re-run blindly** (artor-cli 0.35.0+). Inside one
run the CLI retries a lost reply with the same publish key and never makes a second version; a NEW
`artor publish` is a new key and can. When the failure says the version may already be live, or
that the server is still processing it, check first: `artor project list --json` (or `artor project
search <name> --json`) for the prototype's latest version, compared with the number before this
publish (read it from the same listing before you publish, so you have it). Moved: it went live, report that version (`artor open --json` for the URL). Not moved, or
unsure: ask the user to check the version list in the dashboard. `publish_superseded` /
`publish_failed_superseded` mean nothing was republished: report and ask before publishing again.
`publish_conflict` that ends the run, or a server crash mid-publish: publishing again is safe. A
429 the run did not wait out (no `Retry-After`, or one longer than what is left of the 5 minute wait
budget, such as a spent publish budget) fails at once with the server's message: relay it and
publish later (after the version check, if the run also lost a reply).
Details: the skill's "A publish that lost its reply" note.

**Web-sdk update prompt.** If publish asks about updating `@artorapp/web-sdk` (the review widget),
recommend accepting it — see the skill's "Publishing notes" for why.

## 6. Report

State the assigned version number, the preview URL, and any aliases moved, exactly as printed. If
the result was `replayed: true`, say an earlier attempt of the same publish had already gone live and
no second version was made; report its `url` as returned (it is the version's own URL, not the
alias's, when someone published after the lost attempt). The
URL is **members-only**. A new version is immutable; an overwritten one (step 3) replaces the
previous content at that alias permanently — say clearly which happened. To expose this version
publicly, use `/artor:share`.
