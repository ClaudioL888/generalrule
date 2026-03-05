#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-release-readiness.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "missing executable script: $SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/work/docs/release" "$tmp_dir/work/docs/status"
cat > "$tmp_dir/work/docs/release/CHANGELOG.md" <<'MD'
# Changelog
MD
cat > "$tmp_dir/work/docs/release/RELEASE_NOTES.md" <<'MD'
# Release notes
MD
cat > "$tmp_dir/work/docs/status/current-task.md" <<'MD'
# Current Task
- CURRENT_GATE: Gate 4
- CONTRACT_SYNC_STATUS: synced
- TEST_RESULT: unit=pass;integration=pass;e2e=pass
MD

pushd "$tmp_dir/work" >/dev/null
CHANGED_FILES="docs/prd/0001-problem-statement.md" "$SCRIPT"

if CHANGED_FILES="src/app.ts" "$SCRIPT"; then
  echo "expected failure when gate is below Gate 6"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- CURRENT_GATE: Gate 6
- CONTRACT_SYNC_STATUS: pending
- TEST_RESULT: unit=pass;integration=pass;e2e=pass
MD

if CHANGED_FILES="src/app.ts" "$SCRIPT"; then
  echo "expected failure when contract sync status is not synced"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- CURRENT_GATE: Gate 6
- CONTRACT_SYNC_STATUS: synced
- TEST_RESULT: unit=pass;integration=pass;e2e=pass
MD

CHANGED_FILES="src/app.ts" "$SCRIPT"
FORCE_RELEASE_CHECK=1 CHANGED_FILES="docs/prd/0001-problem-statement.md" "$SCRIPT"
popd >/dev/null

echo "test_validate_release_readiness.sh passed"
