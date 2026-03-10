#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[security-gate] $1" >&2
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

has_changed_file() {
  local needle="$1"
  grep -Fxq "$needle" <<<"$NORMALIZED_CHANGED_FILES"
}

has_changed_prefix() {
  local prefix="$1"
  grep -Eq "^${prefix}" <<<"$NORMALIZED_CHANGED_FILES"
}

ADR_FILE="docs/adr/0001-initial-decision.md"
RUNBOOK_FILE="docs/runbooks/incident-playbook.md"
RELEASE_NOTES_FILE="docs/release/RELEASE_NOTES.md"

[[ -f "$ADR_FILE" ]] || fail "missing ADR file: $ADR_FILE"
grep -Eq 'security_boundary|Security Boundary' "$ADR_FILE" || fail "ADR must describe security boundary (security_boundary)"

[[ -f "$RUNBOOK_FILE" ]] || fail "missing incident playbook: $RUNBOOK_FILE"

NORMALIZED_CHANGED_FILES="$(normalize_changed_files)"
if has_changed_prefix "src/"; then
  has_changed_file "$RELEASE_NOTES_FILE" || fail "src changes require ${RELEASE_NOTES_FILE} update for security impact disclosure"
fi

echo "[security-gate] PASS"
