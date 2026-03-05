#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[role-flow] $1" >&2
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

is_allowed_transition() {
  local task_type="$1"
  local current="$2"
  local next="$3"
  local transition
  transition="${current}:${next}"

  case "$task_type" in
    feature)
      case "$transition" in
        Founder:PM|PM:Architect|Architect:Planner|Planner:Dev|Dev:QA|QA:Reviewer|Reviewer:Release-Ops|Release-Ops:Growth|Growth:PM)
          return 0
          ;;
      esac
      ;;
    bugfix)
      case "$transition" in
        Planner:Dev|Dev:QA|QA:Reviewer|Reviewer:Release-Ops|Release-Ops:Planner)
          return 0
          ;;
      esac
      ;;
    refactor)
      case "$transition" in
        Architect:Planner|Planner:Dev|Dev:QA|QA:Reviewer|Reviewer:Release-Ops|Release-Ops:Architect)
          return 0
          ;;
      esac
      ;;
    ops)
      case "$transition" in
        Planner:Dev|Dev:QA|QA:Reviewer|Reviewer:Release-Ops|Release-Ops:Planner)
          return 0
          ;;
      esac
      ;;
    content)
      case "$transition" in
        PM:Content-Growth|Content-Growth:Reviewer|Reviewer:PM)
          return 0
          ;;
      esac
      ;;
  esac

  return 1
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
task_type="$(extract_meta "TASK_TYPE" "$CURRENT_TASK_FILE")"
current_role="$(extract_meta "CURRENT_ROLE" "$CURRENT_TASK_FILE")"
next_role="$(extract_meta "NEXT_ROLE" "$CURRENT_TASK_FILE")"
handoff_link="$(extract_meta "HANDOFF_LINK" "$CURRENT_TASK_FILE")"

value_required "WORK_TYPE" "$work_type"
value_required "TASK_TYPE" "$task_type"
value_required "CURRENT_ROLE" "$current_role"
value_required "NEXT_ROLE" "$next_role"
value_required "HANDOFF_LINK" "$handoff_link"

case "$task_type" in
  feature|bugfix|refactor|ops|content)
    ;;
  *)
    fail "TASK_TYPE must be one of: feature, bugfix, refactor, ops, content"
    ;;
esac

[[ -f "$handoff_link" ]] || fail "HANDOFF_LINK file not found: $handoff_link"

if ! is_allowed_transition "$task_type" "$current_role" "$next_role"; then
  fail "illegal role transition for ${task_type}: ${current_role} -> ${next_role}"
fi

if grep -Eq '^src/' <<<"$NORMALIZED_CHANGED_FILES"; then
  has_changed_file "$handoff_link" || fail "src changes require HANDOFF_LINK update: $handoff_link"
fi

if [[ "$work_type" == "fast-track" ]]; then
  [[ "$task_type" == "ops" ]] || fail "WORK_TYPE=fast-track must use TASK_TYPE=ops"
fi

if [[ "$LOCAL_MODE" != "1" ]]; then
  task_type_meta="$(extract_meta "TASK_TYPE" "$PR_BODY_SOURCE")"
  current_role_meta="$(extract_meta "CURRENT_ROLE" "$PR_BODY_SOURCE")"
  next_role_meta="$(extract_meta "NEXT_ROLE" "$PR_BODY_SOURCE")"
  handoff_link_meta="$(extract_meta "ROLE_HANDOFF_LINK" "$PR_BODY_SOURCE")"
  work_type_meta="$(extract_meta "WORK_TYPE" "$PR_BODY_SOURCE")"

  value_required "TASK_TYPE(metadata)" "$task_type_meta"
  value_required "CURRENT_ROLE(metadata)" "$current_role_meta"
  value_required "NEXT_ROLE(metadata)" "$next_role_meta"
  value_required "ROLE_HANDOFF_LINK" "$handoff_link_meta"
  value_required "WORK_TYPE(metadata)" "$work_type_meta"

  [[ "$task_type_meta" == "$task_type" ]] || fail "TASK_TYPE mismatch between metadata and current-task"
  [[ "$current_role_meta" == "$current_role" ]] || fail "CURRENT_ROLE mismatch between metadata and current-task"
  [[ "$next_role_meta" == "$next_role" ]] || fail "NEXT_ROLE mismatch between metadata and current-task"
  [[ "$handoff_link_meta" == "$handoff_link" ]] || fail "ROLE_HANDOFF_LINK mismatch between metadata and current-task"

  if [[ "$work_type_meta" == "fast-track" ]]; then
    followup_link="$(extract_meta "FAST_TRACK_FOLLOWUP_LINK" "$PR_BODY_SOURCE")"
    value_required "FAST_TRACK_FOLLOWUP_LINK" "$followup_link"
  fi
fi

echo "[role-flow] PASS"
