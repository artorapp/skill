# Troubleshooting

Symptom → cause → fix. Error strings below are the CLI's exact output; match against them, then apply
the fix. When the message is relayed from the server (e.g. `pull failed (HTTP …)`), read the relayed
text rather than expecting fixed CLI wording.

| Symptom (what you see) | Cause | Fix |
| --- | --- | --- |
| `command not found: artor` (or similar) | CLI not installed | Install it — the CLI publishes to npm as **`artor-cli`** (command stays `artor`): `npm install -g artor-cli` (or `pnpm add -g artor-cli`). Re-run `artor --version`. |
| ``This CLI is too old for the Artor server. Run `artor update`.`` (HTTP 426) | Server's minimum-CLI floor was bumped | `artor update`, then retry the command. |
| ``boot smoke test failed — the bundle crashes on `node <entry>` before binding its port: …`` (ends: ``Fix the build, or re-run with `--no-smoke` if your app legitimately needs runtime env/services to boot.``) | The built bundle crashes on startup (e.g. missing dependency, bad import) | Read the crash output and **fix the build**. Only re-run with `--no-smoke` if the app **legitimately** needs live secrets/services to boot — never as a reflex to bypass a genuine crash. |
| `couldn't detect a framework, a build script, or an index.html. Pass --dir <build-output>, or --node --entry <server.js> for a server.` | Running `publish` where there's no detectable app — usually a **monorepo/workspace root** | `cd` into the specific app's folder (the one whose `package.json` has the `build` script + framework dep) and publish there. Or pass `--dir`/`--node --entry` if the output/entry is non-standard. |
| ``no `build` script in package.json. Pass --dir <build-output> instead.`` | Same as above — cwd has a `package.json` but no `build` script | `cd` into the real app folder, or pass `--dir <build-output>`. |
| `found .html files but no index.html at the project root — rename your entry page to index.html (or pass --dir <path>).` | Plain-HTML static publish, but the entry page isn't named `index.html` at the root | Rename the homepage to exactly `index.html` at the root, or pass `--dir <path>`. The CLI never guesses the entry. |
| `pull failed (HTTP <status>): <server message>` | No previous version exists yet (v1), **or** a legacy row with no stored source snapshot | Read the relayed server message. For a v1 changelog, skip the diff and write `"Initial version."`. For a legacy row with no source, ask the user for a manual `--message`. |
| ``No live versions to open. Run `artor publish` first.`` | `artor open` with nothing published | Publish first (`artor publish`), then `artor open`. |
| `Already linked to "<name>" (<id>) — pass --force to re-point.` | `artor link` on a dir that's already linked to a different project | If re-pointing is intended, re-run with `--force`. Otherwise you're in the wrong dir — check `artor status`. |
| `Already linked to project "<slug>".` (from `artor init`) | `init` in an already-linked dir | Not an error — `init` just re-runs registry login + skill sync. Publish directly. |
| Suddenly logged out after `artor dev` (on or off) | `artor dev` drops the stored token **and** default org on **every** switch (on or off) | `artor login` again (and re-select the org if you have 2+). `artor dev off` returns to production. |
| Publishing/reading against the wrong org | Wrong active/default org | `artor whoami` to see the active org; `artor org list` then `artor org use <id\|slug>` to switch. |
| `artor status` shows `corrupt (<reason>)` for the project | The local `.artor/project.json` link is malformed | Re-link: `artor link <slug>` (add `--force` if needed) to rewrite it, or `artor init` for a new project. |
| `No local (pullable) env vars for this org. Nothing to write.` (from `artor env pull`) | The org has no `local (pullable)` env vars | Nothing to fix. Server-only vars are never pulled; if a var should be downloadable, an admin sets it with `artor env set KEY=VALUE --local`. |
| Private-package install fails (401/403 / missing scope) | Missing/stale `.npmrc` proxy block | `artor registry login` re-writes the managed `.npmrc` block (or re-run `artor pull`/`init`, which re-derive it). See `references/org-admin.md`. |
