---
description: Diagnose why Artor isn't working — orchestrate the CLI's status checks and match errors to fixes.
---

There is **no** `artor doctor` command. Diagnose by orchestrating the checks below in order, then
match any error against the artor skill's troubleshooting reference (auto-loaded as `/artor:artor`).
End by **reporting findings + the fix**, not by guessing.

## 1. Is the CLI installed?

```bash
artor --version
```

- Not found → check `node --version` first: the CLI needs **Node 22 or newer** (if it is missing
  or older, suggest the current LTS from https://nodejs.org, Homebrew's `brew install node` on
  macOS, or a version manager such as nvm). Then the CLI publishes to npm as **`artor-cli`**
  (command stays `artor`): suggest `npm install -g artor-cli` (or `pnpm add -g artor-cli`), then
  re-check.

## 2. Is this dir linked, and who am I?

```bash
artor status
```

- `not linked` → run `artor init` (new project) or `artor link <slug>` (existing project).
- `corrupt (<reason>)` → the local link is malformed; re-link with `artor link <slug> --force`.
- `not logged in` → `artor login`.

## 3. Accidentally in dev mode?

```bash
artor dev status
```

- If it reports a non-production API target, you're pointed at a dev dashboard (and were logged out
  of prod when it was switched on). Fix: `artor dev off`, then `artor login` again.

## 4. Monorepo / workspace root?

If `publish`/`init` failed to detect an app: check for a `workspaces` field in `package.json` or a
`pnpm-workspace.yaml`. If present and the root holds no detectable app, this is a workspace root:
`cd` into the specific app's folder (the one with the `build` script + framework dep) and retry
there.

With artor-cli 0.34.0 or later (check `artor --version`), a listed workspace app with no lockfile
of its own has its dependencies installed at the workspace root, and a Next app's nested
standalone server is found on its own for the usual layouts. If a monorepo publish fails on
`workspace:*` or on a missing `.next/standalone/server.js`: below 0.34.0, run `artor update` and
retry; at 0.34.0 or later, do not loop on `artor update`, check instead that the workspace lists the
folder (`pnpm-workspace.yaml` `packages` / root `workspaces`), that the app folder has no lockfile of
its own, and that the workspace root is not at or above the home folder with no git repository above
the app. See the skill's "Monorepos" limits.

## 5. Right org?

```bash
artor whoami
artor org list
```

- Wrong active org → `artor org use <id|slug>`.

## 6. Match the error → fix

Take the exact CLI error string and look it up in the skill's troubleshooting reference (e.g. HTTP
426 → `artor update` — 0.16.0+ normally self-heals this automatically, so seeing it means the
auto-update couldn't run; boot smoke test failed → read the crash, fix the build; `pull failed
(HTTP …)` → read the relayed server message; `Already linked … --force`). Apply the matched fix.

## Wrap up

Report what you found at each step, the single root cause, and the exact fix applied or recommended.
