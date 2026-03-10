#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-role-flow.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "missing executable script: $SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/work/docs/status" "$tmp_dir/work/docs/prompts" "$tmp_dir/work/docs/specs" "$tmp_dir/work/docs/design" "$tmp_dir/work/docs/plans" "$tmp_dir/work/docs/contracts"
cat > "$tmp_dir/work/docs/prompts/dev.md" <<'MD'
# Dev Prompt
MD
cat > "$tmp_dir/work/docs/prompts/qa.md" <<'MD'
# QA Prompt
MD
cat > "$tmp_dir/work/docs/prompts/release-ops.md" <<'MD'
# Release Ops Prompt
MD
cat > "$tmp_dir/work/docs/specs/SPEC-0001-core-flow.md" <<'MD'
# Spec
MD
cat > "$tmp_dir/work/docs/design/SPEC-0001-core-flow-design.md" <<'MD'
# Design
MD
cat > "$tmp_dir/work/docs/plans/SPEC-0001-core-flow-plan.md" <<'MD'
# Plan
MD
cat > "$tmp_dir/work/docs/contracts/SPEC-0001-core-flow-api-frontend-map.md" <<'MD'
# Contract
MD
cat > "$tmp_dir/work/docs/status/handoff.md" <<'MD'
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
- Artifact summary: implemented feature slice
- Test Evidence: unit=pass;integration=pass;e2e=pass
- Risk Summary: low

## Definition of Done

- [ ] Acceptance criteria met: yes

## Handoff To

- Recipient: QA
- Next action: run regression checks
MD
cat > "$tmp_dir/work/docs/status/current-task.md" <<'MD'
# Current Task
- SPEC_ID: SPEC-0001-core-flow
- WORK_TYPE: full
- TASK_TYPE: feature
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- HANDOFF_LINK: docs/status/handoff.md
MD

pr_ok="$tmp_dir/pr-ok.md"
cat > "$pr_ok" <<'PR'
## Governance Metadata
- WORK_TYPE: full
- TASK_TYPE: feature
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- ROLE_HANDOFF_LINK: docs/status/handoff.md
PR

changed_files=$'src/app.ts\ndocs/status/handoff.md'

pushd "$tmp_dir/work" >/dev/null
cat > docs/status/current-task.md <<'MD'
# Current Task
- SPEC_ID: SPEC-0001-core-flow
- WORK_TYPE: full
- TASK_TYPE: feature
- CURRENT_ROLE: Dev
- NEXT_ROLE: Release-Ops
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- HANDOFF_LINK: docs/status/handoff.md
MD
if CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_ok" "$SCRIPT"; then
  echo "expected failure for illegal role transition"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- SPEC_ID: SPEC-0001-core-flow
- WORK_TYPE: full
- TASK_TYPE: feature
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- HANDOFF_LINK: docs/status/missing-handoff.md
MD
if CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_ok" "$SCRIPT"; then
  echo "expected failure for missing handoff file"
  exit 1
fi

cat > docs/status/handoff.md <<'MD'
# Role Handoff

## Inputs

- Current role prompt asset: docs/prompts/dev.md

## Outputs

- Primary artifact link: docs/contracts/SPEC-0001-core-flow-api-frontend-map.md
- Test Evidence: unit=pass

## Definition of Done

- [ ] Acceptance criteria met: yes

## Handoff To

- Recipient: QA
MD
cat > docs/status/current-task.md <<'MD'
# Current Task
- SPEC_ID: SPEC-0001-core-flow
- WORK_TYPE: full
- TASK_TYPE: feature
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- HANDOFF_LINK: docs/status/handoff.md
MD
if CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_ok" "$SCRIPT"; then
  echo "expected failure for missing prompt and section references in handoff"
  exit 1
fi

cat > docs/status/handoff.md <<'MD'
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
- Artifact summary: implemented feature slice
- Test Evidence: unit=pass;integration=pass;e2e=pass
- Risk Summary: low

## Definition of Done

- [ ] Acceptance criteria met: yes

## Handoff To

- Recipient: QA
- Next action: run regression checks
MD

cat > docs/status/current-task.md <<'MD'
# Current Task
- SPEC_ID: SPEC-0001-core-flow
- WORK_TYPE: full
- TASK_TYPE: feature
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- HANDOFF_LINK: docs/status/handoff.md
MD

CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_ok" "$SCRIPT"
popd >/dev/null

echo "test_validate_role_flow.sh passed"
