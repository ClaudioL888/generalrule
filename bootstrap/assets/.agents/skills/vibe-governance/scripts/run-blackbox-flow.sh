#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run-blackbox-flow.sh prepare --goal <single-line-goal> [--task-type <feature|bugfix|refactor|ops|content>] [--work-type <full|mini|fast-track>] [--spec-id <SPEC-...>]
  run-blackbox-flow.sh approve --gate <Gate 0|Gate 2|Gate 3|发布|release> [--decision <approved|rejected>] [--goal <...>] [--task-type <...>] [--work-type <...>] [--spec-id <...>]
  run-blackbox-flow.sh start [--goal <...>] [--task-type <...>] [--work-type <...>] [--spec-id <...>]
  run-blackbox-flow.sh status

Examples:
  run-blackbox-flow.sh prepare --goal "做一个让新用户 10 分钟内完成首次发布的流程"
  run-blackbox-flow.sh approve --gate "Gate 0" --goal "做一个让新用户 10 分钟内完成首次发布的流程" --task-type feature --work-type full --spec-id SPEC-20260305-core-flow
  run-blackbox-flow.sh start
USAGE
}

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

SESSION_FILE="${SESSION_FILE:-docs/status/blackbox-session.md}"
CURRENT_TASK_FILE="${CURRENT_TASK_FILE:-docs/status/current-task.md}"
HANDOFF_TEMPLATE="docs/status/TEMPLATE-role-handoff.md"
SESSION_TEMPLATE="docs/status/TEMPLATE-blackbox-session.md"
TASK_PACK_SCRIPT=".agents/skills/vibe-task-pack/scripts/new-task-pack.sh"
QUALITY_GATES_SCRIPT=".agents/skills/vibe-quality-gates/scripts/run-local-gates.sh"
PREFLIGHT_SCRIPT="scripts/ci/validate-preflight-gate.sh"
CAPABILITY_SCRIPT="scripts/ci/check-codex-capabilities.sh"

now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\\|&]/\\\\&/g'
}

upsert_kv() {
  local file="$1"
  local key="$2"
  local value="$3"
  local escaped

  escaped="$(escape_sed "$value")"
  mkdir -p "$(dirname "$file")"
  if [[ ! -f "$file" ]]; then
    printf '# Auto-generated\n- %s: %s\n' "$key" "$value" > "$file"
    return
  fi

  if grep -Eq "^-[[:space:]]+${key}:[[:space:]]*" "$file"; then
    sed -i.bak -E "s|^-[[:space:]]+${key}:[[:space:]]*.*$|- ${key}: ${escaped}|" "$file"
    rm -f "${file}.bak"
  else
    printf -- '- %s: %s\n' "$key" "$value" >> "$file"
  fi
}

kv_get() {
  local file="$1"
  local key="$2"
  sed -n -E "s/^-[[:space:]]+${key}:[[:space:]]*(.*)$/\1/p" "$file" | tail -n1
}

replace_token_file() {
  local file="$1"
  local key="$2"
  local value="$3"
  local escaped

  escaped="$(escape_sed "$value")"
  sed -i.bak "s|{{${key}}}|${escaped}|g" "$file"
  rm -f "${file}.bak"
}

slugify() {
  local input="$1"
  local slug
  slug="$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')"
  if [[ -z "$slug" ]]; then
    slug="task"
  fi
  printf '%s' "$slug"
}

derive_spec_id() {
  local goal="$1"
  local slug
  slug="$(slugify "$goal")"
  slug="$(printf '%s' "$slug" | cut -c1-24)"
  printf 'SPEC-%s-%s\n' "$(date -u +%Y%m%d)" "$slug"
}

validate_task_type() {
  case "$1" in
    feature|bugfix|refactor|ops|content)
      ;;
    *)
      echo "invalid task type: $1" >&2
      exit 1
      ;;
  esac
}

validate_work_type() {
  case "$1" in
    full|mini|fast-track)
      ;;
    *)
      echo "invalid work type: $1" >&2
      exit 1
      ;;
  esac
}

run_capability_gate() {
  [[ -x "$CAPABILITY_SCRIPT" ]] || { echo "missing capability script: $CAPABILITY_SCRIPT" >&2; exit 1; }
  bash "$CAPABILITY_SCRIPT"
}

run_preflight_gate() {
  [[ -x "$PREFLIGHT_SCRIPT" ]] || { echo "missing preflight script: $PREFLIGHT_SCRIPT" >&2; exit 1; }
  bash "$PREFLIGHT_SCRIPT"
}

