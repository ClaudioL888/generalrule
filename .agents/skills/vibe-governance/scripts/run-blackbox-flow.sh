#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run-blackbox-flow.sh start --goal <single-line-goal> [--task-type <feature|bugfix|refactor|ops|content>] [--work-type <full|mini|fast-track>] [--spec-id <SPEC-...>]
  run-blackbox-flow.sh brainstorm [--note <path>]
  run-blackbox-flow.sh spec-quality [--auto] [--status <approved|degraded>] [--workflow-status <passed|unavailable>] [--note <path>]
  run-blackbox-flow.sh approve --gate <Gate 0|Gate 2|Gate 3|release> [--decision <approved|rejected>]
  run-blackbox-flow.sh status

Examples:
  run-blackbox-flow.sh start --goal "Create a path that lets new users finish their first release within 10 minutes"
  run-blackbox-flow.sh brainstorm --note "docs/status/brainstorming/spec-20260305-core.md"
  run-blackbox-flow.sh spec-quality --auto --status approved --note "docs/status/spec-quality/spec-20260305-core.md"
  run-blackbox-flow.sh approve --gate "Gate 0"
  run-blackbox-flow.sh approve --gate "Gate 2"
  run-blackbox-flow.sh approve --gate "Gate 3"
  run-blackbox-flow.sh approve --gate "release"
USAGE
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$ROOT_DIR"
source scripts/lib/standards-binding.sh

SESSION_FILE="${SESSION_FILE:-docs/status/blackbox-session.md}"
CURRENT_TASK_FILE="${CURRENT_TASK_FILE:-docs/status/current-task.md}"
HANDOFF_TEMPLATE="docs/status/TEMPLATE-role-handoff.md"
SESSION_TEMPLATE="docs/status/TEMPLATE-blackbox-session.md"
TASK_PACK_SCRIPT=".agents/skills/vibe-task-pack/scripts/new-task-pack.sh"
QUALITY_GATES_SCRIPT=".agents/skills/vibe-quality-gates/scripts/run-local-gates.sh"
BRAINSTORM_TEMPLATE="docs/status/TEMPLATE-brainstorming.md"
SPEC_QUALITY_TEMPLATE="docs/status/TEMPLATE-spec-quality.md"
SPEC_WORKFLOW_REVIEW_SCRIPT="scripts/dev/run-spec-workflow-review.sh"

now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\\|&]/\\\\&/g'
}

upsert_kv() {
  local file="$1"
  local key="$2"
  local value="$3"
  local escaped

  escaped="$(escape_sed "$value")"
  mkdir -p "$(dirname "$file")"
  if [[ ! -f "$file" ]]; then
    printf '# Auto-generated\n- %s: %s\n' "$key" "$value" > "$file"
    return
  fi

  if grep -Eq "^-[[:space:]]+${key}:[[:space:]]*" "$file"; then
    sed -i.bak -E "s|^-[[:space:]]+${key}:[[:space:]]*.*$|- ${key}: ${escaped}|" "$file"
    rm -f "${file}.bak"
  else
    printf -- '- %s: %s\n' "$key" "$value" >> "$file"
  fi
}

kv_get() {
  local file="$1"
  local key="$2"
  sed -n -E "s/^-[[:space:]]+${key}:[[:space:]]*(.*)$/\1/p" "$file" | tail -n1
}

replace_token_file() {
  local file="$1"
  local key="$2"
  local value="$3"
  local escaped

  escaped="$(escape_sed "$value")"
  sed -i.bak "s|{{${key}}}|${escaped}|g" "$file"
  rm -f "${file}.bak"
}

slugify() {
  local input="$1"
  local slug
  slug="$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')"
  if [[ -z "$slug" ]]; then
    slug="task"
  fi
  printf '%s' "$slug"
}

derive_spec_id() {
  local goal="$1"
  local slug
  slug="$(slugify "$goal")"
  slug="$(printf '%s' "$slug" | cut -c1-24)"
  printf 'SPEC-%s-%s\n' "$(date -u +%Y%m%d)" "$slug"
}

validate_task_type() {
  case "$1" in
    feature|bugfix|refactor|ops|content)
      ;;
    *)
      echo "invalid task type: $1" >&2
      exit 1
      ;;
  esac
}

validate_work_type() {
  case "$1" in
    full|mini|fast-track)
      ;;
    *)
      echo "invalid work type: $1" >&2
      exit 1
      ;;
  esac
}

transition_for_stage() {
  local task_type="$1"
  local stage="$2"

  case "$task_type:$stage" in
    feature:gate0) echo "Founder|PM" ;;
    feature:gate2) echo "Architect|Planner" ;;
    feature:gate3) echo "Planner|Dev" ;;
    feature:release) echo "Reviewer|Release-Ops" ;;
    feature:done) echo "Release-Ops|Growth" ;;

    bugfix:gate0) echo "Planner|Dev" ;;
    bugfix:gate2) echo "Planner|Dev" ;;
    bugfix:gate3) echo "Planner|Dev" ;;
    bugfix:release) echo "Reviewer|Release-Ops" ;;
    bugfix:done) echo "Release-Ops|Planner" ;;

    refactor:gate0) echo "Architect|Planner" ;;
    refactor:gate2) echo "Architect|Planner" ;;
    refactor:gate3) echo "Planner|Dev" ;;
    refactor:release) echo "Reviewer|Release-Ops" ;;
    refactor:done) echo "Release-Ops|Architect" ;;

    ops:gate0) echo "Planner|Dev" ;;
    ops:gate2) echo "Planner|Dev" ;;
    ops:gate3) echo "Planner|Dev" ;;
    ops:release) echo "Reviewer|Release-Ops" ;;
    ops:done) echo "Release-Ops|Planner" ;;

    content:gate0) echo "PM|Content-Growth" ;;
    content:gate2) echo "PM|Content-Growth" ;;
    content:gate3) echo "Content-Growth|Reviewer" ;;
    content:release) echo "Reviewer|PM" ;;
    content:done) echo "PM|Content-Growth" ;;

    *)
      echo "unsupported transition stage: ${task_type}:${stage}" >&2
      exit 1
      ;;
  esac
}

handoff_file_for() {
  local spec_id="$1"
  local current_role="$2"
  local next_role="$3"
  local spec_slug from_slug to_slug

  spec_slug="$(printf '%s' "$spec_id" | tr '[:upper:]' '[:lower:]')"
  from_slug="$(printf '%s' "$current_role" | tr '[:upper:] ' '[:lower:]-' | sed 's/[^a-z0-9-]//g')"
  to_slug="$(printf '%s' "$next_role" | tr '[:upper:] ' '[:lower:]-' | sed 's/[^a-z0-9-]//g')"
  printf 'docs/status/handoffs/%s-%s-to-%s.md\n' "$spec_slug" "$from_slug" "$to_slug"
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
      echo "unsupported role for prompt path: $role" >&2
      exit 1
      ;;
  esac
}

