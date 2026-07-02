# Org admin deep-dive

Org knowledge (env vars, mock datasets, org skills, templates, private registries) is scoped to the
**org of the linked directory**. Setting/removing most of it needs an **owner or admin** role;
admin-gated verbs are marked below. Confirm intent before each write, and report exactly what was
configured.

## Env vars — `artor env`

Org-scoped configuration. Two visibility classes:

- **`--local` → `local (pullable)`** — downloadable to laptops via `artor env pull`.
- **default (no `--local`) → `server-only`** — injected into node-server containers at start, and
  **never** downloadable.

```bash
artor env set KEY=VALUE [--local]   # set (local/pullable) or server-only (default)
artor env list                      # (alias ls) — names + class ONLY; values are write-only
artor env rm KEY                     # (alias remove)
artor env pull                       # write pullable vars to ./.env.local
```

- **Values are write-only** — `list` returns names + class, never the value.
- **`env pull`** writes a **managed block** into `./.env.local` (mode `0600`), preserving your own
  hand-added lines outside the block. Empty pull prints `No local (pullable) env vars for this org.
  Nothing to write.`
- Values containing `"` or a trailing `\` are rejected loudly.

## Mock datasets — `artor mock`

Org-level fixtures served at `/__mock/<name>` — but only as a **fallback**: a deployment that bundles
its own `mocks/<name>.json` **wins** over the org dataset (fallback, not override).

```bash
artor mock set <name> <file.json>    # upload; server validates (no CLI-side checks)
artor mock list                      # (alias ls) — name + bytes
artor mock rm <name>                  # (alias remove)
artor mock promote <name> [--ref <r>] # copy this version's bundled mocks/<name>.json into the org dataset
```

- `promote` requires a **linked project**; `--ref` defaults to `latest`. It copies the published
  version's bundled `mocks/<name>.json` into the org dataset.

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

## Folders — `artor folder`

Organize prototypes into folders within the linked dir's org. Interactive pickers appear on a TTY for
`create`/`color`/`move`.

```bash
artor folder list                    # (alias ls)
artor folder create [<name>] [--color <c>]
artor folder rename <ref> "<new>"
artor folder color <ref> [<css|none>]
artor folder move [<project>] [<folder>]
artor folder rm <ref> [--with-content|--with-prototypes|--with-projects] [--yes]
artor folder clear <ref> [--yes]
```

- **`rm`** by default moves the folder's prototypes to **Draft**. `--with-content` (and its aliases)
  **trashes** them instead — **admin-only**.
- **`clear`** soft-deletes every prototype in the folder — **admin-only**.
- The **Draft** folder is immutable: it can't be renamed or deleted.

## Operator (platform super-admins)

Only for platform super-admins listed in `ARTOR_SUPERADMINS`.

| Goal                      | Command                                                                    |
| ------------------------- | -------------------------------------------------------------------------- |
| List all orgs             | `artor admin org list` (alias `ls`)                                        |
| Get / set an org's plan   | `artor admin plan get <orgId>` / `admin plan set <orgId> <free\|pro\|enterprise>` |
| Platform share ceiling    | `artor admin share-ceiling get` / `set <days>` (server clamps to [1, 90])  |
| Delete / restore an org   | `artor admin org delete <id> --confirm [--reason]` / `admin org restore <id>` |
| Delete / restore a user   | `artor admin user delete <id> --confirm [--reason]` / `admin user restore <id>` |
