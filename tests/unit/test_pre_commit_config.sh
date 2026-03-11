#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOT_CONFIG="$ROOT_DIR/.pre-commit-config.yaml"
BOOTSTRAP_CONFIG="$ROOT_DIR/bootstrap/assets/.pre-commit-config.yaml"

[[ -f "$ROOT_CONFIG" ]] || { echo "missing root pre-commit config"; exit 1; }
[[ -f "$BOOTSTRAP_CONFIG" ]] || { echo "missing bootstrap pre-commit config"; exit 1; }

grep -Fq 'files: ^bootstrap/assets/docs/status/current-task.md$' "$ROOT_CONFIG" || {
  echo "root pre-commit config should target bootstrap current-task path"
  exit 1
}
grep -Fq 'CHANGED_FILES="bootstrap/assets/docs/status/current-task.md"' "$ROOT_CONFIG" || {
  echo "root pre-commit config should validate the bootstrap current-task path"
  exit 1
}
grep -Fq 'files: ^docs/status/current-task.md$' "$BOOTSTRAP_CONFIG" || {
  echo "bootstrap pre-commit config should target generated current-task path"
  exit 1
}
grep -Fq 'CHANGED_FILES="docs/status/current-task.md"' "$BOOTSTRAP_CONFIG" || {
  echo "bootstrap pre-commit config should validate the generated current-task path"
  exit 1
}

echo "test_pre_commit_config.sh passed"