role_primary_artifact() {
  local role="$1"
  local spec_id="$2"
  local design_link="$3"
  local plan_link="$4"
  case "$role" in
    Founder|PM) printf 'docs/specs/%s.md\n' "$spec_id" ;;
    Architect) printf '%s\n' "$design_link" ;;
    Planner) printf '%s\n' "$plan_link" ;;
    Dev) printf 'docs/contracts/%s-api-frontend-map.md\n' "$spec_id" ;;
    QA|Reviewer) printf 'docs/status/current-task.md\n' ;;
    Release-Ops) printf 'docs/release/RELEASE_NOTES.md\n' ;;
    Growth|Content-Growth) printf 'docs/metrics/ENGINEERING_METRICS.md\n' ;;
    *)
      echo "unsupported role for primary artifact: $role" >&2
      exit 1
      ;;
  esac
}

role_secondary_artifact() {
  local role="$1"
  case "$role" in
    Founder|PM) printf 'docs/prd/0001-problem-statement.md\n' ;;
    Architect) printf 'docs/adr/0001-initial-decision.md\n' ;;
    Planner) printf 'docs/test-plan/0001-test-plan.md\n' ;;
    Dev) printf 'docs/status/current-task.md\n' ;;
    QA) printf 'docs/test-plan/0001-test-plan.md\n' ;;
    Reviewer) printf 'docs/release/CHANGELOG.md\n' ;;
    Release-Ops) printf 'docs/release/CHANGELOG.md\n' ;;
    Growth|Content-Growth) printf 'docs/release/RELEASE_NOTES.md\n' ;;
    *)
      echo "unsupported role for secondary artifact: $role" >&2
      exit 1
      ;;
  esac
}

brainstorm_file_for() {
  local spec_id="$1"
  local spec_slug

  spec_slug="$(printf '%s' "$spec_id" | tr '[:upper:]' '[:lower:]')"
  printf 'docs/status/brainstorming/%s.md\n' "$spec_slug"
}

spec_quality_file_for() {
  local spec_id="$1"
  local spec_slug

  spec_slug="$(printf '%s' "$spec_id" | tr '[:upper:]' '[:lower:]')"
  printf 'docs/status/spec-quality/%s.md\n' "$spec_slug"
}

design_file_for() {
  local spec_id="$1"
  printf 'docs/design/%s-design.md\n' "$spec_id"
}

plan_file_for() {
  local spec_id="$1"
  printf 'docs/plans/%s-plan.md\n' "$spec_id"
}

role_standards_csv_for() {
  local role="$1"
  local task_type="$2"
  role_standards_csv "$role" "$task_type"
}

standards_state_summary() {
  local profile role_dod evidence deviation
  if [[ -f "$CURRENT_TASK_FILE" ]]; then
    profile="$(kv_get "$CURRENT_TASK_FILE" "STANDARDS_PROFILE")"
    role_dod="$(kv_get "$CURRENT_TASK_FILE" "ROLE_DOD_STATUS")"
    evidence="$(kv_get "$CURRENT_TASK_FILE" "EVIDENCE_STATUS")"
    deviation="$(kv_get "$CURRENT_TASK_FILE" "DEVIATION_STATUS")"
  elif [[ -f "$SESSION_FILE" ]]; then
    profile="$(kv_get "$SESSION_FILE" "STANDARDS_PROFILE")"
    role_dod="$(kv_get "$SESSION_FILE" "ROLE_DOD_STATUS")"
    evidence="$(kv_get "$SESSION_FILE" "EVIDENCE_STATUS")"
    deviation="$(kv_get "$SESSION_FILE" "DEVIATION_STATUS")"
  fi

  if [[ -z "$profile" && -z "$role_dod" && -z "$evidence" && -z "$deviation" ]]; then
    return
  fi

  printf 'standards=%s; dod=%s; evidence=%s; deviation=%s\n' \
    "${profile:-pending}" \
    "${role_dod:-pending}" \
    "${evidence:-pending}" \
    "${deviation:-none}"
}

ensure_handoff_file() {
  local file="$1"
  local spec_id="$2"
  local task_type="$3"
  local current_role="$4"
  local next_role="$5"
  local current_prompt
  local next_prompt
  local primary_artifact
  local secondary_artifact
  local current_standards
  local next_standards

  mkdir -p "$(dirname "$file")"
  if [[ ! -f "$file" ]]; then
    if [[ -f "$HANDOFF_TEMPLATE" ]]; then
      cp "$HANDOFF_TEMPLATE" "$file"
    else
      cat > "$file" <<'FALLBACK'
# Role Handoff

## Inputs
- TODO

## Outputs
- TODO

## Definition of Done
- TODO

## Handoff To
- TODO
FALLBACK
    fi
  fi

  current_prompt="$(role_prompt_path "$current_role")"
  next_prompt="$(role_prompt_path "$next_role")"
  primary_artifact="$(role_primary_artifact "$current_role" "$spec_id" "$(design_file_for "$spec_id")" "$(plan_file_for "$spec_id")")"
  secondary_artifact="$(role_secondary_artifact "$current_role")"
  current_standards="$(role_standards_csv_for "$current_role" "$task_type")"
  next_standards="$(role_standards_csv_for "$next_role" "$task_type")"

  replace_token_file "$file" "spec_id" "$spec_id"
  replace_token_file "$file" "task_type" "$task_type"
  replace_token_file "$file" "current_role" "$current_role"
  replace_token_file "$file" "next_role" "$next_role"
  replace_token_file "$file" "current_role_prompt" "$current_prompt"
  replace_token_file "$file" "next_role_prompt" "$next_prompt"
  replace_token_file "$file" "current_role_standards" "$current_standards"
  replace_token_file "$file" "next_role_standards" "$next_standards"
  replace_token_file "$file" "deviation_reason" "none"
  replace_token_file "$file" "primary_artifact_link" "$primary_artifact"
  replace_token_file "$file" "secondary_artifact_link" "$secondary_artifact"
  replace_token_file "$file" "primary_evidence_link" "$primary_artifact"
  replace_token_file "$file" "secondary_evidence_link" "$secondary_artifact"
  replace_token_file "$file" "test_result" "pending"
  replace_token_file "$file" "risk_1" "pending review"
  replace_token_file "$file" "risk_evidence" "pending review"
  replace_token_file "$file" "docs_sync_evidence" "docs/status/current-task.md"
}

ensure_session_file() {
  if [[ -f "$SESSION_FILE" ]]; then
    return
  fi

  mkdir -p "$(dirname "$SESSION_FILE")"
  if [[ -f "$SESSION_TEMPLATE" ]]; then
    cp "$SESSION_TEMPLATE" "$SESSION_FILE"
  else
    cat > "$SESSION_FILE" <<'FALLBACK'
# Blackbox Session
- GOAL: TODO(goal)
- SPEC_ID: TODO(spec_id)
- TASK_TYPE: TODO(task_type)
- WORK_TYPE: TODO(work_type)
- CURRENT_GATE: Gate 0
- CURRENT_ROLE: Founder
- NEXT_ROLE: PM
- STANDARDS_PROFILE: feature:full
- CURRENT_ROLE_STANDARDS: docs/NORMS.md,docs/standards/discovery-standards.md,docs/standards/documentation-standards.md
- NEXT_ROLE_STANDARDS: docs/standards/discovery-standards.md,docs/standards/documentation-standards.md
- ROLE_DOD_STATUS: pending
- EVIDENCE_STATUS: pending
- DEVIATION_STATUS: none
- DESIGN_LINK: docs/design/TODO-design.md
- PLAN_LINK: docs/plans/TODO-plan.md
- APPROVAL_GATE_0: pending
- APPROVAL_GATE_2: pending
- APPROVAL_GATE_3: pending
- APPROVAL_RELEASE: pending
- DESIGN_SYNC_STATUS: pending
- PLAN_SYNC_STATUS: pending
- SPEC_QUALITY_STATUS: pending
- SPEC_WORKFLOW_STATUS: pending
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/todo.md
- BRAINSTORMING_STATUS: pending
- BRAINSTORMING_LINK: docs/status/brainstorming/todo.md
- STATUS: active
- LAST_ACTION: start
- LAST_UPDATED: TODO(updated_at)
FALLBACK
  fi
}

