#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[spec-quality] $1" >&2
  exit 1
}

extract_meta() {
  local key="$1"
  local source="$2"
  sed -n -E "s/^[-*] +${key}:[[:space:]]*(.*)$/\1/p" "$source" | tail -n1
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

has_changed_prefix() {
  local prefix="$1"
  grep -Eq "^${prefix}" <<<"$NORMALIZED_CHANGED_FILES"
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

SPEC_WORKFLOW_REQUIRED="${SPEC_WORKFLOW_REQUIRED:-optional}"
CURRENT_TASK_FILE="${CURRENT_TASK_FILE:-docs/status/current-task.md}"

case "$SPEC_WORKFLOW_REQUIRED" in
  optional|strict)
    ;;
  *)
    fail "SPEC_WORKFLOW_REQUIRED must be optional or strict"
    ;;
esac

NORMALIZED_CHANGED_FILES="$(normalize_changed_files)"

requires_spec_quality=0
if has_changed_prefix "src/" || has_changed_prefix "docs/specs/" || has_changed_prefix "docs/design/" || has_changed_prefix "docs/prd/" || has_changed_prefix "docs/plans/"; then
  requires_spec_quality=1
fi

if [[ "$requires_spec_quality" -eq 0 ]]; then
  echo "[spec-quality] SKIP (no spec-scoped changes)"
  exit 0
fi

[[ -f "$CURRENT_TASK_FILE" ]] || fail "current task file missing: $CURRENT_TASK_FILE"

spec_quality_status="$(extract_meta "SPEC_QUALITY_STATUS" "$CURRENT_TASK_FILE")"
spec_workflow_status="$(extract_meta "SPEC_WORKFLOW_STATUS" "$CURRENT_TASK_FILE")"
spec_workflow_link="$(extract_meta "SPEC_WORKFLOW_LINK" "$CURRENT_TASK_FILE")"

value_required "SPEC_QUALITY_STATUS" "$spec_quality_status"
value_required "SPEC_WORKFLOW_STATUS" "$spec_workflow_status"
value_required "SPEC_WORKFLOW_LINK" "$spec_workflow_link"

case "$spec_quality_status" in
  approved|degraded|pending)
    ;;
  *)
    fail "SPEC_QUALITY_STATUS must be approved, degraded, or pending"
    ;;
esac

case "$spec_workflow_status" in
  passed|unavailable|pending)
    ;;
  *)
    fail "SPEC_WORKFLOW_STATUS must be passed, unavailable, or pending"
    ;;
esac

[[ -f "$spec_workflow_link" ]] || fail "SPEC_WORKFLOW_LINK file missing: $spec_workflow_link"

grep -Eq '^# Spec Quality Review ' "$spec_workflow_link" || fail "SPEC_WORKFLOW_LINK must point to a spec quality review note"

if [[ "$SPEC_WORKFLOW_REQUIRED" == "strict" ]]; then
  [[ "$spec_quality_status" == "approved" ]] || fail "strict mode requires SPEC_QUALITY_STATUS=approved"
  [[ "$spec_workflow_status" == "passed" ]] || fail "strict mode requires SPEC_WORKFLOW_STATUS=passed"
else
  [[ "$spec_quality_status" != "pending" ]] || fail "optional mode still requires SPEC_QUALITY_STATUS to be resolved before implementation"
  [[ "$spec_workflow_status" != "pending" ]] || fail "optional mode still requires SPEC_WORKFLOW_STATUS to be resolved before implementation"
fi

echo "[spec-quality] PASS"
