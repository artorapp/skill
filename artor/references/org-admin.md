# Org admin deep-dive

Org knowledge (env vars, mock datasets, org skills, templates, private registries) is scoped to the
**org of the linked directory** (env vars and mocks can also be scoped narrower — see below).
Setting/removing most of it needs an **owner or admin** role; admin-gated verbs are marked below.
Confirm intent before each write, and report exactly what was configured.

## Env vars — `artor env`

Both `env` and `mock` (below) share the same three-level scope model and flag grammar:

- **No flag, run inside a linked project** → the **project** scope (every version of that one
  prototype). This is the default — a behavior change from earlier releases, which defaulted to
  the org; see the CLI changelog.
- **`--scope org`** → the org scope (every node-server deployment in the org, unless overridden by
  a project or version row). **This is the canonical spelling.** The bare **`--org` is a deprecated
  alias** here: it still works and prints a one-line stderr note, but `--org <ref>` names a target
  **organization** everywhere else in the CLI, while `env`/`mock` always act on the org linked to
  the current folder. To change organization, run `artor org use`.
- **`--version <ref>`** → exactly one immutable version's scope (`<ref>` = alias, version number,
  or content hash); it implies `--scope version`. **`--scope project`** names the default
  explicitly.
- Outside a linked project, `set`/`rm` (and `mock set`/`rm`/`pin`) with no org scope are a **loud
  error** — "Not in a linked project. Run inside one, or pass --org for the org scope." There is no
  silent org-wide fallback for a mutating verb.
- **Guard rails:** a duplicate or incoherent selector is refused rather than resolved; `--org`
  passed where a sub-command has no place for it (`env list --org acme`) is a hard error explaining
  both meanings, never a quiet read of another org; and an EMPTY value (`--version=`,
  `--version ""`) fails loud instead of silently downgrading to project scope. Both `--scope org`
  and `--scope=org` parse identically.
