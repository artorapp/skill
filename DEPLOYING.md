# Deploying the Artor skill

How this skill reaches users, and how to ship a new version. The skill is distributed as a
**single-skill Claude Code plugin** served from the **`artor` marketplace** in this repo — there
is no separate "skill registry"; a git repo *is* the marketplace.

## What's in the repo

```
.claude-plugin/marketplace.json   # marketplace manifest (lists the plugin)
artor/
├── .claude-plugin/plugin.json    # plugin manifest (name + version)
├── SKILL.md                      # the skill itself  ← source of truth
├── references/                   # on-demand deep dives loaded from SKILL.md
└── commands/                     # /artor:* slash commands (Claude Code only)
skill.sh                          # convenience installer (curl | bash)
scripts/release.sh                # one-step version bump + validation
scripts/check-release.mjs         # consistency + drift checks (also run by CI)
.github/workflows/ci.yml          # CI: checks + claude plugin validate
```

- **`marketplace.json`** — `name: "artor"`, `owner`, and a `plugins[]` entry with
  `source: "./artor"` and a `version`. This file is what `claude plugin marketplace add` reads.
- **`plugin.json`** — the plugin's own `name: "artor"` and `version`. This is what
  `claude plugin install` / `claude plugin update` key off.
- The two `version` fields **must always match.**

## How users install

```bash
# one-liner
curl -fsSL https://raw.githubusercontent.com/artorapp/skill/main/skill.sh | bash

# or explicitly
claude plugin marketplace add artorapp/skill
claude plugin install artor@artor          # plugin@marketplace
```

Or inside Claude Code: `/plugin marketplace add artorapp/skill` → `/plugin install artor@artor`.
The skill loads next session as `/artor:artor`.

## Releasing a new version

The skill mirrors the [`artor` CLI](https://artor.app) command surface, so update it whenever a
CLI command, flag, or agent-relied-on output changes.

```bash
# 1. edit the source of truth
$EDITOR artor/SKILL.md          # and artor/references/*.md, artor/commands/*.md as needed

# 2. sweep for drift: every fact you changed may also live in a command file
grep -rl "<the old wording>" artor/

# 3. add a CHANGELOG.md entry, then bump + validate in one step
./scripts/release.sh X.Y.Z      # bumps BOTH manifests, runs checks + plugin validate, stages

# 4. commit + push
git commit -m "skill: <what changed> (vX.Y.Z)"
git push
```

That's it — pushing to `main` makes the new version available to `claude plugin update`.
CI (`.github/workflows/ci.yml`) re-runs `scripts/check-release.mjs` (version match, changelog
entry, drift guards, frontmatter sanity) and `claude plugin validate` on every push/PR.

> **When you fix a cross-file contradiction, add a drift guard** for it in
> `scripts/check-release.mjs` (section 4) so it can never come back.

### Versioning (pre-1.0, 0.x semver)

| Change | Bump |
|--------|------|
| New skill capability: new command file, new workflow, documents **new CLI behavior** | **MINOR** (`0.1.0 → 0.2.0`) |
| Clarifies/fixes wording about **existing, already-documented behavior**; typo/formatting | **PATCH** (`0.1.0 → 0.1.1`) |

The line that matters: *does an agent gain the ability to do something it couldn't before?*
New CLI feature documented → MINOR, even if "docs-only". Better explanation of a feature the
skill already covered → PATCH.

### Why the version bump is mandatory

`claude plugin update artor` only pulls a new copy **when the manifest `version` changes**. Push a
new `SKILL.md` *without* bumping and already-installed users keep the **old** skill — it silently
drifts. Bump on **every** content change, and keep both manifests in lock-step.

> If you forget and have already pushed: bump both versions in a follow-up commit and push again.
> A plain content push with an unchanged version is effectively invisible to installed users.

## Verifying a release

```bash
# manifests are well-formed
claude plugin validate .

# fresh end-to-end install (in a throwaway shell / machine)
claude plugin marketplace add artorapp/skill
claude plugin install artor@artor
claude plugin list                 # confirm the new version is shown
```

The installer URL must also stay reachable:

```bash
curl -fsSL -o /dev/null -w "%{http_code}\n" \
  https://raw.githubusercontent.com/artorapp/skill/main/skill.sh   # expect 200
```

## Rollback

Manifest version is the only thing `claude plugin update` keys off, so roll forward, don't roll
back the number:

```bash
git revert <bad-commit>        # restore the previous SKILL.md content
# then bump BOTH versions to a NEW value higher than the bad one (e.g. 0.3.0 -> 0.3.1)
git commit --amend             # fold the bump in, or add a follow-up commit
git push
```

Reusing or lowering a version means installed users won't pull the fix.

## Source of truth

This repo is canonical — edit `artor/SKILL.md` here. The Artor monorepo no longer vendors the
skill; its `AGENTS.md` points here and carries the keep-current rule that ties a CLI change to a
skill update.

## Uninstall (for users)

```bash
claude plugin uninstall artor
claude plugin marketplace remove artor
```
