---
description: Create, list, edit, extend, or turn off an anonymous public link to an Artor version - no other org access, but the prototype itself is fully interactive, with optional guest commenting.
---

`artor share` mints **anonymous** links — anyone with the URL sees the prototype with
no Artor login. This is the **only** way org content leaves the closed garden, so confirm intent
before creating one, and never expose a version the user didn't mean to make public.

Public links are **view-only in terms of org access**: no source pull, no remix, nothing else in
the org, and server-only secrets never load for a public visitor. The **prototype itself**, though,
is fully interactive for anyone holding the link - its forms, API routes, and server actions run
normally for a visitor, exactly as they do for a signed-in member. **Guest commenting** (below) is
a separate, optional toggle: it only controls whether an accountless visitor can post through
Artor's own review-comment widget, not whether the prototype's own routes accept writes (those
always do, regardless of this setting). Treat a shared link as a demo, not a place for real
credentials or destructive actions - a shared prototype's own cross-site request protections can't
be relied on inside a shared preview.

## Create a link

The version must already be **published** (`artor share` does not build or ship anything — run
`/artor:publish` first if needed).

**Ask whether they want comments.** If the user hasn't said either way, ask ONE short question
before minting: should visitors without an Artor account be able to leave comments, and if so
with what identity, anonymous, name, or name + email? Then pass the answer explicitly:

```bash
# Follows the newest publish (default mode):
artor share add [--days N] [--warn] [--comments off|anonymous|name|name-email]

# Pinned to ONE fixed version (its bytes never change):
artor share add --mode pinned --deployment <id> [--days N] [--comments off|anonymous|name|name-email]

# With a link password (see "Link passwords" below - pipe it, never put it in argv):
printf '%s' "$PW" | artor share add --password-stdin
```

- `off` turns off guest commenting only (Artor's review widget) - the prototype's own routes accept
  writes either way; `anonymous` posts as "Anonymous guest"; `name` asks the visitor for a name;
  `name-email` asks for a name and an email.
- **The URL is a per-share subdomain**, e.g. `https://s-a1b2c3d4e5f6g7h8i9.preview.artor.app`
  (`s-` plus 18 lowercase alphanumeric characters), serving the shared version directly at its
  root. It's stable for the life of the share: safe to copy from the address bar and refresh-safe.
  An older link (`https://share.preview.artor.app/{token}`) still works — it auto-redirects to
  the new subdomain, no reshare needed.
- Without `--comments`, a non-interactive run (any agent-driven run) silently keeps the org's
  admin-set default, fine when the user says "just use the default", wrong when they had a
  preference you never asked about. On an interactive terminal the CLI itself asks with a picker.
- `share add` prints the guest-commenting mode the link ended up with; report it back alongside
  the URL. On an older server that predates guest commenting, the CLI prints a notice that the
  link is view-only - relay that honestly, but don't let it imply the prototype won't work: it
  means no org access beyond the prototype and no guest-comment feature on this link, not that
  the prototype's own forms, API routes, or server actions are disabled (they run normally for
  any visitor, on any server version).
- **Guest comments are contained**: a commenting guest writes through the review widget only,
  own-threads-only visibility, self-asserted identity, nothing else in the org. Guest threads
  show up in `artor comments` marked `guest <alias>`; filter with `--guests-only` / `--no-guests`.
- **A live link is recopyable.** The full URL prints at `share add` **and** is re-displayed by
  `artor share list` while the link is live — so a lost link isn't gone, just run `share list`. A
  **disabled** (turned-off) link shows `(off - reshare to copy)` (CLI 0.22.0 and older print an
  em-dash variant, `(off — reshare to copy)` - match either); an **expired** or **legacy**
  (pre-encryption) row shows `(reshare to copy)` — those have no recoverable URL, so re-add for a
  fresh one.
- **`--days N`** sets duration (default 7). The server clamps it to the org cap and the platform
  ceiling (≤ 90 days). **`--warn`** emails the sharer ~24h before expiry.

## Manage links

```bash
artor share list [--json]             # this project's links (run in the linked dir)
artor share set <share> [--comments off|anonymous|name|name-email]
artor share set <share> --remove-password          # take the password off
printf '%s' "$PW" | artor share set <share> --password-stdin   # set or change it
artor share extend <share> [--days N]
artor share off <share>
```

- **`<share>` is a link id from `share list`, or a unique 4+ character prefix of one.** A prefix
  resolves against the **linked** project's links (so run it inside the project); a full id works
  from anywhere. Anything shorter, or an ambiguous prefix, is refused with the candidates listed,
  never acted on. Because `off` is irreversible, a **prefix** there is confirmed with the resolved
  id named, and is **refused on an unattended run**: from an agent-driven run pass the **full id**.

