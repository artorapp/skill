# Artor Skill — Diagnosis Report

Date: 2026-07-02 · Skill version reviewed: **0.6.1** · Scope: diagnosis only, no changes made.

Reviewed: `artor/SKILL.md`, all four `artor/commands/*.md`, both plugin manifests, `skill.sh`,
`README.md`, `DEPLOYING.md`, `CHANGELOG.md`.

---

## Summary

The skill is in good shape overall: complete command coverage, unusually careful semantics
(pull vs remix, pinned vs latest, "turned off" vs "revoked"), explicit trust notes for untrusted
input, and a disciplined release process. The main problems are **content drift between
`SKILL.md` and the command files** (including one outright contradiction), **duplication with no
single source of truth**, and **zero test/CI infrastructure** for a repo whose entire product is
documentation. Below: findings ranked, then proposed new subskills, then optimizations.

---

## 1. High-priority issues (correctness)

### 1.1 Contradiction: share-link recoverability

`commands/start-here.md` (step 4) says:

> Capture the **one-time token** from the output and hand it to them (**it's never
> re-retrievable**).

But `SKILL.md` ("Share a prototype publicly") and `commands/share.md` — updated in 0.5.0 — say
the opposite: **a live link is recopyable** via `artor share list`. `start-here.md` was never
updated for the 0.5.0 recopyable-links change. An agent running the walkthrough will give the
user false urgency and wrong information. **Fix: rewrite step 4 to match share.md.**

### 1.2 Drift: `/artor:publish` doesn't know about the boot test

The publish boot test and `--no-smoke` escape were added to `SKILL.md` in 0.6.0, but
`commands/publish.md` (written at 0.3.0) never mentions them. An agent driving `/artor:publish`
that hits a boot-test failure has no guidance to diagnose it or offer `--no-smoke`. Same drift
class as 1.1: features land in `SKILL.md` and the command files silently fall behind.

### 1.3 Drift: monorepo guidance missing from the commands

0.6.1's monorepo section exists only in `SKILL.md`. `commands/publish.md` and
`commands/start-here.md` — the two flows where an agent actually runs `init`/`publish` — say
nothing about checking for a workspace root first. A user invoking `/artor:publish` inside a
monorepo root gets the exact failure 0.6.1 was written to prevent.

### 1.4 Hardcoded shared temp path in changelog generation

Both `SKILL.md` and `publish.md` instruct pulling the previous version into a **fixed** path,
`/tmp/artor-prev-source`. Two problems:

- **Stale contents**: a leftover pull from a *different* project (or an older version of the same
  one) silently pollutes the diff → wrong changelog.
- No cleanup step is specified.

Fix: instruct a unique temp dir (`mktemp -d`) and an explicit "remove it after diffing" step —
or better, have the CLI grow a `artor diff [--ref <r>]` command so the skill doesn't have to
choreograph this at all (see §4.1).

---

## 2. Structural issues (maintainability)

### 2.1 No single source of truth: SKILL.md ⟷ commands duplicate ~60% of content

The changelog flow, share semantics, and comments loop each exist **twice**, near-verbatim
(SKILL.md + the matching command file). Sections 1.1–1.3 are the predictable result: every
release must touch N places and some get missed. Options, in order of preference:

1. **Thin commands**: each `commands/*.md` shrinks to the workflow skeleton + "the `/artor:artor`
   skill is loaded; follow its <section> for details". Commands stay useful as entry points;
   facts live once.
2. A generation step (script assembles command files from SKILL.md sections) — more machinery,
   probably overkill at this size.

A release-checklist line in DEPLOYING.md ("grep the command files for every fact you changed")
is the minimum viable fix if you keep duplication.

### 2.2 `skill.sh` echoes the command list — a third copy

Lines 22–26 of `skill.sh` list the four commands with one-line descriptions, duplicating README
and the manifests. When a command is added/renamed (it already happened: `start` → `start-here`
in 0.4.0), this is another place to forget. Either trim to "run `/artor:start-here` to begin"
or accept it and add it to the release checklist.

