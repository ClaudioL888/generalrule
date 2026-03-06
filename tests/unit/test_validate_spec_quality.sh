#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-spec-quality.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "missing executable script: $SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/work/docs/status/spec-quality" "$tmp_dir/work/docs/specs"

cat > "$tmp_dir/work/docs/status/spec-quality/spec-0001-core-flow.md" <<'MD'
# Spec Quality Review SPEC-0001-core-flow

## 1. 审查上下文
- SPEC_ID: SPEC-0001-core-flow
- 审查方式：manual fallback
- 审查结论：approved
- MCP 状态：unavailable
MD

pushd "$tmp_dir/work" >/dev/null

cat > docs/status/current-task.md <<'MD'
# Current Task
- SPEC_QUALITY_STATUS: pending
- SPEC_WORKFLOW_STATUS: pending
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/spec-0001-core-flow.md
MD

if CHANGED_FILES="docs/specs/SPEC-0001-core-flow.md" "$SCRIPT"; then
  echo "expected failure when spec quality is still pending"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- SPEC_QUALITY_STATUS: degraded
- SPEC_WORKFLOW_STATUS: unavailable
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/spec-0001-core-flow.md
MD

CHANGED_FILES="docs/specs/SPEC-0001-core-flow.md" "$SCRIPT"

if SPEC_WORKFLOW_REQUIRED=strict CHANGED_FILES="docs/specs/SPEC-0001-core-flow.md" "$SCRIPT"; then
  echo "expected strict mode failure when workflow status is unavailable"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- SPEC_QUALITY_STATUS: approved
- SPEC_WORKFLOW_STATUS: passed
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/spec-0001-core-flow.md
MD

SPEC_WORKFLOW_REQUIRED=strict CHANGED_FILES="docs/specs/SPEC-0001-core-flow.md" "$SCRIPT"
CHANGED_FILES="docs/status/current-task.md" "$SCRIPT"

popd >/dev/null

echo "test_validate_spec_quality.sh passed"
