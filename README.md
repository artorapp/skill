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

Restart Claude Code (or start a new session). The skill then loads as `/artor:artor`.

## Update

```bash
claude plugin update artor
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
└── SKILL.md                      # the skill
skill.sh                          # convenience installer
```

## Maintaining

This repo is the **source of truth** — edit `artor/SKILL.md` directly here. The full release
runbook (versioning, validation, verification, rollback) lives in **[DEPLOYING.md](DEPLOYING.md)**.

The one rule worth repeating: bump the `version` in **both** `artor/.claude-plugin/plugin.json`
**and** `.claude-plugin/marketplace.json` (to the same value) on every content change —
`claude plugin update` only pulls on a version bump, so an unbumped push silently leaves installed
users on the old skill.
