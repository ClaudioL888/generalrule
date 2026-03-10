#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[spec-pack] $1" >&2
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

has_changed_prefix() {
  local prefix="$1"
  grep -Eq "^${prefix}" <<<"$NORMALIZED_CHANGED_FILES"
}

assert_spec_shape() {
  local spec_file="$1"
  local required_sections=(
    "## 1. Goals and Non-Goals"
    "## 2. User Stories"
    "## 3. API Changes"
    "## 4. Frontend Changes"
    "## 5. Acceptance Criteria"
    "## 6. Risks"
    "## 7. Rollback Plan"
  )

  local section
  for section in "${required_sections[@]}"; do
    grep -Fq "$section" "$spec_file" || fail "SPEC file missing required section: $section"
  done
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
src_changed=0
if has_changed_prefix "src/"; then
  src_changed=1
fi

CURRENT_TASK_FILE="${CURRENT_TASK_FILE:-$DEFAULT_CURRENT_TASK_FILE}"
[[ -f "$CURRENT_TASK_FILE" ]] || fail "current task file missing: $CURRENT_TASK_FILE"

spec_id="$(extract_meta "SPEC_ID" "$CURRENT_TASK_FILE")"
task_type="$(extract_meta "TASK_TYPE" "$CURRENT_TASK_FILE")"
work_type_current="$(extract_meta "WORK_TYPE" "$CURRENT_TASK_FILE")"
design_link_current="$(extract_meta "DESIGN_LINK" "$CURRENT_TASK_FILE")"
plan_link_current="$(extract_meta "PLAN_LINK" "$CURRENT_TASK_FILE")"
design_sync_status="$(extract_meta "DESIGN_SYNC_STATUS" "$CURRENT_TASK_FILE")"
plan_sync_status="$(extract_meta "PLAN_SYNC_STATUS" "$CURRENT_TASK_FILE")"
value_required "SPEC_ID" "$spec_id"
value_required "TASK_TYPE" "$task_type"
value_required "WORK_TYPE" "$work_type_current"
value_required "DESIGN_LINK" "$design_link_current"
value_required "PLAN_LINK" "$plan_link_current"
value_required "DESIGN_SYNC_STATUS" "$design_sync_status"
value_required "PLAN_SYNC_STATUS" "$plan_sync_status"

case "$task_type" in
  feature|bugfix|refactor|ops|content)
    ;;
  *)
    fail "TASK_TYPE must be one of: feature, bugfix, refactor, ops, content"
    ;;
esac

spec_link="docs/specs/${spec_id}.md"
design_link="$design_link_current"
plan_link="$plan_link_current"
if [[ "$LOCAL_MODE" != "1" ]]; then
  task_type_meta="$(extract_meta "TASK_TYPE" "$PR_BODY_SOURCE")"
  value_required "TASK_TYPE(metadata)" "$task_type_meta"
  [[ "$task_type_meta" == "$task_type" ]] || fail "TASK_TYPE mismatch between PR metadata and current-task"

  spec_link_meta="$(extract_meta "SPEC_LINK" "$PR_BODY_SOURCE")"
  value_required "SPEC_LINK" "$spec_link_meta"
  spec_link="$spec_link_meta"

  work_type_meta="$(extract_meta "WORK_TYPE" "$PR_BODY_SOURCE")"
  value_required "WORK_TYPE(metadata)" "$work_type_meta"

  plan_link="$(extract_meta "PLAN_LINK" "$PR_BODY_SOURCE")"
  design_link="$(extract_meta "DESIGN_LINK" "$PR_BODY_SOURCE")"
  [[ "$design_link" == "$design_link_current" ]] || fail "DESIGN_LINK mismatch between PR metadata and current-task"
  [[ "$plan_link" == "$plan_link_current" ]] || fail "PLAN_LINK mismatch between PR metadata and current-task"

  case "$task_type" in
    feature|refactor)
      value_required "PLAN_LINK" "$plan_link"
      value_required "DESIGN_LINK" "$design_link"
      if [[ "$src_changed" == "1" ]]; then
        has_changed_file "$plan_link" || fail "PLAN_LINK must be updated for src changes"
        has_changed_file "$design_link" || fail "DESIGN_LINK must be updated for src changes"
      fi
      ;;
    bugfix|ops|content)
      value_required "PLAN_LINK" "$plan_link"
      value_required "DESIGN_LINK" "$design_link"
      if [[ "$src_changed" == "1" ]]; then
        has_changed_file "$plan_link" || fail "PLAN_LINK must be updated for src changes"
      fi
      ;;
  esac
fi

[[ -f "$spec_link" ]] || fail "SPEC file not found: $spec_link"
[[ -f "$design_link" ]] || fail "DESIGN file not found: $design_link"
[[ -f "$plan_link" ]] || fail "PLAN file not found: $plan_link"

spec_file_base="$(basename "$spec_link")"
spec_file_stem="${spec_file_base%.md}"
[[ "$spec_file_stem" == "$spec_id" ]] || fail "SPEC_ID ($spec_id) must match spec filename stem ($spec_file_stem)"

design_file_base="$(basename "$design_link")"
plan_file_base="$(basename "$plan_link")"
[[ "${design_file_base%.md}" == "${spec_id}-design" ]] || fail "DESIGN_LINK must point to docs/design/${spec_id}-design.md"
[[ "${plan_file_base%.md}" == "${spec_id}-plan" ]] || fail "PLAN_LINK must point to docs/plans/${spec_id}-plan.md"

assert_spec_shape "$spec_link"

if [[ "$src_changed" == "1" ]]; then
  has_changed_file "$spec_link" || fail "src changes require SPEC_LINK file update: $spec_link"
  case "$task_type" in
    feature|refactor)
      [[ "$design_sync_status" == "synced" ]] || fail "src changes for ${task_type} require DESIGN_SYNC_STATUS=synced"
      [[ "$plan_sync_status" == "synced" ]] || fail "src changes for ${task_type} require PLAN_SYNC_STATUS=synced"
      has_changed_file "$design_link" || fail "src changes for ${task_type} require DESIGN_LINK file update: $design_link"
      has_changed_file "$plan_link" || fail "src changes for ${task_type} require PLAN_LINK file update: $plan_link"
      ;;
    bugfix|ops|content)
      [[ "$plan_sync_status" == "synced" ]] || fail "src changes for ${task_type} require PLAN_SYNC_STATUS=synced"
      has_changed_file "$plan_link" || fail "src changes for ${task_type} require PLAN_LINK file update: $plan_link"
      ;;
  esac
  if [[ "$LOCAL_MODE" == "1" ]]; then
    case "$task_type" in
      feature|refactor)
        has_changed_file "$plan_link" || fail "src changes for ${task_type} require docs/plans update"
        has_changed_file "$design_link" || fail "src changes for ${task_type} require docs/design update"
        ;;
      bugfix|ops|content)
        has_changed_file "$plan_link" || fail "src changes for ${task_type} require docs/plans update"
        ;;
    esac
  fi
fi

echo "[spec-pack] PASS"
