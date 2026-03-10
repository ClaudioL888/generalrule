#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
USAGE_DOC="$ROOT_DIR/docs/USAGE.md"
README_FILE="$ROOT_DIR/README.md"

[[ -f "$USAGE_DOC" ]] || {
  echo "missing usage document: $USAGE_DOC"
  exit 1
}

[[ -s "$USAGE_DOC" ]] || {
  echo "usage document is empty: $USAGE_DOC"
  exit 1
}

grep -q '\[docs/USAGE.md\](\./docs/USAGE.md)' "$README_FILE" || {
  echo "README.md must link to ./docs/USAGE.md"
  exit 1
}

required_sections=(
  "## 1. Positioning and Fit"
  "## 2. Prerequisites"
  "## 3. Quick Start (5 Minutes)"
  "## 5. Daily Development and Gate Flow"
  "### 5.1 Skill-Driven Development (Recommended)"
  "### 5.2 Recommended Read Order"
  "### 5.3 Metrics and Exceptions"
  "## 6. Common Failures and Fixes"
  "## 7. Version Upgrades and Regression Verification"
)

for section in "${required_sections[@]}"; do
  grep -q "$section" "$USAGE_DOC" || {
    echo "missing required section in usage doc: $section"
    exit 1
  }
done

echo "test_usage_doc.sh passed"
