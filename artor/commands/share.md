---
description: Create, list, extend, or turn off an anonymous view-only public link to an Artor version.
---

`artor share` mints **anonymous, view-only** links — anyone with the URL sees the prototype with
no Artor login. This is the **only** way org content leaves the closed garden, so confirm intent
before creating one, and never expose a version the user didn't mean to make public.

Public links are **view-only**: no source pull, no remix, no other org access, and server-only
secrets never load for a public visitor.

## Create a link

The version must already be **published** (`artor share` does not build or ship anything — run
`/artor:publish` first if needed).

```bash
# Follows the newest publish (default mode):
artor share add [--days N] [--warn]

# Pinned to ONE fixed version (its bytes never change):
artor share add --mode pinned --deployment <id> [--days N]
```

- **A live link is recopyable.** The full URL prints at `share add` **and** is re-displayed by
  `artor share list` while the link is live — so a lost link isn't gone, just run `share list`.
  Only a **dead** (turned-off/expired) or **legacy** (pre-encryption) link has no recoverable URL
  (`share list` shows `(reshare to copy)`); re-add for a fresh one.
- **`--days N`** sets duration (default 7). The server clamps it to the org cap and the platform
  ceiling (≤ 90 days). **`--warn`** emails the sharer ~24h before expiry.

## Manage links

```bash
artor share list                      # this project's links (run in the linked dir)
artor share extend <shareId> [--days N]
artor share off <shareId>
```

- `extend` only re-clamps a **live** link.
- `off` kills a link **permanently** — say **"turned off"**, never "revoked". A turned-off or
  expired link is **dead**; to share again, create a new link (fresh token). `extend` cannot
  resurrect a dead link.

Report the link/token exactly as the CLI returns it; never invent one.
