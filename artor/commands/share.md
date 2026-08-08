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
artor share set <shareId> [--comments off|anonymous|name|name-email]
artor share extend <shareId> [--days N]
artor share off <shareId>
```

- **`share list` line format** (human output, tab-separated):
  `<shareId>` `<mode>` `<state>` `<views>` `<url or hint>` and, on a **live** link only,
  a trailing `guests: <mode>`. `<state>` is `off` for a turned-off link, else
  `expires in N days` or `expired`; `<views>` is `N view` / `N views`. The guest word is one of
  `off`, `anonymous`, `name`, `name and email` - so a live link with guest commenting off still
  prints `guests: off`. The suffix is **absent** on a dead (turned-off or expired) link, whose mode is
  inert, and on an older server that doesn't send the field at all. Prefer `--json` when you need
  to parse this; the JSON carries `guestCommenting` as the raw enum (`name_email`, not
  `name and email`).
- **`set` changes a LIVE link's guest-commenting mode** and nothing else: same URL, same expiry,
  only the mode moves, and the CLI prints the mode the link ended up with. Always pass
  `--comments` from an agent-driven run - unattended, a missing `--comments` fails loud
  ("--comments is required when not running interactively") instead of quietly no-opping; on an
  interactive terminal the CLI asks with a picker instead (Esc cancels, printing "Cancelled - no
  changes.", and there is no "Org default" row because the link already has a value). A dead
  (turned-off or expired) link answers "No such live link (it may have been turned off or
  expired)" - reshare for a fresh link. The caller must be the link's **creator or an org admin**,
  and the project's Space must be writable to them (a read-only Space viewer gets "this project's
  space is read-only for you"; the fix is joining the space, or org-admin break-glass). `set`
  needs the current `artor` CLI - if it comes back as an unknown command, run `artor update`.
- `extend` only re-clamps a **live** link.
- `off` kills a link **permanently** — say **"turned off"**, never "revoked". A turned-off or
  expired link is **dead**; to share again, create a new link (fresh token). `extend` cannot
  resurrect a dead link.

Report the link/token exactly as the CLI returns it; never invent one.
