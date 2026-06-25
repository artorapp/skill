# Deploying the Artor skill

How this skill reaches users, and how to ship a new version. The skill is distributed as a
**single-skill Claude Code plugin** served from the **`artor` marketplace** in this repo — there
is no separate "skill registry"; a git repo *is* the marketplace.

## What's in the repo

```
.claude-plugin/marketplace.json   # marketplace manifest (lists the plugin)
artor/
├── .claude-plugin/plugin.json    # plugin manifest (name + version)
└── SKILL.md                      # the skill itself  ← source of truth
skill.sh                          # convenience installer (curl | bash)
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
$EDITOR artor/SKILL.md

# 2. bump BOTH version fields to the SAME new value
#    artor/.claude-plugin/plugin.json        ->  "version"
#    .claude-plugin/marketplace.json         ->  plugins[0].version

# 3. validate the manifests
claude plugin validate .

# 4. commit + push
git add -A
git commit -m "skill: <what changed> (vX.Y.Z)"
git push
```

That's it — pushing to `main` makes the new version available to `claude plugin update`.

### Versioning (pre-1.0, 0.x semver)

| Change | Bump |
|--------|------|
| New skill capability / command coverage / behavior change | **MINOR** (`0.1.0 → 0.2.0`) |
| Typo, wording, formatting only | **PATCH** (`0.1.0 → 0.1.1`) |

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
