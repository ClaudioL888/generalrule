#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ -f "$ROOT_DIR/scripts/lib/step-report.sh" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/scripts/lib/step-report.sh"
else
  emit_step_report() { return 0; }
fi

failures=0
DOCS_ROOT="${DOCS_ROOT:-docs}"

if [[ ! -d "$DOCS_ROOT" ]]; then
  echo "[doc-link-check] docs root does not exist: $DOCS_ROOT" >&2
  exit 1
fi

while IFS= read -r -d '' file; do
  while IFS= read -r match; do
    target="${match#*](}"
    target="${target%)}"

    if [[ -z "$target" || "$target" == \#* || "$target" == http://* || "$target" == https://* || "$target" == mailto:* ]]; then
      continue
    fi

    if [[ "$target" == *"{{"* || "$target" == *"}}"* ]]; then
      continue
    fi

    clean_target="${target%%#*}"
    clean_target="${clean_target%%\?*}"

    if [[ -z "$clean_target" ]]; then
      continue
    fi

    if [[ "$clean_target" == /* ]]; then
      resolved_path="${PWD}${clean_target}"
    else
      resolved_path="$(cd "$(dirname "$file")" && pwd)/$clean_target"
    fi

    if [[ ! -e "$resolved_path" ]]; then
      echo "[doc-link-check] missing link target in $file: $target" >&2
      failures=$((failures + 1))
    fi
  done < <(grep -oE '\[[^]]+\]\(([^)]+)\)' "$file" || true)
done < <(find "$DOCS_ROOT" -type f -name '*.md' -print0)

if [[ "$failures" -gt 0 ]]; then
  echo "[doc-link-check] FAIL ($failures missing links)" >&2
  emit_step_report \
    "validate-doc-links" \
    "doc links gate" \
    "校验 docs 下 markdown 链接可达性" \
    "none" \
    "none" \
    "validate-doc-links.sh" \
    "fail" \
    "发现 ${failures} 个失效链接" \
    "修复文档链接后重试"
  exit 1
fi

echo "[doc-link-check] PASS"
emit_step_report \
  "validate-doc-links" \
  "doc links gate" \
  "校验 docs 下 markdown 链接可达性" \
  "none" \
  "none" \
  "validate-doc-links.sh" \
  "pass" \
  "文档链接校验通过" \
  "继续执行后续门禁"
