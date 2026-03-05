#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.githooks"
PRE_PUSH_HOOK="$HOOKS_DIR/pre-push"
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

if [[ ! -d "$HOOKS_DIR" ]]; then
  mkdir -p "$HOOKS_DIR"
fi

if [[ ! -f "$PRE_PUSH_HOOK" ]]; then
  echo "missing hook template: $PRE_PUSH_HOOK" >&2
  exit 1
fi
if [[ ! -f "$PRE_COMMIT_HOOK" ]]; then
  echo "missing hook template: $PRE_COMMIT_HOOK" >&2
  exit 1
fi

chmod +x "$PRE_PUSH_HOOK" "$PRE_COMMIT_HOOK"
git -C "$REPO_ROOT" config core.hooksPath .githooks

echo "hooks installed: core.hooksPath=.githooks"
echo "restore default hooks path: git config --unset core.hooksPath"
