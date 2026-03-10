#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-standards-binding.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "missing executable script: $SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

write_base_docs() {
  mkdir -p docs/status/handoffs docs/standards docs/metrics docs/release
  cat > docs/NORMS.md <<'MD'
# NORMS
MD
  cat > docs/standards/coding-standards.md <<'MD'
# Coding Standards
MD
  cat > docs/standards/testing-standards.md <<'MD'
# Testing Standards
MD
  cat > docs/standards/security-standards.md <<'MD'
# Security Standards
MD
  cat > docs/standards/observability-standards.md <<'MD'
# Observability Standards
MD
  cat > docs/standards/documentation-standards.md <<'MD'
# Documentation Standards
MD
  cat > docs/standards/discovery-standards.md <<'MD'
# Discovery Standards
MD
  cat > docs/standards/design-standards.md <<'MD'
# Design Standards
MD
  cat > docs/standards/planning-standards.md <<'MD'
# Planning Standards
MD
  cat > docs/standards/release-standards.md <<'MD'
# Release Standards
MD
  cat > docs/metrics/ENGINEERING_METRICS.md <<'MD'
# Engineering Metrics
MD
  cat > docs/release/CHANGELOG.md <<'MD'
# Changelog
MD
  cat > docs/release/RELEASE_NOTES.md <<'MD'
# Release Notes
MD
  cat > docs/status/exception.md <<'MD'
# Exception
MD
}

pushd "$tmp_dir" >/dev/null
write_base_docs
changed_files=$'src/app.ts\ndocs/status/current-task.md\ndocs/status/handoffs/current.md'

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
- HANDOFF_LINK: docs/status/handoffs/current.md
- DESIGN_SYNC_STATUS: synced
- PLAN_SYNC_STATUS: synced
- SPEC_QUALITY_STATUS: approved
- SPEC_WORKFLOW_STATUS: unavailable
- SPEC_WORKFLOW_LINK: docs/status/spec-quality.md
- EXCEPTION_STATUS: none
- EXCEPTION_LINK: N/A
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
- API_SURFACE_CHANGED: yes
- FRONTEND_SURFACE_CHANGED: yes
- CONTRACT_SYNC_STATUS: synced
- BRAINSTORMING_STATUS: done
- BRAINSTORMING_LINK: docs/status/brainstorming.md
- TEST_COMMANDS: npm test
- TEST_RESULT: unit=pass;integration=pass;e2e=pass
- UPDATED_AT: 2026-03-06T00:00:00Z
- NEXT_ACTION: handoff to QA
MD
mkdir -p docs/design docs/plans
cat > docs/design/SPEC-0001-core-flow-design.md <<'MD'
# Design
MD
cat > docs/plans/SPEC-0001-core-flow-plan.md <<'MD'
# Plan
MD
cat > docs/status/spec-quality.md <<'MD'
# Spec Quality
MD
cat > docs/status/brainstorming.md <<'MD'
# Brainstorming
MD

cat > docs/status/handoffs/current.md <<'MD'
# Role Handoff
- TASK_TYPE: feature
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA

## Inputs
- Current role prompt asset: docs/prompts/dev.md
- Next role prompt asset: docs/prompts/qa.md

## Outputs
- Primary artifact link: docs/contracts/SPEC-0001-core-flow-api-frontend-map.md
- Secondary artifact link: docs/status/current-task.md
- Artifact summary: implemented
- Test Evidence: unit=pass;integration=pass;e2e=pass
- Risk Summary: low

## Applicable Standards
- Current role standards: docs/standards/coding-standards.md,docs/standards/documentation-standards.md
- Next role standards: docs/standards/testing-standards.md,docs/standards/documentation-standards.md
- Deviation note: none

## Evidence Summary
- Primary evidence: docs/contracts/SPEC-0001-core-flow-api-frontend-map.md
- Secondary evidence: docs/status/current-task.md
- Test Evidence: unit=pass;integration=pass;e2e=pass
- Risk evidence: low
- Documentation sync evidence: docs/status/current-task.md

## Definition of Done
- [ ] Acceptance criteria met: yes

## Handoff To
- Recipient: QA
- Next action: run regression checks
MD