transition_for_stage() {
  local task_type="$1"
  local stage="$2"

  case "$task_type:$stage" in
    feature:gate0) echo "Founder|PM" ;;
    feature:gate2) echo "Architect|Planner" ;;
    feature:gate3) echo "Planner|Dev" ;;
    feature:release) echo "Reviewer|Release-Ops" ;;
    feature:done) echo "Release-Ops|Growth" ;;

    bugfix:gate0) echo "Planner|Dev" ;;
    bugfix:gate2) echo "Planner|Dev" ;;
    bugfix:gate3) echo "Planner|Dev" ;;
    bugfix:release) echo "Reviewer|Release-Ops" ;;
    bugfix:done) echo "Release-Ops|Planner" ;;

    refactor:gate0) echo "Architect|Planner" ;;
    refactor:gate2) echo "Architect|Planner" ;;
    refactor:gate3) echo "Planner|Dev" ;;
    refactor:release) echo "Reviewer|Release-Ops" ;;
    refactor:done) echo "Release-Ops|Architect" ;;

    ops:gate0) echo "Planner|Dev" ;;
    ops:gate2) echo "Planner|Dev" ;;
    ops:gate3) echo "Planner|Dev" ;;
    ops:release) echo "Reviewer|Release-Ops" ;;
    ops:done) echo "Release-Ops|Planner" ;;

    content:gate0) echo "PM|Content-Growth" ;;
    content:gate2) echo "PM|Content-Growth" ;;
    content:gate3) echo "Content-Growth|Reviewer" ;;
    content:release) echo "Reviewer|PM" ;;
    content:done) echo "PM|Content-Growth" ;;

    *)
      echo "unsupported transition stage: ${task_type}:${stage}" >&2
      exit 1
      ;;
  esac
}

handoff_file_for() {
  local spec_id="$1"
  local current_role="$2"
  local next_role="$3"
  local spec_slug from_slug to_slug

  spec_slug="$(printf '%s' "$spec_id" | tr '[:upper:]' '[:lower:]')"
  from_slug="$(printf '%s' "$current_role" | tr '[:upper:] ' '[:lower:]-' | sed 's/[^a-z0-9-]//g')"
  to_slug="$(printf '%s' "$next_role" | tr '[:upper:] ' '[:lower:]-' | sed 's/[^a-z0-9-]//g')"
  printf 'docs/status/handoffs/%s-%s-to-%s.md\n' "$spec_slug" "$from_slug" "$to_slug"
}

ensure_handoff_file() {
  local file="$1"
  local spec_id="$2"
  local task_type="$3"
  local current_role="$4"
  local next_role="$5"

  mkdir -p "$(dirname "$file")"
  if [[ ! -f "$file" ]]; then
    if [[ -f "$HANDOFF_TEMPLATE" ]]; then
      cp "$HANDOFF_TEMPLATE" "$file"
    else
      cat > "$file" <<'FALLBACK'
# Role Handoff

## Inputs
- TODO

## Outputs
- TODO

## Definition of Done
- TODO

## Handoff To
- TODO
FALLBACK
    fi
  fi

  replace_token_file "$file" "spec_id" "$spec_id"
  replace_token_file "$file" "task_type" "$task_type"
  replace_token_file "$file" "current_role" "$current_role"
  replace_token_file "$file" "next_role" "$next_role"
}

ensure_session_file() {
  if [[ -f "$SESSION_FILE" ]]; then
    return
  fi

  mkdir -p "$(dirname "$SESSION_FILE")"
  if [[ -f "$SESSION_TEMPLATE" ]]; then
    cp "$SESSION_TEMPLATE" "$SESSION_FILE"
  else
    cat > "$SESSION_FILE" <<'FALLBACK'
# Blackbox Session
- GOAL: TODO(goal)
- SPEC_ID: TODO(spec_id)
- TASK_TYPE: TODO(task_type)
- WORK_TYPE: TODO(work_type)
- CURRENT_GATE: Gate 0
- CURRENT_ROLE: Founder
- NEXT_ROLE: PM
- APPROVAL_GATE_0: pending
- APPROVAL_GATE_2: pending
- APPROVAL_GATE_3: pending
- APPROVAL_RELEASE: pending
- STATUS: active
- LAST_ACTION: start
- LAST_UPDATED: TODO(updated_at)
FALLBACK
  fi
}

