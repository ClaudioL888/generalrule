#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[citation-quality] $1" >&2
  exit 1
}

normalize_changed_files() {
  if [[ -n "${CHANGED_FILES:-}" ]]; then
    printf '%s\n' "$CHANGED_FILES" | tr ' ' '\n' | sed '/^$/d'
    return
  fi

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
      git diff --name-only HEAD~1...HEAD
    else
      git diff --name-only HEAD
    fi
    return
  fi

  fail "CHANGED_FILES is required when git context is unavailable"
}

is_placeholder_value() {
  local value="$1"
  [[ -z "$value" || "$value" == *"TODO("* || "$value" == *"{{"* || "$value" == "TBD" || "$value" == "N/A" ]]
}

validate_source_line() {
  local file="$1"
  local line="$2"
  local source type note

  source="$(printf '%s\n' "$line" | sed -n -E 's/^- SOURCE:[[:space:]]*([^|]+)[[:space:]]+\|[[:space:]]*TYPE:[[:space:]]*([^|]+)[[:space:]]+\|[[:space:]]*NOTE:[[:space:]]*(.+)$/\1/p' | head -n1 | sed 's/[[:space:]]*$//')"
  type="$(printf '%s\n' "$line" | sed -n -E 's/^- SOURCE:[[:space:]]*([^|]+)[[:space:]]+\|[[:space:]]*TYPE:[[:space:]]*([^|]+)[[:space:]]+\|[[:space:]]*NOTE:[[:space:]]*(.+)$/\2/p' | head -n1 | sed 's/[[:space:]]*$//')"
  note="$(printf '%s\n' "$line" | sed -n -E 's/^- SOURCE:[[:space:]]*([^|]+)[[:space:]]+\|[[:space:]]*TYPE:[[:space:]]*([^|]+)[[:space:]]+\|[[:space:]]*NOTE:[[:space:]]*(.+)$/\3/p' | head -n1 | sed 's/[[:space:]]*$//')"

  [[ -n "$source" && -n "$type" && -n "$note" ]] || fail "$file contains malformed citation line: $line"
  is_placeholder_value "$source" && fail "$file contains placeholder SOURCE in citation block"
  is_placeholder_value "$note" && fail "$file contains placeholder NOTE in citation block"

  case "$type" in
    primary|secondary|internal)
      ;;
    *)
      fail "$file contains unsupported citation TYPE: $type"
      ;;
  esac

  case "$source" in
    http://*|https://*|docs/*|src/*|./*|../*|*.md)
      ;;
    *)
      fail "$file contains unsupported SOURCE reference: $source"
      ;;
  esac

  printf '%s\n' "$type"
}

extract_citation_block() {
  local file="$1"

  awk '
    BEGIN { in_section = 0 }
    /^##[[:space:]]+([0-9]+\.[[:space:]]+)?References and Evidence$/ {
      in_section = 1
      next
    }
    /^##[[:space:]]+/ {
      if (in_section) {
        exit
      }
    }
    in_section {
      print
    }
  ' "$file"
}

validate_doc() {
  local file="$1"
  local citation_block citation_lines line type
  local has_primary_or_internal=0
  local valid_lines=0

  [[ -f "$file" ]] || fail "changed citation-scoped doc not found: $file"

  grep -Eq '^##[[:space:]]+([0-9]+\.[[:space:]]+)?References and Evidence$' "$file" || fail "$file must include section: ## References and Evidence"

  citation_block="$(extract_citation_block "$file")"
  citation_lines="$(printf '%s\n' "$citation_block" | grep -E '^- SOURCE: ' || true)"
  [[ -n "$citation_lines" ]] || fail "$file must include at least one structured citation line"

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    type="$(validate_source_line "$file" "$line")"
    valid_lines=$((valid_lines + 1))
    if [[ "$type" == "primary" || "$type" == "internal" ]]; then
      has_primary_or_internal=1
    fi
  done <<<"$citation_lines"

  [[ "$valid_lines" -gt 0 ]] || fail "$file must include at least one valid citation line"
  [[ "$has_primary_or_internal" -eq 1 ]] || fail "$file must include at least one primary or internal citation"
}

NORMALIZED_CHANGED_FILES="$(normalize_changed_files)"

citation_files="$(printf '%s\n' "$NORMALIZED_CHANGED_FILES" | grep -E '^docs/(prd|design|adr|specs)/.*\.md$' || true)"

if [[ -z "$citation_files" ]]; then
  echo "[citation-quality] SKIP (no citation-scoped docs changes)"
  exit 0
fi

while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  validate_doc "$file"
done <<<"$citation_files"

echo "[citation-quality] PASS"
