#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "scripts/lib/standards-binding.sh" ]]; then
  source "scripts/lib/standards-binding.sh"
elif [[ -f "$SCRIPT_DIR/../lib/standards-binding.sh" ]]; then
  source "$SCRIPT_DIR/../lib/standards-binding.sh"
else
  echo "[standards-binding] missing helper: scripts/lib/standards-binding.sh" >&2
  exit 1
fi

fail() {
  echo "[standards-binding] $1" >&2
  exit 1
}

warn() {
  echo "[standards-binding] WARN: $1" >&2
  WARNINGS=$((WARNINGS + 1))
}

issue() {
  local severity="$1"
  local message="$2"
  if [[ "$severity" == "hard" ]]; then
    fail "$message"
  fi
  warn "$message"
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
  if [[ -z "$value" || "$normalized" == "tbd" || "$normalized" == "null" ]]; then
    fail "${name} is required"
  fi
}

normalize_changed_files() {
  if [[ -n "${CHANGED_FILES:-}" ]]; then
    printf '%s\n' "$CHANGED_FILES" | tr ' ' '\n' | sed '/^$/d'
    return
  fi

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [[ "${LOCAL_MODE:-0}" == "1" ]]; then
      if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
        git diff --name-only HEAD~1...HEAD
      else
        git diff --name-only HEAD
      fi
      return
    fi

    if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
      git diff --name-only HEAD~1...HEAD
    else
      git diff --name-only HEAD
    fi
    return
  fi

  fail "CHANGED_FILES is required when git context is unavailable"
}

list_contains() {
  local list="$1"
  local needle="$2"
  csv_to_lines "$list" | grep -Fxq "$needle"
}

section_required() {
  local handoff_file="$1"
  local section="$2"
  grep -Fq "$section" "$handoff_file" || fail "handoff missing required section: $section"
}

line_value() {
  local prefix="$1"
  local file="$2"
  sed -n -E "s|^-[[:space:]]+${prefix}[：:][[:space:]]*(.*)$|\1|p" "$file" | tail -n1
}

value_is_placeholder() {
  local value="$1"
  local normalized
  normalized="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
  [[ -z "$value" || "$normalized" == "tbd" || "$normalized" == "null" || "$normalized" == "pending" || "$value" == *'{{'* || "$value" == *'TODO('* ]]
}

value_is_na() {
  local value="$1"
  local normalized
  normalized="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
  [[ "$normalized" == "n/a" || "$normalized" == "na" || "$normalized" == "none" ]]
}

