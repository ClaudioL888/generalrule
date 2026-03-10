#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-observability-gate.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "missing executable script: $SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/work/docs/status" "$tmp_dir/work/docs/metrics"

pushd "$tmp_dir/work" >/dev/null
OBS_ENFORCEMENT=warn "$SCRIPT"

if OBS_ENFORCEMENT=strict "$SCRIPT"; then
  echo "expected strict mode failure when maintenance records are missing"
  exit 1
fi

cat > docs/metrics/TEMPLATE-dora-aarrr.md <<'MD'
# DORA/AARRR
MD
cat > docs/metrics/ENGINEERING_METRICS.md <<'MD'
# Engineering Metrics
MD
cat > docs/status/2026-03-weekly.md <<'MD'
# Weekly
MD
cat > docs/status/2026-03-monthly.md <<'MD'
# Monthly
MD
cat > docs/status/2026-03-metrics-weekly.md <<'MD'
# Metrics Weekly
MD

OBS_ENFORCEMENT=strict "$SCRIPT"
popd >/dev/null

echo "test_validate_observability_gate.sh passed"