if CHANGED_FILES="$changed_files" LOCAL_MODE=1 "$SCRIPT"; then
  echo "expected failure when Dev handoff misses testing-standards"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- TASK_ID: T1
- SPEC_ID: SPEC-0002-arch
- TASK_TYPE: feature
- ROLE: Architect
- WORK_TYPE: full
- CURRENT_GATE: Gate 2
- CURRENT_ROLE: Architect
- NEXT_ROLE: Planner
- STANDARDS_PROFILE: feature:full
- CURRENT_ROLE_STANDARDS: docs/standards/design-standards.md,docs/standards/security-standards.md,docs/standards/observability-standards.md
- NEXT_ROLE_STANDARDS: docs/standards/planning-standards.md,docs/standards/testing-standards.md
- ROLE_DOD_STATUS: met
- EVIDENCE_STATUS: complete
- DEVIATION_STATUS: none
- DESIGN_LINK: docs/design/SPEC-0002-arch-design.md
- PLAN_LINK: docs/plans/SPEC-0002-arch-plan.md
- HANDOFF_LINK: docs/status/handoffs/current.md
- DESIGN_SYNC_STATUS: synced
- PLAN_SYNC_STATUS: synced
- SPEC_QUALITY_STATUS: approved
- SPEC_WORKFLOW_STATUS: unavailable
- SPEC_WORKFLOW_LINK: docs/status/spec-quality.md
- EXCEPTION_STATUS: none
- EXCEPTION_LINK: N/A
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
- API_SURFACE_CHANGED: no
- FRONTEND_SURFACE_CHANGED: no
- CONTRACT_SYNC_STATUS: synced
- BRAINSTORMING_STATUS: done
- BRAINSTORMING_LINK: docs/status/brainstorming.md
- TEST_COMMANDS: npm test
- TEST_RESULT: unit=pass
- UPDATED_AT: 2026-03-06T00:00:00Z
- NEXT_ACTION: handoff to Planner
MD
cat > docs/design/SPEC-0002-arch-design.md <<'MD'
# Design 2
MD
cat > docs/plans/SPEC-0002-arch-plan.md <<'MD'
# Plan 2
MD
cat > docs/status/handoffs/current.md <<'MD'
# Role Handoff
- TASK_TYPE: feature
- CURRENT_ROLE: Architect
- NEXT_ROLE: Planner

## Inputs
- Current role prompt asset: docs/prompts/architect.md
- Next role prompt asset: docs/prompts/planner.md

## Outputs
- Primary artifact link: docs/design/SPEC-0002-arch-design.md
- Secondary artifact link: docs/adr/0001-initial-decision.md
- Artifact summary: design ready
- Test Evidence: N/A pre-implementation
- Risk Summary: low

## Applicable Standards
- Current role standards: docs/standards/security-standards.md,docs/standards/observability-standards.md
- Next role standards: docs/standards/planning-standards.md,docs/standards/testing-standards.md
- Deviation note: none

## Evidence Summary
- Primary evidence: docs/design/SPEC-0002-arch-design.md
- Secondary evidence: docs/adr/0001-initial-decision.md
- Test Evidence: N/A pre-implementation
- Risk evidence: low
- Documentation sync evidence: docs/status/current-task.md

## Definition of Done
- [ ] Acceptance criteria met: yes

## Handoff To
- Recipient: Planner
- Next action: prepare plan
MD
if CHANGED_FILES="$changed_files" LOCAL_MODE=1 "$SCRIPT"; then
  echo "expected failure when Architect handoff misses design-standards"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- TASK_ID: T1
