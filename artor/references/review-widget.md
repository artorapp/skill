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
- **Next.js Pages Router / Vite / CRA / Angular**: `artor init` prepends a guarded
  `import { init } from "@artorapp/web-sdk"; if (typeof window !== "undefined") init();` block to the
  detected entry file: `pages/_app.tsx` or `src/pages/_app.tsx`; Vite `src/main.tsx`, `.ts`, `.jsx` or `.js` (a JS entry,
  e.g. a default Vue app, is wired from artor-cli 0.31.0); CRA `src/index.tsx`, `.ts`, `.jsx` or
  `.js`; Angular: the browser entry `angular.json` names for the project `ng build` selects
  (`browser`, or `main` on the browser builders), else `src/main.ts` (artor-cli 0.31.0+).

## An existing setup is left alone (artor-cli 0.31.0+)

- **`artor init` never edits a project that already sets the widget up.** Any import of
  `@artorapp/web-sdk` in the entry (named, aliased, namespace, side-effect, a subpath, `import()`
  with or without a bundler magic comment, or `require`), a call to `ArtorWebSdk.init` (also
  `ArtorWebSdk?.init(`, `ArtorWebSdk.init?.(` or `window["ArtorWebSdk"].init(`), or an
  `index.html` (root, `public/` or `src/`) with a `<script>` loading the SDK counts, and so does a
  commented-out import. A type-only import (`import type`, `export type ... from`, or
  `import { type A }` where every name is type-only) loads nothing at runtime, so it does NOT
  count: init wires the entry and keeps it. init prints
  `@artorapp/web-sdk is already set up in <file>; left it unchanged.` For Next.js, a layout that
  already renders `<ArtorReview>` counts, and an `artor-review.tsx` Artor did not generate is never
  overwritten. Don't "fix" such a project by adding a second `import { init }`: it won't compile.
- **Only the entry and the HTML pages are checked.** A setup in another file (a module the entry
  imports) is not seen, so init wires the entry too; remove one of the two.
- **The dependency is declared once.** `"@artorapp/web-sdk": "latest"` goes into
  `devDependencies` only when no section (`dependencies`, `devDependencies`, `peerDependencies`,
  `optionalDependencies`) declares it; an existing version or pin (`^0.11.0`, `file:`,
  `workspace:*`) is never changed. A `<script>` that loads the SDK by URL needs no dependency, so
  none is added. The line is inserted as a minimal text edit (key order, indent, line endings and
  a BOM are kept); a package.json that can't be edited safely (invalid JSON, not an object, or a
  non-object `devDependencies`) is left as is with a warning naming the line to add. Re-running
  `artor init` leaves every file byte-identical, except the repair below.
- Older CLIs (0.30.0 and earlier) prepended their block regardless, which could leave an entry
  with two `init` imports. **Re-running `artor init` (0.31.0+) repairs it:** it removes only the
  managed block next to the project's own setup, and only when that setup still starts the SDK
  itself (an `init` it imports is called, `ArtorWebSdk.init`, its own `<ArtorReview>`, or the
  app-served script) and the managed block is untouched: a commented-out or sorter-moved import, or
  a bare `import "@artorapp/web-sdk"`, is left alone. It prints `Removed a duplicate Artor setup from
  <file> (the project already sets up @artorapp/web-sdk in <path>).` On an older CLI, remove the
  managed block by hand and keep the project's own import. For Next.js the repair also deletes the
  generated `artor-review.tsx` when no other file may import it, else keeps it with a note.

## Manual wiring

If `artor init` reported it could not auto-wire (it prints a manual reminder — e.g. no `<body>` tag,
or no known entry file), add the call by hand in the framework's client entry:

```ts
// App Router — in your root layout's "use client" component:
import { init } from "@artorapp/web-sdk";
useEffect(() => init().teardown, []);

// Pages Router / Vite / CRA / Angular: top of the client entry file:
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
