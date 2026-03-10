#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/ci/collect-metrics.sh"

[[ -x "$SCRIPT" ]] || { echo "missing executable script: $SCRIPT"; exit 1; }

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/work"
pushd "$tmp_dir/work" >/dev/null
git init -q
cat > README.md <<'MD'
# Demo
MD
git add README.md
git -c user.name=test -c user.email=test@example.com commit -q -m "feat: init"

OUTPUT_FILE="docs/status/metrics-weekly.md"
CI_FAILURE_RATE="0.2" "$SCRIPT" --output "$OUTPUT_FILE"

[[ -f "$OUTPUT_FILE" ]] || { echo "missing metrics output"; exit 1; }
grep -q '^# Weekly Metrics Snapshot' "$OUTPUT_FILE" || { echo "missing metrics title"; exit 1; }
grep -q 'CI Failure Rate: 0.2' "$OUTPUT_FILE" || { echo "missing CI failure rate"; exit 1; }

"$SCRIPT" --stdout | grep -q '## DORA' || { echo "stdout report missing DORA section"; exit 1; }

popd >/dev/null

echo "test_collect_metrics.sh passed"