ensure_current_task_file() {
  if [[ -f "$CURRENT_TASK_FILE" ]]; then
    return
  fi
  mkdir -p "$(dirname "$CURRENT_TASK_FILE")"
  cat > "$CURRENT_TASK_FILE" <<'FALLBACK'
# Current Task
- TASK_ID: TODO(task_id)
- SPEC_ID: TODO(spec_id)
- TASK_TYPE: feature
- ROLE: Founder
- WORK_TYPE: full
- CURRENT_GATE: Gate 0
- CURRENT_ROLE: Founder
- NEXT_ROLE: PM
- STANDARDS_PROFILE: feature:full
- CURRENT_ROLE_STANDARDS: docs/NORMS.md,docs/standards/discovery-standards.md,docs/standards/documentation-standards.md
- NEXT_ROLE_STANDARDS: docs/standards/discovery-standards.md,docs/standards/documentation-standards.md
- ROLE_DOD_STATUS: pending
- EVIDENCE_STATUS: pending
- DEVIATION_STATUS: none
- DESIGN_LINK: docs/design/TODO-design.md
- PLAN_LINK: docs/plans/TODO-plan.md
- HANDOFF_LINK: docs/status/handoffs/todo.md
- DESIGN_SYNC_STATUS: pending
- PLAN_SYNC_STATUS: pending
- SPEC_QUALITY_STATUS: pending
- SPEC_WORKFLOW_STATUS: pending
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/todo.md
- EXCEPTION_STATUS: none
- EXCEPTION_LINK: N/A
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
- API_SURFACE_CHANGED: no
- FRONTEND_SURFACE_CHANGED: no
- CONTRACT_SYNC_STATUS: pending
- BRAINSTORMING_STATUS: pending
- BRAINSTORMING_LINK: docs/status/brainstorming/todo.md
- TEST_COMMANDS: pending
- TEST_RESULT: pending
- UPDATED_AT: 1970-01-01T00:00:00Z
- NEXT_ACTION: pending
FALLBACK
}

ensure_brainstorm_file() {
  local file="$1"
  local spec_id="$2"
  local goal="$3"

  mkdir -p "$(dirname "$file")"
  if [[ ! -f "$file" ]]; then
    if [[ -f "$BRAINSTORM_TEMPLATE" ]]; then
      cp "$BRAINSTORM_TEMPLATE" "$file"
    else
      cat > "$file" <<'FALLBACK'
# Brainstorming Brief

## Goals and Non-Goals
- Goal: TODO
- Non-goal: TODO

## Users and Scenarios
- Target persona: TODO
- Core scenario: TODO

## Technical Choice Candidates
- Option A: TODO
- Option B: TODO
- Tradeoff: TODO

## Risks and Boundaries
- Risk: TODO
- Constraints: TODO
FALLBACK
    fi
  fi

  replace_token_file "$file" "spec_id" "$spec_id"
  replace_token_file "$file" "project_goal" "$goal"
}

ensure_spec_quality_file() {
  local file="$1"
  local spec_id="$2"

  mkdir -p "$(dirname "$file")"
  if [[ ! -f "$file" ]]; then
    if [[ -f "$SPEC_QUALITY_TEMPLATE" ]]; then
      cp "$SPEC_QUALITY_TEMPLATE" "$file"
    else
      cat > "$file" <<'FALLBACK'
# Spec Quality Review TODO(spec_id)

## 1. Review Context
- SPEC_ID: TODO(spec_id)
- Review method: TODO(method)
- Review conclusion: TODO(status)
- MCP status: TODO(workflow_status)

## 2. Key Findings
- Ambiguity: TODO
- Missing item: TODO
- Contract risk: TODO

## 3. Decision
- Recommended action: TODO
- Allowed to enter Gate 0 / Gate 2: TODO
- Downgrade reason (if any): TODO
FALLBACK
    fi
  fi

  replace_token_file "$file" "spec_id" "$spec_id"
}

set_brainstorm_pending() {
  local spec_id="$1"
  local goal="$2"
  local note_file

  ensure_current_task_file
  ensure_session_file

  note_file="$(brainstorm_file_for "$spec_id")"
  ensure_brainstorm_file "$note_file" "$spec_id" "$goal"

  upsert_kv "$CURRENT_TASK_FILE" "BRAINSTORMING_STATUS" "pending"
  upsert_kv "$CURRENT_TASK_FILE" "BRAINSTORMING_LINK" "$note_file"
  upsert_kv "$SESSION_FILE" "BRAINSTORMING_STATUS" "pending"
  upsert_kv "$SESSION_FILE" "BRAINSTORMING_LINK" "$note_file"
}

set_spec_quality_pending() {
  local spec_id="$1"
  local note_file

  ensure_current_task_file
  ensure_session_file

  note_file="$(spec_quality_file_for "$spec_id")"
  ensure_spec_quality_file "$note_file" "$spec_id"

  upsert_kv "$CURRENT_TASK_FILE" "SPEC_QUALITY_STATUS" "pending"
  upsert_kv "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_STATUS" "pending"
  upsert_kv "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_LINK" "$note_file"
  upsert_kv "$SESSION_FILE" "SPEC_QUALITY_STATUS" "pending"
  upsert_kv "$SESSION_FILE" "SPEC_WORKFLOW_STATUS" "pending"
  upsert_kv "$SESSION_FILE" "SPEC_WORKFLOW_LINK" "$note_file"
}

spec_quality_mode() {
  local mode="${SPEC_WORKFLOW_REQUIRED:-optional}"
  case "$mode" in
    optional|strict)
      printf '%s\n' "$mode"
      ;;
    *)
      echo "invalid SPEC_WORKFLOW_REQUIRED: $mode (use optional or strict)" >&2
      exit 1
      ;;
  esac
}

print_card() {
  local stage_goal="$1"
  local done_summary="$2"
  local hard_gate="$3"
  local one_action="$4"
  local next_step="$5"
  local standards_summary

  standards_summary="$(standards_state_summary || true)"
  if [[ -n "$standards_summary" ]]; then
    done_summary="${done_summary}; ${standards_summary}"
  fi

  cat <<CARD
[blackbox-card]
- Phase Goal: ${stage_goal}
- AI Completed: ${done_summary}
- Hard Gate Status: ${hard_gate}
- You Only Need To Do One Thing: ${one_action}
- Next Step: ${next_step}
CARD
}

