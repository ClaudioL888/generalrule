#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-permissions-gate.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "missing executable script: $SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/work/.github"

pr_file="$tmp_dir/pr.md"
cat > "$pr_file" <<'PR'
## Governance Metadata
- CODEOWNER_REVIEW: approved
- SECURITY_REVIEW: approved
- RELEASE_REVIEW: approved
PR

pushd "$tmp_dir/work" >/dev/null
if PR_BODY_FILE="$pr_file" "$SCRIPT"; then
  echo "expected failure when CODEOWNERS is missing"
  exit 1
fi

cat > .github/CODEOWNERS <<'OWN'
* @YOUR_ORG/general-owners
/docs/ @YOUR_ORG/docs-owners
/scripts/ci/ @YOUR_ORG/platform-owners
/.codex/ @YOUR_ORG/platform-owners
/.github/ @YOUR_ORG/platform-owners
OWN

pr_missing="$tmp_dir/pr-missing.md"
cat > "$pr_missing" <<'PR'
## Governance Metadata
- CODEOWNER_REVIEW: approved
- SECURITY_REVIEW: approved
PR

if PR_BODY_FILE="$pr_missing" "$SCRIPT"; then
  echo "expected failure when RELEASE_REVIEW is missing"
  exit 1
fi

PR_BODY_FILE="$pr_file" "$SCRIPT"
LOCAL_MODE=1 "$SCRIPT"
popd >/dev/null

echo "test_validate_permissions_gate.sh passed"
