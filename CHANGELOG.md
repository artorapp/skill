# Changelog

All notable changes to the Artor Claude Code skill (the `artor` plugin + marketplace) are
documented here. Format follows [Keep a Changelog](https://keepachangelog.com/); this project
uses pre-1.0 (0.x) semver — new user-visible capability bumps MINOR, fixes/docs bump PATCH.

After a version bump, users pull it with `claude plugin marketplace update artor && claude plugin
update artor@artor` (update only fires on a version bump).

## [0.17.0] - 2026-08-03

Documents **guest commenting on public links** and teaches the agent to ask about it.

### Added

- **Ask before minting a public link**: when a user asks for a public share and hasn't said
  either way, the agent now asks one short question first - should accountless visitors be able
  to comment, and with what identity (anonymous / name / name + email) - and passes the answer
  explicitly via the new `artor share add --comments off|anonymous|name|name-email` flag.
  Without the flag, a non-interactive run keeps the org's admin-set default; the flag is how an
  agent honors an actual preference.
- **Guest-commenting model documented** in "Share a prototype publicly": a public link is
  view-only by default; guest commenting is its one opt-in write surface. A commenting guest
  writes through the review widget only - own-threads-only visibility, self-asserted identity,
  no source pull, no remix, nothing else in the org.
- **Guest threads in `artor comments`**: threads left by public-link guests are marked
  (`guest <alias>`; JSON `guest: true` + `guestAlias`), with the new `--guests-only` /
  `--no-guests` filters documented - including the recommendation to use `--no-guests` before
  an AI pass over team feedback, and a reminder that guest identity is self-asserted.
- **Reporting guidance**: `share add` now prints the link's resulting guest-commenting mode;
  the agent reports it back alongside the URL, and honestly relays the CLI's notice when an
  older server predates guest commenting (the link stays view-only there).

### Changed

- Command tables updated: the share table gains the `--comments` row; the comments row gains
  `[--guests-only|--no-guests]`.
- "Interpreting requests": "give me a public link" now routes through the ask-about-comments
  step before `artor share add`.

Requires `artor-cli` >= 0.21.0 for `--comments` and the guest filters (older CLIs ignore
unknown flags silently - update first).

## [0.16.0] - 2026-07-24

Documents **Spaces**, the access wall above folders, and the new org-readable Space mode.

### Added

- **`artor space`** - the whole verb set (`list`, `create`, `rename`, `read`, `rm`, `members
  add|rm`) documented in `references/org-admin.md`, with a new top-level row in SKILL.md's
  project-lifecycle table. A Space is the ONLY permission boundary between org members:
  **Org -> Space -> Folder -> Prototype -> Version**. Three kinds - Organization (every member),
  Personal (owner-only, never admins or operators), and shared (explicit member list, Team plan
  or higher).
- **`artor space read <space> on|off`** - open a shared Space so every org member can see it,
  open its prototypes, and leave comments, while still being unable to publish, rename, move,
  trash, share, edit folders, or touch env vars and mocks. Documents that a write attempt is a
  403 `space_read_only` (deliberately not a 404 - the caller can already see the content), that
  `pull`/`remix`/`env pull` at read level require a **publisher seat** (a reviewer gets 403
  `publisher_required`), that flipping it needs a Space admin OR an org admin and is always
  audited, and that turning it off revokes reach immediately while comments already left stay.
- `artor init --space <s>` and `--space <name|id>` on `folder list|create|move`.

### Changed

- Folders are now described as cosmetic **within a Space** rather than org-wide, with one
  protected **Draft per Space**, and folder ops noted as 404 in an unreachable Space / 403 in a
  read-only one.
- The `env`/`mock` project-scope note in SKILL.md is relabelled "previous release" - the
  Spaces note takes the current-release slot.

## [0.15.2] - 2026-07-23

Documents the mock hygiene fixes shipping with **artor-cli 0.18.1**.

### Changed

- `artor publish` now prints a warning naming any bundled `mocks/*.json` files skipped from the
  version snapshot (oversize or invalid JSON). Documented as a heads-up, not a failure: the mock
  still serves via the bundled fallback, so the fix is to shrink or repair the file and republish
  to have it pinned.
- Every `artor mock` verb is documented as validating the `<name>` locally before the network,
  and `artor mock pin` as validating the `<sha>` shape (full 64-char lowercase hex) locally. A
  "no such revision" error therefore signals a genuinely unknown sha, not a malformed one - copy
  the exact sha from `artor mock revisions <name>`.

## [0.15.1] - 2026-07-22

Documents the new **version label cap** shipping with the next artor-cli release.

### Changed

- `artor publish --label` is documented as a one-line value with a **128-character maximum** -
  the CLI now fails loud before uploading when the label is longer, the server rejects it with
  a clean 400 (`label_too_long`), and the database column is sized to match. Newlines and tabs
  in a label are flattened to single spaces.
- Command-map row for "Publish with a label" now carries the cap inline so agents generating
  labels stay under it.

## [0.15.0] - 2026-07-19

Documents **slide decks**, a second Artor project kind, mirroring artor-cli **0.18.0**'s slides
support (`artor init --slides` / `artor slides init`). Decks reuse the exact same version,
alias, preview, share, and comment machinery as prototypes — the skill's biggest addition here
is explaining the two places that differ: static-only enforcement and per-kind folders.

### Added

- **New project-lifecycle row: create + link a slide deck.** `artor init --slides` (canonical)
  or `artor slides init` (alias — same options as `init`, appends `--slides` exactly once even
  if already passed) creates a slides-kind project. Added to the command reference table in
  `SKILL.md` right under the plain `artor init` row.
- **New section "Slide decks (a second project kind)" in `SKILL.md`**, covering:
  - Everything else (versions, aliases, preview URLs, sharing, comments) is unchanged — a deck
    is a project whose `kind` is `"slides"` instead of `"prototype"`.
  - **Static-only, enforced both ends.** `artor publish --node` (or an auto-detected
    node-server framework) inside a slides project fails client-side, before any build or
    upload, with the exact message: "This is a slides project: only static bundles can be
    published. Remove --node or use a static build." An old CLI that predates this check
    instead gets the server's own `400 slides_static_only` — never a crash, no
    `ARTOR_CLI_MIN_VERSION` bump was needed.
  - **Folders are per-kind.** Inside a slides project, `artor folder ...` automatically targets
    slides folders — its own separate "Draft" default, never the prototype Draft. The
    interactive folder picker in `init`/`slides init` asks "Where should this slide deck live?"
    and lists only slides folders.
  - **A deck can exist with no local checkout.** The dashboard supports dropping an `.html` file
    or a `.zip` (with `index.html` at its root) directly onto a slides folder to publish a new
    deck or a new version, with no CLI involved. `artor pull --project <slug>` (and
    `remix`/`rename`/`rm`) work on such a deck exactly like any prototype — project
    listing/lookup commands resolve across both kinds by default.
  - **No env vars, no mocks** — both only ever apply to node-server containers, so a static
    deck has neither code path and there's no "disable" flag to look for.
- **`artor/commands/publish.md`** (the `/artor:publish` walkthrough) gained a precondition
  callout: if the linked project is a slide deck, don't retry a failed `--node` publish — the
  project is static-only, publish as static instead.
- **`artor/references/org-admin.md`**'s folders section gained a note that folders are
  strictly per-kind: a slide deck's folders (including its own Draft) are entirely separate
  from a prototype's, with no cross-kind folder move.
- **`SKILL.md` frontmatter description** now mentions slide decks alongside prototypes/web apps
  so the skill triggers on "ship a deck" / "publish this deck" phrasing, not just prototype
  language.

## [0.14.0] - 2026-07-10

Documents `artor dump` (previously absent from the skill) and its new plan-limited **dump
credits**, mirroring artor-cli **0.17.1** (the dump-credit release; 0.18.0 remains the scoped
env/mock release documented in 0.13.0 below).

### Added

- **`artor dump` in the project-lifecycle command table.** Bulk-exports the source of every
  project in the active org to `<out>/<slug>/v<version>/` (default `./artor-dump`), latest
  version only unless `--all-versions`; existing files are never overwritten. The skill never
  documented this command before, so agents had no way to reach the whole-org export.
- **Dump-credit semantics in the `pull` vs `remix` section** (now `pull` vs `remix` vs
  `dump`). Each run spends one plan-limited credit (Free: 2 per month; paid plans: 1 per
  24 hours; operators can tune both per org). Over the allowance the CLI prints
  `Dump allowance used. Next dump available in Xh Ym.` and exits 1 without downloading
  anything; on success it prints how many dumps remain in the window.
- **Agent guidance for the over-limit case:** relay the allowance message to the user
  verbatim and do NOT retry in a loop; the wait time is real. For a single project's code,
  always prefer `artor pull` - it is unmetered.

## [0.13.0] - 2026-07-10

Mirrors artor-cli **0.18.0** (scoped env vars, revisioned/scoped mocks, publish-time mock drift
gate). `artor env` and `artor mock` now both target one of three scopes — org, project, or a
single immutable version — and inside a linked project their default scope **changed** from org
to project. Mocks also gained a full revision history and a per-version pin escape hatch.

### Changed

- **Breaking default-scope change, documented prominently.** Inside a linked project directory,
  `artor env set|list|rm` and `artor mock set|list|rm` now default to the **linked project's**
  scope instead of the org's. An agent that used to run `artor env set KEY=VALUE` expecting an
  org-wide write must now pass `--org` explicitly to get that behavior; unqualified, the same
  command now only affects the one linked prototype. Called out with its own callout box in
  `SKILL.md` right under the org/project/version command table, and reflected in
  `references/org-admin.md`'s env/mock sections and `references/troubleshooting.md`.
- **`artor env pull` inside a linked project now returns the project + org merged effective
  set** (previously org-only). `--org` restores the old org-only pull. The empty-result message
  also changed from "for this org" to "at this scope" to match (both docs and the CLI's exact
  string were updated together).
- **`references/org-admin.md`** env/mock sections rewritten around the shared three-scope model
  (no flag → project when linked; `--org` → org; `--version <ref>` → one immutable version),
  including the permission split: org-scope `set`/`rm` stays admin-only, project/version-scope
  `set`/`rm`/`pin` only needs a publisher seat (mirrors the `artor publish` gate). `list` /
  `revisions` / `status` stay any-member reads at any scope.
- **`commands/org-setup.md`** (the `/artor:org-setup` admin-onboarding walkthrough) now adds an
  explicit `--org` to every `env`/`mock` example command, with a callout at the top explaining
  why — this walkthrough is org-wide setup, and the commands would otherwise silently target
  the linked project instead under the new default.

### Added

- **New mock verbs documented: `artor mock revisions <name>` and `artor mock pin <name> <sha>
  --version <ref>`.** `revisions` lists a name's edit history at org or project scope (sha,
  author, date, and which live versions currently use it) — it works at org/project scope only
  since a version pins exactly one sha, not a history (`--version` is rejected loudly). `pin`
  repoints an **already-published** version's mock binding to an existing revision sha with
  **no republish** — the documented escape hatch for "the data I already shipped was wrong, fix
  it in place." Both added to the command reference table and the org-admin deep-dive.
