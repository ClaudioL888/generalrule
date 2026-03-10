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

role_prompt_path() {
  local role="$1"
  case "$role" in
    Founder) printf 'docs/prompts/founder.md\n' ;;
    PM) printf 'docs/prompts/pm.md\n' ;;
    Architect) printf 'docs/prompts/architect.md\n' ;;
    Planner) printf 'docs/prompts/planner.md\n' ;;
    Dev) printf 'docs/prompts/dev.md\n' ;;
    QA) printf 'docs/prompts/qa.md\n' ;;
    Reviewer) printf 'docs/prompts/reviewer.md\n' ;;
    Release-Ops) printf 'docs/prompts/release-ops.md\n' ;;
    Growth) printf 'docs/prompts/growth.md\n' ;;
    Content-Growth) printf 'docs/prompts/content-growth.md\n' ;;
    *)
      fail "unsupported role for prompt path: $role"
      ;;
  esac
}

validate_handoff_sections() {
  local handoff_file="$1"
  local section
  for section in "## Inputs" "## Outputs" "## Definition of Done" "## Handoff To"; do
    grep -Fq "$section" "$handoff_file" || fail "handoff missing required section: $section"
  done
}

validate_handoff_prompts() {
  local handoff_file="$1"
  local current_role="$2"
  local next_role="$3"
  local current_prompt next_prompt

  current_prompt="$(role_prompt_path "$current_role")"
  next_prompt="$(role_prompt_path "$next_role")"

  [[ -f "$current_prompt" ]] || fail "current role prompt file not found: $current_prompt"
  [[ -f "$next_prompt" ]] || fail "next role prompt file not found: $next_prompt"
  grep -Fq "$current_prompt" "$handoff_file" || fail "handoff must reference current role prompt: $current_prompt"
  grep -Fq "$next_prompt" "$handoff_file" || fail "handoff must reference next role prompt: $next_prompt"
}

validate_role_artifacts() {
  local handoff_file="$1"
  local current_role="$2"
  local spec_id="$3"
  local design_link="$4"
  local plan_link="$5"
  local contract_link
  contract_link="docs/contracts/${spec_id}-api-frontend-map.md"

  case "$current_role" in
    Founder|PM)
      grep -Fq "docs/specs/${spec_id}.md" "$handoff_file" || fail "handoff for ${current_role} must reference docs/specs/${spec_id}.md"
      ;;
    Architect)
      grep -Fq "$design_link" "$handoff_file" || fail "handoff for Architect must reference ${design_link}"
      ;;
    Planner)
      grep -Fq "$plan_link" "$handoff_file" || fail "handoff for Planner must reference ${plan_link}"
      ;;
    Dev)
      grep -Fq "$contract_link" "$handoff_file" || fail "handoff for Dev must reference ${contract_link}"
      grep -Fq "Test Evidence:" "$handoff_file" || fail "handoff for Dev must include Test Evidence"
      if grep -Eq 'Test Evidence:.*(TODO|\{\{|pending)' "$handoff_file"; then
        fail "handoff for Dev must resolve Test Evidence before passing gate"
      fi
      ;;
    QA)
      grep -Fq "Test Evidence:" "$handoff_file" || fail "handoff for QA must include Test Evidence"
      grep -Eq '(regression|docs/test-plan/)' "$handoff_file" || fail "handoff for QA must mention regression or test plan context"
      ;;
    Reviewer)
      grep -Fq "docs/status/current-task.md" "$handoff_file" || fail "handoff for Reviewer must reference docs/status/current-task.md"
      grep -Eq '(risk)' "$handoff_file" || fail "handoff for Reviewer must include risk context"
      ;;
    Release-Ops)
      grep -Fq "docs/release/CHANGELOG.md" "$handoff_file" || fail "handoff for Release-Ops must reference docs/release/CHANGELOG.md"
      grep -Fq "docs/release/RELEASE_NOTES.md" "$handoff_file" || fail "handoff for Release-Ops must reference docs/release/RELEASE_NOTES.md"
      ;;
    Growth|Content-Growth)
      grep -Eq 'docs/metrics/|AARRR|content' "$handoff_file" || fail "handoff for ${current_role} must reference metrics or growth context"
      ;;
  esac

  return 0
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
spec_id="$(extract_meta "SPEC_ID" "$CURRENT_TASK_FILE")"
design_link="$(extract_meta "DESIGN_LINK" "$CURRENT_TASK_FILE")"
plan_link="$(extract_meta "PLAN_LINK" "$CURRENT_TASK_FILE")"

value_required "WORK_TYPE" "$work_type"
value_required "TASK_TYPE" "$task_type"
value_required "CURRENT_ROLE" "$current_role"
value_required "NEXT_ROLE" "$next_role"
value_required "HANDOFF_LINK" "$handoff_link"
value_required "SPEC_ID" "$spec_id"
value_required "DESIGN_LINK" "$design_link"
value_required "PLAN_LINK" "$plan_link"

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

validate_handoff_sections "$handoff_link"
validate_handoff_prompts "$handoff_link" "$current_role" "$next_role"
validate_role_artifacts "$handoff_link" "$current_role" "$spec_id" "$design_link" "$plan_link"

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
