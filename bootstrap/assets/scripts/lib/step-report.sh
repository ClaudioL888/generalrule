#!/usr/bin/env bash
set -euo pipefail

resolve_step_report_mode() {
  local hard="${1:-0}"
  local mode="${STEP_REPORT_MODE:-detailed}"
  case "$mode" in
    detailed|minimal|off)
      ;;
    *)
      mode="detailed"
      ;;
  esac

  if [[ "$hard" == "1" && "$mode" == "off" ]]; then
    echo "[step-report] WARN: STEP_REPORT_MODE=off is not allowed in hard mode, downgraded to minimal" >&2
    mode="minimal"
  fi

  printf '%s\n' "$mode"
}

emit_step_report() {
  local step_id="${1:-unknown-step}"
  local step_name="${2:-unnamed}"
  local actions="${3:-none}"
  local files_created="${4:-none}"
  local files_updated="${5:-none}"
  local commands_run="${6:-none}"
  local gate_status="${7:-skip}"
  local result_summary="${8:-none}"
  local next_action="${9:-none}"

  local mode
  mode="$(resolve_step_report_mode "${STEP_REPORT_HARD:-0}")"
  if [[ "$mode" == "off" ]]; then
    return 0
  fi

  case "$gate_status" in
    pass|fail|warn|skip)
      ;;
    *)
      gate_status="fail"
      ;;
  esac

  if [[ "$mode" == "minimal" ]]; then
    actions="none"
    files_created="none"
    files_updated="none"
    commands_run="none"
  fi

  [[ -n "$files_created" ]] || files_created="none"
  [[ -n "$files_updated" ]] || files_updated="none"
  [[ -n "$commands_run" ]] || commands_run="none"

  cat <<EOF
[step-report]
- STEP_ID: ${step_id}
- STEP_NAME: ${step_name}
- ACTIONS: ${actions}
- FILES_CREATED: ${files_created}
- FILES_UPDATED: ${files_updated}
- COMMANDS_RUN: ${commands_run}
- GATE_STATUS: ${gate_status}
- RESULT_SUMMARY: ${result_summary}
- NEXT_ACTION: ${next_action}
EOF
}