validate_handoff_fields() {
  local handoff_file="$1"
  local severity="$2"
  local current_standards="$3"
  local next_standards="$4"
  local current_line next_line deviation_line primary_evidence secondary_evidence test_evidence risk_evidence docs_sync_evidence standard_path

  section_required "$handoff_file" "## Applicable Standards"
  section_required "$handoff_file" "## Evidence Summary"

  current_line="$(line_value 'Current role standards' "$handoff_file")"
  next_line="$(line_value 'Next role standards' "$handoff_file")"
  deviation_line="$(line_value 'Deviation note' "$handoff_file")"
  primary_evidence="$(line_value 'Primary evidence' "$handoff_file")"
  secondary_evidence="$(line_value 'Secondary evidence' "$handoff_file")"
  test_evidence="$(line_value 'Test Evidence' "$handoff_file")"
  risk_evidence="$(line_value 'Risk evidence' "$handoff_file")"
  docs_sync_evidence="$(line_value 'Documentation sync evidence' "$handoff_file")"

  for pair in \
    "handoff Current role standards:$current_line" \
    "handoff Next role standards:$next_line" \
    "handoff Deviation note:$deviation_line" \
    "handoff Primary evidence:$primary_evidence" \
    "handoff Secondary evidence:$secondary_evidence" \
    "handoff Test Evidence:$test_evidence" \
    "handoff Risk evidence:$risk_evidence" \
    "handoff Documentation sync evidence:$docs_sync_evidence"; do
    local name="${pair%%:*}"
    local value="${pair#*:}"
    if [[ -z "$value" ]]; then
      issue "$severity" "${name} is required"
    fi
  done

  [[ "$current_line" == "$current_standards" ]] || issue "$severity" "handoff Current role standards must equal CURRENT_ROLE_STANDARDS"
  [[ "$next_line" == "$next_standards" ]] || issue "$severity" "handoff Next role standards must equal NEXT_ROLE_STANDARDS"

  while IFS= read -r standard_path; do
    [[ -n "$standard_path" ]] || continue
    [[ -f "$standard_path" ]] || issue "$severity" "required standards file missing: $standard_path"
    grep -Fq "$standard_path" "$handoff_file" || issue "$severity" "handoff must reference standards file: $standard_path"
  done < <(csv_to_lines "$current_standards")

  while IFS= read -r standard_path; do
    [[ -n "$standard_path" ]] || continue
    [[ -f "$standard_path" ]] || issue "$severity" "next role standards file missing: $standard_path"
    grep -Fq "$standard_path" "$handoff_file" || issue "$severity" "handoff must reference next role standards file: $standard_path"
  done < <(csv_to_lines "$next_standards")

  for value_name in primary_evidence secondary_evidence test_evidence risk_evidence docs_sync_evidence; do
    local value="${!value_name}"
    if value_is_placeholder "$value"; then
      issue "$severity" "handoff ${value_name} contains placeholder or pending value"
    fi
    if ! value_is_na "$value" && [[ "$value" == docs/* ]] && [[ ! -f "$value" ]]; then
      issue "$severity" "handoff ${value_name} points to missing file: $value"
    fi
  done
}

validate_pr_metadata() {
  local pr_body="$1"
  local standards_profile="$2"
  local role_dod_status="$3"
  local evidence_status="$4"
  local deviation_status="$5"
  local standards_profile_meta role_dod_meta evidence_meta deviation_meta

  standards_profile_meta="$(extract_meta 'STANDARDS_PROFILE' "$pr_body")"
  role_dod_meta="$(extract_meta 'ROLE_DOD_STATUS' "$pr_body")"
  evidence_meta="$(extract_meta 'EVIDENCE_STATUS' "$pr_body")"
  deviation_meta="$(extract_meta 'DEVIATION_STATUS' "$pr_body")"

  value_required 'STANDARDS_PROFILE(metadata)' "$standards_profile_meta"
  value_required 'ROLE_DOD_STATUS(metadata)' "$role_dod_meta"
  value_required 'EVIDENCE_STATUS(metadata)' "$evidence_meta"
  value_required 'DEVIATION_STATUS(metadata)' "$deviation_meta"

  [[ "$standards_profile_meta" == "$standards_profile" ]] || fail 'STANDARDS_PROFILE mismatch between metadata and current-task'
  [[ "$role_dod_meta" == "$role_dod_status" ]] || fail 'ROLE_DOD_STATUS mismatch between metadata and current-task'
  [[ "$evidence_meta" == "$evidence_status" ]] || fail 'EVIDENCE_STATUS mismatch between metadata and current-task'
  [[ "$deviation_meta" == "$deviation_status" ]] || fail 'DEVIATION_STATUS mismatch between metadata and current-task'
}

WARNINGS=0
LOCAL_MODE="${LOCAL_MODE:-0}"
CURRENT_TASK_FILE="${CURRENT_TASK_FILE:-docs/status/current-task.md}"
NORMALIZED_CHANGED_FILES="$(normalize_changed_files)"
PR_BODY_SOURCE=""

if ! grep -Eq '^(src/|docs/specs/|docs/design/|docs/plans/|docs/contracts/|docs/status/current-task\.md|docs/status/handoffs/)' <<<"$NORMALIZED_CHANGED_FILES"; then
  echo '[standards-binding] SKIP (no standards-scoped changes)'
  exit 0
fi

if [[ "$LOCAL_MODE" != "1" ]]; then
  if [[ -n "${PR_BODY_FILE:-}" ]]; then
    [[ -f "$PR_BODY_FILE" ]] || fail "PR_BODY_FILE not found: $PR_BODY_FILE"
    PR_BODY_SOURCE="$PR_BODY_FILE"
  elif [[ -n "${PR_BODY:-}" ]]; then
    PR_BODY_SOURCE="$(mktemp)"
    printf '%s\n' "$PR_BODY" > "$PR_BODY_SOURCE"
  else
    fail 'PR_BODY_FILE or PR_BODY must be provided unless LOCAL_MODE=1'
  fi
fi

[[ -f "$CURRENT_TASK_FILE" ]] || fail "current task file missing: $CURRENT_TASK_FILE"

work_type="$(extract_meta 'WORK_TYPE' "$CURRENT_TASK_FILE")"
task_type="$(extract_meta 'TASK_TYPE' "$CURRENT_TASK_FILE")"
current_role="$(extract_meta 'CURRENT_ROLE' "$CURRENT_TASK_FILE")"
next_role="$(extract_meta 'NEXT_ROLE' "$CURRENT_TASK_FILE")"
handoff_link="$(extract_meta 'HANDOFF_LINK' "$CURRENT_TASK_FILE")"
standards_profile="$(extract_meta 'STANDARDS_PROFILE' "$CURRENT_TASK_FILE")"
current_role_standards="$(extract_meta 'CURRENT_ROLE_STANDARDS' "$CURRENT_TASK_FILE")"
next_role_standards="$(extract_meta 'NEXT_ROLE_STANDARDS' "$CURRENT_TASK_FILE")"
role_dod_status="$(extract_meta 'ROLE_DOD_STATUS' "$CURRENT_TASK_FILE")"
evidence_status="$(extract_meta 'EVIDENCE_STATUS' "$CURRENT_TASK_FILE")"
deviation_status="$(extract_meta 'DEVIATION_STATUS' "$CURRENT_TASK_FILE")"
exception_status="$(extract_meta 'EXCEPTION_STATUS' "$CURRENT_TASK_FILE")"
exception_link="$(extract_meta 'EXCEPTION_LINK' "$CURRENT_TASK_FILE")"

value_required 'WORK_TYPE' "$work_type"
value_required 'TASK_TYPE' "$task_type"
value_required 'CURRENT_ROLE' "$current_role"
value_required 'NEXT_ROLE' "$next_role"
value_required 'HANDOFF_LINK' "$handoff_link"
value_required 'STANDARDS_PROFILE' "$standards_profile"
value_required 'CURRENT_ROLE_STANDARDS' "$current_role_standards"
value_required 'NEXT_ROLE_STANDARDS' "$next_role_standards"
value_required 'ROLE_DOD_STATUS' "$role_dod_status"
value_required 'EVIDENCE_STATUS' "$evidence_status"
value_required 'DEVIATION_STATUS' "$deviation_status"
value_required 'EXCEPTION_STATUS' "$exception_status"

[[ -f "$handoff_link" ]] || fail "HANDOFF_LINK file not found: $handoff_link"

case "$role_dod_status" in
  pending|met) ;;
  *) fail 'ROLE_DOD_STATUS must be pending or met' ;;
esac

case "$evidence_status" in
  pending|complete) ;;
  *) fail 'EVIDENCE_STATUS must be pending or complete' ;;
esac

case "$deviation_status" in
  none|documented|required) ;;
  *) fail 'DEVIATION_STATUS must be none, documented, or required' ;;
esac

expected_profile="$(standards_profile_for "$task_type" "$work_type")"
[[ "$standards_profile" == "$expected_profile" ]] || fail "STANDARDS_PROFILE must equal ${expected_profile}"

expected_current="$(role_standards_csv "$current_role" "$task_type")"
expected_next="$(role_standards_csv "$next_role" "$task_type")"
[[ -n "$expected_current" ]] || fail "could not derive CURRENT_ROLE_STANDARDS for ${current_role}/${task_type}"
[[ -n "$expected_next" ]] || fail "could not derive NEXT_ROLE_STANDARDS for ${next_role}/${task_type}"

severity="$(role_gate_severity "$current_role" "${STANDARDS_ENFORCEMENT:-strict}")"

[[ "$current_role_standards" == "$expected_current" ]] || issue "$severity" "CURRENT_ROLE_STANDARDS must equal derived standards set"
[[ "$next_role_standards" == "$expected_next" ]] || issue "$severity" "NEXT_ROLE_STANDARDS must equal derived standards set"

validate_handoff_fields "$handoff_link" "$severity" "$expected_current" "$expected_next"

if [[ "$role_dod_status" != 'met' ]]; then
  issue "$severity" 'ROLE_DOD_STATUS must be met before handoff passes standards gate'
fi

if [[ "$evidence_status" != 'complete' ]]; then
  issue "$severity" 'EVIDENCE_STATUS must be complete before handoff passes standards gate'
fi

case "$deviation_status" in
  none)
    deviation_line="$(line_value 'Deviation note' "$handoff_link")"
    [[ "$deviation_line" == 'none' ]] || issue "$severity" 'DEVIATION_STATUS=none requires handoff Deviation note: none'
    ;;
  documented)
    value_is_na "$exception_link" && fail 'DEVIATION_STATUS=documented requires EXCEPTION_LINK to be set'
    if [[ "$exception_link" == docs/* && ! -f "$exception_link" ]]; then
      fail "DEVIATION_STATUS=documented requires EXCEPTION_LINK file: $exception_link"
    fi
    deviation_line="$(line_value 'Deviation note' "$handoff_link")"
    if value_is_na "$deviation_line" || value_is_placeholder "$deviation_line"; then
      fail 'DEVIATION_STATUS=documented requires a non-empty handoff Deviation note'
    fi
    ;;
  required)
    fail 'DEVIATION_STATUS=required must be resolved before standards gate can pass'
    ;;
esac

if [[ "$LOCAL_MODE" != '1' ]]; then
  validate_pr_metadata "$PR_BODY_SOURCE" "$standards_profile" "$role_dod_status" "$evidence_status" "$deviation_status"
fi

if [[ "$WARNINGS" -gt 0 ]]; then
  echo '[standards-binding] PASS (warnings present)'
else
  echo '[standards-binding] PASS'
fi
