#!/usr/bin/env bash
set -euo pipefail

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
  exit 1
fi

echo "[doc-link-check] PASS"
