#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="$ROOT_DIR/.codex/config.toml"
RULE_FILE="$ROOT_DIR/.codex/rules/default.rules"
CAPABILITY_SCRIPT="$ROOT_DIR/scripts/ci/check-codex-capabilities.sh"

[[ -f "$CONFIG_FILE" ]] || {
  echo "missing config file: $CONFIG_FILE"
  exit 1
}

[[ -f "$RULE_FILE" ]] || {
  echo "missing rules file: $RULE_FILE"
  exit 1
}

[[ -x "$CAPABILITY_SCRIPT" ]] || {
  echo "missing executable capability script: $CAPABILITY_SCRIPT"
  exit 1
}

ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import pathlib
import tomllib
import os

root = pathlib.Path(os.environ["ROOT_DIR"])
cfg_path = root / ".codex" / "config.toml"
cfg = tomllib.loads(cfg_path.read_text(encoding="utf-8"))

def require_path(path, expected=None):
    cur = cfg
    for key in path:
        if key not in cur:
            raise SystemExit(f"missing key: {'.'.join(path)}")
        cur = cur[key]
    if expected is not None and cur != expected:
        raise SystemExit(
            f"unexpected value for {'.'.join(path)}: {cur!r} != {expected!r}"
        )
    return cur

require_path(["approval_policy"], "on-request")
require_path(["sandbox_mode"], "workspace-write")
require_path(["allow_login_shell"], False)
require_path(["sandbox_workspace_write", "network_access"], False)
require_path(["sandbox_workspace_write", "exclude_tmpdir_env_var"], False)
require_path(["sandbox_workspace_write", "exclude_slash_tmp"], False)
require_path(["project_doc_max_bytes"], 65536)
fallback = require_path(["project_doc_fallback_filenames"])
if "AGENTS.override.md" not in fallback:
    raise SystemExit("project_doc_fallback_filenames must include AGENTS.override.md")

require_path(["profiles", "strict", "approval_policy"], "untrusted")
require_path(["profiles", "strict", "sandbox_mode"], "read-only")
require_path(["profiles", "strict", "allow_login_shell"], False)
require_path(["profiles", "release", "approval_policy"], "on-request")
require_path(["profiles", "release", "sandbox_mode"], "workspace-write")
require_path(["profiles", "release", "allow_login_shell"], False)
require_path(["profiles", "release", "sandbox_workspace_write", "network_access"], False)
PY

grep -q 'decision = "allow"' "$RULE_FILE" || {
  echo "rules file must include allow decisions"
  exit 1
}
grep -q 'decision = "prompt"' "$RULE_FILE" || {
  echo "rules file must include prompt decisions"
  exit 1
}
grep -q 'decision = "forbidden"' "$RULE_FILE" || {
  echo "rules file must include forbidden decisions"
  exit 1
}
for blocked in \
  'pattern = \["git", "reset", "--hard"\]' \
  'pattern = \["git", "checkout", "--"\]' \
  'pattern = \["rm", "-rf", "/"\]' \
  'pattern = \["curl"\]' \
  'pattern = \["wget"\]'; do
  grep -q "$blocked" "$RULE_FILE" || {
    echo "missing forbidden rule pattern: $blocked"
    exit 1
  }
done

if grep -E '^prefix_rule\(' "$RULE_FILE" | grep -vq 'justification ='; then
  echo "every prefix_rule must define justification"
  exit 1
fi

command -v codex >/dev/null 2>&1 || {
  echo "codex binary not found; strict official mode requires codex with --rules and justification support"
  exit 1
}

bash "$CAPABILITY_SCRIPT"

strict_decision() {
  local cmd_output
  cmd_output="$(
    codex execpolicy check --pretty \
      --rules "$RULE_FILE" \
      -- "$@" 2>/dev/null || true
  )"
  printf '%s\n' "$cmd_output"
}

git_status_decision="$(strict_decision git status)"
if grep -qi '"decision": "forbidden"' <<<"$git_status_decision"; then
  echo "git status should not be forbidden"
  exit 1
fi

npm_install_decision="$(strict_decision npm install)"
grep -qi '"decision": "prompt"' <<<"$npm_install_decision" || {
  echo "npm install should resolve to prompt"
  exit 1
}

hard_reset_decision="$(strict_decision git reset --hard)"
grep -qi '"decision": "forbidden"' <<<"$hard_reset_decision" || {
  echo "git reset --hard should resolve to forbidden"
  exit 1
}

echo "test_codex_runtime_config.sh passed"
