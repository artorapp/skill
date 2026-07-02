#!/usr/bin/env bash
# One-step release for the Artor skill.
#
#   ./scripts/release.sh 0.7.0
#
# Bumps BOTH manifests to the given version, verifies a CHANGELOG entry exists,
# runs the consistency checks + `claude plugin validate`, and stages the result.
# You review and commit.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:-}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "usage: ./scripts/release.sh X.Y.Z" >&2
  exit 1
fi

node - "$VERSION" <<'EOF'
const fs = require("node:fs");
const version = process.argv[2];
for (const [file, mutate] of [
  ["artor/.claude-plugin/plugin.json", (j) => (j.version = version)],
  [".claude-plugin/marketplace.json", (j) => (j.plugins.find((p) => p.name === "artor").version = version)],
]) {
  const j = JSON.parse(fs.readFileSync(file, "utf8"));
  mutate(j);
  fs.writeFileSync(file, JSON.stringify(j, null, 2) + "\n");
  console.log(`bumped ${file} -> ${version}`);
}
EOF

node scripts/check-release.mjs

if command -v claude >/dev/null 2>&1; then
  claude plugin validate .
else
  echo "warn: 'claude' CLI not found — skipping plugin validate (CI will run it)" >&2
fi

git add artor/.claude-plugin/plugin.json .claude-plugin/marketplace.json
echo
echo "Staged version bump to $VERSION. Review, then:"
echo "  git commit -m \"skill: <what changed> (v$VERSION)\" && git push"
