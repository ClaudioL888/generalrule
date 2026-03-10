#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ ! -f ".pre-commit-config.yaml" ]]; then
  echo "missing .pre-commit-config.yaml" >&2
  exit 1
fi

if ! command -v pre-commit >/dev/null 2>&1; then
  echo "pre-commit is not installed. Install it first, then run: pre-commit install" >&2
  exit 1
fi

pre-commit install

echo "pre-commit installed"
