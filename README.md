# Artor — the agent skill

One skill that teaches **any coding agent** to drive the [`artor`](https://artor.app) CLI: publish,
version, and share prototypes (Next.js and framework-agnostic) — init/publish/open/share, fork or
restore, act on review comments, and manage org knowledge (skills, env vars, mock datasets,
registries).

It ships in two shapes from this one repo:

- **Claude Code** → the **full plugin**: the `/artor:artor` knowledge skill **and** the `/artor:*`
  slash commands, served from the `artor` marketplace in this repo.
- **Every other agent** (Codex, Cursor, Gemini, Copilot, OpenCode, …) → the **knowledge skill**
  (`SKILL.md` + its `references/`), installed via the cross-platform `skills` CLI. Same workflows,
  no slash commands.

The `artor` CLI is the same for every agent (`npm install -g artor-cli`); the skill only teaches the
agent how to drive it.

## Install

### Claude Code (full plugin)

```bash
claude plugin marketplace add artorapp/skill
claude plugin install artor@artor
```

Or inside Claude Code: `/plugin marketplace add artorapp/skill` → `/plugin install artor@artor`.
Or, from a clone, run `./skill.sh` (idempotent — registers/refreshes the marketplace and
installs/updates the plugin via the `claude` CLI). Restart Claude Code; the skill loads as
`/artor:artor` and the commands below become available.

### Every other agent (knowledge skill)

Cross-platform (including Windows), auto-detecting installed agents:

```bash
npx skills add artorapp/skill
```

Or, if you have the `artor` CLI, `artor install-skills` runs the same thing. This installs the
`SKILL.md` knowledge skill (and its `references/`) into your agent's skills directory; it does **not**
carry the `/artor:*` slash commands or the plugin manifest (those are Claude-plugin-specific). The
skill is also discoverable through [skills.sh](https://skills.sh).

You can also drop `SKILL.md` into any directory the agent scans — the folder must be named `artor`
(matching the skill's `name`). OpenCode reads `~/.config/opencode/skills/*/SKILL.md` (global) or
`.opencode/skills/*/SKILL.md` (per-project), and also `~/.claude/skills/*/SKILL.md`.

## Commands (Claude Code)

The plugin auto-invokes the `/artor:artor` knowledge skill when your prompt matches, and ships these
explicit slash commands:

| Command                   | What it does                                                                        |
| ------------------------- | ---------------------------------------------------------------------------------- |
| `/artor:start-here`       | First-run walkthrough — install/check the CLI, sign in, link, publish, share.       |
| `/artor:publish`          | Build + ship the next version with a generated changelog; return the preview URL.   |
| `/artor:share`            | Create / list / extend / turn off an anonymous view-only public link.               |
| `/artor:address-comments` | Read reviewer comments → fix → re-publish → resolve the threads.                     |
| `/artor:remix`            | Fork someone's prototype into a new project you own, then install + ship v1.         |
| `/artor:pull`             | Fetch a specific version's exact source safely, staying linked.                      |
| `/artor:doctor`           | Diagnose why Artor isn't working (orchestrates the CLI's status checks + fixes).     |
| `/artor:org-setup`        | Admin onboarding — env vars, mock datasets, org skills, templates, registries.       |

## Update

**Claude Code** — refresh the marketplace cache first, then pull the new plugin version (`plugin
update` only sees a new version after the marketplace is refreshed):

```bash
claude plugin marketplace update artor
claude plugin update artor@artor
```

**Other agents** — re-run `npx skills add artorapp/skill` (or `artor update-skill skills`).

## Uninstall

```bash
claude plugin uninstall artor
claude plugin marketplace remove artor
```

## Layout

```
.claude-plugin/marketplace.json   # marketplace manifest
artor/
├── .claude-plugin/plugin.json    # plugin manifest (name + version + metadata)
├── SKILL.md                      # the auto-invoked knowledge skill (agent-agnostic)
├── references/                   # on-demand deep dives loaded from SKILL.md
│   ├── review-widget.md          #   SDK wiring per framework, manual wiring, updates
│   ├── org-admin.md              #   env/mock/skills/templates/registry/folder + operator
│   └── troubleshooting.md        #   symptom → cause → fix (exact CLI error strings)
└── commands/                     # /artor:<name> slash commands (Claude Code only)
    ├── start-here.md  publish.md  share.md  address-comments.md
    └── remix.md  pull.md  doctor.md  org-setup.md
CHANGELOG.md                      # bulleted release history
LICENSE                           # MIT
skill.sh                          # convenience Claude-plugin installer
scripts/
├── release.sh                    # one-step version bump + validation + staging
└── check-release.mjs             # consistency + drift guards (also run by CI)
.github/workflows/ci.yml          # CI: check-release.mjs, plugin validate, link check
```

## Maintaining

This repo is the **source of truth** — edit `artor/SKILL.md` (and `references/`, `commands/`)
directly here. The full release runbook (versioning, validation, verification, rollback) lives in
**[DEPLOYING.md](DEPLOYING.md)**. Licensed **MIT** (see [LICENSE](LICENSE)).

The rules worth repeating on every content change:

1. Bump the `version` in **both** manifests to the same value — `scripts/release.sh X.Y.Z` does this
   plus runs the checks and stages the result. An unbumped push silently leaves installed users on
   the old skill.
2. Add a new **[CHANGELOG.md](CHANGELOG.md)** entry (grouped Added / Changed / Fixed) and mirror it
   into the GitHub Release notes.
3. When you fix a cross-file contradiction, add a **drift guard** for it in
   `scripts/check-release.mjs`. CI (`.github/workflows/ci.yml`) re-runs the checks and `claude plugin
   validate` on every push/PR.
