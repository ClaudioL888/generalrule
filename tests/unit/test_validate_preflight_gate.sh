#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

cp -R "$ROOT_DIR/bootstrap/assets"/. "$tmp_dir"/

mock_bin="$tmp_dir/mock-bin"
mkdir -p "$mock_bin"
cat > "$mock_bin/codex" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == "execpolicy" && "$2" == "check" && "$3" == "--help" ]]; then
  echo "Usage: codex execpolicy check [OPTIONS] --rules <PATH> <COMMAND>..."
  exit 0
fi
if [[ "$1" == "execpolicy" && "$2" == "check" ]]; then
  echo '{"decision":"allow"}'
  exit 0
fi
exit 1
MOCK
chmod +x "$mock_bin/codex"

pushd "$tmp_dir" >/dev/null

rm -f docs/status/blackbox-session.md
if PATH="$mock_bin:/usr/bin:/bin" bash scripts/ci/validate-preflight-gate.sh >/dev/null 2>&1; then
  echo "expected failure when blackbox-session is missing"
  exit 1
fi

cat > docs/status/blackbox-session.md <<'MD'
# Blackbox Session
- APPROVAL_GATE_0: pending
MD
if PATH="$mock_bin:/usr/bin:/bin" bash scripts/ci/validate-preflight-gate.sh >/dev/null 2>&1; then
  echo "expected failure when APPROVAL_GATE_0 is pending"
  exit 1
fi

cat > docs/status/blackbox-session.md <<'MD'
# Blackbox Session
- APPROVAL_GATE_0: approved
MD
PATH="$mock_bin:/usr/bin:/bin" bash scripts/ci/validate-preflight-gate.sh

popd >/dev/null

echo "test_validate_preflight_gate.sh passed"
