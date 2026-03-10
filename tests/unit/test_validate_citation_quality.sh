#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-citation-quality.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "missing executable script: $SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/work/docs/specs" "$tmp_dir/work/docs/design" "$tmp_dir/work/docs/status"

cat > "$tmp_dir/work/docs/specs/SPEC-0001-core-flow.md" <<'MD'
# Feature Spec

## 1. Goals and Non-Goals
x
MD

pushd "$tmp_dir/work" >/dev/null

if CHANGED_FILES="docs/specs/SPEC-0001-core-flow.md" "$SCRIPT"; then
  echo "expected failure when citation block is missing"
  exit 1
fi

cat > docs/specs/SPEC-0001-core-flow.md <<'MD'
# Feature Spec

## 1. Goals and Non-Goals
x

## References and Evidence

- SOURCE: https://blog.example.com/post | TYPE: secondary | NOTE: market summary
MD

if CHANGED_FILES="docs/specs/SPEC-0001-core-flow.md" "$SCRIPT"; then
  echo "expected failure when no primary or internal source exists"
  exit 1
fi

cat > docs/specs/SPEC-0001-core-flow.md <<'MD'
# Feature Spec

## 1. Goals and Non-Goals
x

## References and Evidence

- SOURCE: https://docs.example.com/spec | TYPE: primary | NOTE: official contract definition
- SOURCE: docs/prd/0001-problem-statement.md | TYPE: internal | NOTE: approved product context
MD

CHANGED_FILES="docs/specs/SPEC-0001-core-flow.md" "$SCRIPT"

CHANGED_FILES="docs/status/current-task.md" "$SCRIPT"

popd >/dev/null

echo "test_validate_citation_quality.sh passed"
