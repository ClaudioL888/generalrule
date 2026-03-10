#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[exception-gate] $1" >&2
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

LOCAL_MODE="${LOCAL_MODE:-0}"
DEFAULT_CURRENT_TASK_FILE="docs/status/current-task.md"

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
fi

NORMALIZED_CHANGED_FILES="$(normalize_changed_files)"
CURRENT_TASK_FILE="${CURRENT_TASK_FILE:-$DEFAULT_CURRENT_TASK_FILE}"
[[ -f "$CURRENT_TASK_FILE" ]] || fail "current task file missing: $CURRENT_TASK_FILE"

work_type="$(extract_meta "WORK_TYPE" "$CURRENT_TASK_FILE")"
exception_status="$(extract_meta "EXCEPTION_STATUS" "$CURRENT_TASK_FILE")"
exception_link="$(extract_meta "EXCEPTION_LINK" "$CURRENT_TASK_FILE")"
rework_risk="$(extract_meta "REWORK_RISK" "$CURRENT_TASK_FILE")"
metrics_impact="$(extract_meta "METRICS_IMPACT" "$CURRENT_TASK_FILE")"

value_required "WORK_TYPE" "$work_type"
value_required "REWORK_RISK" "$rework_risk"

case "$exception_status" in
  none|required|approved)
    ;;
  *)
    fail "EXCEPTION_STATUS must be none, required, or approved"
    ;;
esac

case "$rework_risk" in
  low|medium|high)
    ;;
  *)
    fail "REWORK_RISK must be low, medium, or high"
    ;;
esac

case "$metrics_impact" in
  none|engineering|product|both)
    ;;
  *)
    fail "METRICS_IMPACT must be none, engineering, product, or both"
    ;;
esac

if [[ "$work_type" == "fast-track" && "$exception_status" == "none" ]]; then
  fail "WORK_TYPE=fast-track requires EXCEPTION_STATUS to be required or approved"
fi

if [[ "$exception_status" == "none" ]]; then
  case "${exception_link:-}" in
    ""|N/A|none|None)
      ;;
    *)
      [[ -f "$exception_link" ]] || fail "EXCEPTION_LINK points to missing file: $exception_link"
      ;;
  esac
else
  value_required "EXCEPTION_LINK" "$exception_link"
  [[ -f "$exception_link" ]] || fail "EXCEPTION_LINK file missing: $exception_link"
  grep -Eq '^-[[:space:]]+EXCEPTION_ID:' "$exception_link" || fail "EXCEPTION_LINK must include EXCEPTION_ID"
  grep -Eq '^-[[:space:]]+FOLLOWUP_DEADLINE:' "$exception_link" || fail "EXCEPTION_LINK must include FOLLOWUP_DEADLINE"
  grep -Eq '^-[[:space:]]+ADR_LINK:' "$exception_link" || fail "EXCEPTION_LINK must include ADR_LINK"

  if grep -Eq '^src/' <<<"$NORMALIZED_CHANGED_FILES"; then
    has_changed_file "$exception_link" || fail "src changes with exception require EXCEPTION_LINK update: $exception_link"
  fi
fi

if [[ "$LOCAL_MODE" != "1" ]]; then
  exception_status_meta="$(extract_meta "EXCEPTION_STATUS" "$PR_BODY_SOURCE")"
  exception_link_meta="$(extract_meta "EXCEPTION_LINK" "$PR_BODY_SOURCE")"
  rework_risk_meta="$(extract_meta "REWORK_RISK" "$PR_BODY_SOURCE")"
  metrics_impact_meta="$(extract_meta "METRICS_IMPACT" "$PR_BODY_SOURCE")"

  value_required "REWORK_RISK(metadata)" "$rework_risk_meta"

  [[ "$exception_status_meta" == "$exception_status" ]] || fail "EXCEPTION_STATUS mismatch between metadata and current-task"
  [[ "$rework_risk_meta" == "$rework_risk" ]] || fail "REWORK_RISK mismatch between metadata and current-task"
  [[ "$metrics_impact_meta" == "$metrics_impact" ]] || fail "METRICS_IMPACT mismatch between metadata and current-task"

  if [[ "$exception_status" == "none" ]]; then
    case "${exception_link_meta:-}" in
      ""|N/A|none|None)
        ;;
      *)
        fail "EXCEPTION_LINK metadata must be N/A when EXCEPTION_STATUS=none"
        ;;
    esac
  else
    value_required "EXCEPTION_LINK(metadata)" "$exception_link_meta"
    [[ "$exception_link_meta" == "$exception_link" ]] || fail "EXCEPTION_LINK mismatch between metadata and current-task"
  fi
fi

echo "[exception-gate] PASS"
