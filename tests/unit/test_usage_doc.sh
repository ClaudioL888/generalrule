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
  "## 1. 项目定位与适用场景"
  "## 2. 前置条件"
  "## 3. 快速开始（5 分钟）"
  "## 5. 日常开发与门禁流程"
  "### 5.1 Skill 驱动开发（推荐）"
  "## 6. 常见失败与修复"
  "## 7. 版本升级与回归验证"
)

for section in "${required_sections[@]}"; do
  grep -q "$section" "$USAGE_DOC" || {
    echo "missing required section in usage doc: $section"
    exit 1
  }
done

echo "test_usage_doc.sh passed"
