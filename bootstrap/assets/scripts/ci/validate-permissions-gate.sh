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
  echo "[permissions-gate] $msg" >&2
  emit_step_report \
    "validate-permissions-gate" \
    "permissions gate" \
    "校验 CODEOWNERS 与审批元数据" \
    "none" \
    "none" \
    "validate-permissions-gate.sh" \
    "fail" \
    "$msg" \
    "补齐权限配置与审批字段后重试"
  exit 1
}

extract_meta() {
  local key="$1"
  local source="$2"
  sed -n -E "s/^[-*] +${key}:[[:space:]]*(.*)$/\1/p" "$source" | tail -n1
}

value_required() {
  local name="$1"
  local value="$2"
  local normalized
  normalized="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
  if [[ -z "$value" || "$normalized" == "tbd" || "$normalized" == "n/a" || "$normalized" == "none" || "$normalized" == "null" ]]; then
    fail "${name} is required"
  fi
}

CODEOWNERS_FILE=".github/CODEOWNERS"
[[ -f "$CODEOWNERS_FILE" ]] || fail "missing CODEOWNERS file: $CODEOWNERS_FILE"

for required_pattern in \
  '^[[:space:]]*/?docs/' \
  '^[[:space:]]*/?scripts/ci/' \
  '^[[:space:]]*/?\.codex/' \
  '^[[:space:]]*/?\.github/'; do
  grep -Eq "$required_pattern" "$CODEOWNERS_FILE" || fail "CODEOWNERS missing required path rule pattern: $required_pattern"
done

LOCAL_MODE="${LOCAL_MODE:-0}"
PR_BODY_SOURCE=""

if [[ "$LOCAL_MODE" != "1" ]]; then
  if [[ -n "${PR_BODY_FILE:-}" ]]; then
    [[ -f "$PR_BODY_FILE" ]] || fail "PR_BODY_FILE not found: $PR_BODY_FILE"
    PR_BODY_SOURCE="$PR_BODY_FILE"
  elif [[ -n "${PR_BODY:-}" ]]; then
    PR_BODY_SOURCE="$(mktemp)"
    printf '%s\n' "$PR_BODY" > "$PR_BODY_SOURCE"
  else
    fail "PR_BODY_FILE or PR_BODY must be provided unless LOCAL_MODE=1"
  fi

  for key in CODEOWNER_REVIEW SECURITY_REVIEW RELEASE_REVIEW; do
    value="$(extract_meta "$key" "$PR_BODY_SOURCE")"
    value_required "$key" "$value"
    if [[ "$value" != "approved" ]]; then
      fail "$key must be approved"
    fi
  done
fi

echo "[permissions-gate] PASS"
emit_step_report \
  "validate-permissions-gate" \
  "permissions gate" \
  "校验 CODEOWNERS 与审批元数据" \
  "none" \
  "none" \
  "validate-permissions-gate.sh" \
  "pass" \
  "权限门禁通过" \
  "继续执行后续门禁"
