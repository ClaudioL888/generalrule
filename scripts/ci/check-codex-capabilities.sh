#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[codex-capability-check] $1" >&2
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
