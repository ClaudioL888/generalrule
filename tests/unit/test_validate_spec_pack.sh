#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-spec-pack.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "missing executable script: $SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/work/docs/status" "$tmp_dir/work/docs/specs" "$tmp_dir/work/docs/design" "$tmp_dir/work/docs/plans"

cat > "$tmp_dir/work/docs/status/current-task.md" <<'MD'
# Current Task
- SPEC_ID: SPEC-0001-core-flow
- TASK_TYPE: feature
- WORK_TYPE: full
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- DESIGN_SYNC_STATUS: synced
- PLAN_SYNC_STATUS: synced
MD

cat > "$tmp_dir/work/docs/specs/SPEC-0001-core-flow.md" <<'MD'
# Feature Spec

## 1. Goals and Non-Goals
x
## 2. User Stories
x
## 3. API Changes
x
## 4. Frontend Changes
x
## 5. Acceptance Criteria
x
## 6. Risks
x
## 7. Rollback Plan
x
MD

cat > "$tmp_dir/work/docs/design/SPEC-0001-core-flow-design.md" <<'MD'
# Design
MD
cat > "$tmp_dir/work/docs/plans/SPEC-0001-core-flow-plan.md" <<'MD'
# Plan
MD

pr_missing_spec="$tmp_dir/pr-missing-spec.md"
cat > "$pr_missing_spec" <<'PR'
## Governance Metadata
- WORK_TYPE: full
- TASK_TYPE: feature
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
PR

pr_ok="$tmp_dir/pr-ok.md"
cat > "$pr_ok" <<'PR'
## Governance Metadata
- WORK_TYPE: full
- TASK_TYPE: feature
- SPEC_LINK: docs/specs/SPEC-0001-core-flow.md
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
PR

changed_files=$'src/app.ts\ndocs/specs/SPEC-0001-core-flow.md\ndocs/design/SPEC-0001-core-flow-design.md\ndocs/plans/SPEC-0001-core-flow-plan.md'

pushd "$tmp_dir/work" >/dev/null
if CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_missing_spec" "$SCRIPT"; then
  echo "expected failure when SPEC_LINK metadata is missing"
  exit 1
fi

cat > docs/specs/SPEC-0001-core-flow.md <<'MD'
# Feature Spec

## 1. Goals and Non-Goals
x
MD
if CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_ok" "$SCRIPT"; then
  echo "expected failure when spec section is incomplete"
  exit 1
fi

cat > docs/specs/SPEC-0001-core-flow.md <<'MD'
# Feature Spec

## 1. Goals and Non-Goals
x
## 2. User Stories
x
## 3. API Changes
x
## 4. Frontend Changes
x
## 5. Acceptance Criteria
x
## 6. Risks
x
## 7. Rollback Plan
x
MD

CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_ok" "$SCRIPT"
popd >/dev/null

echo "test_validate_spec_pack.sh passed"