ensure_current_task_file() {
  if [[ -f "$CURRENT_TASK_FILE" ]]; then
    return
  fi
  mkdir -p "$(dirname "$CURRENT_TASK_FILE")"
  cat > "$CURRENT_TASK_FILE" <<'FALLBACK'
# Current Task
- TASK_ID: TODO(task_id)
- SPEC_ID: TODO(spec_id)
- TASK_TYPE: feature
- ROLE: Founder
- WORK_TYPE: full
- CURRENT_GATE: Gate 0
- CURRENT_ROLE: Founder
- NEXT_ROLE: PM
- HANDOFF_LINK: docs/status/handoffs/todo.md
- API_SURFACE_CHANGED: no
- FRONTEND_SURFACE_CHANGED: no
- CONTRACT_SYNC_STATUS: pending
- TEST_COMMANDS: pending
- TEST_RESULT: pending
- UPDATED_AT: 1970-01-01T00:00:00Z
- NEXT_ACTION: pending
FALLBACK
}

print_card() {
  local stage_goal="$1"
  local done_summary="$2"
  local hard_gate="$3"
  local one_action="$4"
  local next_step="$5"

  cat <<CARD
[blackbox-card]
- 阶段目标: ${stage_goal}
- AI 已完成: ${done_summary}
- 硬门禁状态: ${hard_gate}
- 你只需做一件事: ${one_action}
- 下一步: ${next_step}
CARD
}

run_partial_gates() {
  local changed_files="${CHANGED_FILES:-}"
  if [[ -z "$changed_files" ]]; then
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
        changed_files="$(git diff --name-only HEAD~1...HEAD)"
      else
        changed_files="$(git diff --name-only HEAD)"
      fi
    else
      changed_files="docs/status/current-task.md"
    fi
  fi

  CHANGED_FILES="$changed_files" bash scripts/ci/check-codex-capabilities.sh
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-spec-pack.sh
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-role-flow.sh
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-api-frontend-sync.sh
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-governance.sh
  DOCS_ROOT=docs bash scripts/ci/validate-doc-links.sh
}

run_release_gates() {
  if [[ -x "$QUALITY_GATES_SCRIPT" ]]; then
    bash "$QUALITY_GATES_SCRIPT"
    return
  fi

  local changed_files="${CHANGED_FILES:-}"
  if [[ -z "$changed_files" ]]; then
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
        changed_files="$(git diff --name-only HEAD~1...HEAD)"
      else
        changed_files="$(git diff --name-only HEAD)"
      fi
    else
      changed_files="docs/status/current-task.md"
    fi
  fi

  CHANGED_FILES="$changed_files" bash scripts/ci/check-codex-capabilities.sh
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-spec-pack.sh
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-role-flow.sh
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-api-frontend-sync.sh
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-permissions-gate.sh
  CHANGED_FILES="$changed_files" bash scripts/ci/validate-security-gate.sh
  CHANGED_FILES="$changed_files" LOCAL_MODE=1 bash scripts/ci/validate-governance.sh
  CHANGED_FILES="$changed_files" bash scripts/ci/validate-release-readiness.sh
  OBS_ENFORCEMENT=warn bash scripts/ci/validate-observability-gate.sh
  DOCS_ROOT=docs bash scripts/ci/validate-doc-links.sh
}

normalize_gate() {
  local raw="$1"
  local g
  g="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[[:space:]]+//g')"
  case "$g" in
    gate0|0|批准gate0)
      printf 'gate0\n'
      ;;
    gate2|2|批准gate2)
      printf 'gate2\n'
      ;;
    gate3|3|批准gate3)
      printf 'gate3\n'
      ;;
    发布|release|gate6|6|批准发布)
      printf 'release\n'
      ;;
    *)
      echo "unknown gate: $raw" >&2
      exit 1
      ;;
  esac
}

update_current_task_transition() {
  local spec_id="$1"
  local task_type="$2"
  local work_type="$3"
  local current_gate="$4"
  local current_role="$5"
  local next_role="$6"
  local next_action="$7"
  local handoff

  handoff="$(handoff_file_for "$spec_id" "$current_role" "$next_role")"
  ensure_handoff_file "$handoff" "$spec_id" "$task_type" "$current_role" "$next_role"

  ensure_current_task_file

  upsert_kv "$CURRENT_TASK_FILE" "TASK_ID" "${spec_id}-task-1"
  upsert_kv "$CURRENT_TASK_FILE" "SPEC_ID" "$spec_id"
  upsert_kv "$CURRENT_TASK_FILE" "TASK_TYPE" "$task_type"
  upsert_kv "$CURRENT_TASK_FILE" "ROLE" "$current_role"
  upsert_kv "$CURRENT_TASK_FILE" "WORK_TYPE" "$work_type"
  upsert_kv "$CURRENT_TASK_FILE" "CURRENT_GATE" "$current_gate"
  upsert_kv "$CURRENT_TASK_FILE" "CURRENT_ROLE" "$current_role"
  upsert_kv "$CURRENT_TASK_FILE" "NEXT_ROLE" "$next_role"
  upsert_kv "$CURRENT_TASK_FILE" "HANDOFF_LINK" "$handoff"
  upsert_kv "$CURRENT_TASK_FILE" "UPDATED_AT" "$(now_utc)"
  upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "$next_action"

  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "TEST_COMMANDS")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "TEST_COMMANDS" "pending"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "TEST_RESULT")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "TEST_RESULT" "pending"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "API_SURFACE_CHANGED")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "API_SURFACE_CHANGED" "no"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "FRONTEND_SURFACE_CHANGED")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "FRONTEND_SURFACE_CHANGED" "no"
  fi
  if [[ -z "$(kv_get "$CURRENT_TASK_FILE" "CONTRACT_SYNC_STATUS")" ]]; then
    upsert_kv "$CURRENT_TASK_FILE" "CONTRACT_SYNC_STATUS" "pending"
  fi
}

