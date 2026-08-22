---
description: Admin onboarding for an Artor org — configure env vars, mock datasets, org skills, starter templates, and private registries.
---

Guided setup of org-level knowledge for an **owner/admin**. All of this is scoped to the org of the
**linked directory**, and most writes **require an owner or admin role** (admin-gated steps marked
below). Confirm intent **before each write**, and report what was configured. Full flag reference and
semantics: the artor skill's org-admin reference (auto-loaded as `/artor:artor`).

**`env` and `mock` default to the linked PROJECT's scope, not the org - pass `--scope org`
explicitly** for every command below (this walkthrough is org-wide setup, so every `env`/`mock`
command needs it). `--scope org` is the canonical selector; the bare `--org` still works as a scope
alias but is deprecated and warns on stderr, because `--org <ref>` names a target organization
everywhere else in the CLI.

First confirm you're set up: `artor status` / `artor whoami` name the **active org** (the one these
writes will land in) with your role - read it there rather than assuming. Change it with
`artor org use <ref>` if needed.

## 1. Env vars (admin)

Decide **per variable**: pullable to laptops, or server-only.

```bash
artor env set KEY=VALUE --local --scope org  # local (pullable): downloadable via `artor env pull`
artor env set KEY=VALUE --scope org          # server-only: injected into containers, never downloadable
artor env set KEY --stdin --scope org        # value read from stdin (preferred for real secrets)
artor env list --scope org                   # names + class only (values are write-only)
```

Ask which class each secret should be before setting it. Prefer **server-only** for anything that
should never reach a laptop.

**Pipe real credentials, don't type them into argv.** `printf %s "$SECRET" | artor env set
STRIPE_KEY --stdin --scope org` keeps the value out of shell history and process listings. Exactly
one trailing newline is stripped. `KEY=VALUE` together with `--stdin` is refused, and run against a
terminal the command refuses and prints the pipe form rather than echoing the secret.

## 2. Mock datasets (admin)

```bash
artor mock set <name> <file.json> --scope org   # served at /__mock/<name> as a FALLBACK (org seed)
```

A deployment that bundles its own `mocks/<name>.json`, or a project mock, wins over the org seed at
snapshot time — mocks resolve `bundled > project > org` once, at publish. Use `artor mock promote
<name> [--ref <r>]` to lift a published version's bundled mock into the org dataset.

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
