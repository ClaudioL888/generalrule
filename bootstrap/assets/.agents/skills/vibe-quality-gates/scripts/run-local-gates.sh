#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$ROOT_DIR"

STEP_REPORT_HARD=1
if [[ -f "scripts/lib/step-report.sh" ]]; then
  # shellcheck disable=SC1091
  source "scripts/lib/step-report.sh"
else
  echo "missing step report helper: scripts/lib/step-report.sh" >&2
  exit 1
fi

if [[ -z "${CHANGED_FILES:-}" ]]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
      upstream_ref="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')"
      base_commit="$(git merge-base HEAD "$upstream_ref")"
      CHANGED_FILES="$(git diff --name-only "$base_commit...HEAD")"
    elif git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
      CHANGED_FILES="$(git diff --name-only HEAD~1...HEAD)"
    else
      CHANGED_FILES="$(git diff --name-only HEAD)"
    fi
  else
    CHANGED_FILES="docs/status/current-task.md"
  fi
fi

export CHANGED_FILES

pass_count=0
fail_count=0
warn_count=0

run_step() {
  local step_id="$1"
  local title="$2"
  shift 2
  local cmd_display="$*"
  local tmp_out
  tmp_out="$(mktemp)"

  echo "[quality-gates] running: $title"
  if "$@" >"$tmp_out" 2>&1; then
    cat "$tmp_out"
    local status="pass"
    if grep -q "WARN" "$tmp_out"; then
      status="warn"
      warn_count=$((warn_count + 1))
    else
      pass_count=$((pass_count + 1))
    fi
    emit_step_report \
      "$step_id" \
      "local gate: $title" \
      "执行本地门禁步骤" \
      "none" \
      "none" \
      "$cmd_display" \
      "$status" \
      "$title 执行完成" \
      "继续下一项门禁"
    rm -f "$tmp_out"
    return 0
  else
    local exit_code=$?
    cat "$tmp_out" >&2
    rm -f "$tmp_out"
    fail_count=$((fail_count + 1))
    emit_step_report \
      "$step_id" \
      "local gate: $title" \
      "执行本地门禁步骤" \
      "none" \
      "none" \
      "$cmd_display" \
      "fail" \
      "$title 执行失败" \
      "按报错修复后重试该门禁"
    return "$exit_code"
  fi
}

run_step "gates-capability" "codex capabilities" bash scripts/ci/check-codex-capabilities.sh
run_step "gates-spec-pack" "spec pack" env LOCAL_MODE=1 bash scripts/ci/validate-spec-pack.sh
run_step "gates-role-flow" "role flow" env LOCAL_MODE=1 bash scripts/ci/validate-role-flow.sh
run_step "gates-api-frontend" "api/frontend sync" env LOCAL_MODE=1 bash scripts/ci/validate-api-frontend-sync.sh
run_step "gates-permissions" "permissions" env LOCAL_MODE=1 bash scripts/ci/validate-permissions-gate.sh
run_step "gates-security" "security" bash scripts/ci/validate-security-gate.sh
run_step "gates-governance" "governance" env LOCAL_MODE=1 bash scripts/ci/validate-governance.sh
run_step "gates-release" "release readiness" bash scripts/ci/validate-release-readiness.sh
run_step "gates-observability" "observability" bash scripts/ci/validate-observability-gate.sh
run_step "gates-doc-links" "doc links" bash scripts/ci/validate-doc-links.sh

echo "[quality-gates] PASS"
summary_status="pass"
summary_result="通过=${pass_count}; 告警=${warn_count}; 失败=${fail_count}"
if [[ "$fail_count" -gt 0 ]]; then
  summary_status="fail"
fi
emit_step_report \
  "gates-summary" \
  "local gates summary" \
  "汇总门禁执行结果" \
  "none" \
  "none" \
  "run-local-gates.sh" \
  "$summary_status" \
  "$summary_result" \
  "可进入下一阶段"

if [[ "$fail_count" -gt 0 ]]; then
  exit 1
fi