run_task_pack() {
  local spec_id="$1"
  local task_type="$2"
  local current_role="$3"
  local next_role="$4"

  if [[ ! -x "$TASK_PACK_SCRIPT" ]]; then
    return
  fi

  bash "$TASK_PACK_SCRIPT" \
    --spec-id "$spec_id" \
    --task-type "$task_type" \
    --current-role "$current_role" \
    --next-role "$next_role"
}

cmd_prepare() {
  local goal=""
  local task_type="feature"
  local work_type="full"
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
        echo "unknown argument for prepare: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  [[ -n "$goal" ]] || { echo "--goal is required" >&2; exit 1; }
  validate_task_type "$task_type"
  validate_work_type "$work_type"
  run_capability_gate

  if [[ -z "$spec_id" ]]; then
    spec_id="$(derive_spec_id "$goal")"
  fi

  print_card \
    "只读预检（不写入项目文件）" \
    "能力门槛通过；建议 SPEC_ID=${spec_id}; TASK_TYPE=${task_type}; WORK_TYPE=${work_type}" \
    "Gate 0 待批准" \
    "批准 Gate 0" \
    "执行 approve Gate 0 后再运行 start"

  emit_step_report \
    "blackbox-prepare" \
    "blackbox prepare" \
    "执行只读预检并生成建议参数" \
    "none" \
    "none" \
    "scripts/ci/check-codex-capabilities.sh" \
    "pass" \
    "预检通过，等待 Gate 0 批准" \
    "执行 approve --gate Gate 0"

  cat <<NEXT
[next-command]
bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 0" --goal "${goal}" --task-type "${task_type}" --work-type "${work_type}" --spec-id "${spec_id}"
NEXT
}