run_partial_gates() {
  local changed_files="${CHANGED_FILES:-}"
  if [[ -z "$changed_files" ]]; then
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
        changed_files="$(git diff --name-only HEAD~1...HEAD)"
      else
        changed_files="$(git diff --name-only HEAD)"
      fi
    else
      changed_files="docs/status/current-task.md"
    fi
  fi

  CHANGED_FILES="$changed_files" bash scripts/ci/check-codex-capabilities.sh || return 1
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-spec-pack.sh || return 1
  CHANGED_FILES="$changed_files" bash scripts/ci/validate-spec-quality.sh || return 1
  CHANGED_FILES="$changed_files" bash scripts/ci/validate-citation-quality.sh || return 1
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-role-flow.sh || return 1
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-standards-binding.sh || return 1
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-api-frontend-sync.sh || return 1
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-governance.sh || return 1
  DOCS_ROOT=docs bash scripts/ci/validate-doc-links.sh || return 1
}

run_release_gates() {
  if [[ -x "$QUALITY_GATES_SCRIPT" ]]; then
    bash "$QUALITY_GATES_SCRIPT"
    return
  fi

  local changed_files="${CHANGED_FILES:-}"
  if [[ -z "$changed_files" ]]; then
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
        changed_files="$(git diff --name-only HEAD~1...HEAD)"
      else
        changed_files="$(git diff --name-only HEAD)"
      fi
    else
      changed_files="docs/status/current-task.md"
    fi
  fi

  CHANGED_FILES="$changed_files" bash scripts/ci/check-codex-capabilities.sh || return 1
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-spec-pack.sh || return 1
  CHANGED_FILES="$changed_files" bash scripts/ci/validate-spec-quality.sh || return 1
  CHANGED_FILES="$changed_files" bash scripts/ci/validate-citation-quality.sh || return 1
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-role-flow.sh || return 1
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-standards-binding.sh || return 1
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-api-frontend-sync.sh || return 1
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-permissions-gate.sh || return 1
  CHANGED_FILES="$changed_files" bash scripts/ci/validate-security-gate.sh || return 1
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-governance.sh || return 1
  CHANGED_FILES="$changed_files" bash scripts/ci/validate-release-readiness.sh || return 1
  OBS_ENFORCEMENT=warn bash scripts/ci/validate-observability-gate.sh || return 1
  DOCS_ROOT=docs bash scripts/ci/validate-doc-links.sh || return 1
}

normalize_gate() {
  local raw="$1"
  local g
  g="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[[:space:]]+//g')"
  case "$g" in
    gate0|0|approvegate0)
      printf 'gate0\n'
      ;;
    gate2|2|approvegate2)
      printf 'gate2\n'
      ;;
    gate3|3|approvegate3)
      printf 'gate3\n'
      ;;
    release|gate6|6|approverelease)
      printf 'release\n'
      ;;
    *)
      echo "unknown gate: $raw" >&2
      exit 1
      ;;
  esac
}

update_current_task_transition() {
  local spec_id="$1"
  local task_type="$2"
  local work_type="$3"
  local current_gate="$4"
  local current_role="$5"
  local next_role="$6"
  local next_action="$7"
  local handoff
  local design_link
  local plan_link
  local standards_profile
  local current_role_standards
  local next_role_standards

  handoff="$(handoff_file_for "$spec_id" "$current_role" "$next_role")"
  design_link="$(design_file_for "$spec_id")"
  plan_link="$(plan_file_for "$spec_id")"
  standards_profile="$(standards_profile_for "$task_type" "$work_type")"
  current_role_standards="$(role_standards_csv_for "$current_role" "$task_type")"
  next_role_standards="$(role_standards_csv_for "$next_role" "$task_type")"
  ensure_handoff_file "$handoff" "$spec_id" "$task_type" "$current_role" "$next_role"

  ensure_current_task_file

  upsert_kv "$CURRENT_TASK_FILE" "TASK_ID" "${spec_id}-task-1"
  upsert_kv "$CURRENT_TASK_FILE" "SPEC_ID" "$spec_id"
  upsert_kv "$CURRENT_TASK_FILE" "TASK_TYPE" "$task_type"
  upsert_kv "$CURRENT_TASK_FILE" "ROLE" "$current_role"
  upsert_kv "$CURRENT_TASK_FILE" "WORK_TYPE" "$work_type"
  upsert_kv "$CURRENT_TASK_FILE" "CURRENT_GATE" "$current_gate"
  upsert_kv "$CURRENT_TASK_FILE" "CURRENT_ROLE" "$current_role"
  upsert_kv "$CURRENT_TASK_FILE" "NEXT_ROLE" "$next_role"
  upsert_kv "$CURRENT_TASK_FILE" "STANDARDS_PROFILE" "$standards_profile"
  upsert_kv "$CURRENT_TASK_FILE" "CURRENT_ROLE_STANDARDS" "$current_role_standards"
  upsert_kv "$CURRENT_TASK_FILE" "NEXT_ROLE_STANDARDS" "$next_role_standards"
  upsert_kv "$CURRENT_TASK_FILE" "ROLE_DOD_STATUS" "pending"
  upsert_kv "$CURRENT_TASK_FILE" "EVIDENCE_STATUS" "pending"
  upsert_kv "$CURRENT_TASK_FILE" "DEVIATION_STATUS" "none"
  upsert_kv "$CURRENT_TASK_FILE" "DESIGN_LINK" "$design_link"
  upsert_kv "$CURRENT_TASK_FILE" "PLAN_LINK" "$plan_link"
  upsert_kv "$CURRENT_TASK_FILE" "HANDOFF_LINK" "$handoff"
  upsert_kv "$CURRENT_TASK_FILE" "UPDATED_AT" "$(now_utc)"
  upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "$next_action"

  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "TEST_COMMANDS")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "TEST_COMMANDS" "pending"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "TEST_RESULT")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "TEST_RESULT" "pending"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "API_SURFACE_CHANGED")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "API_SURFACE_CHANGED" "no"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "FRONTEND_SURFACE_CHANGED")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "FRONTEND_SURFACE_CHANGED" "no"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "CONTRACT_SYNC_STATUS")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "CONTRACT_SYNC_STATUS" "pending"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "DESIGN_SYNC_STATUS")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "DESIGN_SYNC_STATUS" "pending"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "PLAN_SYNC_STATUS")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "PLAN_SYNC_STATUS" "pending"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "SPEC_QUALITY_STATUS")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "SPEC_QUALITY_STATUS" "pending"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_STATUS")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_STATUS" "pending"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_LINK")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_LINK" "$(spec_quality_file_for "$spec_id")"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "EXCEPTION_STATUS")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "EXCEPTION_STATUS" "none"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "EXCEPTION_LINK")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "EXCEPTION_LINK" "N/A"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "REWORK_RISK")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "REWORK_RISK" "medium"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "METRICS_IMPACT")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "METRICS_IMPACT" "engineering"
  fi

  upsert_kv "$SESSION_FILE" "STANDARDS_PROFILE" "$standards_profile"
  upsert_kv "$SESSION_FILE" "CURRENT_ROLE_STANDARDS" "$current_role_standards"
  upsert_kv "$SESSION_FILE" "NEXT_ROLE_STANDARDS" "$next_role_standards"
  upsert_kv "$SESSION_FILE" "ROLE_DOD_STATUS" "pending"
  upsert_kv "$SESSION_FILE" "EVIDENCE_STATUS" "pending"
  upsert_kv "$SESSION_FILE" "DEVIATION_STATUS" "none"
}

