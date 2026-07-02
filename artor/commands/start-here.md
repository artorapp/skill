---
description: First-run Artor walkthrough — installs or checks the artor CLI, signs you in, links a project, ships your first version, and optionally shares it.
---

You are guiding a user through Artor for the **first time**. Walk them end-to-end, one step at a
time, confirming each step succeeded before moving on. Report exactly what the CLI prints — never
invent a version number or URL.

## 0. Is the `artor` CLI installed?

Run a capability check first:

```bash
artor --version
```

- **If it prints a version** → the CLI is installed; continue to step 1.
- **If the command is not found** → stop and help them install it. Artor's CLI publishes to npm as
  **`artor-cli`** (the command is still `artor`):

  ```bash
  npm install -g artor-cli      # or: pnpm add -g artor-cli
  ```

  Then re-run `artor --version` to confirm before continuing. Do not proceed until the CLI
  responds.

## 1. Sign in

```bash
artor status      # local, read-only: is this dir linked + who am I?
artor whoami      # confirms the signed-in user + active org
```

- If not signed in, run `artor login` and let them complete the device approval in the browser.
- If they belong to 2+ orgs, confirm the active one (`artor org list` / `artor org use <id|slug>`).

## 2. Link a project

**Monorepo pre-check first.** If the root `package.json` has a `workspaces` field, or a
`pnpm-workspace.yaml` exists, the current dir is a workspace root, not a publishable app. `cd` into
the specific app's folder (the one whose `package.json` has the `build` script + framework dep). If
you don't know which app, ask before continuing. (See the artor skill's "Monorepos" section.)

- If `.artor/project.json` already exists, this dir is linked — skip to step 3.
- Otherwise create + link a project here (or `artor link <slug>` to attach to an existing project):

  ```bash
  artor init
  ```

  `artor init` also installs the `@artorapp/web-sdk` review widget and wires it into the client
  entry (safe to commit — it self-disables off the preview origin). If it reports it couldn't
  auto-wire, follow its printed reminder. Widget details: the artor skill's review-widget reference.

## 3. Publish the first version

```bash
artor publish
```

- Builds on demand (no need to `npm run build` first). Next/SSR → node-server; pure-static → static.
- **Boot test:** the app is started before upload; if it crashes, publish stops with the crash
  output. Read it and fix the build — don't reflexively reach for `--no-smoke`.
- Report the **exact** version number and **preview URL** the CLI returns. This URL is
  **members-only** — anyone opening it must be logged into the org.
- Open it: `artor open` (prints the URL first; headless-safe).

## 4. (Optional) Share it publicly

Only if they want anyone (no login) to view it — explain this is the one way content leaves the
closed garden:

```bash
artor share add        # anonymous, view-only link that follows the newest version
```

The full URL prints here **and** is recopyable any time the link is live via `artor share list`, so
a lost link isn't gone. Hand the printed URL to them. Details: `/artor:share`.

## Wrap up

Summarize what they now have: signed in, project linked, first version published (with its URL),
and — if shared — the public link. Point them at `/artor:publish` for the next version,
`/artor:share` to manage public links, and `/artor:address-comments` to act on reviewer feedback.
