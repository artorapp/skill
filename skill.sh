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
if ! add_out=$(claude plugin marketplace add artorapp/skill 2>&1); then
  # "add" fails when the marketplace is already registered — refresh it instead.
  # Any other failure (network, auth) is real: surface both errors and stop.
  if ! update_out=$(claude plugin marketplace update artor 2>&1); then
    echo "error: could not register or refresh the marketplace" >&2
    echo "--- marketplace add ---" >&2; echo "$add_out" >&2
    echo "--- marketplace update ---" >&2; echo "$update_out" >&2
    exit 1
  fi
  echo "$update_out"
else
  echo "$add_out"
fi

echo "==> Installing / updating the artor plugin"
if ! install_out=$(claude plugin install artor@artor 2>&1); then
  # "install" fails when the plugin is already installed — update it instead.
  if ! update_out=$(claude plugin update artor@artor 2>&1); then
    echo "error: could not install or update the artor plugin" >&2
    echo "--- plugin install ---" >&2; echo "$install_out" >&2
    echo "--- plugin update ---" >&2; echo "$update_out" >&2
    exit 1
  fi
  echo "$update_out"
else
  echo "$install_out"
fi

echo
echo "Done. Restart Claude Code (or start a new session), then run /artor:start-here to begin."
echo "The /artor:artor knowledge skill and the /artor:* commands are listed in the README:"
echo "  https://github.com/artorapp/skill#commands"
