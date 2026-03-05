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
  echo "[observability-gate] $msg" >&2
  emit_step_report \
    "validate-observability-gate" \
    "observability gate" \
    "校验维护记录与 DORA/AARRR 初始化" \
    "none" \
    "none" \
    "validate-observability-gate.sh" \
    "fail" \
    "$msg" \
    "补齐观测维护文档后重试"
  exit 1
}

warn() {
  echo "[observability-gate] WARN: $1" >&2
}

OBS_ENFORCEMENT="${OBS_ENFORCEMENT:-warn}"
case "$OBS_ENFORCEMENT" in
  warn|strict)
    ;;
  *)
    fail "OBS_ENFORCEMENT must be warn or strict"
    ;;
esac

issues=()

if [[ ! -f "docs/metrics/TEMPLATE-dora-aarrr.md" ]]; then
  issues+=("missing docs/metrics/TEMPLATE-dora-aarrr.md")
fi

if [[ ! -d "docs/status" ]]; then
  issues+=("missing docs/status directory")
else
  weekly_count="$(find docs/status -maxdepth 1 -type f -name '*weekly*.md' ! -name 'TEMPLATE-*' | wc -l | tr -d ' ')"
  monthly_count="$(find docs/status -maxdepth 1 -type f -name '*monthly*.md' ! -name 'TEMPLATE-*' | wc -l | tr -d ' ')"

  if [[ "$weekly_count" == "0" ]]; then
    issues+=("no weekly maintenance record found in docs/status")
  fi

  if [[ "$monthly_count" == "0" ]]; then
    issues+=("no monthly maintenance record found in docs/status")
  fi
fi

if [[ "${#issues[@]}" -eq 0 ]]; then
  echo "[observability-gate] PASS"
  emit_step_report \
    "validate-observability-gate" \
    "observability gate" \
    "校验维护记录与 DORA/AARRR 初始化" \
    "none" \
    "none" \
    "validate-observability-gate.sh" \
    "pass" \
    "观测门禁通过" \
    "继续执行后续门禁"
  exit 0
fi

if [[ "$OBS_ENFORCEMENT" == "strict" ]]; then
  for item in "${issues[@]}"; do
    fail "$item"
  done
fi

for item in "${issues[@]}"; do
  warn "$item"
done

echo "[observability-gate] PASS (warn mode)"
emit_step_report \
  "validate-observability-gate" \
  "observability gate" \
  "校验维护记录与 DORA/AARRR 初始化" \
  "none" \
  "none" \
  "validate-observability-gate.sh" \
  "warn" \
  "观测门禁告警（warn 模式）" \
  "补齐周/月维护记录并考虑切 strict"