run_task_pack() {
  local spec_id="$1"
  local task_type="$2"
  local current_role="$3"
  local next_role="$4"

  if [[ ! -x "$TASK_PACK_SCRIPT" ]]; then
    return
  fi

  bash "$TASK_PACK_SCRIPT" \
    --spec-id "$spec_id" \
    --task-type "$task_type" \
    --current-role "$current_role" \
    --next-role "$next_role"
}

cmd_start() {
  local goal=""
  local task_type="feature"
  local work_type="full"
  local spec_id=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --goal)
        goal="${2:-}"
        shift 2
        ;;
      --task-type)
        task_type="${2:-}"
        shift 2
        ;;
      --work-type)
        work_type="${2:-}"
        shift 2
        ;;
      --spec-id)
        spec_id="${2:-}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "unknown argument for start: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  if [[ -z "$goal" ]]; then
    echo "--goal is required" >&2
    exit 1
  fi

  validate_task_type "$task_type"
  validate_work_type "$work_type"

  if [[ -z "$spec_id" ]]; then
    spec_id="$(derive_spec_id "$goal")"
  fi

  local transition current_role next_role
  transition="$(transition_for_stage "$task_type" gate0)"
  current_role="${transition%%|*}"
  next_role="${transition##*|}"

  ensure_session_file
  run_task_pack "$spec_id" "$task_type" "$current_role" "$next_role"
  update_current_task_transition "$spec_id" "$task_type" "$work_type" "Gate 0" "$current_role" "$next_role" "Complete brainstorming first, then update the design doc and mark it synced"
  set_brainstorm_pending "$spec_id" "$goal"
  set_spec_quality_pending "$spec_id"

  upsert_kv "$SESSION_FILE" "GOAL" "$goal"
  upsert_kv "$SESSION_FILE" "SPEC_ID" "$spec_id"
  upsert_kv "$SESSION_FILE" "TASK_TYPE" "$task_type"
  upsert_kv "$SESSION_FILE" "WORK_TYPE" "$work_type"
  upsert_kv "$SESSION_FILE" "CURRENT_GATE" "Gate 0"
  upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
  upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
  upsert_kv "$SESSION_FILE" "DESIGN_LINK" "$(design_file_for "$spec_id")"
  upsert_kv "$SESSION_FILE" "PLAN_LINK" "$(plan_file_for "$spec_id")"
  upsert_kv "$SESSION_FILE" "APPROVAL_GATE_0" "pending"
  upsert_kv "$SESSION_FILE" "APPROVAL_GATE_2" "pending"
  upsert_kv "$SESSION_FILE" "APPROVAL_GATE_3" "pending"
  upsert_kv "$SESSION_FILE" "APPROVAL_RELEASE" "pending"
  upsert_kv "$SESSION_FILE" "DESIGN_SYNC_STATUS" "pending"
  upsert_kv "$SESSION_FILE" "PLAN_SYNC_STATUS" "pending"
  upsert_kv "$SESSION_FILE" "SPEC_QUALITY_STATUS" "pending"
  upsert_kv "$SESSION_FILE" "SPEC_WORKFLOW_STATUS" "pending"
  upsert_kv "$SESSION_FILE" "SPEC_WORKFLOW_LINK" "$(spec_quality_file_for "$spec_id")"
  upsert_kv "$SESSION_FILE" "BRAINSTORMING_STATUS" "pending"
  upsert_kv "$SESSION_FILE" "BRAINSTORMING_LINK" "$(brainstorm_file_for "$spec_id")"
  upsert_kv "$SESSION_FILE" "STATUS" "waiting_gate_0"
  upsert_kv "$SESSION_FILE" "LAST_ACTION" "start"
  upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"
  upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "Run brainstorming first, then complete spec quality review, update the design doc, and set DESIGN_SYNC_STATUS to synced"
  upsert_kv "$CURRENT_TASK_FILE" "UPDATED_AT" "$(now_utc)"

  print_card \
    "Complete setup and bind the goal" \
    "Initialized the task pack and created the brainstorming brief plus spec quality review (both still need completion)" \
    "Gate 0 pending approval" \
    "Mark brainstorming complete first" \
    "After brainstorming and spec quality are complete, update the design doc and then approve Gate 0"
}

cmd_brainstorm() {
  local note=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --note)
        note="${2:-}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "unknown argument for brainstorm: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  [[ -f "$SESSION_FILE" ]] || { echo "missing session file: $SESSION_FILE" >&2; exit 1; }
  ensure_current_task_file

  local spec_id goal note_file
  spec_id="$(kv_get "$SESSION_FILE" "SPEC_ID")"
  goal="$(kv_get "$SESSION_FILE" "GOAL")"
  [[ -n "$spec_id" ]] || { echo "session SPEC_ID is empty" >&2; exit 1; }

  note_file="$note"
  if [[ -z "$note_file" ]]; then
    note_file="$(kv_get "$CURRENT_TASK_FILE" "BRAINSTORMING_LINK")"
  fi
  if [[ -z "$note_file" ]]; then
    note_file="$(brainstorm_file_for "$spec_id")"
  fi

  ensure_brainstorm_file "$note_file" "$spec_id" "$goal"
  [[ -f "$note_file" ]] || { echo "brainstorm note file not found: $note_file" >&2; exit 1; }

  upsert_kv "$CURRENT_TASK_FILE" "BRAINSTORMING_STATUS" "done"
  upsert_kv "$CURRENT_TASK_FILE" "BRAINSTORMING_LINK" "$note_file"
  upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "Approve Gate 0"
  upsert_kv "$CURRENT_TASK_FILE" "UPDATED_AT" "$(now_utc)"

  upsert_kv "$SESSION_FILE" "BRAINSTORMING_STATUS" "done"
  upsert_kv "$SESSION_FILE" "BRAINSTORMING_LINK" "$note_file"
  upsert_kv "$SESSION_FILE" "LAST_ACTION" "brainstorm"
  upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

  print_card \
    "Prepare requirements and technical selection" \
    "Marked brainstorming complete and recorded the note path" \
    "Spec quality and design sync still pending" \
    "Run spec-quality to record the review conclusion" \
    "After spec quality is complete, update the design doc and then approve Gate 0"
}