cmd_start() {
  local goal_override=""
  local task_type_override=""
  local work_type_override=""
  local spec_id_override=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --goal)
        goal_override="${2:-}"
        shift 2
        ;;
      --task-type)
        task_type_override="${2:-}"
        shift 2
        ;;
      --work-type)
        work_type_override="${2:-}"
        shift 2
        ;;
      --spec-id)
        spec_id_override="${2:-}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "unknown argument for start: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  [[ -f "$SESSION_FILE" ]] || { echo "missing session file: $SESSION_FILE (run prepare + approve Gate 0 first)" >&2; exit 1; }

  run_preflight_gate

  local goal task_type work_type spec_id transition current_role next_role
  goal="$(kv_get "$SESSION_FILE" "GOAL")"
  task_type="$(kv_get "$SESSION_FILE" "TASK_TYPE")"
  work_type="$(kv_get "$SESSION_FILE" "WORK_TYPE")"
  spec_id="$(kv_get "$SESSION_FILE" "SPEC_ID")"

  [[ -n "$goal" && -n "$task_type" && -n "$work_type" && -n "$spec_id" ]] || {
    echo "session missing required fields (GOAL/TASK_TYPE/WORK_TYPE/SPEC_ID)" >&2
    exit 1
  }

  if [[ -n "$goal_override" && "$goal_override" != "$goal" ]]; then
    echo "start --goal does not match approved session GOAL" >&2
    exit 1
  fi
  if [[ -n "$task_type_override" && "$task_type_override" != "$task_type" ]]; then
    echo "start --task-type does not match approved session TASK_TYPE" >&2
    exit 1
  fi
  if [[ -n "$work_type_override" && "$work_type_override" != "$work_type" ]]; then
    echo "start --work-type does not match approved session WORK_TYPE" >&2
    exit 1
  fi
  if [[ -n "$spec_id_override" && "$spec_id_override" != "$spec_id" ]]; then
    echo "start --spec-id does not match approved session SPEC_ID" >&2
    exit 1
  fi

  transition="$(transition_for_stage "$task_type" gate2)"
  current_role="${transition%%|*}"
  next_role="${transition##*|}"

  local start_spec_file start_map_file start_handoff_file
  local spec_existed map_existed handoff_existed task_existed session_existed
  start_spec_file="docs/specs/${spec_id}.md"
  start_map_file="docs/contracts/${spec_id}-api-frontend-map.md"
  start_handoff_file="$(handoff_file_for "$spec_id" "$current_role" "$next_role")"
  spec_existed=0
  map_existed=0
  handoff_existed=0
  task_existed=0
  session_existed=0
  [[ -f "$start_spec_file" ]] && spec_existed=1
  [[ -f "$start_map_file" ]] && map_existed=1
  [[ -f "$start_handoff_file" ]] && handoff_existed=1
  [[ -f "$CURRENT_TASK_FILE" ]] && task_existed=1
  [[ -f "$SESSION_FILE" ]] && session_existed=1

  run_task_pack "$spec_id" "$task_type" "$current_role" "$next_role"
  update_current_task_transition "$spec_id" "$task_type" "$work_type" "Gate 2" "$current_role" "$next_role" "等待批准 Gate 2"

  upsert_kv "$SESSION_FILE" "CURRENT_GATE" "Gate 2"
  upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
  upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
  upsert_kv "$SESSION_FILE" "APPROVAL_GATE_2" "pending"
  upsert_kv "$SESSION_FILE" "APPROVAL_GATE_3" "pending"
  upsert_kv "$SESSION_FILE" "APPROVAL_RELEASE" "pending"
  upsert_kv "$SESSION_FILE" "STATUS" "waiting_gate_2"
  upsert_kv "$SESSION_FILE" "LAST_ACTION" "start"
  upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

  print_card \
    "Gate 0 已批准后启动可写流程" \
    "已初始化任务包与 current-task，进入 Gate 2" \
    "Gate 2 待批准" \
    "批准 Gate 2" \
    "AI 自动推进 Planner/Dev 阶段"

  local created_files=()
  local updated_files=()
  if [[ "$spec_existed" -eq 0 ]]; then created_files+=("$start_spec_file"); else updated_files+=("$start_spec_file"); fi
  if [[ "$map_existed" -eq 0 ]]; then created_files+=("$start_map_file"); else updated_files+=("$start_map_file"); fi
  if [[ "$handoff_existed" -eq 0 ]]; then created_files+=("$start_handoff_file"); else updated_files+=("$start_handoff_file"); fi
  if [[ "$task_existed" -eq 0 ]]; then created_files+=("$CURRENT_TASK_FILE"); else updated_files+=("$CURRENT_TASK_FILE"); fi
  if [[ "$session_existed" -eq 0 ]]; then created_files+=("$SESSION_FILE"); else updated_files+=("$SESSION_FILE"); fi

  local created_csv="none"
  local updated_csv="none"
  if [[ "${#created_files[@]}" -gt 0 ]]; then
    created_csv="$(IFS=,; printf '%s' "${created_files[*]}")"
  fi
  if [[ "${#updated_files[@]}" -gt 0 ]]; then
    updated_csv="$(IFS=,; printf '%s' "${updated_files[*]}")"
  fi

  emit_step_report \
    "blackbox-start" \
    "blackbox start" \
    "初始化任务包并推进到 Gate 2" \
    "$created_csv" \
    "$updated_csv" \
    "scripts/ci/validate-preflight-gate.sh ; new-task-pack.sh" \
    "pass" \
    "任务包与会话状态已更新" \
    "批准 Gate 2"
}

