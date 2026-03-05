#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run.sh start --goal <single-line-goal> [--task-type <feature|bugfix|refactor|ops|content>] [--work-type <full|mini|fast-track>] [--spec-id <SPEC-...>]
  run.sh status
  run.sh task-pack --spec-id <id> --task-type <feature|bugfix|refactor|ops|content> --current-role <role> --next-role <role> [--force]
  run.sh gates
  run.sh full-loop --spec-id <id> --task-type <feature|bugfix|refactor|ops|content> --current-role <role> --next-role <role> --work-type <full|mini|fast-track>
USAGE
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$ROOT_DIR"

STEP_REPORT_HARD=1
if [[ -f "scripts/lib/step-report.sh" ]]; then
  # shellcheck disable=SC1091
  source "scripts/lib/step-report.sh"
else
  emit_step_report() { return 0; }
fi

fail_route() {
  local step_id="$1"
  local step_name="$2"
  local cmd="$3"
  local msg="$4"
  emit_step_report \
    "$step_id" \
    "$step_name" \
    "路由执行失败" \
    "none" \
    "none" \
    "$cmd" \
    "fail" \
    "$msg" \
    "按报错修复后重试该路由"
  echo "[vibe-hub] $msg" >&2
  exit 1
}

route_start() {
  local goal=""
  local task_type=""
  local work_type=""
  local spec_id=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --goal)
        goal="${2:-}"
        shift 2
        ;;
      --task-type)
        task_type="${2:-}"
        shift 2
        ;;
      --work-type)
        work_type="${2:-}"
        shift 2
        ;;
      --spec-id)
        spec_id="${2:-}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail_route "hub-start" "vibe hub start" "run.sh start" "unknown argument for start: $1"
        ;;
    esac
  done

  [[ -n "$goal" ]] || fail_route "hub-start" "vibe hub start" "run.sh start" "--goal is required"

  local args=(--goal "$goal")
  if [[ -n "$task_type" ]]; then args+=(--task-type "$task_type"); fi
  if [[ -n "$work_type" ]]; then args+=(--work-type "$work_type"); fi
  if [[ -n "$spec_id" ]]; then args+=(--spec-id "$spec_id"); fi

  local cmd1="bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh prepare ${args[*]}"
  bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh prepare "${args[@]}" || fail_route "hub-start-prepare" "vibe hub start" "$cmd1" "prepare failed"

  local cmd2="bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate Gate 0 ${args[*]}"
  bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 0" "${args[@]}" || fail_route "hub-start-approve-gate0" "vibe hub start" "$cmd2" "approve Gate 0 failed"

  local cmd3="bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh start ${args[*]}"
  bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh start "${args[@]}" || fail_route "hub-start-start" "vibe hub start" "$cmd3" "start failed"

  emit_step_report \
    "hub-start" \
    "vibe hub start" \
    "按单入口完成 prepare -> approve Gate 0 -> start" \
    "none" \
    "docs/status/blackbox-session.md,docs/status/current-task.md" \
    "run.sh start" \
    "pass" \
    "启动流程完成" \
    "按需执行 status 或批准 Gate 2"
}

route_status() {
  bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh status || fail_route "hub-status" "vibe hub status" "run-blackbox-flow.sh status" "status failed"
  emit_step_report \
    "hub-status" \
    "vibe hub status" \
    "路由到黑盒状态查询" \
    "none" \
    "none" \
    "run.sh status" \
    "skip" \
    "状态已输出" \
    "根据状态执行下一步路由"
}

route_task_pack() {
  bash .agents/skills/vibe-task-pack/scripts/new-task-pack.sh "$@" || fail_route "hub-task-pack" "vibe hub task-pack" "new-task-pack.sh" "task-pack failed"
  emit_step_report \
    "hub-task-pack" \
    "vibe hub task-pack" \
    "路由到任务包生成" \
    "none" \
    "docs/specs,docs/contracts,docs/status/current-task.md" \
    "run.sh task-pack" \
    "pass" \
    "任务包路由完成" \
    "执行 gates 或进入实现"
}

route_gates() {
  bash .agents/skills/vibe-quality-gates/scripts/run-local-gates.sh "$@" || fail_route "hub-gates" "vibe hub gates" "run-local-gates.sh" "gates failed"
  emit_step_report \
    "hub-gates" \
    "vibe hub gates" \
    "路由到本地门禁链" \
    "none" \
    "none" \
    "run.sh gates" \
    "pass" \
    "门禁路由完成" \
    "进入下一阶段或修复告警"
}

route_full_loop() {
  bash .agents/skills/vibe-governance/scripts/run-full-loop.sh "$@" || fail_route "hub-full-loop" "vibe hub full-loop" "run-full-loop.sh" "full-loop failed"
  emit_step_report \
    "hub-full-loop" \
    "vibe hub full-loop" \
    "路由到完整治理循环" \
    "none" \
    "docs/status/current-task.md,docs/status/blackbox-session.md" \
    "run.sh full-loop" \
    "pass" \
    "完整循环路由完成" \
    "查看 status 并推进下一 Gate"
}

main() {
  local command="${1:-}"
  [[ -n "$command" ]] || {
    usage >&2
    exit 1
  }
  shift || true

  case "$command" in
    start)
      route_start "$@"
      ;;
    status)
      route_status
      ;;
    task-pack)
      route_task_pack "$@"
      ;;
    gates)
      route_gates "$@"
      ;;
    full-loop)
      route_full_loop "$@"
      ;;
    -h|--help)
      usage
      ;;
    *)
      fail_route "hub-main" "vibe hub" "run.sh" "unknown command: $command"
      ;;
  esac
}

main "$@"
