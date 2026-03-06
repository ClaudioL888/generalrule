#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SPEC_WORKFLOW_AUTO_INSTALL=1 bash "$ROOT_DIR/.codex/bin/spec-workflow.sh" --help >/dev/null
echo "spec-workflow is installed at $ROOT_DIR/.codex/vendor/spec-workflow"