cmd_approve() {
  local gate=""
  local decision="approved"
  local goal_arg=""
  local task_type_arg=""
  local work_type_arg=""
  local spec_id_arg=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --gate)
        gate="${2:-}"
        shift 2
        ;;
      --decision)
        decision="${2:-}"
        shift 2
        ;;
      --goal)
        goal_arg="${2:-}"
        shift 2
        ;;
      --task-type)
        task_type_arg="${2:-}"
        shift 2
        ;;
      --work-type)
        work_type_arg="${2:-}"
        shift 2
        ;;
      --spec-id)
        spec_id_arg="${2:-}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "unknown argument for approve: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  [[ -n "$gate" ]] || { echo "--gate is required" >&2; exit 1; }
  local norm_gate
  norm_gate="$(normalize_gate "$gate")"

  local spec_id task_type work_type goal current_gate

  if [[ "$norm_gate" == "gate0" && ! -f "$SESSION_FILE" ]]; then
    [[ -n "$goal_arg" ]] || { echo "approve Gate 0 without session requires --goal" >&2; exit 1; }
    task_type="${task_type_arg:-feature}"
    work_type="${work_type_arg:-full}"
    spec_id="${spec_id_arg:-$(derive_spec_id "$goal_arg")}" 
    goal="$goal_arg"

    validate_task_type "$task_type"
    validate_work_type "$work_type"
    run_capability_gate

    ensure_session_file

    local transition current_role next_role
    transition="$(transition_for_stage "$task_type" gate0)"
    current_role="${transition%%|*}"
    next_role="${transition##*|}"

    upsert_kv "$SESSION_FILE" "GOAL" "$goal"
    upsert_kv "$SESSION_FILE" "SPEC_ID" "$spec_id"
    upsert_kv "$SESSION_FILE" "TASK_TYPE" "$task_type"
    upsert_kv "$SESSION_FILE" "WORK_TYPE" "$work_type"
    upsert_kv "$SESSION_FILE" "CURRENT_GATE" "Gate 0"
    upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
    upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
    upsert_kv "$SESSION_FILE" "APPROVAL_GATE_0" "approved"
    upsert_kv "$SESSION_FILE" "APPROVAL_GATE_2" "pending"
    upsert_kv "$SESSION_FILE" "APPROVAL_GATE_3" "pending"
    upsert_kv "$SESSION_FILE" "APPROVAL_RELEASE" "pending"
    upsert_kv "$SESSION_FILE" "STATUS" "gate0_approved"
    upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:gate0"
    upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

    print_card \
      "记录 Gate 0 批准（仍为预写阶段）" \
      "会话已建立并标记 Gate 0 approved" \
      "通过" \
      "执行 start" \
      "start 后进入 Gate 2 并创建任务包"

    emit_step_report \
      "blackbox-approve-gate0-bootstrap" \
      "approve gate 0" \
      "创建会话并记录 Gate 0 批准" \
      "$SESSION_FILE" \
      "none" \
      "scripts/ci/check-codex-capabilities.sh ; run-blackbox-flow.sh approve --gate Gate 0" \
      "pass" \
      "Gate 0 已批准，等待 start" \
      "执行 start"
    exit 0
  fi

  [[ -f "$SESSION_FILE" ]] || { echo "missing session file: $SESSION_FILE" >&2; exit 1; }

  spec_id="$(kv_get "$SESSION_FILE" "SPEC_ID")"
  task_type="$(kv_get "$SESSION_FILE" "TASK_TYPE")"
  work_type="$(kv_get "$SESSION_FILE" "WORK_TYPE")"
  goal="$(kv_get "$SESSION_FILE" "GOAL")"
  current_gate="$(kv_get "$SESSION_FILE" "CURRENT_GATE")"

  [[ -n "$spec_id" && -n "$task_type" && -n "$work_type" ]] || {
    echo "session missing required fields" >&2
    exit 1
  }

  if [[ "$decision" != "approved" ]]; then
    upsert_kv "$SESSION_FILE" "STATUS" "blocked"
    upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:${norm_gate}:${decision}"
    upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"
    if [[ -f "$CURRENT_TASK_FILE" ]]; then
      upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "等待 Founder 决策"
      upsert_kv "$CURRENT_TASK_FILE" "UPDATED_AT" "$(now_utc)"
    fi
    print_card \
      "关键 Gate 人工决策" \
      "已记录拒绝结果：${norm_gate}" \
      "阻断" \
      "给出新取舍（缩范围/延期/fast-track）" \
      "AI 等待你的决策后继续"
    emit_step_report \
      "blackbox-approve-${norm_gate}-rejected" \
      "approve ${norm_gate}" \
      "记录 Gate 拒绝并进入阻断状态" \
      "none" \
      "$SESSION_FILE,$CURRENT_TASK_FILE" \
      "run-blackbox-flow.sh approve --gate ${norm_gate} --decision ${decision}" \
      "fail" \
      "Gate 被拒绝，流程阻断" \
      "给出新取舍并重新批准"
    exit 1
  fi

  local transition current_role next_role

  case "$norm_gate" in
    gate0)
      [[ "$current_gate" == "Gate 0" ]] || { echo "Gate 0 approval is only valid when CURRENT_GATE=Gate 0 (current: $current_gate)" >&2; exit 1; }
      transition="$(transition_for_stage "$task_type" gate0)"
      current_role="${transition%%|*}"
      next_role="${transition##*|}"

      upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
      upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
      upsert_kv "$SESSION_FILE" "APPROVAL_GATE_0" "approved"
      upsert_kv "$SESSION_FILE" "STATUS" "gate0_approved"
      upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:gate0"
      upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

      print_card \
        "记录 Gate 0 批准（仍为预写阶段）" \
        "会话已更新为 Gate 0 approved" \
        "通过" \
        "执行 start" \
        "start 后进入 Gate 2 并创建任务包"
      emit_step_report \
        "blackbox-approve-gate0" \
        "approve gate 0" \
        "更新会话为 Gate 0 approved" \
        "none" \
        "$SESSION_FILE" \
        "run-blackbox-flow.sh approve --gate Gate 0" \
        "pass" \
        "Gate 0 已批准" \
        "执行 start"
      ;;

    gate2)
      [[ "$current_gate" == "Gate 2" ]] || { echo "Gate 2 approval is only valid when CURRENT_GATE=Gate 2 (current: $current_gate)" >&2; exit 1; }
      transition="$(transition_for_stage "$task_type" gate3)"
      current_role="${transition%%|*}"
      next_role="${transition##*|}"
      update_current_task_transition "$spec_id" "$task_type" "$work_type" "Gate 3" "$current_role" "$next_role" "等待批准 Gate 3"

      upsert_kv "$SESSION_FILE" "CURRENT_GATE" "Gate 3"
      upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
      upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
      upsert_kv "$SESSION_FILE" "APPROVAL_GATE_2" "approved"
      upsert_kv "$SESSION_FILE" "STATUS" "waiting_gate_3"
      upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:gate2"
      upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

      print_card \
        "完成任务拆解并准备进入实现" \
        "已记录 Gate 2 批准，AI 已锁定单任务执行" \
        "Gate 3 待批准" \
        "批准 Gate 3" \
        "AI 自动执行实现/测试/观察修复并准备发布检查"
      emit_step_report \
        "blackbox-approve-gate2" \
        "approve gate 2" \
        "推进到 Gate 3 并更新角色与交接状态" \
        "none" \
        "$SESSION_FILE,$CURRENT_TASK_FILE" \
        "run-blackbox-flow.sh approve --gate Gate 2" \
        "pass" \
        "Gate 2 已批准，等待 Gate 3" \
        "批准 Gate 3"
      ;;

    gate3)
      [[ "$current_gate" == "Gate 3" ]] || { echo "Gate 3 approval is only valid when CURRENT_GATE=Gate 3 (current: $current_gate)" >&2; exit 1; }

      if run_partial_gates; then
        transition="$(transition_for_stage "$task_type" release)"
        current_role="${transition%%|*}"
        next_role="${transition##*|}"
        update_current_task_transition "$spec_id" "$task_type" "$work_type" "Gate 6" "$current_role" "$next_role" "等待批准发布"

        upsert_kv "$SESSION_FILE" "CURRENT_GATE" "Gate 6"
        upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
        upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
        upsert_kv "$SESSION_FILE" "APPROVAL_GATE_3" "approved"
        upsert_kv "$SESSION_FILE" "STATUS" "waiting_release_approval"
        upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:gate3"
        upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

        print_card \
          "实现阶段自检完成并进入发布候选" \
          "已通过关键门禁（spec/role/contract/governance/doc）" \
          "通过" \
          "批准发布" \
          "AI 执行全量门禁并给出发布后复盘"
        emit_step_report \
          "blackbox-approve-gate3" \
          "approve gate 3" \
          "运行关键门禁并推进到发布候选" \
          "none" \
          "$SESSION_FILE,$CURRENT_TASK_FILE" \
          "run-blackbox-flow.sh approve --gate Gate 3 ; partial gates" \
          "pass" \
          "关键门禁通过，等待发布批准" \
          "批准发布"
      else
        upsert_kv "$SESSION_FILE" "STATUS" "repair_required"
        upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:gate3:repair-required"
        upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"
        if [[ -f "$CURRENT_TASK_FILE" ]]; then
          upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "接受修复方案 A/B"
          upsert_kv "$CURRENT_TASK_FILE" "UPDATED_AT" "$(now_utc)"
        fi

        print_card \
          "实现阶段门禁自检" \
          "发现阻断项，已进入 Observe/Repair" \
          "失败（阻断）" \
          "接受修复方案 A/B" \
          "AI 修复后重跑门禁并再次请求 Gate 3"
        emit_step_report \
          "blackbox-approve-gate3" \
          "approve gate 3" \
          "运行关键门禁并检测到阻断项" \
          "none" \
          "$SESSION_FILE,$CURRENT_TASK_FILE" \
          "run-blackbox-flow.sh approve --gate Gate 3 ; partial gates" \
          "fail" \
          "关键门禁失败，进入修复循环" \
          "接受修复方案 A/B"
        exit 1
      fi
      ;;

    release)
      [[ "$current_gate" == "Gate 6" ]] || { echo "Release approval is only valid when CURRENT_GATE=Gate 6 (current: $current_gate)" >&2; exit 1; }

      if run_release_gates; then
        transition="$(transition_for_stage "$task_type" done)"
        current_role="${transition%%|*}"
        next_role="${transition##*|}"
        update_current_task_transition "$spec_id" "$task_type" "$work_type" "Gate 6" "$current_role" "$next_role" "进入增长复盘并回到下一轮发现"

        upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
        upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
        upsert_kv "$SESSION_FILE" "APPROVAL_RELEASE" "approved"
        upsert_kv "$SESSION_FILE" "STATUS" "released"
        upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:release"
        upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

        print_card \
          "发布与闭环复盘" \
          "已通过全量门禁并记录发布状态" \
          "通过" \
          "无（发布已完成）" \
          "AI 输出 DORA/AARRR 复盘并建议下一轮任务"
        emit_step_report \
          "blackbox-approve-release" \
          "approve release" \
          "运行全量门禁并完成发布状态更新" \
          "none" \
          "$SESSION_FILE,$CURRENT_TASK_FILE" \
          "run-blackbox-flow.sh approve --gate 发布 ; release gates" \
          "pass" \
          "发布完成并进入复盘" \
          "开始下一轮目标"
      else
        upsert_kv "$SESSION_FILE" "STATUS" "repair_required"
        upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:release:repair-required"
        upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"
        if [[ -f "$CURRENT_TASK_FILE" ]]; then
          upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "接受修复方案 A/B"
          upsert_kv "$CURRENT_TASK_FILE" "UPDATED_AT" "$(now_utc)"
        fi

        print_card \
          "发布前全量门禁" \
          "发现阻断项，发布被拒绝" \
          "失败（阻断）" \
          "接受修复方案 A/B" \
          "AI 修复后重跑门禁并再次请求批准发布"
        emit_step_report \
          "blackbox-approve-release" \
          "approve release" \
          "运行全量门禁并检测到阻断项" \
          "none" \
          "$SESSION_FILE,$CURRENT_TASK_FILE" \
          "run-blackbox-flow.sh approve --gate 发布 ; release gates" \
          "fail" \
          "发布门禁失败，已阻断" \
          "接受修复方案 A/B"
        exit 1
      fi
      ;;
  esac

  upsert_kv "$SESSION_FILE" "GOAL" "$goal"
}

