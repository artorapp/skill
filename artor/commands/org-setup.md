---
description: Admin onboarding for an Artor org — configure env vars, mock datasets, org skills, starter templates, and private registries.
---

Guided setup of org-level knowledge for an **owner/admin**. All of this is scoped to the org of the
**linked directory**, and most writes **require an owner or admin role** (admin-gated steps marked
below). Confirm intent **before each write**, and report what was configured. Full flag reference and
semantics: the artor skill's org-admin reference (auto-loaded as `/artor:artor`).

First confirm you're set up: `artor whoami` (right org?) and `artor status` (linked dir). Switch org
with `artor org use <id|slug>` if needed.

## 1. Env vars (admin)

Decide **per variable**: pullable to laptops, or server-only.

```bash
artor env set KEY=VALUE --local     # local (pullable) — downloadable via `artor env pull`
artor env set KEY=VALUE              # server-only — injected into node-server containers, never downloadable
artor env list                       # names + class only (values are write-only)
```

Ask which class each secret should be before setting it. Prefer **server-only** for anything that
should never reach a laptop.

## 2. Mock datasets (admin)

```bash
artor mock set <name> <file.json>    # served at /__mock/<name> as a FALLBACK
```

A deployment that bundles its own `mocks/<name>.json` overrides the org dataset. Use `artor mock
promote <name> [--ref <r>]` to lift a published version's bundled mock into the org.

## 3. Org skills (admin)

```bash
artor skill add <gh-url> [--name X] [--ref branch|tag|sha] [--credential <t>] [--enforced]
artor skill list
```

Private repos: `--credential <token>` or `ARTOR_GITHUB_TOKEN`. Use `enforce`/`pin`/`sync` to manage.

## 4. Starter templates (admin)

```bash
artor template push --name X [--slug y] [--desc z]     # usable via `artor init --template <slug>`
```

## 5. Private registries (admin)

```bash
artor registry add <@scope> --type azure|npmjs [--uplink <url>] [--token <t>] [--name <l>] [--expires YYYY-MM-DD]
artor registry login                 # writes the managed .npmrc block for members
```

The upstream token (`--token` or `ARTOR_REGISTRY_TOKEN`) **stays server-side**; `login` writes only
the org proxy + the caller's own Artor token into `.npmrc`. `init`/`pull`/`remix` re-derive it.

## Wrap up

Report exactly what was configured (which env vars + class, mocks, skills, templates, registries),
and flag any step you skipped for lack of an admin role.