- SPEC_ID: SPEC-0003-review
- TASK_TYPE: feature
- ROLE: Reviewer
- WORK_TYPE: full
- CURRENT_GATE: Gate 6
- CURRENT_ROLE: Reviewer
- NEXT_ROLE: Release-Ops
- STANDARDS_PROFILE: feature:full
- CURRENT_ROLE_STANDARDS: docs/standards/documentation-standards.md,docs/standards/security-standards.md
- NEXT_ROLE_STANDARDS: docs/standards/release-standards.md,docs/standards/observability-standards.md,docs/standards/security-standards.md
- ROLE_DOD_STATUS: pending
- EVIDENCE_STATUS: pending
- DEVIATION_STATUS: none
- DESIGN_LINK: docs/design/SPEC-0002-arch-design.md
- PLAN_LINK: docs/plans/SPEC-0002-arch-plan.md
- HANDOFF_LINK: docs/status/handoffs/current.md
- DESIGN_SYNC_STATUS: synced
- PLAN_SYNC_STATUS: synced
- SPEC_QUALITY_STATUS: approved
- SPEC_WORKFLOW_STATUS: unavailable
- SPEC_WORKFLOW_LINK: docs/status/spec-quality.md
- EXCEPTION_STATUS: none
- EXCEPTION_LINK: N/A
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
- API_SURFACE_CHANGED: no
- FRONTEND_SURFACE_CHANGED: no
- CONTRACT_SYNC_STATUS: synced
- BRAINSTORMING_STATUS: done
- BRAINSTORMING_LINK: docs/status/brainstorming.md
- TEST_COMMANDS: npm test
- TEST_RESULT: unit=pass
- UPDATED_AT: 2026-03-06T00:00:00Z
- NEXT_ACTION: handoff to Release-Ops
MD
cat > docs/status/handoffs/current.md <<'MD'
# Role Handoff
- TASK_TYPE: feature
- CURRENT_ROLE: Reviewer
- NEXT_ROLE: Release-Ops

## Inputs
- Current role prompt asset: docs/prompts/reviewer.md
- Next role prompt asset: docs/prompts/release-ops.md

## Outputs
- Primary artifact link: docs/status/current-task.md
- Secondary artifact link: docs/release/CHANGELOG.md
- Artifact summary: review complete
- Test Evidence: unit=pass
- Risk Summary: medium

## Applicable Standards
- Current role standards: docs/standards/documentation-standards.md
- Next role standards: docs/standards/release-standards.md,docs/standards/observability-standards.md,docs/standards/security-standards.md
- Deviation note: none

## Evidence Summary
- Primary evidence: docs/status/current-task.md
- Secondary evidence: docs/release/CHANGELOG.md
- Test Evidence: unit=pass
- Risk evidence: medium
- Documentation sync evidence: docs/status/current-task.md

## Definition of Done
- [ ] Risk documented: yes

## Handoff To
- Recipient: Release-Ops
- Next action: prepare release
MD
reviewer_out="$tmp_dir/reviewer.out"
CHANGED_FILES="$changed_files" LOCAL_MODE=1 STANDARDS_ENFORCEMENT=mixed "$SCRIPT" >"$reviewer_out" 2>&1
grep -q 'WARN:' "$reviewer_out" || {
  echo "expected warning for Reviewer in mixed mode"
  exit 1
}

if CHANGED_FILES="$changed_files" LOCAL_MODE=1 STANDARDS_ENFORCEMENT=strict "$SCRIPT" >/dev/null 2>&1; then
  echo "expected strict failure for Reviewer standards mismatch"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- TASK_ID: T1
- SPEC_ID: SPEC-0004-review
- TASK_TYPE: feature
- ROLE: Reviewer
- WORK_TYPE: full
- CURRENT_GATE: Gate 6
- CURRENT_ROLE: Reviewer
- NEXT_ROLE: Release-Ops
- STANDARDS_PROFILE: feature:full
- CURRENT_ROLE_STANDARDS: docs/standards/documentation-standards.md,docs/standards/security-standards.md
- NEXT_ROLE_STANDARDS: docs/standards/release-standards.md,docs/standards/observability-standards.md,docs/standards/security-standards.md
- ROLE_DOD_STATUS: met
- EVIDENCE_STATUS: complete
- DEVIATION_STATUS: documented
- DESIGN_LINK: docs/design/SPEC-0002-arch-design.md
- PLAN_LINK: docs/plans/SPEC-0002-arch-plan.md
- HANDOFF_LINK: docs/status/handoffs/current.md
- DESIGN_SYNC_STATUS: synced
- PLAN_SYNC_STATUS: synced
- SPEC_QUALITY_STATUS: approved
- SPEC_WORKFLOW_STATUS: unavailable
- SPEC_WORKFLOW_LINK: docs/status/spec-quality.md
- EXCEPTION_STATUS: approved
- EXCEPTION_LINK: docs/status/exception.md
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
- API_SURFACE_CHANGED: no
- FRONTEND_SURFACE_CHANGED: no
- CONTRACT_SYNC_STATUS: synced
- BRAINSTORMING_STATUS: done
- BRAINSTORMING_LINK: docs/status/brainstorming.md
- TEST_COMMANDS: npm test
- TEST_RESULT: unit=pass
- UPDATED_AT: 2026-03-06T00:00:00Z
- NEXT_ACTION: handoff to Release-Ops
MD
cat > docs/status/handoffs/current.md <<'MD'
# Role Handoff
- TASK_TYPE: feature
- CURRENT_ROLE: Reviewer
- NEXT_ROLE: Release-Ops

