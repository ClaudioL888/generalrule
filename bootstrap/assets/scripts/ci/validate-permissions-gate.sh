#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[permissions-gate] $1" >&2
  exit 1
}

extract_meta() {
  local key="$1"
  local source="$2"
  sed -n -E "s/^[-*] +${key}:[[:space:]]*(.*)$/\1/p" "$source" | tail -n1
}

value_required() {
  local name="$1"
  local value="$2"
  local normalized
  normalized="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
  if [[ -z "$value" || "$normalized" == "tbd" || "$normalized" == "n/a" || "$normalized" == "none" || "$normalized" == "null" ]]; then
    fail "${name} is required"
  fi
}

CODEOWNERS_FILE=".github/CODEOWNERS"
[[ -f "$CODEOWNERS_FILE" ]] || fail "missing CODEOWNERS file: $CODEOWNERS_FILE"

for required_pattern in \
  '^[[:space:]]*/?docs/' \
  '^[[:space:]]*/?scripts/ci/' \
  '^[[:space:]]*/?\.codex/' \
  '^[[:space:]]*/?\.github/'; do
  grep -Eq "$required_pattern" "$CODEOWNERS_FILE" || fail "CODEOWNERS missing required path rule pattern: $required_pattern"
done

LOCAL_MODE="${LOCAL_MODE:-0}"
PR_BODY_SOURCE=""

if [[ "$LOCAL_MODE" != "1" ]]; then
  if [[ -n "${PR_BODY_FILE:-}" ]]; then
    [[ -f "$PR_BODY_FILE" ]] || fail "PR_BODY_FILE not found: $PR_BODY_FILE"
    PR_BODY_SOURCE="$PR_BODY_FILE"
  elif [[ -n "${PR_BODY:-}" ]]; then
    PR_BODY_SOURCE="$(mktemp)"
    printf '%s\n' "$PR_BODY" > "$PR_BODY_SOURCE"
  else
    fail "PR_BODY_FILE or PR_BODY must be provided unless LOCAL_MODE=1"
  fi

  for key in CODEOWNER_REVIEW SECURITY_REVIEW RELEASE_REVIEW; do
    value="$(extract_meta "$key" "$PR_BODY_SOURCE")"
    value_required "$key" "$value"
    if [[ "$value" != "approved" ]]; then
      fail "$key must be approved"
    fi
  done
fi

echo "[permissions-gate] PASS"
