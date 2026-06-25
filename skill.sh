#!/usr/bin/env bash
# Installs the Artor skill as a Claude Code plugin.
#
#   curl -fsSL https://raw.githubusercontent.com/artorapp/skill/main/skill.sh | bash
#
# or, from a clone:  ./skill.sh
set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
  echo "error: 'claude' CLI not found — install Claude Code first: https://claude.com/code" >&2
  exit 1
fi

echo "==> Registering / refreshing the artorapp/skill marketplace"
claude plugin marketplace add artorapp/skill || claude plugin marketplace update artor

echo "==> Installing / updating the artor plugin"
claude plugin install artor@artor || claude plugin update artor@artor

echo
echo "Done. Restart Claude Code (or start a new session)."
echo "Loads the /artor:artor knowledge skill, plus commands:"
echo "  /artor:start-here       first-run walkthrough (installs the CLI, login, init, publish, share)"
echo "  /artor:publish          build + ship the next version, return the preview URL"
echo "  /artor:share            create / list / extend / turn off a public view-only link"
echo "  /artor:address-comments read reviewer comments, fix, re-publish, resolve"
