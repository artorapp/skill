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

echo "==> Registering the artorapp/skill marketplace"
claude plugin marketplace add artorapp/skill || claude plugin marketplace update artor

echo "==> Installing the artor plugin"
claude plugin install artor@artor

echo
echo "Done. Restart Claude Code (or start a new session) — the skill loads as /artor:artor."
