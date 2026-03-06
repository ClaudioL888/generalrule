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
- 当前角色提示资产：docs/prompts/dev.md
- 下一角色提示资产：docs/prompts/qa.md

## Outputs
- 主产物链接：docs/contracts/SPEC-0001-core-flow-api-frontend-map.md
- 辅助产物链接：docs/status/current-task.md
- 产物摘要：implemented
- 测试证据：unit=pass;integration=pass;e2e=pass
- 风险摘要：low

## Applicable Standards
- 当前角色标准：docs/standards/coding-standards.md,docs/standards/documentation-standards.md
- 下一角色标准：docs/standards/testing-standards.md,docs/standards/documentation-standards.md
- 偏差说明：none

## Evidence Summary
- 主证据：docs/contracts/SPEC-0001-core-flow-api-frontend-map.md
- 次证据：docs/status/current-task.md
- 测试证据：unit=pass;integration=pass;e2e=pass
- 风险证据：low
- 文档同步证据：docs/status/current-task.md

## Definition of Done
- [ ] 验收条件达成：yes

## Handoff To
- 交接对象：QA
- 下一动作：run regression checks
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
- 当前角色提示资产：docs/prompts/architect.md
- 下一角色提示资产：docs/prompts/planner.md

## Outputs
- 主产物链接：docs/design/SPEC-0002-arch-design.md
- 辅助产物链接：docs/adr/0001-initial-decision.md
- 产物摘要：design ready
- 测试证据：N/A pre-implementation
- 风险摘要：low

## Applicable Standards
- 当前角色标准：docs/standards/security-standards.md,docs/standards/observability-standards.md
- 下一角色标准：docs/standards/planning-standards.md,docs/standards/testing-standards.md
- 偏差说明：none

## Evidence Summary
- 主证据：docs/design/SPEC-0002-arch-design.md
- 次证据：docs/adr/0001-initial-decision.md
- 测试证据：N/A pre-implementation
- 风险证据：low
- 文档同步证据：docs/status/current-task.md

## Definition of Done
- [ ] 验收条件达成：yes

## Handoff To
- 交接对象：Planner
- 下一动作：prepare plan
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
- 当前角色提示资产：docs/prompts/reviewer.md
- 下一角色提示资产：docs/prompts/release-ops.md

## Outputs
- 主产物链接：docs/status/current-task.md
- 辅助产物链接：docs/release/CHANGELOG.md
- 产物摘要：review complete
- 测试证据：unit=pass
- 风险摘要：medium

## Applicable Standards
- 当前角色标准：docs/standards/documentation-standards.md
- 下一角色标准：docs/standards/release-standards.md,docs/standards/observability-standards.md,docs/standards/security-standards.md
- 偏差说明：none

## Evidence Summary
- 主证据：docs/status/current-task.md
- 次证据：docs/release/CHANGELOG.md
- 测试证据：unit=pass
- 风险证据：medium
- 文档同步证据：docs/status/current-task.md

## Definition of Done
- [ ] 风险已说明：yes

## Handoff To
- 交接对象：Release-Ops
- 下一动作：prepare release
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
- 当前角色提示资产：docs/prompts/reviewer.md
- 下一角色提示资产：docs/prompts/release-ops.md

## Outputs
- 主产物链接：docs/status/current-task.md
- 辅助产物链接：docs/release/CHANGELOG.md
- 产物摘要：review complete
- 测试证据：unit=pass
- 风险摘要：medium

## Applicable Standards
- 当前角色标准：docs/standards/documentation-standards.md,docs/standards/security-standards.md
- 下一角色标准：docs/standards/release-standards.md,docs/standards/observability-standards.md,docs/standards/security-standards.md
- 偏差说明：security note deferred to release checklist

## Evidence Summary
- 主证据：docs/status/current-task.md
- 次证据：docs/release/CHANGELOG.md
- 测试证据：unit=pass
- 风险证据：medium
- 文档同步证据：docs/status/current-task.md

## Definition of Done
- [ ] 风险已说明：yes

## Handoff To
- 交接对象：Release-Ops
- 下一动作：prepare release
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