- **`share list` line format** (human output, tab-separated):
  `<shareId>` `<mode>` `<state>` `<views>` `<url or hint>` and, on a **live** link only,
  a trailing `guests: <mode>`. `<state>` is `off` for a turned-off link, else
  `expires in N days` or `expired`; `<views>` is `N view` / `N views`. The guest word is one of
  `off`, `anonymous`, `name`, `name and email` - so a live link with guest commenting off still
  prints `guests: off`. The suffix is **absent** on a dead (turned-off or expired) link, whose mode is
  inert, and on an older server that doesn't send the field at all. Prefer `--json` when you need
  to parse this; the JSON carries `guestCommenting` as the raw enum (`name_email`, not
  `name and email`).
- **Password state also shows on a live line**, after the guests suffix: `password` when the link
  asks for one, or `needs a password` when the organization requires a password and this link has
  none (so it currently opens for nobody). Neither appears on a dead link. In `--json` they are
  `passwordProtected` and `blockedByPolicy`; an older server omits both.
- **`set` changes a LIVE link's guest-commenting mode, its password, or both** in one call: same
  URL, same expiry, and the CLI prints what the link ended up with. Password flags go **after** the
  share id. Always pass
  a flag from an agent-driven run - a `set` carrying **no** flag at all fails loud unattended
  ("--comments is required when not running interactively") instead of quietly no-opping; on an
  interactive terminal that flag-less form asks with a picker instead (Esc cancels, printing
  "Cancelled - no changes.", and there is no "Org default" row because the link already has a
  value). A password-only `set` is a complete command: it never opens the comments picker. A dead
  (turned-off or expired) link answers "No such live link (it may have been turned off or
  expired)" - reshare for a fresh link. The caller must be the link's **creator or an org admin**,
  and the project's Space must be writable to them (a read-only Space viewer gets "this project's
  space is read-only for you"; the fix is joining the space, or org-admin break-glass). `set`
  needs the current `artor` CLI - if it comes back as an unknown command, run `artor update`.
- `extend` only re-clamps a **live** link.
- `off` kills a link **permanently** — say **"turned off"**, never "revoked". A turned-off or
  expired link is **dead**; to share again, create a new link (fresh token). `extend` cannot
  resurrect a dead link.

## Link passwords

A link can ask for a **password** before it serves anything: available on **every plan**, off by
default, and it changes nothing about a link that has none. Needs artor-cli **0.26.0+** - an older
CLI rejects the flags as unknown, so run `artor update` and retry.

- **The password is never a flag value.** `--password` prompts for it on a terminal (hidden, typed
  twice) and takes **no** value: `--password=hunter2`, `--password hunter2` and
  `--password -hunter2` are all refused rather than silently creating an unprotected link. That
  keeps it out of shell history and `ps`.
- **From an agent-driven (unattended) run, always use `--password-stdin`** and pipe the value:
  `printf '%s' "$PW" | artor share add --password-stdin`. It takes no value either, reads stdin,
  strips exactly one trailing newline, and refuses a terminal ("--password-stdin expects the
  password on stdin (nothing is piped). Use --password to be prompted instead."), a non-UTF-8
  read, or an over-long one.
- **Ask the user for the password.** If they want you to generate one, generate a strong random
  value, show it to them **once**, and say plainly that it cannot be recovered later - Artor keeps
  only a hash and re-displays it nowhere, so a lost password means setting a new one. Never repeat
  a password back beyond what the user already wrote, never put it in argv, and never write it to
  a file in the project.
- **Rules:** 8 to 128 characters, no control characters, never trimmed (a space counts). A
  rejection prints a plain line, e.g. `Password must be at least 8 characters.`, and sends nothing.
- **Organization requirement.** If the organization requires a password on public links, an
  unattended `share add` without one is refused (403, `share_password_required`): "This
  organization requires a password on public links. Re-run with --password (or --password-stdin in
  scripts)." Get a password from the user and retry with `--password-stdin`. An interactive
  terminal is asked in place instead and the link is created without a re-run. While the
  requirement is on, `--remove-password` is refused: "This organization requires a password on
  public links, so it can't be removed."
- **Report back exactly.** `share add` prints "Password: on. Share it separately from the link; it
  can't be shown again." - so deliver the URL and the password through different channels.
  `share set` prints `password saved` or `password removed`.
- **Older server:** the CLI reports that the password was **not** applied and exits 1. On `add`
  the link exists **without** a password ("Run `artor share off <id>` to turn it off, or update
  the server.") - do not hand that URL out. On `set`, a `--comments` change sent in the same call
  is reported separately, because that half did land.
- **Visitor side:** the same URL shows a password page; the right password unlocks it for that
  browser session, up to 24h. Changing or removing the password re-locks every browser that had
  unlocked it. Org members who can already see the prototype's Space are never asked.

Report the link/token exactly as the CLI returns it; never invent one.
