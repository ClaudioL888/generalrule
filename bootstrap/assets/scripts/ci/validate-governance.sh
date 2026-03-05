#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[governance-check] $1" >&2
  exit 1
}

normalize_changed_files() {
  if [[ -n "${CHANGED_FILES:-}" ]]; then
    printf '%s\n' "$CHANGED_FILES" | tr ' ' '\n' | sed '/^$/d'
    return
  fi

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [[ "$LOCAL_MODE" == "1" ]]; then
      if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
        git diff --name-only HEAD~1...HEAD
      else
        git diff --name-only HEAD
      fi
      return
    fi

    if git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
      git diff --name-only "$BASE_REF...HEAD"
      return
    fi

    if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
      git diff --name-only HEAD~1...HEAD
      return
    fi

    git diff --name-only HEAD
    return
  fi

  fail "CHANGED_FILES is required when git context is unavailable"
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

has_changed_file() {
  local needle="$1"
  grep -Fxq "$needle" <<<"$NORMALIZED_CHANGED_FILES"
}

has_changed_prefix() {
  local prefix="$1"
  grep -Eq "^${prefix}" <<<"$NORMALIZED_CHANGED_FILES"
}

assert_changed_file() {
  local field_name="$1"
  local file_path="$2"
  if ! has_changed_file "$file_path"; then
    fail "${field_name} points to ${file_path}, but that file is not in this PR"
  fi
}

validate_current_task_file() {
  local task_file="$1"
  [[ -f "$task_file" ]] || fail "current-task file missing: $task_file (create it and update required fields)"

  local required_keys
  required_keys=(
    "TASK_ID"
    "ROLE"
    "WORK_TYPE"
    "CURRENT_GATE"
    "TEST_COMMANDS"
    "TEST_RESULT"
    "UPDATED_AT"
    "NEXT_ACTION"
  )

  local key
  for key in "${required_keys[@]}"; do
    local val
    val="$(extract_meta "$key" "$task_file")"
    value_required "current-task $key" "$val"
  done
}

resolve_current_task_file() {
  if [[ -n "${CURRENT_TASK_FILE:-}" ]]; then
    printf '%s\n' "$CURRENT_TASK_FILE"
    return
  fi

  if [[ "$LOCAL_MODE" != "1" ]]; then
    local task_state_link
    task_state_link="$(extract_meta "TASK_STATE_LINK" "$PR_BODY_SOURCE")"
    if [[ -n "$task_state_link" && "$task_state_link" != "N/A" && "$task_state_link" != "none" ]]; then
      printf '%s\n' "$task_state_link"
      return
    fi
  fi

  printf '%s\n' "$DEFAULT_CURRENT_TASK_FILE"
}

LOCAL_MODE="${LOCAL_MODE:-0}"
BASE_REF="${BASE_REF:-origin/main}"
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
    fail "PR_BODY_FILE or PR_BODY must be provided in CI full mode"
  fi
fi

NORMALIZED_CHANGED_FILES="$(normalize_changed_files)"
CURRENT_TASK_FILE_EFFECTIVE="$(resolve_current_task_file)"

if has_changed_prefix "src/"; then
  has_changed_file "docs/release/CHANGELOG.md" || fail "src changes require docs/release/CHANGELOG.md update"
  has_changed_file "docs/release/RELEASE_NOTES.md" || fail "src changes require docs/release/RELEASE_NOTES.md update"
  has_changed_prefix "docs/status/" || fail "src changes require at least one docs/status/ update"
  has_changed_file "$CURRENT_TASK_FILE_EFFECTIVE" || fail "src changes require ${CURRENT_TASK_FILE_EFFECTIVE} update"
  validate_current_task_file "$CURRENT_TASK_FILE_EFFECTIVE"
fi

if [[ "$LOCAL_MODE" != "1" ]]; then
  work_type="$(extract_meta "WORK_TYPE" "$PR_BODY_SOURCE")"
  task_state_link="$(extract_meta "TASK_STATE_LINK" "$PR_BODY_SOURCE")"
  value_required "WORK_TYPE" "$work_type"
  value_required "TASK_STATE_LINK" "$task_state_link"
  if [[ -z "${CURRENT_TASK_FILE:-}" ]]; then
    CURRENT_TASK_FILE_EFFECTIVE="$task_state_link"
  fi

  case "$work_type" in
    full|mini|fast-track)
      ;;
    *)
      fail "WORK_TYPE must be one of: full, mini, fast-track"
      ;;
  esac

  test_results="$(extract_meta "TEST_RESULTS" "$PR_BODY_SOURCE")"
  value_required "TEST_RESULTS" "$test_results"
  for test_tier in "unit=pass" "integration=pass" "e2e=pass"; do
    if [[ "$test_results" != *"$test_tier"* ]]; then
      fail "TEST_RESULTS must include $test_tier"
    fi
  done

  approval_execution="$(extract_meta "APPROVAL_EXECUTION" "$PR_BODY_SOURCE")"
  approval_dependency="$(extract_meta "APPROVAL_DEPENDENCY" "$PR_BODY_SOURCE")"
  approval_permission="$(extract_meta "APPROVAL_PERMISSION" "$PR_BODY_SOURCE")"
  for approval_key in approval_execution approval_dependency approval_permission; do
    approval_value="${!approval_key:-}"
    value_required "$approval_key" "$approval_value"
    if [[ "$approval_value" != "approved" ]]; then
      fail "$approval_key must be approved"
    fi
  done

  case "$work_type" in
    full)
      prd_link="$(extract_meta "PRD_LINK" "$PR_BODY_SOURCE")"
      design_link="$(extract_meta "DESIGN_LINK" "$PR_BODY_SOURCE")"
      plan_link="$(extract_meta "PLAN_LINK" "$PR_BODY_SOURCE")"
      value_required "PRD_LINK" "$prd_link"
      value_required "DESIGN_LINK" "$design_link"
      value_required "PLAN_LINK" "$plan_link"
      value_required "TASK_STATE_LINK" "$CURRENT_TASK_FILE_EFFECTIVE"
      assert_changed_file "PRD_LINK" "$prd_link"
      assert_changed_file "DESIGN_LINK" "$design_link"
      assert_changed_file "PLAN_LINK" "$plan_link"
      ;;
    mini)
      mini_plan_link="$(extract_meta "MINI_PLAN_LINK" "$PR_BODY_SOURCE")"
      value_required "MINI_PLAN_LINK" "$mini_plan_link"
      value_required "TASK_STATE_LINK" "$CURRENT_TASK_FILE_EFFECTIVE"
      assert_changed_file "MINI_PLAN_LINK" "$mini_plan_link"
      ;;
    fast-track)
      incident_link="$(extract_meta "INCIDENT_LINK" "$PR_BODY_SOURCE")"
      fast_track_followup_link="$(extract_meta "FAST_TRACK_FOLLOWUP_LINK" "$PR_BODY_SOURCE")"
      value_required "INCIDENT_LINK" "$incident_link"
      value_required "FAST_TRACK_FOLLOWUP_LINK" "$fast_track_followup_link"
      value_required "TASK_STATE_LINK" "$CURRENT_TASK_FILE_EFFECTIVE"
      assert_changed_file "INCIDENT_LINK" "$incident_link"
      ;;
  esac
fi

echo "[governance-check] PASS"
