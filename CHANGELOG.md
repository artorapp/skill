# Changelog

All notable changes to the Artor Claude Code skill (the `artor` plugin + marketplace) are
documented here. Format follows [Keep a Changelog](https://keepachangelog.com/); this project
uses pre-1.0 (0.x) semver — new user-visible capability bumps MINOR, fixes/docs bump PATCH.

After a version bump, users pull it with `claude plugin marketplace update artor && claude plugin
update artor@artor` (update only fires on a version bump).

## [0.9.0] - 2026-07-02

### Added

- **`address-comments` skips `aiIgnored` threads.** `artor-cli` 0.15.0 adds `artor comments
  ignore|unignore <threadId>` and an `aiIgnored` field on every thread in `artor comments --open
  --json`. A reviewer sets `aiIgnored` specifically to keep an automated pass off a thread, so both
  `/artor:address-comments` and the `SKILL.md` "Address review feedback" walkthrough now:
  - filter `aiIgnored: true` threads out of the gather step (`jq '.threads |= map(select(.aiIgnored
    != true))'`) before doing anything with them;
  - explicitly call out that `artor comments resolve`/`reopen` must never be called on an
    `aiIgnored` thread — it's off-limits, not "already handled";
  - the command-reference table gains `artor comments ignore|unignore <threadId>`.

### Notes

- Mirrors `artor-cli` 0.15.0. MINOR bump — documents new CLI behavior the skill must honor.

## [0.8.0] - 2026-07-02

### Added

- **Structured `--json` guidance for artor-cli ≥ 0.14** — the CLI now offers `--json` on every read
  command, and the skill points agents at it instead of scraping human tables:
  - covered surfaces: `status`, `whoami`, `project list|search`, `share list`, `comments`, `trash`,
    `folder list`, `env list`, `mock list`, `skill list`, and `open`;
  - **`artor open --json`** highlighted as the headless way to grab the preview URL — it prints
    `{ "url": … }` and does **not** launch a browser (new command-reference row, publishing note,
    and the "get me the link" interpretation now use it);
  - convention documented: `--json` prints the payload to stdout and suppresses the human
    rendering; if the flag is rejected, the CLI is older than 0.14 → `artor update`.

### Notes

- Mirrors `artor-cli` 0.14.0 (the terminal-UI polish release: `--json` coverage, unified error
  renderer, sub-command `--help`, `open` empty-state now informational with exit 0). MINOR bump —
  documents new CLI behavior.

## [0.7.0] - 2026-07-02

Major rewrite and restructure. `SKILL.md` is now agent-agnostic (any coding agent, not just Claude
Code), leaner, and split into on-demand reference files; four new slash commands; a troubleshooting
reference; and every fact re-validated against `artor-cli` 0.13.0 source.

### Added

- **Four new slash commands:**
  - **`/artor:remix`** — fork someone else's prototype into a new project you own end-to-end:
    `artor remix <project> [name]` (non-TTY needs a name/`--name`), what remix does and does **not**
    do (no dep install, no build), then `cd` in → install with the detected package manager →
    `artor publish` to ship the fork's v1. `.npmrc` is re-derived automatically for private packages.
  - **`/artor:pull`** — fetch a version's exact source safely: warn before overwriting a dirty
    working tree (branch or `--dir` into a fresh dir), `artor pull --ref <version>`, notes on staying
    linked (next publish ships the same project's next version) and automatic `.npmrc` setup.
  - **`/artor:doctor`** — troubleshooting walkthrough. No CLI `doctor` command exists, so it
    orchestrates `artor --version` → `artor status` → `artor dev status` → monorepo check →
    `artor whoami`/`org list`, then matches any error against the troubleshooting reference and
    reports the root cause + fix rather than guessing.
  - **`/artor:org-setup`** — admin onboarding walkthrough (owner/admin role, admin-gated steps
    marked): env vars (local vs server-only decision), mock datasets, org skills, starter templates,
    private registries. Confirms before each write; reports what was configured.
- **`references/` split** — `SKILL.md` now links three on-demand deep dives instead of carrying
  everything inline:
  - **`references/review-widget.md`** — SDK wiring per framework, manual wiring, the update
    procedure, plus the 0.12.1 facts (init auto-installs `@artorapp/web-sdk`; publish self-heals a
    missing install).
  - **`references/org-admin.md`** — env (local/pullable vs server-only, values write-only, `env pull`
    managed block), mock (fallback-not-override, `promote` copies `mocks/<name>.json`), skills
    (add/pin/enforce/sync, `--credential`/`ARTOR_GITHUB_TOKEN`), templates, registry (login writes a
    managed `.npmrc` with the caller's own token; upstream PAT never leaves the server; `--expires`),
    folder verbs (incl. `--with-content` admin gating, Draft immutability), and the operator table.
  - **`references/troubleshooting.md`** — new symptom → cause → fix table using **exact** CLI error
    strings (426, boot-smoke failure, workspace-root errors, `html-no-index`, `pull failed (HTTP …)`,
    `No live versions to open`, `Already linked … --force`, dev-mode logout, `No local (pullable) env
    vars…`).
- **New inline facts in `SKILL.md`:** preview URLs are members-only; `artor open` prints the URL
  first and falls back to `(open it manually: <url>)` (headless-safe); the post-publish smoke check
  is warn-only; a teammate with a plain `git clone` of an already-linked project runs `artor link`;
  a "When NOT to use" section (not a production host, not git, `artor dev` never in a normal flow);
  a note to prefer `--json` where it exists.

### Changed

- **`SKILL.md` audience is now any coding agent** — no `/artor:*` or Claude-specific machinery in
  `SKILL.md`/`references/` (those live only in `commands/`). The frontmatter `description` was
  rewritten per skill-authoring best practice: third person, "Use when", **only** triggering
  conditions (publish/deploy/ship/preview/share/remix/comments/restore vocabulary users actually say)
  — no capability summary. The file is **shorter** than before despite the new facts, via the
  references split.
- **Boot-test + monorepo guidance propagated into the commands** — `start-here.md` and `publish.md`
  gained the monorepo pre-check (cd into the app from a workspace root) and boot-test failure
  handling (read the crash, fix the build; `--no-smoke` only for apps that legitimately need live
  services — never as a reflex). Previously these lived only in `SKILL.md`.
- **Changelog flow uses `mktemp -d` + cleanup** — the previous-version snapshot now pulls into a
  unique temp dir with an explicit `rm -rf` after diffing, replacing the fixed `/tmp/artor-prev-source`
  path that could carry stale contents from a different project.
- **Commands thinned to the shared pattern** — each command is a short workflow skeleton plus
  explicit pointers into the auto-loaded `/artor:artor` skill, so explanatory prose lives once.
- **README rewritten around the multi-agent story** — one skill, every agent: Claude Code (full
  plugin: knowledge skill + slash commands) vs everything else (knowledge skill via
  `artor install-skills` / `npx skills add artorapp/skill`). Commands table lists all eight commands;
  Layout documents `references/`, `scripts/`, and CI; LICENSE (MIT) called out.

### Fixed

- **`start-here.md` share step no longer contradicts 0.5.0** — it claimed a "one-time token … never
  re-retrievable", the opposite of `share.md`/`SKILL.md` (live links are recopyable via
  `artor share list`). Rewritten to match: the URL prints at `share add` and is recopyable any time
  the link is live. (`check-release.mjs`'s drift guard now rejects this wording anywhere.)
- **Corrected the install family** — canonical `install-skills` (plural; `install-skill` is a legacy
  alias) via `npx skills`, **cross-platform including Windows**, for every non-Claude tool; the old
  `curl | bash` route no longer exists in the CLI; bare `install` shows a TTY picker; `update-skill
  [claude-plugin|skills]` refreshes an install. Fixes the stale "macOS/Linux-only / curl|bash"
  claim in `SKILL.md` and README.
- **HTTP 426 wording** — now quotes the real CLI message
  ("This CLI is too old for the Artor server. Run `artor update`.").
- **`pull` failure wording** — both no-previous-version and legacy-no-source now documented as the
  relayed `pull failed (HTTP <status>): <server message>` (the CLI passes through the server text);
  the agent is told to read the relayed message rather than expect distinct CLI wording.
- **`share list` off-hint wording** — disabled links show `(off — reshare to copy)`, expired/legacy
  show `(reshare to copy)` (was collapsed into one).
- **Secret-exclusion list aligned** with the real force-excluded set (`.envrc`, `.yarnrc*`,
  `credentials*`, `id_rsa*`, `kubeconfig`, etc.), keeping the "and similar" hedge.
- **Missing flags documented** where relevant: publish `--entry`/`--yes`/`--no-install`, init
  `--org`, remix `--name`/`--org`, skill `--credential`, registry `--name`/`--expires`.

### Repo infrastructure

- **CI** (`.github/workflows/ci.yml`) runs `scripts/check-release.mjs`, `claude plugin validate`, and
  a local markdown-link check on every push/PR.
- **`scripts/release.sh`** — one-step version bump of both manifests + checks + `plugin validate` +
  staging.
- **`scripts/check-release.mjs`** — drift guards (version match, changelog entry, command
  frontmatter, referenced `references/*.md` exist, share-link one-time-token wording rejected,
  frontmatter ≤ 1024 chars).
- **LICENSE (MIT)** added; **`plugin.json` metadata** (author, homepage, repository, license,
  keywords) filled in.
- **`skill.sh` robustness** — distinguishes "already installed" from real (network/auth) failures
  and surfaces both errors instead of masking the first.

### Notes

- Mirrors `artor-cli` 0.13.0 (validated against source): symlink-preserving node-server publish
  (0.12.0), web-sdk auto-install + publish self-heal (0.12.1), verbose-log secret redaction and
  Windows spawn correctness (0.13.0). No manifest version bump in this commit — that happens at
  release time via `scripts/release.sh`.

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
