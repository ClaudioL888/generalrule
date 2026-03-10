#!/usr/bin/env bash
set -euo pipefail
source scripts/lib/standards-binding.sh

usage() {
  cat <<'USAGE'
Usage:
  new-task-pack.sh --spec-id <id> --task-type <feature|bugfix|refactor|ops|content> --current-role <role> --next-role <role> [--force]
USAGE
}

SPEC_ID=""
TASK_TYPE=""
CURRENT_ROLE=""
NEXT_ROLE=""
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec-id)
      SPEC_ID="${2:-}"
      shift 2
      ;;
    --task-type)
      TASK_TYPE="${2:-}"
      shift 2
      ;;
    --current-role)
      CURRENT_ROLE="${2:-}"
      shift 2
      ;;
    --next-role)
      NEXT_ROLE="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$SPEC_ID" || -z "$TASK_TYPE" || -z "$CURRENT_ROLE" || -z "$NEXT_ROLE" ]]; then
  usage >&2
  exit 1
fi

case "$TASK_TYPE" in
  feature|bugfix|refactor|ops|content)
    ;;
  *)
    echo "invalid --task-type: $TASK_TYPE" >&2
    exit 1
    ;;
esac

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

role_standards_csv_for() {
  local role="$1"
  local task_type="$2"
  role_standards_csv "$role" "$task_type"
}

for required in \
  docs/specs/TEMPLATE-feature-spec.md \
  docs/contracts/TEMPLATE-api-frontend-map.md \
  docs/design/TEMPLATE-feature-design.md \
  docs/plans/TEMPLATE-feature-plan.md \
  docs/status/TEMPLATE-role-handoff.md \
  docs/status/current-task.md; do
  [[ -f "$required" ]] || { echo "missing required file: $required" >&2; exit 1; }
done

mkdir -p docs/specs docs/contracts docs/design docs/plans docs/status/handoffs docs/status/spec-quality

spec_file="docs/specs/${SPEC_ID}.md"
map_file="docs/contracts/${SPEC_ID}-api-frontend-map.md"
design_file="docs/design/${SPEC_ID}-design.md"
plan_file="docs/plans/${SPEC_ID}-plan.md"
spec_quality_file="docs/status/spec-quality/${SPEC_ID}.md"
spec_slug="$(printf '%s' "$SPEC_ID" | tr '[:upper:]' '[:lower:]')"
from_slug="$(printf '%s' "$CURRENT_ROLE" | tr '[:upper:] ' '[:lower:]-' | sed 's/[^a-z0-9-]//g')"
to_slug="$(printf '%s' "$NEXT_ROLE" | tr '[:upper:] ' '[:lower:]-' | sed 's/[^a-z0-9-]//g')"
handoff_file="docs/status/handoffs/${spec_slug}-${from_slug}-to-${to_slug}.md"
current_prompt="$(role_prompt_path "$CURRENT_ROLE")"
next_prompt="$(role_prompt_path "$NEXT_ROLE")"
primary_artifact="$(role_primary_artifact "$CURRENT_ROLE" "$SPEC_ID" "$design_file" "$plan_file")"
secondary_artifact="$(role_secondary_artifact "$CURRENT_ROLE")"
current_standards="$(role_standards_csv_for "$CURRENT_ROLE" "$TASK_TYPE")"
next_standards="$(role_standards_csv_for "$NEXT_ROLE" "$TASK_TYPE")"
standards_profile="$(standards_profile_for "$TASK_TYPE" "${WORK_TYPE:-full}")"

maybe_copy() {
  local src="$1"
  local dst="$2"
  if [[ -f "$dst" && "$FORCE" != "1" ]]; then
    return
  fi
  cp "$src" "$dst"
}

maybe_copy docs/specs/TEMPLATE-feature-spec.md "$spec_file"
maybe_copy docs/contracts/TEMPLATE-api-frontend-map.md "$map_file"
maybe_copy docs/design/TEMPLATE-feature-design.md "$design_file"
maybe_copy docs/plans/TEMPLATE-feature-plan.md "$plan_file"
maybe_copy docs/status/TEMPLATE-role-handoff.md "$handoff_file"

replace_token_file() {
  local file="$1"
  local key="$2"
  local value="$3"
  local escaped
  escaped="$(printf '%s' "$value" | sed -e 's/[\|&]/\\&/g')"
  sed -i.bak "s|{{${key}}}|${escaped}|g" "$file"
  rm -f "${file}.bak"
}

for f in "$spec_file" "$map_file" "$design_file" "$plan_file" "$handoff_file"; do
  replace_token_file "$f" "spec_id" "$SPEC_ID"
  replace_token_file "$f" "task_type" "$TASK_TYPE"
  replace_token_file "$f" "current_role" "$CURRENT_ROLE"
  replace_token_file "$f" "next_role" "$NEXT_ROLE"
