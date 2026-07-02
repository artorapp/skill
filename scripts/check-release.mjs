#!/usr/bin/env node
// Release-consistency checks for the Artor skill repo.
// Run directly (node scripts/check-release.mjs) or via CI / scripts/release.sh.
// Exits non-zero on the first class of failure, printing every finding first.

import { readFileSync, existsSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const read = (p) => readFileSync(join(root, p), "utf8");
const errors = [];
const check = (ok, msg) => {
  if (!ok) errors.push(msg);
};

// 1. Both manifests parse and versions match.
const plugin = JSON.parse(read("artor/.claude-plugin/plugin.json"));
const marketplace = JSON.parse(read(".claude-plugin/marketplace.json"));
const entry = marketplace.plugins?.find((p) => p.name === "artor");
check(!!entry, "marketplace.json has no plugins[] entry named 'artor'");
check(
  entry && plugin.version === entry.version,
  `version mismatch: plugin.json=${plugin.version} marketplace.json=${entry?.version}`,
);
check(
  /^\d+\.\d+\.\d+$/.test(plugin.version ?? ""),
  `plugin version '${plugin.version}' is not X.Y.Z semver`,
);

// 2. CHANGELOG.md has an entry for the current version.
const changelog = read("CHANGELOG.md");
check(
  changelog.includes(`## [${plugin.version}]`),
  `CHANGELOG.md has no '## [${plugin.version}]' entry`,
);

// 3. Every command file has frontmatter with a description.
const commandsDir = join(root, "artor/commands");
for (const f of readdirSync(commandsDir).filter((f) => f.endsWith(".md"))) {
  const body = read(join("artor/commands", f));
  check(
    /^---\n[\s\S]*?\bdescription:\s*\S/.test(body),
    `artor/commands/${f}: missing frontmatter description`,
  );
}

// 4. Drift guards — facts that once went stale in one copy while fixed in another.
//    Add a line here whenever a release fixes a cross-file contradiction.
const allDocs = ["artor/SKILL.md"]
  .concat(
    readdirSync(commandsDir)
      .filter((f) => f.endsWith(".md"))
      .map((f) => `artor/commands/${f}`),
  )
  .map((p) => [p, read(p)]);

for (const [p, body] of allDocs) {
  // 0.5.0: live share links ARE recopyable via `artor share list`.
  check(
    !/never re-?retrievable|one-?time token/i.test(body),
    `${p}: claims share links are one-time/never re-retrievable (recopyable since 0.5.0)`,
  );
  // Referenced skill files must exist.
  for (const m of body.matchAll(/\breferences\/([a-z0-9-]+\.md)/g)) {
    check(
      existsSync(join(root, "artor/references", m[1])),
      `${p}: references missing file artor/references/${m[1]}`,
    );
  }
}

// 5. SKILL.md frontmatter sanity (agentskills.io spec: name + description, <=1024 chars).
const skill = read("artor/SKILL.md");
const fm = skill.match(/^---\n([\s\S]*?)\n---/);
check(!!fm, "artor/SKILL.md: missing YAML frontmatter");
if (fm) {
  check(fm[1].length <= 1024, `SKILL.md frontmatter is ${fm[1].length} chars (max 1024)`);
  check(/^name:\s*artor\s*$/m.test(fm[1]), "SKILL.md frontmatter: name must be 'artor'");
  check(/^description:\s*\S/m.test(fm[1]), "SKILL.md frontmatter: missing description");
}

if (errors.length) {
  console.error(`check-release: ${errors.length} problem(s)\n`);
  for (const e of errors) console.error(`  ✗ ${e}`);
  process.exit(1);
}
console.log(`check-release: OK (version ${plugin.version})`);