### 2.3 SKILL.md is monolithic (~340 lines) — no progressive disclosure

Everything loads whenever the skill triggers, including content most sessions never need
(operator/admin table, review-widget wiring internals, org registry setup). The Agent Skills
format supports supporting files loaded on demand. Suggested split:

```
artor/
├── SKILL.md                    # triggers, first-check, core workflows, command tables (lean)
└── references/
    ├── review-widget.md        # SDK wiring, per-framework entry points, update procedure
    ├── org-admin.md            # env/mock/skills/templates/registry + operator table
    └── troubleshooting.md      # new — see §3.1
```

Keep publish/share/comments workflows inline (they're the hot path); point to references for
the rest. This also creates natural homes for the growth in §4.

---

## 3. Gaps (missing content)

### 3.1 No troubleshooting section

Failure guidance is scattered (HTTP 426 in the CLI table, boot-test in publish notes, legacy
share rows in the share section) and much of it is absent entirely. A consolidated
symptom → cause → fix table would cover:

- `command not found: artor` → install `artor-cli`
- HTTP 426 → `artor update` (already documented, move/copy here)
- Boot-test crash on publish → read crash output; `--no-smoke` only if the app truly needs live services
- "no build script" at a workspace root → monorepo, `cd` into the app
- Token expired / logged out (e.g. after `artor dev`) → `artor login`
- Wrong org publish target → `artor org list` / `org use`
- `artor link` onto a dir already linked → `--force` semantics
- `pull` errors: no `latest` yet vs legacy row without source snapshot (currently only in the changelog-flow steps)

### 3.2 Under-explained commands (listed but not usable)

The reference tables name these, but an agent can't confidently drive them:

- **`artor env set --local` vs org-level; what "pullable" means for `env pull`** — the semantics
  of local/pullable/server-only env vars are never defined.
- **`artor mock`** — one row mentions `/__mock/<name>`; nothing on when to use mocks, the file
  format, or what `promote` does.
- **`artor registry login`** — listed with zero explanation.
- **`artor folder`** subcommands — six verbs in one row, no workflow.
- **`artor link` vs `init`** decision — when attaching to an existing project matters (a teammate
  cloning a repo that's already an Artor project is a common case with no guidance).

Either document them (in `references/org-admin.md`) or consciously mark them "run
`artor <cmd> --help`" and keep them out of the tables.

### 3.3 No "when NOT to use" section

Skill-discovery best practice. Candidates: not a production-deploy tool (vs Vercel/hosting),
not a git replacement, `artor dev` never in a normal workflow (this one is documented but buried).

### 3.4 Trigger-phrase coverage in the frontmatter description

The description is good but misses vocabulary users actually say: **"deploy this"**, **"put
this online"**, **"demo link"**, **"preview link"** is there but not "preview URL", **"send
this to my team"**, **"what did reviewers say"**. Also, per skill-authoring guidance,
descriptions should lean toward *triggering conditions*, not a capability summary — the current
one spends half its length summarizing the CLI surface ("wraps the artor CLI to init/publish/
open/share…"), which an agent may treat as a substitute for reading the body.

### 3.5 JSON-payload handling guidance

`artor comments --open --json` on a heavily-reviewed version can be large. One line suggesting
`jq` filtering (e.g. extract `route` + latest comment body per thread) would keep agent context
lean. Same for any future `--json` surfaces.

---

## 4. Proposed new subskills / slash commands

Ranked by expected value:

| Priority | Command | Rationale |
|---|---|---|
| **P1** | `/artor:remix` | Forking someone's prototype is a first-class flow (pull, `.npmrc` setup, install with the right package manager, init widget check, first publish of the fork). Today it's two paragraphs in SKILL.md with no end-to-end driver. |
| **P1** | `/artor:doctor` (or `troubleshoot`) | Runs `artor --version` → `artor status` → `artor whoami` → checks `.artor/project.json`, monorepo root detection, dev-mode status; maps findings to the §3.1 table. Turns "it doesn't work" into a one-command diagnosis. |
| **P2** | `/artor:org-setup` | Admin onboarding: env vars, mock datasets, org skills, templates, private registries — a guided walkthrough mirroring `start-here` but for owners/admins. Also the natural home for the §3.2 explanations. |
| **P2** | `/artor:pull` | "Get me the code reviewers saw" — pull a specific version safely (warn about overwriting the working tree, suggest a branch/temp dir), the sibling of `address-comments` step 2. |
| **P3** | `/artor:mock` | Set up a mock dataset and wire the app to `/__mock/<name>` — only worth it if mocks are a real usage pillar. |

Not worth commands: `update`, `org use`, `folder` (single-line invocations; the knowledge skill
handles them).

---

## 5. Testing & CI (currently: none)

The product of this repo is agent-facing documentation, and none of it is tested.

1. **CI on every push/PR (GitHub Actions):**
   - `claude plugin validate .`
   - Assert `plugin.json` version == `marketplace.json` plugins[0].version (the #1 documented
     footgun, trivially scriptable).
   - Assert `CHANGELOG.md` contains an entry for the current version.
   - Markdown link check.
   - Grep-level drift guards: e.g. fail if `start-here.md` still says "never re-retrievable",
     or if a flag documented in SKILL.md's publish section is absent from `publish.md`.
2. **Scenario evals (the real test):** a handful of scripted pressure prompts run against a
   fresh agent with the skill installed — "publish this" in a monorepo root, "share this" when
   nothing is published yet, "the link I made last week, get it back" (recopy vs re-add),
   "publish, the boot test failed" (must not reflexively reach for `--no-smoke`). Baseline-vs-skill
   behavior is the only way to know the words actually steer the model. Even 5 scenarios run
   manually before each MINOR release would have caught 1.1–1.3.
3. **A `release.sh`** that does bump-both-manifests + validate + changelog check in one step,
   so DEPLOYING.md's manual 4-step dance can't be half-done.

---

## 6. Smaller optimizations & nits

- **`skill.sh` error masking**: `add … || update …` and `install … || update …` — a *network*
  failure on the first command silently falls through to the second, whose error message then
  misleads. Distinguish "already exists" from other failures, or at least echo both errors.
- **Versioning-rule ambiguity**: DEPLOYING.md says new capability/coverage = MINOR, wording =
  PATCH. 0.6.0 (docs-only, new CLI features documented) was MINOR; 0.6.1 (docs-only, new
  guidance section) was PATCH with a justification note. The distinction "documents new CLI
  behavior = MINOR, clarifies existing behavior = PATCH" is what's actually practiced — write
  that down explicitly.
- **`plugin.json` metadata**: no `license` (and no LICENSE file in the repo), no `keywords`,
  no `repository` field. Cheap wins for marketplace/skills.sh discoverability.
- **`artor open` in headless environments**: presumably opens a browser; one line on what
  happens (or what to report instead) when there's no display would help CI/remote agents.
- **start-here step 3** asserts the preview URL is members-only; SKILL.md never states this
  outside the share section. State it once in SKILL.md's publish notes (it's a fact agents
  should report when handing over a preview URL).
- **Changelog cap**: "under 2 000 characters" appears three times across two files — dedup
  target once §2.1 is addressed.

---

## 7. Suggested roadmap

1. **v0.6.2 (PATCH, urgent)** — fix the `start-here.md` one-time-token contradiction (1.1);
   add boot-test/`--no-smoke` and monorepo lines to `publish.md`/`start-here.md` (1.2, 1.3);
   switch changelog flow to `mktemp -d` + cleanup (1.4).
2. **v0.7.0 (MINOR)** — restructure: thin commands + `references/` split (2.1, 2.3);
   troubleshooting section (3.1); description/trigger tune-up (3.4); LICENSE + manifest metadata.
3. **v0.8.0 (MINOR)** — new commands: `/artor:remix`, `/artor:doctor` (§4 P1s).
4. **Parallel, no version needed** — CI workflow + `release.sh` + first scenario evals (§5).
