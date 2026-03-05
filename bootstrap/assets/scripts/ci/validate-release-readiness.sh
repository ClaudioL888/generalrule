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
  echo "[release-readiness] $msg" >&2
  emit_step_report \
    "validate-release-readiness" \
    "release readiness gate" \
    "校验发布前置条件与 current-task 状态" \
    "none" \
    "none" \
    "validate-release-readiness.sh" \
    "fail" \
    "$msg" \
    "补齐发布条件后重试"
  exit 1
}

normalize_changed_files() {
  if [[ -n "${CHANGED_FILES:-}" ]]; then
    printf '%s\n' "$CHANGED_FILES" | tr ' ' '\n' | sed '/^$/d'
    return
  fi

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
      git diff --name-only HEAD~1...HEAD
    else
      git diff --name-only HEAD
    fi
    return
  fi

  fail "CHANGED_FILES is required when git context is unavailable"
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

has_changed_prefix() {
  local prefix="$1"
  grep -Eq "^${prefix}" <<<"$NORMALIZED_CHANGED_FILES"
}

FORCE_RELEASE_CHECK="${FORCE_RELEASE_CHECK:-0}"
NORMALIZED_CHANGED_FILES="$(normalize_changed_files)"

if [[ "$FORCE_RELEASE_CHECK" != "1" ]] && ! has_changed_prefix "src/"; then
  echo "[release-readiness] SKIP (no src changes)"
  emit_step_report \
    "validate-release-readiness" \
    "release readiness gate" \
    "校验发布前置条件与 current-task 状态" \
    "none" \
    "none" \
    "validate-release-readiness.sh" \
    "skip" \
    "无 src 变更，跳过发布就绪校验" \
    "继续执行后续门禁"
  exit 0
fi

[[ -s "docs/release/CHANGELOG.md" ]] || fail "docs/release/CHANGELOG.md must exist and be non-empty"
[[ -s "docs/release/RELEASE_NOTES.md" ]] || fail "docs/release/RELEASE_NOTES.md must exist and be non-empty"

CURRENT_TASK_FILE="${CURRENT_TASK_FILE:-docs/status/current-task.md}"
[[ -f "$CURRENT_TASK_FILE" ]] || fail "missing current task file: $CURRENT_TASK_FILE"

current_gate_raw="$(extract_meta "CURRENT_GATE" "$CURRENT_TASK_FILE")"
value_required "CURRENT_GATE" "$current_gate_raw"

if [[ "$current_gate_raw" =~ ([0-9]+) ]]; then
  gate_num="${BASH_REMATCH[1]}"
else
  fail "CURRENT_GATE must contain numeric gate level (e.g., Gate 6)"
fi

if (( gate_num < 6 )); then
  fail "CURRENT_GATE must be at least Gate 6 before release"
fi

test_result="$(extract_meta "TEST_RESULT" "$CURRENT_TASK_FILE")"
value_required "TEST_RESULT" "$test_result"

contract_sync_status="$(extract_meta "CONTRACT_SYNC_STATUS" "$CURRENT_TASK_FILE")"
value_required "CONTRACT_SYNC_STATUS" "$contract_sync_status"
if [[ "$contract_sync_status" != "synced" ]]; then
  fail "CONTRACT_SYNC_STATUS must be synced before release"
fi

echo "[release-readiness] PASS"
emit_step_report \
  "validate-release-readiness" \
  "release readiness gate" \
  "校验发布前置条件与 current-task 状态" \
  "none" \
  "none" \
  "validate-release-readiness.sh" \
  "pass" \
  "发布就绪门禁通过" \
  "可进入发布流程"
