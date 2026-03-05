#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-doc-links.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "missing executable script: $SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/docs"
cat > "$tmp_dir/docs/ok.md" <<'MD'
# OK

Link to [target](./target.md).
MD
cat > "$tmp_dir/docs/target.md" <<'MD'
# Target
MD

DOCS_ROOT="$tmp_dir/docs" "$SCRIPT"

cat > "$tmp_dir/docs/bad.md" <<'MD'
# Bad

Link to [missing](./missing.md).
MD

if DOCS_ROOT="$tmp_dir/docs" "$SCRIPT"; then
  echo "expected failure on missing markdown link"
  exit 1
fi

echo "test_validate_doc_links.sh passed"
