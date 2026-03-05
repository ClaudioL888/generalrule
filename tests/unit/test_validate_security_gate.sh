#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-security-gate.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "missing executable script: $SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/work/docs/adr" "$tmp_dir/work/docs/runbooks" "$tmp_dir/work/docs/release"
cat > "$tmp_dir/work/docs/adr/0001-initial-decision.md" <<'MD'
# ADR

security_boundary: public-api/private-worker
MD
cat > "$tmp_dir/work/docs/runbooks/incident-playbook.md" <<'MD'
# Incident
MD
cat > "$tmp_dir/work/docs/release/RELEASE_NOTES.md" <<'MD'
# Release Notes
MD

pushd "$tmp_dir/work" >/dev/null
if CHANGED_FILES="src/app.ts" "$SCRIPT"; then
  echo "expected failure when src changes without release notes update"
  exit 1
fi

CHANGED_FILES=$'src/app.ts\ndocs/release/RELEASE_NOTES.md' "$SCRIPT"

rm -f docs/runbooks/incident-playbook.md
if CHANGED_FILES=$'src/app.ts\ndocs/release/RELEASE_NOTES.md' "$SCRIPT"; then
  echo "expected failure when incident playbook is missing"
  exit 1
fi
popd >/dev/null

echo "test_validate_security_gate.sh passed"