cmd_spec_quality() {
  local status="approved"
  local workflow_status="unavailable"
  local note=""
  local auto="0"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --status)
        status="${2:-}"
        shift 2
        ;;
      --workflow-status)
        workflow_status="${2:-}"
        shift 2
        ;;
      --note)
        note="${2:-}"
        shift 2
        ;;
      --auto)
        auto="1"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "unknown argument for spec-quality: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  case "$status" in
    approved|degraded)
      ;;
    *)
      echo "spec-quality --status must be approved or degraded" >&2
      exit 1
      ;;
  esac

  case "$workflow_status" in
    passed|unavailable)
      ;;
    *)
      echo "spec-quality --workflow-status must be passed or unavailable" >&2
      exit 1
      ;;
  esac

  [[ -f "$SESSION_FILE" ]] || { echo "missing session file: $SESSION_FILE" >&2; exit 1; }
  ensure_current_task_file

  local spec_id note_file mode
  spec_id="$(kv_get "$SESSION_FILE" "SPEC_ID")"
  [[ -n "$spec_id" ]] || { echo "session SPEC_ID is empty" >&2; exit 1; }
  mode="$(spec_quality_mode)"

  note_file="$note"
  if [[ -z "$note_file" ]]; then
    note_file="$(kv_get "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_LINK")"
  fi
  if [[ -z "$note_file" ]]; then
    note_file="$(spec_quality_file_for "$spec_id")"
  fi

  ensure_spec_quality_file "$note_file" "$spec_id"
  [[ -f "$note_file" ]] || { echo "spec quality note file not found: $note_file" >&2; exit 1; }

  local workflow_summary=""
  if [[ "$auto" == "1" ]]; then
    [[ -x "$SPEC_WORKFLOW_REVIEW_SCRIPT" ]] || {
      echo "missing executable spec workflow review script: $SPEC_WORKFLOW_REVIEW_SCRIPT" >&2
      exit 1
    }
    local review_output review_status review_link
    review_output="$(bash "$SPEC_WORKFLOW_REVIEW_SCRIPT" --spec-id "$spec_id" --note "$note_file")"
    review_status="$(printf '%s\n' "$review_output" | sed -n -E 's/^SPEC_WORKFLOW_STATUS=(.*)$/\1/p' | tail -n1)"
    review_link="$(printf '%s\n' "$review_output" | sed -n -E 's/^SPEC_WORKFLOW_LINK=(.*)$/\1/p' | tail -n1)"
    workflow_summary="$(printf '%s\n' "$review_output" | sed -n -E 's/^SPEC_WORKFLOW_SUMMARY=(.*)$/\1/p' | tail -n1)"
    [[ -n "$review_status" ]] || { echo "spec workflow review did not return SPEC_WORKFLOW_STATUS" >&2; exit 1; }
    workflow_status="$review_status"
    [[ -n "$review_link" ]] && note_file="$review_link"
  fi

  upsert_kv "$CURRENT_TASK_FILE" "SPEC_QUALITY_STATUS" "$status"
  upsert_kv "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_STATUS" "$workflow_status"
  upsert_kv "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_LINK" "$note_file"
  upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "Update the design doc and prepare for Gate 0 approval"
  upsert_kv "$CURRENT_TASK_FILE" "UPDATED_AT" "$(now_utc)"

  upsert_kv "$SESSION_FILE" "SPEC_QUALITY_STATUS" "$status"
  upsert_kv "$SESSION_FILE" "SPEC_WORKFLOW_STATUS" "$workflow_status"
  upsert_kv "$SESSION_FILE" "SPEC_WORKFLOW_LINK" "$note_file"
  upsert_kv "$SESSION_FILE" "LAST_ACTION" "spec-quality"
  upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

  print_card \
    "Spec quality review" \
    "Recorded the spec quality conclusion: status=${status}; workflow=${workflow_status}${workflow_summary:+; summary=${workflow_summary}}" \
    "mode=${mode}" \
    "Update the design doc and set DESIGN_SYNC_STATUS to synced" \
    "After design is synced, approve Gate 0"
}

