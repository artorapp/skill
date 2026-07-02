# Review widget wiring

Reviewers leave in-page comments through the `@artorapp/web-sdk` review widget. `artor init`
installs and wires it automatically; this file covers the details for the cases where you need to
wire or update it by hand.

## What `artor init` does

`artor init` installs the `@artorapp/web-sdk` devDependency and wires an `init()` call into the
project's client entry point. The widget **self-disables off the Artor preview origin**, so it is
safe to leave committed — it does nothing in production or on `localhost`.

- **web-sdk auto-install (0.12.1+).** `init` installs the SDK for you; you don't add it manually.
- **Publish self-heals a missing install (0.12.1+).** If `node_modules` is absent, or `web-sdk` is
  listed in `package.json` but not installed, `artor publish` reinstalls dependencies before
  building — a missing SDK install won't break a publish.

## Framework-specific wiring

- **Next.js App Router** — `artor init` writes a managed `"use client"` `ArtorReview` component file
  alongside your root layout and inserts `<ArtorReview />` right after the opening `<body>` tag. The
  component calls `init()` inside `useEffect` and returns `null`.
- **Next.js Pages Router / Vite / CRA** — `artor init` prepends a guarded
  `import { init } from "@artorapp/web-sdk"; if (typeof window !== "undefined") init();` block to the
  detected entry file (`_app.tsx`, `main.tsx`, `src/index.tsx`, etc.).

## Manual wiring

If `artor init` reported it could not auto-wire (it prints a manual reminder — e.g. no `<body>` tag,
or no known entry file), add the call by hand in the framework's client entry:

```ts
// App Router — in your root layout's "use client" component:
import { init } from "@artorapp/web-sdk";
useEffect(() => init().teardown, []);

// Pages Router / Vite / CRA — top of the client entry file:
import { init } from "@artorapp/web-sdk";
if (typeof window !== "undefined") init();
```

The widget mounts on Artor preview origins only (`{previewId}.preview.{host}`). Off that origin
`init()` is a synchronous no-op — no network call, no DOM modification, no overhead.

## Updating the widget

The SDK is bundled into each published version and frozen there (versions are immutable), so there
is no in-place upgrade — bump the dependency and publish a new version:

```bash
npm i @artorapp/web-sdk@latest   # bump the pinned version (or pnpm/yarn/bun add)
artor publish                    # re-bundles + ships the new widget as the next version
```

Re-running `artor init` does **not** update an already-installed SDK (it wires it on first link
only). Old versions keep their old widget by design; to move a shared link onto the new build, move
an alias (`artor publish -v <name>`).
