#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-governance.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "missing executable script: $SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

pr_file_full="$tmp_dir/pr-full.md"
cat > "$pr_file_full" <<'PR'
## Governance Metadata
- WORK_TYPE: full
- PRD_LINK: docs/prd/0001-problem-statement.md
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- TASK_STATE_LINK: docs/status/current-task.md
- TEST_RESULTS: unit=pass;integration=pass;e2e=pass
- APPROVAL_EXECUTION: approved
- APPROVAL_DEPENDENCY: approved
- APPROVAL_PERMISSION: approved
PR

pr_file_no_task_state="$tmp_dir/pr-no-task-state.md"
cat > "$pr_file_no_task_state" <<'PR'
## Governance Metadata
- WORK_TYPE: full
- PRD_LINK: docs/prd/0001-problem-statement.md
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- TEST_RESULTS: unit=pass;integration=pass;e2e=pass
- APPROVAL_EXECUTION: approved
- APPROVAL_DEPENDENCY: approved
- APPROVAL_PERMISSION: approved
PR

if CHANGED_FILES="src/app.ts" PR_BODY_FILE="$pr_file_full" "$SCRIPT"; then
  echo "expected failure when release docs are missing"
  exit 1
fi

mkdir -p "$tmp_dir/work/docs/prd" "$tmp_dir/work/docs/design" "$tmp_dir/work/docs/plans" "$tmp_dir/work/docs/release" "$tmp_dir/work/docs/status/spec-quality" "$tmp_dir/work/docs/status/brainstorming"
cat > "$tmp_dir/work/docs/prd/0001-problem-statement.md" <<'MD'
# PRD
MD
cat > "$tmp_dir/work/docs/design/SPEC-0001-core-flow-design.md" <<'MD'
# Design
MD
cat > "$tmp_dir/work/docs/plans/SPEC-0001-core-flow-plan.md" <<'MD'
# Plan
MD
cat > "$tmp_dir/work/docs/release/CHANGELOG.md" <<'MD'
# Changelog
MD
cat > "$tmp_dir/work/docs/release/RELEASE_NOTES.md" <<'MD'
# Release Notes
MD
cat > "$tmp_dir/work/docs/status/TEMPLATE-role-handoff.md" <<'MD'
# Role Handoff
MD
cat > "$tmp_dir/work/docs/status/spec-quality/spec-0001-core-flow.md" <<'MD'
# Spec Quality Review SPEC-0001-core-flow
MD
cat > "$tmp_dir/work/docs/status/brainstorming/spec-0001-core-flow.md" <<'MD'
# Brainstorming SPEC-0001-core-flow
MD

changed_files=$'src/app.ts\ndocs/release/CHANGELOG.md\ndocs/release/RELEASE_NOTES.md\ndocs/status/current-task.md\ndocs/status/TEMPLATE-role-handoff.md\ndocs/prd/0001-problem-statement.md\ndocs/design/SPEC-0001-core-flow-design.md\ndocs/plans/SPEC-0001-core-flow-plan.md'

pushd "$tmp_dir/work" >/dev/null
cat > docs/status/current-task.md <<'MD'
# Current Task
- TASK_ID: T1
- SPEC_ID: SPEC-0001-core-flow
- TASK_TYPE: feature
- ROLE: Dev
- WORK_TYPE: full
- CURRENT_GATE: Gate 4
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- STANDARDS_PROFILE: feature:full
- CURRENT_ROLE_STANDARDS: docs/standards/coding-standards.md,docs/standards/testing-standards.md,docs/standards/documentation-standards.md
- NEXT_ROLE_STANDARDS: docs/standards/testing-standards.md,docs/standards/documentation-standards.md
- ROLE_DOD_STATUS: met
- EVIDENCE_STATUS: complete
- DEVIATION_STATUS: none
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- HANDOFF_LINK: docs/status/TEMPLATE-role-handoff.md
- DESIGN_SYNC_STATUS: synced
- PLAN_SYNC_STATUS: synced
- SPEC_QUALITY_STATUS: approved
- SPEC_WORKFLOW_STATUS: unavailable
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/spec-0001-core-flow.md
- EXCEPTION_STATUS: none
- EXCEPTION_LINK: N/A
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
- API_SURFACE_CHANGED: yes
- FRONTEND_SURFACE_CHANGED: yes
- CONTRACT_SYNC_STATUS: synced
- BRAINSTORMING_STATUS: done
- BRAINSTORMING_LINK: docs/status/brainstorming/spec-0001-core-flow.md
- TEST_COMMANDS: npm test && npm run lint
- TEST_RESULT: unit=pass;integration=pass;e2e=pass
- UPDATED_AT: 2026-03-03T00:00:00Z
- NEXT_ACTION: handoff to QA
MD

if CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_file_no_task_state" "$SCRIPT"; then
  echo "expected failure when TASK_STATE_LINK is missing in PR metadata"
  exit 1
fi

rm -f docs/status/current-task.md
if CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_file_full" "$SCRIPT"; then
  echo "expected failure when current-task file is missing"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- TASK_ID: T1
- SPEC_ID: SPEC-0001-core-flow
- TASK_TYPE: feature
- ROLE: Dev
- WORK_TYPE: full
- CURRENT_GATE: Gate 4
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- STANDARDS_PROFILE: feature:full
- CURRENT_ROLE_STANDARDS: docs/standards/coding-standards.md,docs/standards/testing-standards.md,docs/standards/documentation-standards.md
- NEXT_ROLE_STANDARDS: docs/standards/testing-standards.md,docs/standards/documentation-standards.md
- ROLE_DOD_STATUS: met
- EVIDENCE_STATUS: complete
- DEVIATION_STATUS: none
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- HANDOFF_LINK: docs/status/TEMPLATE-role-handoff.md
- DESIGN_SYNC_STATUS: synced
- PLAN_SYNC_STATUS: synced
- SPEC_QUALITY_STATUS: approved
- SPEC_WORKFLOW_STATUS: unavailable
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/spec-0001-core-flow.md
- EXCEPTION_STATUS: none
- EXCEPTION_LINK: N/A
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
- API_SURFACE_CHANGED: yes
- FRONTEND_SURFACE_CHANGED: yes
- CONTRACT_SYNC_STATUS: synced
- BRAINSTORMING_STATUS: done
- BRAINSTORMING_LINK: docs/status/brainstorming/spec-0001-core-flow.md
- TEST_COMMANDS: npm test
- UPDATED_AT: 2026-03-03T00:00:00Z
- NEXT_ACTION: handoff to QA
MD

if CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_file_full" "$SCRIPT"; then
  echo "expected failure when TEST_RESULT is missing in current-task"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- TASK_ID: T1
- SPEC_ID: SPEC-0001-core-flow
- TASK_TYPE: feature
- ROLE: Dev
- WORK_TYPE: full
- CURRENT_GATE: Gate 4
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- STANDARDS_PROFILE: feature:full
- CURRENT_ROLE_STANDARDS: docs/standards/coding-standards.md,docs/standards/testing-standards.md,docs/standards/documentation-standards.md
- NEXT_ROLE_STANDARDS: docs/standards/testing-standards.md,docs/standards/documentation-standards.md
- ROLE_DOD_STATUS: met
- EVIDENCE_STATUS: complete
- DEVIATION_STATUS: none
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- HANDOFF_LINK: docs/status/TEMPLATE-role-handoff.md
- DESIGN_SYNC_STATUS: synced
- PLAN_SYNC_STATUS: synced
- SPEC_QUALITY_STATUS: approved
- SPEC_WORKFLOW_STATUS: unavailable
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/spec-0001-core-flow.md
- EXCEPTION_STATUS: none
- EXCEPTION_LINK: N/A
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
- API_SURFACE_CHANGED: yes
- FRONTEND_SURFACE_CHANGED: yes
- CONTRACT_SYNC_STATUS: synced
- BRAINSTORMING_STATUS: done
- BRAINSTORMING_LINK: docs/status/brainstorming/spec-0001-core-flow.md
- TEST_COMMANDS: npm test && npm run lint
- TEST_RESULT: unit=pass;integration=pass;e2e=pass
- UPDATED_AT: 2026-03-03T00:00:00Z
- NEXT_ACTION: handoff to QA
MD

CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_file_full" "$SCRIPT"
CHANGED_FILES="$changed_files" LOCAL_MODE=1 "$SCRIPT"
popd >/dev/null

echo "test_validate_governance.sh passed"
