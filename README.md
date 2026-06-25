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