- **Permission depends on the resolved scope, not how it was reached:** org scope is **admin-only**
  for `set`/`rm`; project or version scope only needs a **publisher seat** (mirrors `artor
  publish`'s gate) — any publisher can manage the config of a prototype they're actively working on.
  `list`/`revisions`/`status` are any member at any scope.

Two visibility classes for env vars:

- **`--local` → `local (pullable)`** — downloadable to laptops via `artor env pull`.
- **default (no `--local`) → `server-only`** — injected into node-server containers at start, and
  **never** downloadable.

```bash
artor env set KEY=VALUE [--local]   [--scope org|project|version] [--version <ref>]
artor env set KEY --stdin [--local] [--scope org|project|version] [--version <ref>]
artor env list [--json]             [--scope org|project|version] [--version <ref>]  # (alias ls)
artor env rm KEY                     [--scope org|project|version] [--version <ref>]  # (alias remove)
artor env pull                       # linked project's EFFECTIVE (project + org merged) vars
                                      # -> ./.env.local; org-only when not linked; takes no
                                      # scope flags
```

- **`env set KEY --stdin` reads the value from stdin** so a secret never lands in shell history or
  a process listing, the preferred form for any real credential:
  `printf %s "$SECRET" | artor env set STRIPE_KEY --stdin`. Exactly one trailing newline is
  stripped, everything else round-trips byte for byte. `KEY=VALUE` together with `--stdin` is
  refused (one value would be discarded), an empty stdin read errors naming the piped form, and run
  against a terminal it refuses and prints the pipe form rather than echoing the secret on screen.

- **Values are write-only** — `list` returns names + class, never the value.
- **Resolution is a live merge at every container cold start** — `version > project > org` — so
  rotating/deleting an inherited var takes effect on the *next* boot, never requiring a republish.
  This is the deliberate opposite of mocks (below), which snapshot at publish time.
- **`env pull`** writes a **managed block** into `./.env.local` (mode `0600`), preserving your own
  hand-added lines outside the block. Empty pull prints `No local (pullable) env vars for this
  scope. Nothing to write.`
- Values containing `"` or a trailing `\` are rejected loudly.

## Mock datasets — `artor mock`

Fixtures served at `/__mock/<name>` — but only as a **fallback**: a deployment that bundles its own
`mocks/<name>.json` wins over a project/org mock, at snapshot time (see below).

```bash
artor mock set <name> <file.json>    [--scope org|project|version] [--version <ref>]
artor mock list [--json]             [--scope org|project|version] [--version <ref>]  # (alias ls)
artor mock rm <name>                  [--scope org|project|version] [--version <ref>]  # (alias remove)
artor mock revisions <name>          [--scope org]                # edit history: sha, author,
                                      # date, which live versions use it (org or project scope
                                      # only — a version has exactly one pin, not a history)
artor mock pin <name> <sha> --version <ref>
                                      # repoint an already-PUBLISHED version's binding to an
                                      # existing revision sha — no republish
artor mock pull                      # linked project's effective mocks -> ./mocks/*.json
artor mock status [--json]           # diff ./mocks/*.json against the linked project, no writes
artor mock promote <name> [--ref <r>] # copy a version's bundled mocks/<name>.json into the org dataset
```

- **Snapshotted at publish time, not a live merge (unlike env vars).** Publishing a version
  resolves `bundled > project > org` **once**, per name, and writes an immutable version binding —
  editing the org/project mock afterward never changes an already-published version's served data,
  only what the *next* publish snapshots. `artor mock pin` is the deliberate escape hatch to repoint
  an already-shipped version without a republish.
- `pull`/`status`/`promote` work on the **linked project only** - no scope variant (they reject a
  scope flag loudly, naming the form to run, rather than silently ignoring it). `revisions` accepts
  `--scope org` to read the org's history instead of the project's, and nothing else.
- **Local shape checks come before the network.** Every verb validates `<name>` against the same
  grammar the server enforces (letters, digits, `_`/`-`, ≤64 chars), and `mock pin` validates the
  `<sha>` shape (64 lowercase hex chars), so a typo fails fast with a precise message. A "no such
  revision" answer therefore means the sha is genuinely not a revision of that mock - copy it
  exactly from `artor mock revisions <name>`.
- `promote` requires a **linked project**; `--ref` defaults to `latest`. It copies the published
  version's bundled `mocks/<name>.json` into the org dataset.
- Get a sha to pin with `artor mock revisions <name>`, then `artor mock pin <name> <sha> --version
  <ref>`.

## Org skills — `artor skill`

Pin git-hosted skills to the org so every member's agent picks them up.

```bash
artor skill add <gh-url> [--name X] [--ref branch|tag|sha] [--credential <t>] [--enforced]
artor skill list                     # (alias ls)
artor skill enforce <name> [--off]   # toggle enforcement
artor skill pin <name> [--ref X] [--yes]
artor skill rm <name>                 # (alias remove)
artor skill sync [--force]           # re-fetch pinned sources
```

- **Private repos:** pass `--credential <token>` or set `ARTOR_GITHUB_TOKEN`.

## Org templates — `artor template`

Starter scaffolds usable via `artor init --template <slug>`.

```bash
artor template push --name X [--slug y] [--desc z]
artor template list                  # (alias ls)
```

## Private registries — `artor registry`

Proxy private npm scopes through Artor so installs work without handing out the upstream credential.

```bash
artor registry add <@scope> --type azure|npmjs [--uplink <url>] [--token <t>] [--name <label>] [--expires YYYY-MM-DD]
artor registry list                  # (alias ls)
artor registry rm <@scope>            # (alias remove)
artor registry login                 # write the managed .npmrc block for this org
```

- **`add` / `rm` are admin-only.** The upstream token comes from `--token` or `ARTOR_REGISTRY_TOKEN`
  and **stays server-side** — it never reaches a client machine.
- **`login`** writes a **managed block** into `./.npmrc` (mode `0600`, force-excluded from published
  tarballs): the org scope → Artor proxy lines plus the **caller's own Artor token**. The upstream PAT
  never leaves the server. `init`, `pull`, and `remix` re-derive this block best-effort automatically.
- `--expires YYYY-MM-DD` bounds the upstream token's validity.

## Spaces — `artor space`

A **Space** is the access wall: **Org → Space → Folder → Prototype → Version**. It is the ONLY
permission boundary between org members — folders are cosmetic grouping *within* a Space. Three
kinds: **Organization** (every member, always exists), **Personal** (one per member, owner-only —
never admins, never operators), **shared** (an explicit member list; needs the Team plan or higher).

```bash
artor space list                             # the Spaces you can see
artor space create <name>                    # shared Space (Team+ plan); you become its admin
artor space rename <space> "<new>"           # Space admin or org admin
artor space read <space> on|off              # let the WHOLE org read + comment
artor space rm <space> [--yes]               # delete an EMPTY shared Space (Space admin or org admin)
artor space rm <space> --move-to <folder> [--yes]   # move its prototypes out first, then delete
artor space members <space>
artor space members <space> add <email-or-id> [--role admin|member]   # Space admin or org admin
artor space members <space> rm <email-or-id>                          # Space admin or org admin
```

- `<space>` resolves by id, exact name, or a **unique partial** (prefix then substring; ambiguity
  lists the candidates and does nothing); members by **email or user id** (run `artor org members`
  for the roster). Organization/Personal Spaces appear in `list` but reject rename/delete/member
  ops.
- **`read` and `members add|rm` move the access wall, so they ask.** Interactively they confirm
  naming the **fully resolved** space (`Let EVERY org member read "Design Ops (client NDA)"?`), so
  a typed `Design` can never silently open a space you were not shown. **Unattended (`--yes` or no
  terminal) a partial ref is refused** - as is one for `space rm` and its `--move-to <folder>`.
  From an agent-driven run, name those targets **exactly** (id or full name). An exact ref is never
  questioned; `artor space members <space>` with no action is read-only and keeps the partial
  ladder.
- **`read on` is a deliberate widening.** Every org member can then see the Space, open its
  prototypes, and **comment** — and nothing else. Publish, rename, move, trash, share, folder ops,
  env vars and mocks all fail with **403 `space_read_only`** (not a 404 — the caller can already
  see the content). Turning it **off** revokes reach immediately; comments already left stay.
- **Source is seat-gated at read level.** `artor pull` / `remix` / `env pull` work for a
  read-only viewer only with a **publisher seat**; a reviewer gets 403 `publisher_required`.
- **Managing a shared Space** (`rename`, `rm`, `members add|rm`, `read`) needs a **Space admin OR
  an org admin**; every one of those actions is audited with the actor. A Space admin manages that
  one Space; an org admin manages **every** shared Space without being a member of it. A plain
  Space member, or a read-only viewer who is not an org admin, gets 403 `space_admin_required`.
- **Managing is not writing.** An org admin who has not joined a shared Space still only VIEWS its
  prototypes: publish, rename, move, trash, share, folder ops, env vars and mocks there fail with
  403 `space_read_only`. The fix is to join it first
  (`artor space members <space> add <their-email>`), which is itself audited.
- A **Personal** Space is never visible to or manageable by anyone else, admins and operators
  included.
- `artor init` asks which Space first, then the folder. Non-TTY lands in the Organization Space's
  Draft.

## Folders — `artor folder`

Organize prototypes into folders **within a Space** in the linked dir's org. Interactive pickers
appear on a TTY for `create`/`color`/`move`. A folder in a Space you can't reach is a clean 404;
in a Space you can only read, every folder op is refused with 403 `space_read_only`.

```bash
artor folder list [--space <name|id>]        # (alias ls)
artor folder create [<name>] [--color <c>] [--space <name|id>]
artor folder rename <ref> "<new>"
artor folder color <ref> [<css|none>]
artor folder move [<project>] [<folder>] [--space <name|id>]
artor folder rm <ref> [--with-content|--with-prototypes|--with-projects] [--yes]
artor folder clear <ref> [--yes]
```

- **`rm`** by default moves the folder's prototypes to **Draft**. `--with-content` (and its aliases)
  **trashes** them instead — **admin-only**.
- **`clear`** soft-deletes every prototype in the folder — **admin-only**.
- The **Draft** folder is immutable: it can't be renamed or deleted. There is exactly one **per
  Space**, and a prototype with no folder resolves to its Space's Draft.
- **Folders are per-kind.** A slide deck's folders are entirely separate from a prototype's —
  each kind gets its own "Draft" and its own namespace of folder names. `artor folder` run
  inside a linked slides project automatically targets slides folders; run inside a prototype
  it targets prototype folders. There's no cross-kind folder move.

## Plan usage - `artor usage`

What the org has consumed against its plan limits. **Owner/admin only** (the same gate as
Settings, Usage in the dashboard); a non-admin and a non-member both get the same 403.

```bash
artor usage [--org <ref>] [--json]
```

- Reports the **plan**, **storage** used (with the age of the reading), **publisher seats**, and
  **public-link views** over the last 30 days. Storage and views carry a fill bar with their
  percentage (none when the cap is unlimited or storage was never measured).
- A **`builds:`** row (artor-cli 0.28.0+) gives the max size of ONE publish: the org's static and
  live app build limits, for example `static <N> MB, live app <N> MB` (a Team org reads
  `static 200 MB, live app 1,000 MB`). The real values come from the server for this org
  (plan and any custom limit): read them off the row, never from this example. No bar: it is a
  per-publish limit, not a running total. Extra publisher seats never raise it.
- `--json` adds an optional `limits: { staticBundleMb, nodeBundleMb }` (MB); an older server
  omits it, so treat it as absent rather than as zero.
- Org resolution: `--org <ref>` wins (a present-but-empty value is refused, never read as absent),
  else the **linked folder's** org, else the saved default / token org. `--json` names the org too.
- **Read each cap honestly, they are not interchangeable:** a `null` storage or views cap means
  **unlimited**; a `null` seat cap means the tier bills **per seat**, NOT unlimited; and a
  never-measured storage reading says so rather than showing `0`. Don't collapse those into
  "no limit".

## Operator (platform super-admins)

Only for platform super-admins listed in `ARTOR_SUPERADMINS`.

| Goal                      | Command                                                                    |
| ------------------------- | -------------------------------------------------------------------------- |
| List all orgs             | `artor admin org list` (alias `ls`)                                        |
| Get / set an org's plan   | `artor admin plan get <orgId>` / `admin plan set <orgId> <free\|pro\|team\|enterprise>` |
| Platform share ceiling    | `artor admin share-ceiling get` / `set <days>` (server clamps to [1, 90])  |
| Delete / restore an org   | `artor admin org delete <id> --confirm [--reason]` / `admin org restore <id>` |
| Delete / restore a user   | `artor admin user delete <id> --confirm [--reason]` / `admin user restore <id>` |
