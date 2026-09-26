# Changelog

All notable changes to the Artor Claude Code skill (the `artor` plugin + marketplace) are
documented here. Format follows [Keep a Changelog](https://keepachangelog.com/); this project
uses pre-1.0 (0.x) semver — new user-visible capability bumps MINOR, fixes/docs bump PATCH.

After a version bump, users pull it with `claude plugin marketplace update artor && claude plugin
update artor@artor` (update only fires on a version bump).

## [0.23.1] - 2026-09-26

Docs-only PATCH, keeping the skill in step with the CLI and the website.

- **Settings paths use `>`.** "Settings > CLI tokens" now matches the CLI's own advice lines
  ("Settings > Billing", "Settings > Team") and the website.
- **`--mocks` takes the space form.** The mock drift gate notes that artor-cli 0.28.0+ also
  accepts `--mocks local|server`, not only `--mocks=local|server`.

## [0.23.0] - 2026-09-26

Mirrors artor-cli **0.28.0**, which ships two features together: the **source snapshot ignore
rules** with a **50 MB source cap**, and **static build size by plan** with **usage bars** and a
**pricing page for agents**. `artor publish` now builds its source snapshot through one ignore
engine that honours every `.gitignore` in the tree plus a new `.artorignore`, and refuses an
oversized snapshot locally with a directory breakdown before any upload; at the end of a publish
it shows how close the build, the source, storage and public-link views are to their limits.
MINOR bump: an agent gains new command surface (`--list-source`, `.artorignore`, the `usage`
object) and new failure modes it must resolve with an ignore rule or the step the CLI names,
never a workaround. **Requires artor-cli 0.28.0+** for the new behavior.

### Added

- **`artor/SKILL.md`, new "What goes into the source snapshot" note** under "Publishing notes":
  - The snapshot file list is built by ONE engine with no git dependency: `.gitignore` files at
    every level plus the parent directories up to the repository root (each scoped to its own
    directory, so a nested app's `ios/`, `android/`, `dist/` or `.expo/` is never uploaded and a
    monorepo's root rules still apply from a sub-app), then `.artorignore` files (same syntax, add
    excludes for tracked-but-private files or force-include a gitignored file or directory with
    `!pattern`), then the hardcoded secret and directory excludes that no ignore file can negate.
  - The hardcoded excludes list `.git-credentials`, `.pgpass`, `.dev.vars` and the `.docker` and
    `.claude` folders next to `.env*`, `.npmrc`, key files and the other secret files.
  - A project with no git works the same with only `.artorignore`; `.git/info/exclude` and the
    global git excludes are not read; ignored directories are never walked.
  - **The snapshot is capped at 50 MB compressed.** After a `Checking source snapshot…` line the
    CLI stops BEFORE building or uploading when it is over and prints the total plus the heaviest
    directories and files; from 75% of the cap (about 37.5 MB) it warns in one line with the
    percent. The size stop also covers the file-content (200 MB), file-count (100,000) and
    compression ratio limits, and when the file sizes alone already break a restore limit it
    stops without reading any file, with the same report.
  - No override flag: the fix is an ignore rule, verified with the new
    `artor publish --list-source` (`--json` for scripts), which prints every file that would ship
    with sizes and totals and exits without building, signing in or uploading. A server 413 names
    the cap and leads with `artor update`, since a CLI before 0.28.0 reads no ignore file.
  - `--list-source --json` also reports `wouldStop`, `breaches` and `empty` (and `null`
    `compressedBytes` / `sha` when nothing was packed), so an agent can predict a refusal without
    hardcoding any limit.
  - Explicit guidance: never stage a slimmed copy of the project to get under the cap; write an
    ignore rule instead.
  - An empty snapshot (a parent repo's `.gitignore` of `*` or `/apps/**`) is a warning, never a
    stop: the publish ships, the warning names the responsible ignore file, and the agent offers
    `!` patterns in the project's own `.artorignore` if the user wants the source kept.
  - For a hand-written static site served from its root, `.artorignore` also removes a file from
    the served site (never `.gitignore`); the skill steers large-asset fixes to `.gitignore` there
    only when `pull` and remix need not restore them, otherwise to making the file smaller. Ignore
    files are never served.
  - New "Slimming a snapshot" playbook: list the source, sort heavy paths into build output
    (`.gitignore`), tracked-but-unneeded files (`.artorignore`) and files the prototype needs
    (compress, never ignore), write the narrowest pattern, re-check, and tell the user.
  - `.artorignore` is read only inside the published folder; symlinks are skipped when they
    leave the project, point at an excluded or ignored file, or loop; `artor template push` packs
    with the same rules.
- **Prices and plan limits come from https://artor.app/pricing.md.** New rule: for any question
  about prices, what a plan includes or "will this fit on my plan", the agent fetches that page
  and answers from it, never from memory or from this file.
  - Pooled limits explained: storage, views and prototypes running at once grow with each extra
    publisher seat on Pro and Team (Enterprise is by contract); build size and memory never do.
  - Real per-org numbers (custom limits) come from `artor usage` (owner/admin).
  - Only an org owner or admin upgrades (Settings > Billing); anyone else asks an org admin;
    Enterprise is by contact.
- **Usage block after a publish.**
  - Fill bars for this build (against its plan limit) and the saved source (against 50 MB), on
    an interactive terminal or anywhere once one reaches 75%. Every publisher sees these sizes.
  - The org's storage and public-link views (last 30 days) appear only at 75% of the org's
    limit, each with a warning line and one next step the server chose: upgrade the plan
    (Settings > Billing), add publisher seats (Settings > Team), or contact support. A step several
    metrics share is printed once, after their lines.
  - Admins see exact numbers and the per-seat amount; other publishers see a percentage, no
    amounts, and "Ask an org admin to ...". The upgrade step is not offered while self-serve
    upgrades are paused. A step from a server newer than the CLI is printed in the server's own
    words (or the metric shows no step). The agent relays what is printed and never invents an
    upgrade.
  - Views are a notice (they never block a publish); storage at 100% stops new publishes, and
    that refusal shows exact numbers only to an admin.
  - Near-limit warnings go to stderr. `--json`: no bars, and a `usage` object in the result
    (`null` against an older server; the per-seat increment is `perSeat`).
- **Build over its limit (static or live app):** the 413 starts "Build too large:", names the
  "static build limit" or "live app build limit", a self-fix and the step (upgrade the plan, or
  contact support; extra seats never raise a build limit). When an upgrade would help the CLI adds
  "See plan limits: https://artor.app/#pricing". The agent relays the step, and fetches and points
  to https://artor.app/pricing.md only when the step offers an upgrade; a support step is relayed
  as is, with no plan pitch (a custom limit or paused upgrades can rule an upgrade out on any
  plan).
- **Command reference:** new row for `artor publish --list-source`.

### Changed

- **"Secrets are never uploaded" note** replaced: the old wording said secrets were excluded
  "regardless of `.gitignore`", which implied `.gitignore` was honoured when it was not. The new
  note states the real precedence (git rules, then `.artorignore`, then the non-negatable
  excludes).
- **"Describe what changed" step 2** now tells the agent to diff the paths
  `--list-source --json` prints against the previous snapshot, not the whole tree, so gitignored
  files never show up as changes; its secret list gains `.git-credentials`, `.pgpass`,
  `.dev.vars` and `.docker/`.
- **`publish --json` shape** documented with `usage` in SKILL.md and `commands/publish.md`.
- **`artor usage`** (`references/org-admin.md`): bars on storage and views, a `builds:` row with
  the org's static and live app build limits (labelled as an example: the real limits come from
  the server for each org), and the `--json` object the CLI defines,
  `{ plan, storage, seats, views, limits, org }`, with unknown server fields dropped and `limits`
  `null` against an older server.
- Plugin and marketplace `version` bumped to `0.23.0`.

### Compatibility

- Gitignored files that used to ride in the snapshot (and that `pull` restored) are no longer
  uploaded as of artor-cli 0.28.0. Restore a specific one with a `!pattern` line in
  `.artorignore`.

## [0.22.0] - 2026-09-26

Mirrors **signed-in preview links** (artor-cli 0.27.0): `artor open --signed-in` lets an agent load a
members-only preview in a browser it drives, from the CLI login alone. Also mirrors 0.27.0's
stricter value-flag parsing. MINOR bump: an agent gains an ability it did not have before (opening a
members-only preview with no dashboard session), plus handling rules for a short-lived credential it
cannot infer from the old surface. **Requires artor-cli 0.27.0+.**

### Added

- **`artor/SKILL.md`, command table**: a new "Publish, open, review" row,
  `artor open --signed-in --json`, next to the existing `artor open --json` row.
- **`artor/SKILL.md`, "Publishing notes": new "Opening a members-only preview in your own browser"
  bullet**, the agent-facing contract:
  - When to use it: a browser the agent controls (headless Playwright, a fresh profile) for
    debugging or screenshots, with no dashboard session, would otherwise hit the sign-in wall.
  - Output shape: `--signed-in --json` prints `{ url, authUrl, expiresAt }`; `--version <n>` /
    `--alias <name>` pick the version exactly as on plain `open`.
  - What `authUrl` is: a **single-use** signed-in link, valid **60 seconds**, scoped to one
    version's preview host; opening it gives that browser **one hour** of member access to that
    version only.
  - How access ends: after one hour, or at once if the CLI token is revoked in Settings → CLI
    tokens; `artor logout` only forgets the token locally and does not revoke it.
  - Handling rules: open it promptly (within 60s) and exactly once, mint a fresh one if it expired
    or was used; **never** paste it into chat, a PR, an issue, a log, or anything that unfurls
    links (an unfurler consumes it); plain `artor open --json` stays the shareable URL and never
    mints a credential.
  - Older servers: the exact refusal line ("This server does not support --signed-in yet, or the
    prototype is not visible to you.") and the fallback (have the user open `url` in their own
    signed-in browser).
- **`artor/SKILL.md`, "Interpreting requests"**: "screenshot / debug the preview in a browser"
  maps to `artor open --signed-in --json` + one navigation to `authUrl`, reporting `url` (never
  `authUrl`) back to the user.
- **`artor/references/troubleshooting.md`**: two new rows, the `--signed-in` older-server /
  not-visible refusal (check org and project first, then fall back to plain `url`) and the new
  `--<flag> needs a value.` error (supply the value; `--flag=--value` for text starting with `--`).

### Changed

- **`artor/SKILL.md`, "CLI conventions", flag-spelling rule**: since artor-cli 0.27.0 **any** value
  flag followed by another `--flag` or by nothing fails before acting (exit 1), usually with
  `--x needs a value.` (`--org`, `--comments`, `space rm --move-to`, `env`/`mock`
  `--scope`/`--version` and `-m`/`--message` keep their own message), where older CLIs sometimes
  silently ran with a default (the org space for `--space`, latest for `--ref`, 7 days for
  `--days`). A free-text value that really starts with `--` uses the `=` form
  (`--message=--hotfix`, `--desc=--beta`).
- **Manifests**: `plugin.json` and `marketplace.json` bumped to `0.22.0`.

## [0.21.0] - 2026-09-18

Mirrors **link passwords** for public share links (artor-cli 0.26.0). A public link can now ask for
a password before it serves anything: available on every plan, off by default, and set from the CLI
at mint time or on a live link. Also mirrors the new **`--hide-widget`** flag on `share add`, which
creates a link with Artor's in-page review widget hidden from signed-in organization members.
MINOR bump: an agent gains an ability it did not have before, and the way it must run that ability
unattended (pipe the secret, never argv) is new guidance it cannot infer from the old surface.

### Added

- **`artor/SKILL.md`, new "Link passwords" subsection** under "Share a prototype publicly", the
  full agent-facing contract for the feature:
  - Available on **every plan**, off by default, and a link with no password behaves exactly as it
    always has. Needs artor-cli **0.26.0+**.
  - **A password is never a flag value.** `--password` prompts on a terminal (hidden, typed twice)
    and takes **no** value - `--password=hunter2`, `--password hunter2` and `--password -hunter2`
    are all refused rather than silently minting an unprotected link, so the secret can never land
    in shell history or `ps`. On `share set` the password flags go **after** the share id.
  - **The agent path is `--password-stdin`**, with the exact pipe form
    (`printf '%s' "$PW" | artor share add --password-stdin`). It takes no value either, reads
    stdin, strips exactly one trailing newline, and refuses a terminal, a non-UTF-8 read, or an
    over-long one.
  - **Handling rules for the secret itself**: ask the user for the password; if asked to generate
    one, generate a strong value, show it **once**, and state plainly that it cannot be recovered
    later (Artor stores only a hash and re-displays it nowhere). Never repeat it back beyond what
    the user already wrote, never put it in argv, never write it to a file in the project.
  - **Shape rules**: 8 to 128 characters, no control characters, never trimmed (a space counts),
    with the CLI's plain refusal line (`Password must be at least 8 characters.`) and the fact
    that nothing is sent on a refusal.
  - **The organization requirement**: an unattended `share add` with no password is refused with
    403 `share_password_required` and the exact message naming both flags; the documented recovery
    is to get a password from the user and retry with `--password-stdin`. An interactive terminal
    is asked in place instead. `--remove-password` is refused while the requirement is on.
  - **Success lines to relay**, verbatim: `Password: on. Share it separately from the link; it
    can't be shown again.` on `add`, and `password saved` / `password removed` on `set` (prefixed
    `Link <id>: ` when a prefix was passed).
  - **Older-server degradation**: the CLI says the password was **not** applied and exits 1. On
    `add` the link exists WITHOUT a password, so the skill tells the agent not to hand the URL out
    and to run the `artor share off <id>` the message names; on `set`, a `--comments` change sent
    in the same call is reported separately because that half did land.
  - **Visitor side**: the same URL shows a password page, an unlock lasts the browser session up
    to 24h, changing or removing the password re-locks every browser that had unlocked it, and org
    members who can already see the prototype's Space are never asked.
- **`artor/SKILL.md`, share command table**: three new rows - protect a NEW link
  (`printf %s "$PW" | artor share add --password-stdin`), set/change a LIVE link's password
  (`artor share set <share> --password-stdin`), and remove one (`--remove-password`).
- **`artor/SKILL.md`, "Share a prototype publicly"**: a new bullet announcing link passwords next
  to the existing mode/duration bullets, and a new `share list` bullet for the password suffixes
  (below).
- **`artor/SKILL.md`, "Interpreting requests"**: "put a password on that link" / "make the link
  private" → the `--password-stdin` pipe (ask for the password, or generate and show once), and
  "take the password off" → `artor share set <shareId> --remove-password`.
- **`artor/commands/share.md`**: a matching **"Link passwords"** section (same rules, same exact
  strings), the password pipe added to both the create and the manage code blocks, and a
  `--remove-password` line.
- **`artor/references/troubleshooting.md`**: seven new symptom rows - the org-requirement refusal
  on `add`, the refusal of `--remove-password` while the requirement is on, the "this flag takes no
  value" family, the `--password-stdin`-against-a-terminal refusal, the shape-rule refusals, the
  older-server "created WITHOUT a password" exit-1 case, and an unknown `--password-stdin` flag
  meaning a CLI below 0.26.0.
- **`artor/SKILL.md`, new `--hide-widget` bullet and command-table row** under "Share a prototype
  publicly": `artor share add --hide-widget` creates the link with Artor's in-page review widget
  hidden from signed-in organization members who open it (a valueless boolean flag;
  `--hide-widget=true` is refused, not silently dropped). Default is shown; it doesn't affect the
  prototype itself or guest commenting. It matches the dashboard Edit dialog's "Show the review
  widget" switch, off, and can be changed later from that dialog. Against an older server the CLI
  prints the exact non-fatal notice ("This server doesn't support hiding the review widget at
  create time - members will still see it. Change it from the dashboard, or update the server.")
  and still exits 0.
- **`artor/commands/share.md`**: a matching `--hide-widget` example in the create code block and a
  bullet with the same rules and exact strings.

### Changed

- **`artor/SKILL.md` + `artor/commands/share.md`, `share list` line format**: a **live** line can
  now append `password` (the link asks for one) or `needs a password` (the organization requires a
  password and this link has none, so it currently opens for nobody), after the `guests:` suffix.
  Neither appears on a dead link, where the state is inert. The `--json` fields are
  `passwordProtected` and `blockedByPolicy`; an older server omits both.
- **`artor/commands/share.md`, the `set` bullet**: `set` is now described as changing a live link's
  guest-commenting mode, its **password**, or **both in one call**, and the "unattended runs must
  pass `--comments`" rule is restated accurately - it is a `set` carrying **no flag at all** that
  fails loud, since a password-only `set` is a complete command and never opens the comments
  picker.
- **`README.md`**: the `/artor:share` row now reads "Create / list / extend / password-protect /
  turn off an anonymous public link".

## [0.20.1] - 2026-09-18

Mirrors a server-side permission change in Artor: an **org admin now manages every shared Space
directly**. No CLI command, flag, or output shape changed, so this is a PATCH bump: the skill's
description of who may run the existing `artor space` verbs was simply out of date.

### Changed

- **`artor/references/org-admin.md`, Spaces section:**
  - `artor space rename`, `artor space rm` (both forms), and `artor space members add|rm` are now
    annotated **"Space admin or org admin"** (previously "Space admin only", or unannotated).
  - Replaced the rule "an org admin may VIEW any shared Space but not govern its membership
    without the audited break-glass step" with the current rule: **managing a shared Space needs a
    Space admin OR an org admin**, each action audited with the actor; a Space admin manages that
    one Space, an org admin manages every shared Space without being a member of it.
  - Documented the refusal an agent will actually see: a plain Space member, or a read-only
    viewer who is not an org admin, gets **403 `space_admin_required`**.
  - New bullet **"Managing is not writing"**: an org admin who has not joined a shared Space still
    only views its prototypes, so publish / rename / move / trash / share / folder ops / env vars /
    mocks there still fail with **403 `space_read_only`**; the remedy is to join first with
    `artor space members <space> add <their-email>` (itself audited).
  - The Personal Space bullet now says it is never visible to **or manageable by** anyone else.
- **`artor/SKILL.md`, `share set` notes:** the remedy for the "this project's space is read-only
  for you" error no longer mentions org-admin break-glass; it now says to join the space, and
  that an org admin can add themselves with `artor space members <space> add <their-email>`.

### Notes

- **No minimum CLI version change.** The server only widened who is accepted; an older CLI keeps
  working and simply succeeds where it used to get a 403.
- The break-glass API route still exists server-side for compatibility, but nothing in the CLI
  ever called it, so the skill no longer refers to it.

## [0.20.0] - 2026-08-22

Mirrors the `artor` CLI's UX-consistency batch (CLI 0.24.0 -> 0.25.0), the largest single change to
the command surface since spaces landed. Almost every command now accepts a **partial ref**, both
`status` and `whoami` report the **active org** an agent should read instead of guessing, `--json`
reaches two write commands (`publish`, `init`), `env`/`mock` gain a canonical `--scope` selector and
a stdin secret path, `publish` renames its alias flag to `--alias`, confirmations get one grammar,
help answers everywhere, and `artor usage` is a new command. MINOR bump: an agent gains several
abilities it did not have before, and several forms it used to write are now deprecated.

### Added

- **`artor/SKILL.md`, new "CLI conventions (help, refs, confirms, flags)" section** (between
  "Monorepos" and "Command reference"), stating once what used to be unstated and is now true
  everywhere:
  - **Help works everywhere and never acts.** `-h`/`--help` is honored on every command and
    anywhere in the arguments, answered before any auth/config/network work, so
    `artor publish --help` prints usage and **does not publish** (it used to publish). `artor help`
    and `artor help <command>` are the long forms. A mistyped command prints a did-you-mean, and
    the suggester deliberately **never** points at `artor rm`.
  - **Refs accept partial matches**, resolved in one ladder: exact id (case-sensitive), exact
    slug/name (case-insensitive), unique prefix, unique substring. Applies to org, prototype,
    folder, space, skill, public link, and comment thread. A ref matching 2+ items is **ambiguous
    at every tier**, including the exact one: the CLI lists candidates and does nothing, so an
    ambiguity message is a request for a more specific ref, never something to retry unchanged.
  - **Public links** (`share set|extend|off`) match on a full id or a **4+ character id prefix**
    (prefix resolved against the linked project's links; a full id works from anywhere).
  - **Comment threads** (`comments resolve|reopen|ignore|unignore`) accept the full uuid, the new
    **8-character short id** printed at the end of each listing row, any unique 4+ character prefix
    of it, or **`#N`**, the listing row number (quote it). A prefix or `#N` costs one listing read,
    so the same `--version`/`--open`/`--guests-only`/`--no-guests` flags must be passed.
  - **Unattended runs must name a destructive target exactly.** `artor rm`, `folder rm`/`clear`,
    `space rm` (its `--move-to` folder too), `space read`, `space members add|rm`, `skill rm`,
    `skill pin --yes`, `share off`, and `pull --project <ref> --force` refuse a prefix/substring hit
    when they cannot ask, and `--org` is held to the same rule on those runs. Called out for what it
    means here: **an agent IS an unattended run**, so it must pass exact ids/full names for anything
    destructive and keep partials for reads and reversible writes.
  - **Confirmations have one grammar**: `-y`/`--yes` anywhere pre-approves; **declining exits `1`**
    with `✗ Cancelled.` on stderr (so a non-zero exit may mean "the user said no", not "it broke");
    no terminal and no `-y` is an actionable failure naming the flag, never a silent yes. Prompts
    draw on stderr, so `--json`/piped stdout stays clean.
  - **Both flag spellings work everywhere**: `--flag value` and GNU `--flag=value` parse
    identically for every value-taking flag, and an empty value (`--org ""`, `--org=`, a trailing
    `--org`) is refused loudly rather than read as absent.
- **`artor/SKILL.md`, "First check"**: a new "Never guess the org - read it" bullet. Both `status`
  and `whoami` now report the **active** org (linked folder org -> saved default -> token home org)
  with the caller's role, and `--json` on either adds `activeOrg`, `role`, `homeOrgMismatch` and
  `orgsUnavailable`. The bullet tells an agent to read those fields rather than infer an org, and
  spells out the three states it must not misreport: `homeOrgMismatch: true` is identity differing
  from target (not a contradiction), `orgsUnavailable: true` means the membership is **unknown**
  (never "you lost a membership", and never an `artor link` suggestion), and a null `activeOrg`
  with a readable listing is a stale `.artor` or revoked membership whose recovery step the CLI
  prints.
- **`artor/SKILL.md`, "New this release: `artor usage`"** plus a command-reference row and a full
  **"Plan usage"** section in `references/org-admin.md`: `artor usage [--org <ref>] [--json]`
  reports plan, storage used (with the age of the reading), publisher seats, and public-link views
  over 30 days. Owner/admin only, and a non-member gets the same 403 (no membership oracle). The
  caps are documented as **not interchangeable**: a null storage/views cap is unlimited, a null
  seat cap means the tier bills **per seat**, and a never-measured storage reading says so rather
  than reading `0`.
- **`artor/SKILL.md` intro**: `org list` and `usage` added to the `--json` read-command list, and a
  new paragraph for the two **write** commands that now emit `--json`. `artor publish --json`
  prints one object (`version`, `url`, `aliases`, `artifactType`, plus `replaced` on an overwrite)
  with all progress on stderr; `artor init --json` prints `projectId`, `slug`, `name`, `orgId`,
  plus `spaceId`/`folderId` when it chose them. Both **never prompt** under `--json`, so a
  multi-org `init` needs `--org` and a `next.config` patch or mock conflict fails loud asking for
  `--yes` / `--mocks=local|server`.
- **`artor/SKILL.md`, "Publishing notes"**: a `--json` bullet (read `version`/`url` off the object,
  not out of prose) and an `--alias` bullet (below).
- **`artor/SKILL.md` share table**: a paragraph defining `<share>` as a link id or a unique 4+
  character prefix, with the rule that `share off` confirms a prefix by naming the resolved id and
  refuses one unattended.
- **`artor/SKILL.md`, env/mock**: an `artor env set KEY --stdin` paragraph. The value is read from
  stdin so it never lands in shell history or a process listing
  (`printf %s "$SECRET" | artor env set STRIPE_KEY --stdin`), which the skill now names the
  **preferred form for any real credential**. Exactly one trailing newline is stripped; `KEY=VALUE`
  with `--stdin` is refused, an empty read errors, and running it against a terminal refuses and
  prints the pipe form.
- **`artor/commands/publish.md`**: an active-org line after `artor status`, an `--alias` paragraph,
  and a `--json` paragraph.
- **`artor/commands/share.md`**: a `<share>` prefix paragraph in "Manage links".
- **`artor/commands/address-comments.md`**: a paragraph on the thread-ref forms (full uuid, short
  id, 4+ prefix, `#N`) and the rule that a prefix or `#N` must be resolved with the same listing
  flags, with a preference for the full uuid from `--json` when it is already in hand.
- **`artor/references/org-admin.md`**: `env set KEY --stdin` in the code block plus its own bullet;
  a "Guard rails" bullet for the scope selector; a "Local shape checks come before the network"
  bullet for `mock` (name grammar and sha shape validated before any round-trip, so "no such
  revision" really means the sha is wrong); and a bullet on `space read` / `space members add|rm`
  confirming interactively with the fully resolved space named, and refusing a partial unattended.
- **`artor/references/troubleshooting.md`**: eleven new symptom rows - ambiguous partial ref;
  unattended partial refusal (including the id-instead-of-name fallback when a name cannot be typed
  back); `✗ Cancelled.` as a decline rather than a failure; the no-terminal confirm refusal; the
  unknown-command did-you-mean and the pointer to `-h`/`artor help`; `whoami` vs `status` home-org
  mismatch; `orgsUnavailable` ("couldn't verify"); `artor usage` 403; the `--org` deprecation note;
  the hard error when `--org` is passed where a sub-command has no place for it; the `publish
--version` deprecation warning; and the `env set --stdin` terminal refusal.

### Changed

- **`--scope org|project|version` is now the canonical scope selector for `env` and `mock`,
  everywhere in the skill** (`SKILL.md` command table, the "Env vars and mocks" section, the
  behavior-change paragraph, `references/org-admin.md` code blocks and bullets, and three
  `references/troubleshooting.md` rows, and every `env`/`mock` invocation in
  `commands/org-setup.md`, whose walkthrough is org-wide by definition). That command file also
  gains the `env set KEY --stdin --scope org` form with a "pipe real credentials, don't type them
  into argv" note, drops the now-invalid `artor env pull --org` (pull takes no scope flags), and
  points at `artor status`/`artor whoami` for the **active org** these writes land in rather than
  asking "right org?". The bare `--org` still works as a scope alias but is
  **deprecated and warns on stderr**, because `--org <ref>` names a target **organization**
  everywhere else in the CLI while `env`/`mock` always act on the current folder's org. Also
  documented: a duplicate/incoherent selector is refused, `--org` where a sub-command has no place
  for it is a hard error explaining both meanings, an empty value fails loud instead of downgrading
  to project scope, and `--scope=org` parses like `--scope org`.
- **`--alias <name>` replaces `-v <name>` as the spelling the skill writes** for publish's movable
  alias (`SKILL.md` table, "Publishing notes", "Small tweaks", "Interpreting requests";
  `commands/publish.md`; `commands/address-comments.md`). `-v` remains the documented short form.
  `--version <name>` still sets the alias but is **deprecated on publish and warns once**, since
  the same spelling means a version NUMBER on `artor open` and the CLI's own version at `-V`; when
  both are passed `--alias` wins.
- **`artor trash` is documented as org-aware.** A new note records that it now resolves the org
  like `restore`/`rm` (`--org <ref>` -> linked folder -> saved default -> token org) and names the
  org in its heading, where it previously always fell back to the token's home org and could list a
  different tenant's trash than the `artor restore` printed beside it. The command row gains
  `[--org <ref>] [--json]`.
- **Command-reference rows updated to the real signatures**: `whoami`/`status` take `--json`;
  `org list` takes `--json` and `org use` takes `<ref>`; `org members` gets its own row;
  `init` takes `--json` and `--org <ref>`; `rename`/`rm`/`restore`/`trash` take `--org <ref>`;
  `publish` gains `--alias` and `--json` rows; the comment and share rows use `<thread>`/`<share>`
  rather than `<threadId>`/`<shareId>`, since neither is required to be a full id any more.
- **`artor/SKILL.md`, "Spaces"**: the heading is no longer labelled "New this release" (it shipped
  two releases ago), so the label reads honestly on `usage` and `--scope`, which are new here.
- **`references/org-admin.md`, mock**: the `pull`/`status`/`revisions` bullet is corrected to
  `pull`/`status`/`promote` (those are the linked-project-only verbs) with `revisions` described
  as accepting `--scope org` and nothing else - the previous wording listed `revisions` in both
  halves of the same sentence.
- Prose added in this release avoids em-dashes, matching the CLI's own output conventions;
  pre-existing wording was left untouched rather than reflowed wholesale.
- No drift guard was added to `scripts/check-release.mjs`: this release introduces no cross-file
  contradiction to guard, and the deprecated spellings it documents (`--org` as a scope, `--version`
  as an alias) are still accepted by the CLI, so a repo-wide ban on either string would be wrong.

## [0.19.0] - 2026-08-08

Mirrors a new `artor` CLI subcommand: `artor share set <shareId> [--comments
off|anonymous|name|name-email]`, the bearer twin of the dashboard's "Edit public share link"
dialog. Until now the guest-commenting mode of a public link could only be chosen when the link
was minted (`share add --comments ...`); changing your mind meant turning the link off and
resharing, which hands out a brand new URL. `set` edits a LIVE link in place instead. MINOR bump:
an agent gains the ability to do something it could not do before.

### Added

- **`artor/SKILL.md`, "Share (anonymous public links)" table**: a new row,
  `Change a live link's guest commenting` -> `artor share set <shareId> [--comments
off|anonymous|name|name-email]`, sitting between the mint-time rows and `share list`.
- **`artor/SKILL.md`, "Share a prototype publicly"**: a new bullet documenting `share set` in
  full, placed just before the `--mode pinned` bullet so the mint-time story reads first:
  - It edits an existing link **in place**: same URL, same expiry, only the guest-commenting mode
    changes, and the CLI prints the mode the link ended up with (the same
    `Guest commenting: ...` line `share add` prints).
  - **Pass `--comments` explicitly on any agent-driven run.** Unattended and without it, the
    command fails loud ("--comments is required when not running interactively") rather than
    silently no-opping, so an agent that forgets the flag gets a clear error instead of a
    reported-but-unmade change.
  - **On an interactive terminal the CLI asks with a picker** instead. It is the `share add`
    picker minus the "Org default" row, because an existing link already carries a value; Esc
    cancels with "Cancelled - no changes." and writes nothing.
  - **Only a LIVE link can be edited.** A turned-off or expired one answers "No such live link
    (it may have been turned off or expired)" - the remedy is a reshare (new link, new URL), never
    an attempt to resurrect the dead one, which matches the existing `extend` semantics.
  - **Permission**: the link's creator, or an org admin. Separately, the project's Space must be
    writable to the caller; a read-only Space viewer gets its own distinct error ("this project's
    space is read-only for you") whose fix is joining the space or org-admin break-glass, not
    asking the link's creator.
  - **Version note**: `set` needs the current `artor` CLI, so an "unknown command" answer means
    run `artor update` and retry.
- **`artor/SKILL.md`, "Interpreting requests"**: a phrasing-to-command line so the intent is
  routed without inventing a flow, "stop guests commenting on that link" / "let people comment on
  it" -> `artor share set <shareId> --comments ...`, with the reminder that the id comes from
  `artor share list` and that the URL and expiry are untouched.
- **`artor/commands/share.md`, "Manage links"**: `artor share set <shareId> [--comments
off|anonymous|name|name-email]` added to the code block (above `extend`, matching the CLI's own
  usage ordering), plus a bullet carrying the same facts as the SKILL.md bullet, so the slash
  command and the skill body cannot drift on this command.

### Changed

- **`artor/SKILL.md` share table wording**: the existing `--comments` row was labelled "Set the
  link's guest-commenting mode", which now reads ambiguously next to `set`. It is retitled
  "Set guest commenting when minting" so the two rows say plainly which is create-time and which
  edits an existing link. The command itself is unchanged.
- **`artor/commands/share.md` frontmatter description**: "Create, list, extend, or turn off"
  becomes "Create, list, edit, extend, or turn off", since editing a link is now part of what the
  command covers.
- Verified the pre-existing claim in this release: `share add --comments
off|anonymous|name|name-email` was already documented in both the SKILL.md table and
  `commands/share.md` (shipped in 0.17.0), so nothing was missing there and nothing was added.
- No other command, flag, or output shape changed, and no drift guard was added to
  `scripts/check-release.mjs` - this release introduces no cross-file contradiction to guard, and
  the wording it adds is not matched verbatim by any downstream tooling.

## [0.18.1] - 2026-08-08

Clarification fix: "view-only" was scoped correctly to the org-access boundary (no source pull, no
remix, nothing else in the org), but two spots told an agent to relay it as a bare phrase to a
user, with no scoping attached. Since the app now proxies a shared prototype's own writes to its
running container, an agent following that instruction literally would tell a designer "this link
is view-only" and the designer would reasonably conclude their contact form, login screen, or API
route will not work for the client. It will. PATCH bump: this corrects wording about existing,
already-documented behavior; it documents no new CLI capability.

### Changed

- **`artor/commands/share.md`**: the frontmatter `description` (line 2), the opening paragraph
  (lines 9-11), the `--comments off` bullet (line 30), the older-server-notice bullet (line 42),
  and the `share list` guest-word bullet (line 67) all now say plainly that "view-only" describes
  what the visitor can reach **in the org** (no source pull, no remix, nothing else in the org),
  not whether the prototype itself works. The prototype's own forms, API routes, and server
  actions run normally for any visitor holding the link, regardless of the guest-commenting
  setting. Added one plain-language limit alongside the clarification, taken from
  `docs/sharing.md`: treat a shared link as a demo, not a place for real credentials or
  destructive actions, because a shared prototype's own cross-site request protections can't be
  relied on inside a shared preview. No internal mechanics (header names, `SameSite`/`Origin`
  behavior) were pulled in - this skill is agent-facing guidance, not an internals doc.
- **`artor/SKILL.md`** ("Share a prototype publicly"): the opening paragraph, the `--comments off`
  parenthetical, the older-server-notice parenthetical, the `share list` guest-word bullet, and the
  closing "Public previews are view-only" bullet all received the same clarification and the same
  plain-language demo/credentials limit, so the same wording doesn't drift between the skill body
  and the slash command.
- **Fixed a related overclaim while correcting the wording**: both files previously said guest
  commenting is "the one opt-in write surface" on a public link. That was true when it was
  written, but it is no longer accurate: a shared prototype's own routes now accept writes on
  their own, independent of the guest-commenting setting. Guest commenting gates one thing only:
  whether an accountless visitor can post through Artor's own review-comment widget. It was never
  and is not a gate on the prototype's own routes.
- No CLI command, flag, or output shape changed. This is a documentation-only correction; no
  drift guard was needed in `scripts/check-release.mjs` since the corrected wording isn't matched
  verbatim by any downstream tooling.

## [0.18.0] - 2026-08-07

Mirrors the artor app's per-share-subdomains rollout: `artor share` now prints a different URL
shape for every public link, and the skill needed to stop teaching the old one. MINOR bump —
the printed output an agent relays to a user changed shape, and the skill gained a fact worth
knowing (existing links keep working automatically) that it didn't carry before.

### Changed

- **`share add` / `share list` / `share extend` now print a per-share subdomain URL**, e.g.
  `https://s-a1b2c3d4e5f6g7h8i9.preview.artor.app` — `s-` followed by an 18-character lowercase
  alphanumeric label, addressed on the preview host. This replaces the previous token-in-path
  form (`https://share.preview.artor.app/{token}`) as what the CLI prints going forward. Both
  `artor/SKILL.md` ("Share a prototype publicly") and `artor/commands/share.md` ("Create a
  link") now document the new shape with a concrete example, so an agent reporting a share link
  back to a user shows the right thing and doesn't second-guess a URL that looks unfamiliar.
- **The new URL serves the shared version directly at its root** — no `/{token}/` path prefix to
  strip — which is why a build's root-absolute asset URLs (the default Vite/CRA output shape)
  resolve correctly under it. Documented as the reason the shape changed, not just the shape
  itself, so an agent understands why a link now looks like a plain subdomain instead of a path.
- **Copy-from-address-bar and refresh are now both safe.** The per-share subdomain is stable for
  the entire life of the share: reloading the page a visitor is on, or copying the URL straight
  out of the browser's address bar instead of from the CLI/dashboard, both land on the same
  working link. Called out explicitly in both docs pages since it's the practical payoff of the
  new shape for anyone reviewing a shared prototype.
- **Existing (legacy) links keep working with zero action from the user.** A link minted before
  this shipped, in the old `https://share.preview.artor.app/{token}` shape, still resolves: it
  now automatically 302-redirects, one hop, to the link's new canonical per-share subdomain. No
  re-share, no new token, no CLI command to run — the old bookmarked or emailed URL just keeps
  opening the prototype. Both docs pages state this plainly so an agent never tells a user to
  regenerate a link solely because of this change.
- **No skill guidance changed regarding "link stopped working after a refresh."** The skill never
  carried that claim to begin with (nothing to walk back), but the new refresh-safety fact is
  now documented affirmatively so an agent won't invent troubleshooting advice for a problem the
  new URL shape doesn't have.
- **Everything else about `artor share` is unchanged** and was re-verified against the CLI source
  (`cli/src/commands/share.ts`) and `docs/sharing.md` while making this pass: the `--comments
  off|anonymous|name|name-email` flag and its picker/org-default behavior, the dead-link hints
  (`(off - reshare to copy)` / `(reshare to copy)` — a turned-off or expired link still shows no
  recoverable URL and still must be reshared for a fresh one), the `share list` tab-separated line
  format and its trailing `guests: <mode>` suffix, `--mode pinned|latest`, `--days`/`--warn`, and
  the "turn off, never revoke" wording. None of it needed a correction.

## [0.17.3] - 2026-08-05

Lockstep with the artor-cli 0.22.1 copy sweep: the CLI's shipped strings no longer use
em-dashes, which changes one exact-quoted output the skill tells agents to string-match.
Docs only, no behavior change.

### Changed

- **`share list` dead-link hint quote updated** in `artor/SKILL.md` and
  `artor/commands/share.md`: CLI 0.22.1+ prints `(off - reshare to copy)` (plain hyphen).
  Both pages now show the new form and note that CLI 0.22.0 and older print the em-dash
  variant `(off — reshare to copy)`, so an agent matching either form stays correct across
  server/CLI version skew.
- No other quoted CLI string changed meaning or wording in ways the skill matches on; the
  managed-block markers (`registry`/`skills`/`sdk`/`env` "managed — do not edit" fences) are
  deliberately unchanged in the CLI for compatibility and remain accurate as quoted.

## [0.17.2] - 2026-08-05

Freshness pass against the final `artor share` CLI source. The `share list` human output now
carries a guest-commenting suffix that no skill page described, so an agent reading that output
had no way to know the trailing field existed or what its words mean. Docs only, no behavior
change.

### Added

- **`share list` line format is now documented**, in both `artor/SKILL.md` (share section) and
  `artor/commands/share.md` (Manage links). The human output is tab-separated
  `<shareId> <mode> <state> <views> <url or hint>`, with the previously undocumented trailing
  `guests: <mode>` on live links.
- **The guest-suffix vocabulary is spelled out**: `off`, `anonymous`, `name`, `name and email` -
  note that the human word for the `name_email` enum is the spaced phrase "name and email", so an
  agent matching on the raw enum against human output would miss it.
- **Three absence cases called out**, so a missing suffix is never read as "guest commenting is
  off": (1) a **turned-off** link, (2) an **expired** link, and (3) an **older server** that does
  not send the field at all. A live link whose mode really is off prints `guests: off`
  explicitly, which is the only reliable "off" signal.
- **`--json` steered as the parsing path** for this line, with the shape difference flagged: the
  JSON payload carries `guestCommenting` as the raw wire enum (`name_email`), not the human
  phrase. `share list` was already listed among the `--json` read commands in the SKILL.md
  preamble, but the Share command table row omitted the flag; it now reads
  `artor share list [--json]`.

### Verified unchanged

- **`--comments` flag surface** re-checked against the CLI's `parseShareAdd`: the accepted values
  remain `off|anonymous|name|name-email` (the hyphenated `name-email` spelling is normalized to
  the `name_email` wire enum), the flag stays optional, and an absent flag still means "ask with
  a picker on a TTY, keep the org admin-set default unattended". Existing skill copy already
  matched, so it was left alone.
- **Dead/legacy link hints** re-checked: a turned-off link still shows `(off — reshare to copy)`
  and an expired or legacy row still shows `(reshare to copy)`. No edit needed.

## [0.17.1] - 2026-08-05

Doc-drift audit against the current CLI source; no behavior change, corrections and
completions only.

### Fixed

- **`artor admin plan set` enum**: the operator plan enum is `free|pro|team|enterprise`; the
  skill (SKILL.md operator table and `references/org-admin.md`) omitted `team`. Both now match
  the CLI usage string exactly.
- **`artor open` empty-state string**: the CLI prints "No live versions to open yet. Run
  `artor publish` first." - the quoted string in SKILL.md and in
  `references/troubleshooting.md` was missing "yet", so exact-string matching would fail.
- **Boot smoke test error string** in `references/troubleshooting.md`: the CLI prints
  "boot smoke test failed: the bundle crashes on `node <entry>` before binding its port",
  with a colon; the table quoted a different separator.
- **Plain-HTML entry error string** in `references/troubleshooting.md`: the CLI prints
  "found .html files but no index.html at the project root. Rename your entry page to
  index.html (or pass --dir <path>)."; the table quoted an older one-sentence variant.

### Added

- **`artor comments ignore|unignore <threadId>`** documented for the first time: a new row in
  the publish/review command table, the `aiIgnored` field added to the documented JSON payload
  (human list marker `AI: off`), and an explicit rule in the address-feedback flow (SKILL.md and
  `commands/address-comments.md`): a thread with `aiIgnored: true` was deliberately excluded
  from AI processing, so an AI pass skips it entirely and never resolves it.
- **Guest commenting reached the `/artor:share` command doc** (`commands/share.md`), which
  still described links as strictly view-only: it now carries the `--comments
  off|anonymous|name|name-email` flag on both `share add` forms, the ask-one-question guidance,
  the non-interactive-keeps-org-default caveat, the printed resulting mode to report back, the
  older-server view-only notice, and the guest-containment summary.
- **Guest markers reached the `/artor:address-comments` command doc**
  (`commands/address-comments.md`): guest threads (`guest: true` + `guestAlias`, human marker
  `guest <alias>`, self-asserted identity) and the `--guests-only` / `--no-guests` filters,
  including the recommendation to use `--no-guests` for a pass over team feedback.
- **`--json` command list completed** in SKILL.md's intro: `space list` and `logs` also accept
  `--json` and are now listed alongside the other read commands.

### Notes

- The slide-deck section documents the `slides` capability shipping on its own CLI branch and
  was deliberately left untouched by this audit.

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
