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

mkdir -p "$tmp_dir/work/docs/status"
cat > "$tmp_dir/work/docs/status/handoff.md" <<'MD'
# Handoff
MD
cat > "$tmp_dir/work/docs/status/current-task.md" <<'MD'
# Current Task
- WORK_TYPE: full
- TASK_TYPE: feature
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
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
- WORK_TYPE: full
- TASK_TYPE: feature
- CURRENT_ROLE: Dev
- NEXT_ROLE: Release-Ops
- HANDOFF_LINK: docs/status/handoff.md
MD
if CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_ok" "$SCRIPT"; then
  echo "expected failure for illegal role transition"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- WORK_TYPE: full
- TASK_TYPE: feature
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- HANDOFF_LINK: docs/status/missing-handoff.md
MD
if CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_ok" "$SCRIPT"; then
  echo "expected failure for missing handoff file"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- WORK_TYPE: full
- TASK_TYPE: feature
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- HANDOFF_LINK: docs/status/handoff.md
MD

CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_ok" "$SCRIPT"
popd >/dev/null

echo "test_validate_role_flow.sh passed"
