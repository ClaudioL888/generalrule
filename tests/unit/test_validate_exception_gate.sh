#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-exception-gate.sh"

[[ -x "$SCRIPT" ]] || { echo "missing executable script: $SCRIPT"; exit 1; }

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/work/docs/status"
pushd "$tmp_dir/work" >/dev/null

cat > docs/status/current-task.md <<'MD'
# Current Task
- WORK_TYPE: full
- EXCEPTION_STATUS: none
- EXCEPTION_LINK: N/A
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
MD

CHANGED_FILES="docs/status/current-task.md" LOCAL_MODE=1 "$SCRIPT"

cat > docs/status/current-task.md <<'MD'
# Current Task
- WORK_TYPE: fast-track
- EXCEPTION_STATUS: none
- EXCEPTION_LINK: N/A
- REWORK_RISK: high
- METRICS_IMPACT: both
MD

if CHANGED_FILES="docs/status/current-task.md" LOCAL_MODE=1 "$SCRIPT"; then
  echo "expected failure when fast-track has no exception"
  exit 1
fi

cat > docs/status/fast-track-exception.md <<'MD'
# Exception
- EXCEPTION_ID: EXC-SPEC-0001
- FOLLOWUP_DEADLINE: 2026-03-10
- ADR_LINK: docs/adr/0001-initial-decision.md
MD

cat > docs/status/current-task.md <<'MD'
# Current Task
- WORK_TYPE: fast-track
- EXCEPTION_STATUS: approved
- EXCEPTION_LINK: docs/status/fast-track-exception.md
- REWORK_RISK: high
- METRICS_IMPACT: both
MD

CHANGED_FILES=$'src/app.ts\ndocs/status/current-task.md\ndocs/status/fast-track-exception.md' LOCAL_MODE=1 "$SCRIPT"

popd >/dev/null

echo "test_validate_exception_gate.sh passed"
