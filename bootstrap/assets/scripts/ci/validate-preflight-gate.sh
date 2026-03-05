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
  echo "[preflight-gate] $msg" >&2
  emit_step_report \
    "preflight-gate" \
    "preflight gate validation" \
    "校验写入前置条件（能力门槛 + Gate0 批准）" \
    "none" \
    "none" \
    "validate-preflight-gate.sh" \
    "fail" \
    "$msg" \
    "先完成 prepare + approve Gate 0"
  exit 1
}

extract_meta() {
  local key="$1"
  local source="$2"
  sed -n -E "s/^[-*] +${key}:[[:space:]]*(.*)$/\1/p" "$source" | tail -n1
}

SESSION_FILE="${SESSION_FILE:-docs/status/blackbox-session.md}"
CHECK_CAPABILITIES="${CHECK_CAPABILITIES:-1}"

if [[ "$CHECK_CAPABILITIES" == "1" ]]; then
  [[ -x "scripts/ci/check-codex-capabilities.sh" ]] || fail "missing scripts/ci/check-codex-capabilities.sh"
  bash scripts/ci/check-codex-capabilities.sh
fi

[[ -f "$SESSION_FILE" ]] || fail "missing $SESSION_FILE (run prepare + approve Gate 0 first)"

approval_gate_0="$(extract_meta "APPROVAL_GATE_0" "$SESSION_FILE")"
if [[ "$approval_gate_0" != "approved" ]]; then
  fail "APPROVAL_GATE_0 must be approved before write operations"
fi

echo "[preflight-gate] PASS"
emit_step_report \
  "preflight-gate" \
  "preflight gate validation" \
  "校验写入前置条件（能力门槛 + Gate0 批准）" \
  "none" \
  "none" \
  "validate-preflight-gate.sh" \
  "pass" \
  "preflight 校验通过" \
  "可进入写入阶段"