## Inputs
- Current role prompt asset: docs/prompts/reviewer.md
- Next role prompt asset: docs/prompts/release-ops.md

## Outputs
- Primary artifact link: docs/status/current-task.md
- Secondary artifact link: docs/release/CHANGELOG.md
- Artifact summary: review complete
- Test Evidence: unit=pass
- Risk Summary: medium

## Applicable Standards
- Current role standards: docs/standards/documentation-standards.md,docs/standards/security-standards.md
- Next role standards: docs/standards/release-standards.md,docs/standards/observability-standards.md,docs/standards/security-standards.md
- Deviation note: security note deferred to release checklist

## Evidence Summary
- Primary evidence: docs/status/current-task.md
- Secondary evidence: docs/release/CHANGELOG.md
- Test Evidence: unit=pass
- Risk evidence: medium
- Documentation sync evidence: docs/status/current-task.md

## Definition of Done
- [ ] Risk documented: yes

## Handoff To
- Recipient: Release-Ops
- Next action: prepare release
MD
CHANGED_FILES="$changed_files" LOCAL_MODE=1 "$SCRIPT"

cat > docs/status/current-task.md <<'MD'
# Current Task
- TASK_ID: T1
- SPEC_ID: SPEC-0004-review
- TASK_TYPE: feature
- ROLE: Reviewer
- WORK_TYPE: full
- CURRENT_GATE: Gate 6
- CURRENT_ROLE: Reviewer
- NEXT_ROLE: Release-Ops
- STANDARDS_PROFILE: feature:full
- CURRENT_ROLE_STANDARDS: docs/standards/documentation-standards.md,docs/standards/security-standards.md
- NEXT_ROLE_STANDARDS: docs/standards/release-standards.md,docs/standards/observability-standards.md,docs/standards/security-standards.md
- ROLE_DOD_STATUS: met
- EVIDENCE_STATUS: complete
- DEVIATION_STATUS: documented
- DESIGN_LINK: docs/design/SPEC-0002-arch-design.md
- PLAN_LINK: docs/plans/SPEC-0002-arch-plan.md
- HANDOFF_LINK: docs/status/handoffs/current.md
- DESIGN_SYNC_STATUS: synced
- PLAN_SYNC_STATUS: synced
- SPEC_QUALITY_STATUS: approved
- SPEC_WORKFLOW_STATUS: unavailable
- SPEC_WORKFLOW_LINK: docs/status/spec-quality.md
- EXCEPTION_STATUS: approved
- EXCEPTION_LINK: N/A
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
- API_SURFACE_CHANGED: no
- FRONTEND_SURFACE_CHANGED: no
- CONTRACT_SYNC_STATUS: synced
- BRAINSTORMING_STATUS: done
- BRAINSTORMING_LINK: docs/status/brainstorming.md
- TEST_COMMANDS: npm test
- TEST_RESULT: unit=pass
- UPDATED_AT: 2026-03-06T00:00:00Z
- NEXT_ACTION: handoff to Release-Ops
MD
if CHANGED_FILES="$changed_files" LOCAL_MODE=1 "$SCRIPT" >/dev/null 2>&1; then
  echo "expected failure when documented deviation lacks EXCEPTION_LINK"
  exit 1
fi

popd >/dev/null

echo "test_validate_standards_binding.sh passed"