done

replace_token_file "$handoff_file" "current_role_prompt" "$current_prompt"
replace_token_file "$handoff_file" "next_role_prompt" "$next_prompt"
replace_token_file "$handoff_file" "current_role_standards" "$current_standards"
replace_token_file "$handoff_file" "next_role_standards" "$next_standards"
replace_token_file "$handoff_file" "deviation_reason" "none"
replace_token_file "$handoff_file" "primary_artifact_link" "$primary_artifact"
replace_token_file "$handoff_file" "secondary_artifact_link" "$secondary_artifact"
replace_token_file "$handoff_file" "primary_evidence_link" "$primary_artifact"
replace_token_file "$handoff_file" "secondary_evidence_link" "$secondary_artifact"
replace_token_file "$handoff_file" "test_result" "pending"
replace_token_file "$handoff_file" "risk_1" "pending review"
replace_token_file "$handoff_file" "risk_evidence" "pending review"
replace_token_file "$handoff_file" "docs_sync_evidence" "docs/status/current-task.md"

if [[ ! -f "$spec_quality_file" && -f docs/status/TEMPLATE-spec-quality.md ]]; then
  cp docs/status/TEMPLATE-spec-quality.md "$spec_quality_file"
  replace_token_file "$spec_quality_file" "spec_id" "$SPEC_ID"
fi

upsert_kv() {
  local file="$1"
  local key="$2"
  local value="$3"
  local escaped
  escaped="$(printf '%s' "$value" | sed -e 's/[\|&]/\\&/g')"
  if grep -Eq "^-[[:space:]]+${key}:[[:space:]]*" "$file"; then
    sed -i.bak -E "s|^-[[:space:]]+${key}:[[:space:]]*.*$|- ${key}: ${escaped}|" "$file"
    rm -f "${file}.bak"
  else
    printf -- "- %s: %s\n" "$key" "$value" >> "$file"
  fi
}

current_task="docs/status/current-task.md"
upsert_kv "$current_task" "SPEC_ID" "$SPEC_ID"
upsert_kv "$current_task" "TASK_TYPE" "$TASK_TYPE"
upsert_kv "$current_task" "CURRENT_ROLE" "$CURRENT_ROLE"
upsert_kv "$current_task" "NEXT_ROLE" "$NEXT_ROLE"
upsert_kv "$current_task" "STANDARDS_PROFILE" "$standards_profile"
upsert_kv "$current_task" "CURRENT_ROLE_STANDARDS" "$current_standards"
upsert_kv "$current_task" "NEXT_ROLE_STANDARDS" "$next_standards"
upsert_kv "$current_task" "ROLE_DOD_STATUS" "pending"
upsert_kv "$current_task" "EVIDENCE_STATUS" "pending"
upsert_kv "$current_task" "DEVIATION_STATUS" "none"
upsert_kv "$current_task" "DESIGN_LINK" "$design_file"
upsert_kv "$current_task" "PLAN_LINK" "$plan_file"
upsert_kv "$current_task" "HANDOFF_LINK" "$handoff_file"
upsert_kv "$current_task" "ROLE" "$CURRENT_ROLE"
upsert_kv "$current_task" "DESIGN_SYNC_STATUS" "pending"
upsert_kv "$current_task" "PLAN_SYNC_STATUS" "pending"
upsert_kv "$current_task" "SPEC_QUALITY_STATUS" "pending"
upsert_kv "$current_task" "SPEC_WORKFLOW_STATUS" "pending"
upsert_kv "$current_task" "SPEC_WORKFLOW_LINK" "$spec_quality_file"
upsert_kv "$current_task" "API_SURFACE_CHANGED" "no"
upsert_kv "$current_task" "FRONTEND_SURFACE_CHANGED" "no"
upsert_kv "$current_task" "CONTRACT_SYNC_STATUS" "pending"
upsert_kv "$current_task" "EXCEPTION_STATUS" "none"
upsert_kv "$current_task" "EXCEPTION_LINK" "N/A"
upsert_kv "$current_task" "REWORK_RISK" "medium"
upsert_kv "$current_task" "METRICS_IMPACT" "engineering"
upsert_kv "$current_task" "UPDATED_AT" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

printf 'task pack ready\n'
printf '  SPEC: %s\n' "$spec_file"
printf '  MAP: %s\n' "$map_file"
printf '  DESIGN: %s\n' "$design_file"
printf '  PLAN: %s\n' "$plan_file"
printf '  HANDOFF: %s\n' "$handoff_file"