cmd_approve() {
  local gate=""
  local decision="approved"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --gate)
        gate="${2:-}"
        shift 2
        ;;
      --decision)
        decision="${2:-}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "unknown argument for approve: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  [[ -f "$SESSION_FILE" ]] || { echo "missing session file: $SESSION_FILE" >&2; exit 1; }
  [[ -n "$gate" ]] || { echo "--gate is required" >&2; exit 1; }
  ensure_current_task_file

  local norm_gate
  norm_gate="$(normalize_gate "$gate")"

  local spec_id task_type work_type goal current_gate
  spec_id="$(kv_get "$SESSION_FILE" "SPEC_ID")"
  task_type="$(kv_get "$SESSION_FILE" "TASK_TYPE")"
  work_type="$(kv_get "$SESSION_FILE" "WORK_TYPE")"
  goal="$(kv_get "$SESSION_FILE" "GOAL")"
  current_gate="$(kv_get "$SESSION_FILE" "CURRENT_GATE")"

  [[ -n "$spec_id" ]] || { echo "session SPEC_ID is empty" >&2; exit 1; }
  [[ -n "$task_type" ]] || { echo "session TASK_TYPE is empty" >&2; exit 1; }
  [[ -n "$work_type" ]] || { echo "session WORK_TYPE is empty" >&2; exit 1; }

  if [[ "$decision" != "approved" ]]; then
    upsert_kv "$SESSION_FILE" "STATUS" "blocked"
    upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:${norm_gate}:${decision}"
    upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"
    upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "Wait for Founder decision"
    print_card \
      "Manual decision on a key gate" \
      "Recorded rejection for ${norm_gate}" \
      "blocked" \
      "Provide a new tradeoff (reduce scope / delay / fast-track)" \
      "AI waits for your decision before continuing"
    exit 1
  fi

  local transition current_role next_role

  case "$norm_gate" in
    gate0)
      [[ "$current_gate" == "Gate 0" ]] || { echo "Gate 0 approval is only valid when CURRENT_GATE=Gate 0 (current: $current_gate)" >&2; exit 1; }
      local brainstorming_status brainstorming_link design_sync_status design_link
      local spec_quality_status spec_workflow_status spec_workflow_link spec_mode
      brainstorming_status="$(kv_get "$CURRENT_TASK_FILE" "BRAINSTORMING_STATUS")"
      brainstorming_link="$(kv_get "$CURRENT_TASK_FILE" "BRAINSTORMING_LINK")"
      design_sync_status="$(kv_get "$CURRENT_TASK_FILE" "DESIGN_SYNC_STATUS")"
      design_link="$(kv_get "$CURRENT_TASK_FILE" "DESIGN_LINK")"
      spec_quality_status="$(kv_get "$CURRENT_TASK_FILE" "SPEC_QUALITY_STATUS")"
      spec_workflow_status="$(kv_get "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_STATUS")"
      spec_workflow_link="$(kv_get "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_LINK")"
      spec_mode="$(spec_quality_mode)"
      [[ -n "$brainstorming_status" ]] || brainstorming_status="$(kv_get "$SESSION_FILE" "BRAINSTORMING_STATUS")"
      [[ -n "$brainstorming_link" ]] || brainstorming_link="$(kv_get "$SESSION_FILE" "BRAINSTORMING_LINK")"
      [[ -n "$design_sync_status" ]] || design_sync_status="$(kv_get "$SESSION_FILE" "DESIGN_SYNC_STATUS")"
      [[ -n "$design_link" ]] || design_link="$(kv_get "$SESSION_FILE" "DESIGN_LINK")"
      [[ -n "$spec_quality_status" ]] || spec_quality_status="$(kv_get "$SESSION_FILE" "SPEC_QUALITY_STATUS")"
      [[ -n "$spec_workflow_status" ]] || spec_workflow_status="$(kv_get "$SESSION_FILE" "SPEC_WORKFLOW_STATUS")"
      [[ -n "$spec_workflow_link" ]] || spec_workflow_link="$(kv_get "$SESSION_FILE" "SPEC_WORKFLOW_LINK")"
      if [[ "$brainstorming_status" != "done" ]]; then
        echo "Gate 0 requires brainstorming completion. Run: bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh brainstorm --note <path>" >&2
        exit 1
      fi
      if [[ -z "$brainstorming_link" || ! -f "$brainstorming_link" ]]; then
        echo "Gate 0 requires valid brainstorming note file. Missing: ${brainstorming_link:-<empty>}" >&2
        exit 1
      fi
      if [[ -z "$spec_workflow_link" || ! -f "$spec_workflow_link" ]]; then
        echo "Gate 0 requires valid spec quality note file. Missing: ${spec_workflow_link:-<empty>}" >&2
        exit 1
      fi
      if [[ "$spec_mode" == "strict" ]]; then
        [[ "$spec_quality_status" == "approved" ]] || { echo "Gate 0 strict mode requires SPEC_QUALITY_STATUS=approved" >&2; exit 1; }
        [[ "$spec_workflow_status" == "passed" ]] || { echo "Gate 0 strict mode requires SPEC_WORKFLOW_STATUS=passed" >&2; exit 1; }
      else
        [[ "$spec_quality_status" != "pending" ]] || { echo "Gate 0 requires spec quality resolution. Run: bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh spec-quality --status approved|degraded --workflow-status passed|unavailable --note <path>" >&2; exit 1; }
        [[ "$spec_workflow_status" != "pending" ]] || { echo "Gate 0 requires spec workflow status resolution. Run: bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh spec-quality --status approved|degraded --workflow-status passed|unavailable --note <path>" >&2; exit 1; }
      fi
      if [[ "$design_sync_status" != "synced" ]]; then
        echo "Gate 0 requires design sync. Update docs/design/<SPEC_ID>-design.md and set DESIGN_SYNC_STATUS=synced in docs/status/current-task.md" >&2
        exit 1
      fi
      if [[ -z "$design_link" || ! -f "$design_link" ]]; then
        echo "Gate 0 requires valid design file. Missing: ${design_link:-<empty>}" >&2
        exit 1
      fi
      transition="$(transition_for_stage "$task_type" gate2)"
      current_role="${transition%%|*}"
      next_role="${transition##*|}"
      update_current_task_transition "$spec_id" "$task_type" "$work_type" "Gate 2" "$current_role" "$next_role" "Update the plan doc and set PLAN_SYNC_STATUS to synced"

      upsert_kv "$SESSION_FILE" "CURRENT_GATE" "Gate 2"
      upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
      upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
      upsert_kv "$SESSION_FILE" "APPROVAL_GATE_0" "approved"
      upsert_kv "$SESSION_FILE" "DESIGN_SYNC_STATUS" "synced"
      upsert_kv "$SESSION_FILE" "STATUS" "waiting_gate_2"
      upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:gate0"
      upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

      print_card \
        "Finish the requirement/design draft and move into architecture confirmation" \
        "Recorded Gate 0 approval and advanced AI to Gate 2" \
        "Gate 2 pending approval" \
        "Update the plan doc and set PLAN_SYNC_STATUS to synced" \
        "After the plan is synced, approve Gate 2"
      ;;

    gate2)
      [[ "$current_gate" == "Gate 2" ]] || { echo "Gate 2 approval is only valid when CURRENT_GATE=Gate 2 (current: $current_gate)" >&2; exit 1; }
      local plan_sync_status plan_link
      local spec_quality_status spec_workflow_status spec_workflow_link spec_mode
      plan_sync_status="$(kv_get "$CURRENT_TASK_FILE" "PLAN_SYNC_STATUS")"
      plan_link="$(kv_get "$CURRENT_TASK_FILE" "PLAN_LINK")"
      spec_quality_status="$(kv_get "$CURRENT_TASK_FILE" "SPEC_QUALITY_STATUS")"
      spec_workflow_status="$(kv_get "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_STATUS")"
      spec_workflow_link="$(kv_get "$CURRENT_TASK_FILE" "SPEC_WORKFLOW_LINK")"
      spec_mode="$(spec_quality_mode)"
      [[ -n "$plan_sync_status" ]] || plan_sync_status="$(kv_get "$SESSION_FILE" "PLAN_SYNC_STATUS")"
      [[ -n "$plan_link" ]] || plan_link="$(kv_get "$SESSION_FILE" "PLAN_LINK")"
      [[ -n "$spec_quality_status" ]] || spec_quality_status="$(kv_get "$SESSION_FILE" "SPEC_QUALITY_STATUS")"
      [[ -n "$spec_workflow_status" ]] || spec_workflow_status="$(kv_get "$SESSION_FILE" "SPEC_WORKFLOW_STATUS")"
      [[ -n "$spec_workflow_link" ]] || spec_workflow_link="$(kv_get "$SESSION_FILE" "SPEC_WORKFLOW_LINK")"
      if [[ "$plan_sync_status" != "synced" ]]; then
        echo "Gate 2 requires plan sync. Update docs/plans/<SPEC_ID>-plan.md and set PLAN_SYNC_STATUS=synced in docs/status/current-task.md" >&2
        exit 1
      fi
      if [[ -z "$plan_link" || ! -f "$plan_link" ]]; then
        echo "Gate 2 requires valid plan file. Missing: ${plan_link:-<empty>}" >&2
        exit 1
      fi
      if [[ -z "$spec_workflow_link" || ! -f "$spec_workflow_link" ]]; then
        echo "Gate 2 requires valid spec quality note file. Missing: ${spec_workflow_link:-<empty>}" >&2
        exit 1
      fi
      if [[ "$spec_mode" == "strict" ]]; then
        [[ "$spec_quality_status" == "approved" ]] || { echo "Gate 2 strict mode requires SPEC_QUALITY_STATUS=approved" >&2; exit 1; }
        [[ "$spec_workflow_status" == "passed" ]] || { echo "Gate 2 strict mode requires SPEC_WORKFLOW_STATUS=passed" >&2; exit 1; }
      else
        [[ "$spec_quality_status" != "pending" ]] || { echo "Gate 2 requires resolved spec quality status" >&2; exit 1; }
        [[ "$spec_workflow_status" != "pending" ]] || { echo "Gate 2 requires resolved spec workflow status" >&2; exit 1; }
      fi
      transition="$(transition_for_stage "$task_type" gate3)"
      current_role="${transition%%|*}"
      next_role="${transition##*|}"
      update_current_task_transition "$spec_id" "$task_type" "$work_type" "Gate 3" "$current_role" "$next_role" "Wait for Gate 3 approval"
      upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "Complete the current role standards and evidence, then set ROLE_DOD_STATUS=met and EVIDENCE_STATUS=complete"

      upsert_kv "$SESSION_FILE" "CURRENT_GATE" "Gate 3"
      upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
      upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
      upsert_kv "$SESSION_FILE" "APPROVAL_GATE_2" "approved"
      upsert_kv "$SESSION_FILE" "PLAN_SYNC_STATUS" "synced"
      upsert_kv "$SESSION_FILE" "STATUS" "waiting_gate_3"
      upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:gate2"
      upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

      print_card \
        "Finish task breakdown and prepare for implementation" \
        "Recorded Gate 2 approval and locked AI into single-task execution" \
        "Gate 3 pending approval" \
        "Complete the current role standards and evidence, then approve Gate 3" \
        "AI will run implementation, testing, observe/repair, and then prepare release checks"
      ;;

    gate3)
      [[ "$current_gate" == "Gate 3" ]] || { echo "Gate 3 approval is only valid when CURRENT_GATE=Gate 3 (current: $current_gate)" >&2; exit 1; }

      if run_partial_gates; then
        transition="$(transition_for_stage "$task_type" release)"
        current_role="${transition%%|*}"
        next_role="${transition##*|}"
        update_current_task_transition "$spec_id" "$task_type" "$work_type" "Gate 6" "$current_role" "$next_role" "Wait for release approval"

        upsert_kv "$SESSION_FILE" "CURRENT_GATE" "Gate 6"
        upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
        upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
        upsert_kv "$SESSION_FILE" "APPROVAL_GATE_3" "approved"
        upsert_kv "$SESSION_FILE" "STATUS" "waiting_release_approval"
        upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:gate3"
        upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

        print_card \
          "Implementation self-check is complete and the change is now a release candidate" \
          "Passed key gates (spec/role/contract/governance/doc)" \
          "pass" \
          "Approve release" \
          "AI runs the full gate chain and then produces the post-release retrospective"
      else
        upsert_kv "$SESSION_FILE" "STATUS" "repair_required"
        upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:gate3:repair-required"
        upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"
        upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "Accept repair option A/B"
        upsert_kv "$CURRENT_TASK_FILE" "UPDATED_AT" "$(now_utc)"

        print_card \
          "Implementation-stage gate self-check" \
          "Found blockers and entered Observe/Repair" \
          "failed (blocked)" \
          "Accept repair option A/B" \
          "AI repairs the issue, reruns the gates, and requests Gate 3 again"
        exit 1
      fi
      ;;

    release)
      [[ "$current_gate" == "Gate 6" ]] || { echo "Release approval is only valid when CURRENT_GATE=Gate 6 (current: $current_gate)" >&2; exit 1; }

      if run_release_gates; then
        transition="$(transition_for_stage "$task_type" done)"
        current_role="${transition%%|*}"
        next_role="${transition##*|}"
        update_current_task_transition "$spec_id" "$task_type" "$work_type" "Gate 6" "$current_role" "$next_role" "Enter growth retrospective and return to the next discovery loop"

        upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
        upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
        upsert_kv "$SESSION_FILE" "APPROVAL_RELEASE" "approved"
        upsert_kv "$SESSION_FILE" "STATUS" "released"
        upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:release"
        upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

        print_card \
          "Release and close-the-loop retrospective" \
          "Passed the full gate chain and recorded release state" \
          "pass" \
          "none (release complete)" \
          "AI outputs the DORA/AARRR retrospective and suggests the next task"
      else
        upsert_kv "$SESSION_FILE" "STATUS" "repair_required"
        upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:release:repair-required"
        upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"
        upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "Accept repair option A/B"
        upsert_kv "$CURRENT_TASK_FILE" "UPDATED_AT" "$(now_utc)"

        print_card \
          "Full pre-release gate chain" \
          "Found blockers and rejected release" \
          "failed (blocked)" \
          "Accept repair option A/B" \
          "AI repairs the issue, reruns the gates, and requests release approval again"
        exit 1
      fi
      ;;
  esac

  upsert_kv "$SESSION_FILE" "GOAL" "$goal"
}

