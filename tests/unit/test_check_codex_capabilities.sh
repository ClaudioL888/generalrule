#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/ci/check-codex-capabilities.sh"

[[ -x "$SCRIPT" ]] || {
  echo "missing executable script: $SCRIPT"
  exit 1
}

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

expect_fail() {
  local name="$1"
  local expected="$2"
  shift 2

  local output
  local status
  set +e
  output="$($@ 2>&1)"
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    echo "expected failure for scenario: $name"
    echo "$output"
    exit 1
  fi

  if ! grep -q "$expected" <<<"$output"; then
    echo "unexpected error for scenario: $name"
    echo "$output"
    exit 1
  fi
}

# Scenario A: codex command missing -> must fail.
expect_fail "missing-codex" "codex command not found" env PATH="/usr/bin:/bin" bash "$SCRIPT"

# Scenario B: codex exists but --rules unsupported -> must fail.
mock_b="$tmp_dir/mock-b"
mkdir -p "$mock_b"
cat > "$mock_b/codex" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == "execpolicy" && "$2" == "check" && "$3" == "--help" ]]; then
  echo "Usage: codex execpolicy check [OPTIONS] --policy <PATH> <COMMAND>..."
  exit 0
fi
exit 0
MOCK
chmod +x "$mock_b/codex"
expect_fail "missing-rules-flag" "does not support --rules" env PATH="$mock_b:/usr/bin:/bin" bash "$SCRIPT"

# Scenario C: --rules supported but justification parser unsupported -> must fail.
mock_c="$tmp_dir/mock-c"
mkdir -p "$mock_c"
cat > "$mock_c/codex" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == "execpolicy" && "$2" == "check" && "$3" == "--help" ]]; then
  echo "Usage: codex execpolicy check [OPTIONS] --rules <PATH> <COMMAND>..."
  exit 0
fi
if [[ "$1" == "execpolicy" && "$2" == "check" ]]; then
  echo "starlark error: unsupported named parameter: justification" >&2
  exit 1
fi
exit 0
MOCK
chmod +x "$mock_c/codex"
expect_fail "justification-unsupported" "parser rejected" env PATH="$mock_c:/usr/bin:/bin" bash "$SCRIPT"

# Scenario D: --rules and justification both supported -> must pass.
mock_d="$tmp_dir/mock-d"
mkdir -p "$mock_d"
cat > "$mock_d/codex" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == "execpolicy" && "$2" == "check" && "$3" == "--help" ]]; then
  echo "Usage: codex execpolicy check [OPTIONS] --rules <PATH> <COMMAND>..."
  exit 0
fi
if [[ "$1" == "execpolicy" && "$2" == "check" ]]; then
  has_rules=0
  for arg in "$@"; do
    if [[ "$arg" == "--rules" ]]; then
      has_rules=1
      break
    fi
  done
  if [[ "$has_rules" -eq 1 ]]; then
    echo '{"decision":"allow"}'
    exit 0
  fi
  exit 1
fi
exit 0
MOCK
chmod +x "$mock_d/codex"
env PATH="$mock_d:/usr/bin:/bin" bash "$SCRIPT"

echo "test_check_codex_capabilities.sh passed"
