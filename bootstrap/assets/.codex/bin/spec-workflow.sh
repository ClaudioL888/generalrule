#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SPEC_WORKFLOW_VERSION="${SPEC_WORKFLOW_VERSION:-2.2.5}"
SPEC_WORKFLOW_HOME_DEFAULT="$ROOT_DIR/.spec-workflow-mcp"
VENDOR_ROOT="$ROOT_DIR/.codex/vendor/spec-workflow"
NPM_CACHE_DIR="$ROOT_DIR/.codex/vendor/npm-cache"
BIN_PATH="$VENDOR_ROOT/node_modules/.bin/spec-workflow-mcp"
AUTO_INSTALL="${SPEC_WORKFLOW_AUTO_INSTALL:-0}"

export SPEC_WORKFLOW_HOME="${SPEC_WORKFLOW_HOME:-$SPEC_WORKFLOW_HOME_DEFAULT}"
export npm_config_cache="${npm_config_cache:-$NPM_CACHE_DIR}"

mkdir -p "$SPEC_WORKFLOW_HOME" "$VENDOR_ROOT" "$NPM_CACHE_DIR"

if [[ ! -x "$BIN_PATH" && "$AUTO_INSTALL" == "1" ]]; then
  echo "Installing @pimzino/spec-workflow-mcp@$SPEC_WORKFLOW_VERSION into $VENDOR_ROOT" >&2
  npm install \
    --no-save \
    --no-audit \
    --fund=false \
    --omit=optional \
    --prefer-offline \
    --prefix "$VENDOR_ROOT" \
    "@pimzino/spec-workflow-mcp@$SPEC_WORKFLOW_VERSION"
fi

if [[ ! -x "$BIN_PATH" ]]; then
  echo "spec-workflow is not installed in $VENDOR_ROOT" >&2
  echo "Run: bash scripts/dev/install-spec-workflow.sh" >&2
  exit 1
fi

exec "$BIN_PATH" "$@"
