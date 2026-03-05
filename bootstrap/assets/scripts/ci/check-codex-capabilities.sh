#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ -f "$ROOT_DIR/scripts/lib/step-report.sh" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/scripts/lib/step-report.sh"
else
  emit_step_report() { return 0; }
fi

fail() {
  local msg="$1"
  echo "[codex-capability-check] $msg" >&2
  emit_step_report \
    "capability-check" \
    "codex capability check" \
    "校验 codex 是否支持官方规则语义" \
    "none" \
    "none" \
    "codex execpolicy check --help ; codex execpolicy check --rules" \
    "fail" \
    "$msg" \
    "升级 codex 后重试"
  exit 1
}

if ! command -v codex >/dev/null 2>&1; then
  fail "codex command not found. Install/upgrade Codex CLI that supports --rules and prefix_rule(..., justification=...)."
fi

help_output="$(codex execpolicy check --help 2>&1 || true)"
if ! grep -q -- "--rules" <<<"$help_output"; then
  fail "codex execpolicy check does not support --rules. Please upgrade Codex CLI to an official-compatible version."
fi

tmp_rules="$(mktemp)"
cleanup() {
  rm -f "$tmp_rules"
}
trap cleanup EXIT

cat > "$tmp_rules" <<'RULES'
description = "capability-check"
prefix_rule(pattern = ["git", "status"], decision = "allow", justification = "Read-only inspection.")
RULES

if ! codex execpolicy check --pretty --rules "$tmp_rules" -- git status >/dev/null 2>&1; then
  fail "codex parser rejected prefix_rule(..., justification=...) or --rules policy evaluation. Please upgrade Codex CLI."
fi

echo "[codex-capability-check] PASS"
emit_step_report \
  "capability-check" \
  "codex capability check" \
  "校验 codex 是否支持官方规则语义" \
  "none" \
  "none" \
  "codex execpolicy check --help ; codex execpolicy check --rules" \
  "pass" \
  "能力门槛通过" \
  "继续执行后续门禁"
