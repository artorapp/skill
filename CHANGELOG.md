# Changelog

All notable changes to the Artor Claude Code skill (the `artor` plugin + marketplace) are
documented here. Format follows [Keep a Changelog](https://keepachangelog.com/); this project
uses pre-1.0 (0.x) semver — new user-visible capability bumps MINOR, fixes/docs bump PATCH.

After a version bump, users pull it with `claude plugin marketplace update artor && claude plugin
update artor@artor` (update only fires on a version bump).

## [0.6.1] - 2026-06-30

### Added

- **Monorepo guidance** — `SKILL.md` gains a new "Monorepos: run per-app, from the app's own
  directory" section so an agent knows how to proceed inside a workspace repo. It spells out that:
  - the `artor` CLI has **no** workspace or monorepo awareness: `artor init` and `artor publish`
    operate on the **current working directory** (they read the cwd's `package.json`, detect the
    framework, and build there), with no app picker and no workspace scanning;
  - running at a monorepo/workspace root finds no `build` script and **fails**, because the root
    is not a publishable app;
  - the model is **per-folder** — before `init`/`publish`, the working directory must be the
    specific app's directory whose `package.json` carries the `build` script and the framework
    dependency (e.g. `next`), never the workspace root, and the `.artor` link is per-folder too;
  - **detect a monorepo first** by checking for a `workspaces` field in the root `package.json`
    or a `pnpm-workspace.yaml`, and if present treat it as a workspace root, not an app;
  - then **`cd` into the target app** (e.g. `cd apps/web`) and run `artor init`, then
    `artor publish`, from inside it;
  - if the user has not said which app, **ask** which subfolder to publish rather than guessing.

### Notes

- Docs-only skill change; no command surface, flag, or CLI behavior changed. This clarifies
  **where** the existing `init`/`publish` commands must be run in a multi-app repo. No invented
  flags or picker — none exist. PATCH bump per the pre-1.0 (0.x) wording/guidance rule.

## [0.6.0] - 2026-06-29

### Added

- **Publish boot test** — `SKILL.md` now documents that `artor publish` boot-tests a live app
  before upload: Artor starts it exactly as the server will and waits for it to listen, and if
  it crashes on startup (e.g. a missing dependency) publishing **stops on your machine** with the
  crash output, so a version that can't run never goes live. Agents are told the boot test passes
  as soon as the app listens (it doesn't slow a healthy publish).
- **`--no-smoke` escape** — documented for the case where a publish fails the boot test because the
  app legitimately needs live secrets/services to start; re-running with `--no-smoke` skips it.
- **Package-manager detection** — clarified that the build uses the project's **own** package
  manager (npm, pnpm, yarn, or Bun), detected from the lockfile each publish, so switching managers
  is picked up automatically.
- **`artor pull` sets up `.npmrc`** — documented that pulling a private-package prototype now
  configures your `.npmrc` so scoped packages install immediately **through Artor with your own
  token** — the upstream credential never travels to a remixer's machine.

### Notes

- Mirrors `artor-cli` 0.11.0 (the release that ships `--no-smoke`, Bun detection, the boot test,
  and the `pull` `.npmrc` setup). Docs-only skill change; no command surface added here.

## [0.5.1] - 2026-06-26

### Added

- Documented the **`artor install` command family** in `SKILL.md` / README: `install-claude-plugin`
  (native Claude Code plugin via the `claude` CLI) vs `install-skills` (every other tool — Codex,
  Cursor, Gemini, Copilot, … — via the Vercel `npx skills` CLI, cross-platform). Bare `artor install`
  asks which on a TTY. (Backfilled changelog entry — the bump shipped in 0.5.1.)

## [0.5.0] - 2026-06-26

### Added

- Documented that **live share links are recopyable** via `artor share list` (the bearer twin of the
  dashboard's re-display), so a designer can recopy a still-live link from the terminal — plus
  reporting guidance for sharing flows. (Backfilled changelog entry — the bump shipped in 0.5.0.)

## [0.4.1] - 2026-06-25

### Added

- Documented two previously-missing CLI commands in `SKILL.md` (new "CLI itself" table):
  - **`artor update`** — self-updates the CLI; called out as the fix for an **HTTP 426 Upgrade
    Required** response (server's minimum-CLI floor bumped).
  - **`artor dev`** — retarget the CLI at a local/custom dashboard for development, with the
    caveat that it **clears the stored token + default org** on every switch (`artor dev off`
    restores production).

## [0.4.0] - 2026-06-25

### Changed

- **Renamed `/artor:start` → `/artor:start-here`** (clearer first-run entry point). Update any
  muscle memory or docs that referenced `/artor:start`.
- Clarified that the walkthrough **installs** the `artor` CLI (`npm install -g artor-cli`) when
  it's missing, not merely checks for it — reflected in the command description and README.

## [0.3.0] - 2026-06-25

### Added

- **`/artor:start`** — first-run walkthrough command. Checks the `artor` CLI is installed (and
  guides `npm install -g artor-cli` if it's missing) before signing in, linking a project,
  publishing the first version, and optionally sharing it.
- **`/artor:publish`** — ship the next version end-to-end: preconditions check, diff-based
  bullet-point changelog generation (secret-excluded), `artor publish --message`, and a faithful
  report of the version number + preview URL.
- **`/artor:share`** — create, list, extend, or turn off an anonymous view-only public link to a
  published version, with the one-time-token and "turned off, never revoked" semantics spelled out.
- **`/artor:address-comments`** — full reviewer-feedback loop: read open threads
  (`artor comments --open --json`) → fix in code → re-publish → `artor comments resolve <threadId>`.

### Changed

- `SKILL.md` command reference now lists `artor comments resolve <threadId>` / `reopen <threadId>`.

### Fixed

- Corrected the stale "**Read-only:** `artor comments` cannot mark a thread addressed" note in
  `SKILL.md` — the CLI gained `comments resolve|reopen`, so the skill now documents resolving
  threads from the CLI (the headless twin of the in-page widget's resolve button).

## [0.2.0] - 2026-06-25

### Added

- Documented **plain-HTML / no-build static publish**: a hand-written root `index.html` (plus
  assets) publishes as a static site with no framework or build step, including the
  "must be named `index.html`, never guesses the entry page" rule.

## [0.1.0] - 2026-06-25

### Added

- Initial Artor Claude Code skill: the `artor` plugin (`SKILL.md` wrapping the full `artor` CLI
  surface — auth, project lifecycle, publish/open/review, sharing, org knowledge, operator),
  the `artor` marketplace, the `skill.sh` one-line installer, and the `DEPLOYING.md` release
  runbook.