cmd_status() {
  [[ -f "$SESSION_FILE" ]] || { echo "missing session file: $SESSION_FILE" >&2; exit 1; }

  local goal task_type work_type current_gate current_role next_role status
  goal="$(kv_get "$SESSION_FILE" "GOAL")"
  task_type="$(kv_get "$SESSION_FILE" "TASK_TYPE")"
  work_type="$(kv_get "$SESSION_FILE" "WORK_TYPE")"
  current_gate="$(kv_get "$SESSION_FILE" "CURRENT_GATE")"
  current_role="$(kv_get "$SESSION_FILE" "CURRENT_ROLE")"
  next_role="$(kv_get "$SESSION_FILE" "NEXT_ROLE")"
  status="$(kv_get "$SESSION_FILE" "STATUS")"

  local one_action="查看 current-task 并继续"
  local next_step="继续按状态推进"

  case "$status" in
    gate0_approved)
      one_action="执行 start"
      next_step="AI 初始化任务包并进入 Gate 2"
      ;;
    waiting_gate_2)
      one_action="批准 Gate 2"
      next_step="AI 推进 Planner/Dev"
      ;;
    waiting_gate_3)
      one_action="批准 Gate 3"
      next_step="AI 进入实现/测试与自检"
      ;;
    waiting_release_approval)
      one_action="批准发布"
      next_step="AI 执行全量门禁并发布"
      ;;
    repair_required)
      one_action="接受修复方案 A/B"
      next_step="AI 修复后重跑门禁"
      ;;
    released)
      one_action="新建下一条一句话目标"
      next_step="进入下一轮黑盒循环"
      ;;
  esac

  print_card \
    "当前黑盒会话状态" \
    "goal=${goal}; task_type=${task_type}; work_type=${work_type}; gate=${current_gate}; role=${current_role}->${next_role}" \
    "$status" \
    "$one_action" \
    "$next_step"
  emit_step_report \
    "blackbox-status" \
    "blackbox status" \
    "读取会话并输出当前阶段建议" \
    "none" \
    "none" \
    "run-blackbox-flow.sh status" \
    "skip" \
    "当前状态: ${status}" \
    "$one_action"
}

main() {
  local command="${1:-}"
  if [[ -z "$command" ]]; then
    usage >&2
    exit 1
  fi
  shift || true

  case "$command" in
    prepare)
      cmd_prepare "$@"
      ;;
    start)
      cmd_start "$@"
      ;;
    approve)
      cmd_approve "$@"
      ;;
    status)
      cmd_status
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "unknown command: $command" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
