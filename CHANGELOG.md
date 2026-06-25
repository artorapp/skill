# Changelog

All notable changes to the Artor Claude Code skill (the `artor` plugin + marketplace) are
documented here. Format follows [Keep a Changelog](https://keepachangelog.com/); this project
uses pre-1.0 (0.x) semver — new user-visible capability bumps MINOR, fixes/docs bump PATCH.

After a version bump, users pull it with `claude plugin marketplace update artor && claude plugin
update artor@artor` (update only fires on a version bump).

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
