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

- Not found → the CLI publishes to npm as **`artor-cli`** (command stays `artor`): suggest
  `npm install -g artor-cli` (or `pnpm add -g artor-cli`), then re-check.

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
`pnpm-workspace.yaml`. If present, this is a workspace root — `cd` into the specific app's folder
(the one with the `build` script + framework dep) and retry there.

## 5. Right org?

```bash
artor whoami
artor org list
```

- Wrong active org → `artor org use <id|slug>`.

## 6. Match the error → fix

Take the exact CLI error string and look it up in the skill's troubleshooting reference (e.g. HTTP
426 → `artor update`; boot smoke test failed → read the crash, fix the build; `pull failed
(HTTP …)` → read the relayed server message; `Already linked … --force`). Apply the matched fix.

## Wrap up

Report what you found at each step, the single root cause, and the exact fix applied or recommended.