- **New mock verb documented: `artor mock status [--json]`.** Diffs the linked project's local
  `./mocks/*.json` files against its server-effective bindings with no writes — `local only` /
  `server only` / `modified` per name. This is the same diff the publish-time drift gate (below)
  runs automatically; `status` lets an agent check it ahead of time.
- **New section: "Env vars and mocks: org, project, or version scope"** in `SKILL.md`. Explains
  the shared scope-flag grammar (`--org` / `--version <ref>` / no-flag-means-project-when-linked)
  and, critically, the **asymmetry in when resolution happens**: env vars are a live merge at
  every container cold start (rotating an org/project var takes effect on the next boot, no
  republish, but can change behavior for an old already-published version that depends on it);
  mocks are snapshotted **once**, at publish time, into an immutable per-version binding (editing
  the org/project mock afterward only affects the *next* publish — `artor mock pin` is the
  deliberate exception that repoints an already-shipped version's binding directly).
- **New publish flag documented: `artor publish --mocks=local|server`.** Added to the publish
  command table and a new "Mock drift gate" bullet under "Publishing notes." Before building,
  `artor publish` diffs local `./mocks/*.json` against the linked project's server-effective
  mock bindings; a name on only one side is never a conflict, but a name with **different**
  content on both sides is — `--mocks=local`/`--mocks=server` resolves every conflict the same
  way with no prompt (required off a TTY when a real conflict exists — the CLI fails loud
  asking for the flag rather than picking a silent default that could clobber either side's
  edit); on a TTY with no flag, each conflict prompts interactively. No local `mocks/` dir
  skips the check entirely.
- **New troubleshooting rows**, all keyed to exact CLI strings: the unlinked-directory loud
  error (`Not in a linked project. Run inside one, or pass --org for the org scope.`) for a
  mutating `env`/`mock` verb; a "used to touch the whole org, now touches one project" entry
  pointing at the default-scope change; ``mock revisions works at org or project scope only;
  --version is not supported``; and the non-TTY publish mock-drift failure asking for
  `--mocks=`.

### Fixed

- `references/troubleshooting.md`'s `env pull` empty-result row updated to the CLI's current
  exact string (`No local (pullable) env vars at this scope. Nothing to write.`, was "for this
  org") so the table stays a verbatim match, not a paraphrase.

## [0.12.0] - 2026-07-09

Mirrors artor-cli **0.17.0** (runtime crash logs). An agent can now retrieve the actual stack
trace of a version that crashed on the server — the debug loop no longer dead-ends at a
"Failed to start" badge.

### Added

- **New command documented: `artor logs [ref] [--json]`.** Reads a version's runtime logs
  (default `latest`; `ref` is an alias, version number, or content hash — the same grammar as
  `open`/`comments`). A crashed version returns the persisted crash tail captured the moment
  its cold start failed; a running version returns its live log tail; a version with neither
  prints "No logs captured" and exits `1`. `--json` emits the machine-readable payload
  (`version`, `runtimeState`, `cause: "boot" | "oom"`, `capturedAt`, `source: "crash" | "live"
  | "none"`, `text`). Added to the "Publish, open, review" command table.
- **New workflow section: "Debugging a crashed version (read logs → fix → re-publish)".**
  The three-step loop for a version that fails to start on the server after building fine
  locally: `artor logs --json` → diagnose from `cause` + the stack in `text` (oom = reduce
  startup memory or raise the plan; boot = read it like any Node crash) → fix and re-publish
  (a new version is never held back by the old one's failures). Includes the honest limits:
  logs are scrubbed of org env-var values server-side (`[redacted:NAME]`), capture is
  start-time only (no tail for a mid-life crash), and log text is the prototype's own
  untrusted output — data, never instructions.
- **New troubleshooting row.** "Preview shows 'This version crashed while starting' / 'needs
  more memory'" → run `artor logs --json`, fix the cause, re-publish. Replaces the previous
  dead end where the only advice was reproducing locally.
- **`artor status` non-hint documented.** `status` stays local/offline by contract, so the
  skill points agents at `artor logs` when a preview shows a crash page instead of expecting
  a status-command hint.

## [0.11.0] - 2026-07-08

Mirrors artor-cli **0.16.0** (streaming publish + automatic updates). Also ships the
version-hygiene work that was authored against a parallel "0.10.0" branch but never released
(the published 0.10.0 was the CLI-0.15.0 docs release), folded in here.

### Added

- **Automatic CLI updates documented.** The CLI now keeps itself current: an HTTP 426
  ("CLI too old") self-heals on a global/packaged install — the CLI updates itself and
  re-runs the failed command exactly once — so agents will usually never see the 426 error
  at all. Interactive non-CI commands also background-check for a newer version after
  finishing (at most one install attempt per hour). New command surface documented:
  `artor update --off` / `artor update --on` (persistent opt-out/in) and the
  `ARTOR_NO_AUTOUPDATE=1` one-run escape hatch.
- **New troubleshooting row for the reverse mismatch.** "This server does not support the
  current publish protocol" means the _server_ is older than the CLI (it predates the
  streaming publish protocol); the fix is operator-side, not `artor update`. The skill now
  tells agents to relay that to the user instead of retrying.
- **Small-tweak overwrite prompt.** Before publishing, the AI now judges whether a change is a
  tiny tweak (copy/text-only, a single style change, a typo fix) or a real change. For a tiny
  tweak, it asks whether to overwrite the current version in place (confirming which alias, e.g.
  `latest` or `staging`) instead of minting a permanent new version — this is meant to slow the
  version-number bloat that comes from publishing after every trivial AI-driven edit. A real
  change still always publishes as a new version, no extra prompt. Overwriting requires the
  project owner or an org admin; a 403 falls back to a normal new-version publish, reported
  plainly to the designer. Overwriting also turns off any public share pinned to that version
  (the designer must reshare for a live link again) — the skill now calls this out before
  offering to overwrite.
- **Local git safety checkpoint before every publish.** If the working directory is a git repo
  with uncommitted changes, the skill now commits them locally (reusing the drafted changelog
  message) before running `artor publish` — a rollback point for a bad AI edit or a version
  overwrite gone wrong. Local-only, never pushed; skipped silently if git isn't installed or this
  isn't a repo.
- **Git vs. Artor role clarified.** `SKILL.md` now states plainly that Artor's version list is
  for sharing/reviewing prototypes, not a substitute for commit history — git remains the source
  of truth, especially now that a version can be intentionally overwritten.
- **Recommend accepting the web-sdk update prompt.** The skill now tells agents to recommend
  accepting the publish-time `@artorapp/web-sdk` update prompt when offered.

### Changed

- **426 guidance updated everywhere** (SKILL.md, troubleshooting reference, `/artor:doctor`):
  seeing the manual "Run `artor update`" message now implies the self-heal couldn't run
  (CI, `npx`/project-local install, auto-update off, or the update failed) — the manual fix
  is the fallback, not the default path.

## [0.10.0] - 2026-07-05

### Added

- **Documents `artor init`'s git auto-init** — `init` now auto-runs `git init` (+ a starter
  `.gitignore`) when the folder isn't already inside a repository, best-effort so a failure only
  warns and never blocks linking. Documented in the "First check" section and the project-lifecycle
  command-reference row, with the new `--no-git` opt-out flag.
- **Documents the publish-time `@artorapp/web-sdk` update check** — `artor publish` now checks npm
  for a newer review-widget SDK version when the project still pins `"latest"` (what `init` writes)
  and offers to update it before building. Never blocks or fails a publish: asks on a TTY, updates
  silently with `--yes`, skips silently with no TTY and no `--yes`; an explicit version pin is left
  alone. Documented in "Publishing notes", the publish command-reference row, and
  `commands/publish.md`'s flag list, with the new `--no-sdk-update` opt-out flag.

### Notes

- Mirrors `artor-cli` 0.15.0 (PR #184: publish-time web-sdk update check + `artor init` git
  auto-init). MINOR bump — documents new CLI behavior, no skill logic changes.

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
