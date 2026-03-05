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
MD

cat > "$tmp_dir/work/docs/specs/SPEC-0001-core-flow.md" <<'MD'
# Feature Spec

## 1. 目标与非目标
x
## 2. 用户故事
x
## 3. API 变更
x
## 4. 前端变更
x
## 5. 验收标准
x
## 6. 风险
x
## 7. 回滚方案
x
MD

cat > "$tmp_dir/work/docs/design/0001-architecture-overview.md" <<'MD'
# Design
MD
cat > "$tmp_dir/work/docs/plans/0001-implementation-plan.md" <<'MD'
# Plan
MD

pr_missing_spec="$tmp_dir/pr-missing-spec.md"
cat > "$pr_missing_spec" <<'PR'
## Governance Metadata
- WORK_TYPE: full
- TASK_TYPE: feature
- DESIGN_LINK: docs/design/0001-architecture-overview.md
- PLAN_LINK: docs/plans/0001-implementation-plan.md
PR

pr_ok="$tmp_dir/pr-ok.md"
cat > "$pr_ok" <<'PR'
## Governance Metadata
- WORK_TYPE: full
- TASK_TYPE: feature
- SPEC_LINK: docs/specs/SPEC-0001-core-flow.md
- DESIGN_LINK: docs/design/0001-architecture-overview.md
- PLAN_LINK: docs/plans/0001-implementation-plan.md
PR

changed_files=$'src/app.ts\ndocs/specs/SPEC-0001-core-flow.md\ndocs/design/0001-architecture-overview.md\ndocs/plans/0001-implementation-plan.md'

pushd "$tmp_dir/work" >/dev/null
if CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_missing_spec" "$SCRIPT"; then
  echo "expected failure when SPEC_LINK metadata is missing"
  exit 1
fi

cat > docs/specs/SPEC-0001-core-flow.md <<'MD'
# Feature Spec

## 1. 目标与非目标
x
MD
if CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_ok" "$SCRIPT"; then
  echo "expected failure when spec section is incomplete"
  exit 1
fi

cat > docs/specs/SPEC-0001-core-flow.md <<'MD'
# Feature Spec

## 1. 目标与非目标
x
## 2. 用户故事
x
## 3. API 变更
x
## 4. 前端变更
x
## 5. 验收标准
x
## 6. 风险
x
## 7. 回滚方案
x
MD

CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_ok" "$SCRIPT"
popd >/dev/null

echo "test_validate_spec_pack.sh passed"