cmd_status() {
  [[ -f "$SESSION_FILE" ]] || { echo "missing session file: $SESSION_FILE" >&2; exit 1; }

  local goal task_type work_type current_gate current_role next_role status
  goal="$(kv_get "$SESSION_FILE" "GOAL")"
  task_type="$(kv_get "$SESSION_FILE" "TASK_TYPE")"
  work_type="$(kv_get "$SESSION_FILE" "WORK_TYPE")"
  current_gate="$(kv_get "$SESSION_FILE" "CURRENT_GATE")"
  current_role="$(kv_get "$SESSION_FILE" "CURRENT_ROLE")"
  next_role="$(kv_get "$SESSION_FILE" "NEXT_ROLE")"
  status="$(kv_get "$SESSION_FILE" "STATUS")"

  local one_action="Review current-task and continue"
  local next_step="Continue based on the current state"
  local brainstorming_status
  local design_sync_status
  local plan_sync_status
  brainstorming_status="$(kv_get "$SESSION_FILE" "BRAINSTORMING_STATUS")"
  design_sync_status="$(kv_get "$SESSION_FILE" "DESIGN_SYNC_STATUS")"
  plan_sync_status="$(kv_get "$SESSION_FILE" "PLAN_SYNC_STATUS")"

  case "$status" in
    waiting_gate_0)
      if [[ "$brainstorming_status" == "done" ]]; then
        local spec_quality_status spec_workflow_status
        spec_quality_status="$(kv_get "$SESSION_FILE" "SPEC_QUALITY_STATUS")"
        spec_workflow_status="$(kv_get "$SESSION_FILE" "SPEC_WORKFLOW_STATUS")"
        if [[ "$spec_quality_status" == "pending" || "$spec_workflow_status" == "pending" ]]; then
          one_action="Run spec-quality to record the review conclusion"
          next_step="After spec quality is complete, sync the design doc and approve Gate 0"
        elif [[ "$design_sync_status" == "synced" ]]; then
          one_action="Approve Gate 0"
          next_step="AI advances the PM/Architect draft"
        else
          one_action="Update the design doc and set DESIGN_SYNC_STATUS to synced"
          next_step="After design is synced, approve Gate 0"
        fi
      else
        one_action="Mark brainstorming complete first"
        next_step="Run run-blackbox-flow.sh brainstorm --note <path>"
      fi
      ;;
    waiting_gate_2)
      if [[ "$plan_sync_status" == "synced" ]]; then
        one_action="Approve Gate 2"
        next_step="AI advances Planner breakdown"
      else
        one_action="Update the plan doc and set PLAN_SYNC_STATUS to synced"
        next_step="After the plan is synced, approve Gate 2"
      fi
      ;;
    waiting_gate_3)
      one_action="Set ROLE_DOD_STATUS=met and EVIDENCE_STATUS=complete before approving Gate 3"
      next_step="AI enters implementation, testing, and self-check"
      ;;
    waiting_release_approval)
      one_action="Approve release"
      next_step="AI runs the full gate chain and releases"
      ;;
    repair_required)
      one_action="Accept repair option A/B"
      next_step="AI repairs the issue and reruns the gates"
      ;;
    released)
      one_action="Create the next one-sentence goal"
      next_step="Enter the next blackbox loop"
      ;;
  esac

  print_card \
    "Current blackbox session state" \
    "goal=${goal}; task_type=${task_type}; work_type=${work_type}; gate=${current_gate}; role=${current_role}->${next_role}" \
    "$status" \
    "$one_action" \
    "$next_step"
}

main() {
  local command="${1:-}"
  if [[ -z "$command" ]]; then
    usage >&2
    exit 1
  fi
  shift || true

  case "$command" in
    start)
      cmd_start "$@"
      ;;
    brainstorm)
      cmd_brainstorm "$@"
      ;;
    spec-quality)
      cmd_spec_quality "$@"
      ;;
    approve)
      cmd_approve "$@"
      ;;
    status)
      cmd_status
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "unknown command: $command" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
