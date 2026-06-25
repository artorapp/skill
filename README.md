# Artor — Claude Code skill

A Claude Code skill that wraps the [`artor`](https://artor.app) CLI to publish, version, and
share Next.js (and framework-agnostic) prototypes — init/publish/open/share, fork or restore,
and sync org skills, env vars, mock datasets, and registries.

Distributed as a single-skill **plugin** served from the `artor` marketplace in this repo.

## Install

One-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/artorapp/skill/main/skill.sh | bash
```

Or with the Claude Code CLI directly:

```bash
claude plugin marketplace add artorapp/skill
claude plugin install artor@artor
```

Or from inside Claude Code:

```
/plugin marketplace add artorapp/skill
/plugin install artor@artor
```

> **Recommended:** use one of the Claude-plugin methods above. They install the **full plugin** —
> the `/artor:artor` knowledge skill **and** the `/artor:*` slash commands.

### Via the `skills` CLI (skills.sh)

The skill is also discoverable through [skills.sh](https://skills.sh) (the Vercel-Labs skills
directory) and installable with the cross-agent `skills` CLI:

```bash
npx skills add artorapp/skill
```

> **Caveat — knowledge skill only.** `npx skills` installs the `SKILL.md` knowledge skill into
> your agent's skills directory; it does **not** carry the `/artor:*` slash commands or the plugin
> manifest (those are Claude-plugin-specific). For the commands, install via the Claude plugin
> marketplace above. skills.sh listings populate automatically from anonymous `skills add`
> telemetry — there's no manual submission.

### Other agents (OpenCode, etc.)

The `/artor:*` slash commands and the plugin/marketplace are **Claude Code-specific**. Other
agents that support the `SKILL.md` format (e.g. **OpenCode**) can use the **knowledge skill** —
the same workflows, just without the slash commands.

Easiest, auto-detects installed agents:

```bash
npx skills add artorapp/skill
```

Or drop the `SKILL.md` into a directory the agent scans (the folder name must be `artor`, matching
the skill's `name`). For OpenCode — global (all projects):

```bash
mkdir -p ~/.config/opencode/skills/artor
curl -fsSL https://raw.githubusercontent.com/artorapp/skill/main/artor/SKILL.md \
  -o ~/.config/opencode/skills/artor/SKILL.md
```

Per-project, use `.opencode/skills/artor/SKILL.md` instead. OpenCode also reads
`~/.claude/skills/*/SKILL.md`, so a single `artor/` folder there serves Claude Code and OpenCode
at once. The `artor` CLI install (`npm install -g artor-cli`) is the same for every agent — the
skill only teaches the agent how to drive it.

Restart Claude Code (or start a new session). The skill then loads as `/artor:artor`, and the
commands below become available.

## Commands

The plugin auto-invokes the `/artor:artor` knowledge skill when your prompt matches, and ships
these explicit slash commands:

| Command                   | What it does                                                                       |
| ------------------------- | ---------------------------------------------------------------------------------- |
| `/artor:start-here`       | First-run walkthrough — installs/checks the CLI, signs in, links, publishes, shares.|
| `/artor:publish`          | Build + ship the next version with a generated changelog; returns the preview URL. |
| `/artor:share`            | Create / list / extend / turn off an anonymous view-only public link.              |
| `/artor:address-comments` | Read reviewer comments → fix → re-publish → resolve the threads.                    |

## Update

Refresh the marketplace cache first, then pull the new plugin version — `plugin update` only sees
a new version after the marketplace is refreshed:

```bash
claude plugin marketplace update artor
claude plugin update artor@artor
```

## Uninstall

```bash
claude plugin uninstall artor
claude plugin marketplace remove artor
```

## Layout

```
.claude-plugin/marketplace.json   # marketplace manifest
artor/
├── .claude-plugin/plugin.json    # plugin manifest
├── SKILL.md                      # the auto-invoked knowledge skill
└── commands/                     # explicit /artor:<name> slash commands
    ├── start-here.md
    ├── publish.md
    ├── share.md
    └── address-comments.md
CHANGELOG.md                      # bulleted release history
skill.sh                          # convenience installer
```

## Maintaining

This repo is the **source of truth** — edit `artor/SKILL.md` directly here. The full release
runbook (versioning, validation, verification, rollback) lives in **[DEPLOYING.md](DEPLOYING.md)**.

The two rules worth repeating on every content change:

1. Bump the `version` in **both** `artor/.claude-plugin/plugin.json` **and**
   `.claude-plugin/marketplace.json` (to the same value) — `claude plugin update` only pulls on a
   version bump, so an unbumped push silently leaves installed users on the old skill.
2. Add a new **[CHANGELOG.md](CHANGELOG.md)** entry for the bump — extensive, bullet-pointed,
   grouped Added / Changed / Fixed — and mirror the bullets into the matching GitHub Release notes.
