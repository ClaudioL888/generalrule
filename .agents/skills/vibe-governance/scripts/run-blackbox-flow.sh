#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run-blackbox-flow.sh start --goal <single-line-goal> [--task-type <feature|bugfix|refactor|ops|content>] [--work-type <full|mini|fast-track>] [--spec-id <SPEC-...>]
  run-blackbox-flow.sh approve --gate <Gate 0|Gate 2|Gate 3|发布|release> [--decision <approved|rejected>]
  run-blackbox-flow.sh status

Examples:
  run-blackbox-flow.sh start --goal "做一个让新用户 10 分钟内完成首次发布的流程"
  run-blackbox-flow.sh approve --gate "Gate 0"
  run-blackbox-flow.sh approve --gate "Gate 2"
  run-blackbox-flow.sh approve --gate "Gate 3"
  run-blackbox-flow.sh approve --gate "发布"
USAGE
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$ROOT_DIR"

SESSION_FILE="${SESSION_FILE:-docs/status/blackbox-session.md}"
CURRENT_TASK_FILE="${CURRENT_TASK_FILE:-docs/status/current-task.md}"
HANDOFF_TEMPLATE="docs/status/TEMPLATE-role-handoff.md"
SESSION_TEMPLATE="docs/status/TEMPLATE-blackbox-session.md"
TASK_PACK_SCRIPT=".agents/skills/vibe-task-pack/scripts/new-task-pack.sh"
QUALITY_GATES_SCRIPT=".agents/skills/vibe-quality-gates/scripts/run-local-gates.sh"

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

cmd_start() {
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
        echo "unknown argument for start: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  if [[ -z "$goal" ]]; then
    echo "--goal is required" >&2
    exit 1
  fi

  validate_task_type "$task_type"
  validate_work_type "$work_type"

  if [[ -z "$spec_id" ]]; then
    spec_id="$(derive_spec_id "$goal")"
  fi

  local transition current_role next_role
  transition="$(transition_for_stage "$task_type" gate0)"
  current_role="${transition%%|*}"
  next_role="${transition##*|}"

  ensure_session_file
  run_task_pack "$spec_id" "$task_type" "$current_role" "$next_role"
  update_current_task_transition "$spec_id" "$task_type" "$work_type" "Gate 0" "$current_role" "$next_role" "等待批准 Gate 0"

  upsert_kv "$SESSION_FILE" "GOAL" "$goal"
  upsert_kv "$SESSION_FILE" "SPEC_ID" "$spec_id"
  upsert_kv "$SESSION_FILE" "TASK_TYPE" "$task_type"
  upsert_kv "$SESSION_FILE" "WORK_TYPE" "$work_type"
  upsert_kv "$SESSION_FILE" "CURRENT_GATE" "Gate 0"
  upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
  upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
  upsert_kv "$SESSION_FILE" "APPROVAL_GATE_0" "pending"
  upsert_kv "$SESSION_FILE" "APPROVAL_GATE_2" "pending"
  upsert_kv "$SESSION_FILE" "APPROVAL_GATE_3" "pending"
  upsert_kv "$SESSION_FILE" "APPROVAL_RELEASE" "pending"
  upsert_kv "$SESSION_FILE" "STATUS" "waiting_gate_0"
  upsert_kv "$SESSION_FILE" "LAST_ACTION" "start"
  upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

  print_card \
    "绑定一句话目标并建立任务包" \
    "已初始化 SPEC、契约映射、角色交接与 current-task" \
    "Gate 0 待批准" \
    "批准 Gate 0" \
    "AI 自动推进 PM/Architect 草案并等待 Gate 2"
}

cmd_approve() {
  local gate=""
  local decision="approved"

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

  [[ -f "$SESSION_FILE" ]] || { echo "missing session file: $SESSION_FILE" >&2; exit 1; }
  [[ -n "$gate" ]] || { echo "--gate is required" >&2; exit 1; }

  local norm_gate
  norm_gate="$(normalize_gate "$gate")"

  local spec_id task_type work_type goal current_gate
  spec_id="$(kv_get "$SESSION_FILE" "SPEC_ID")"
  task_type="$(kv_get "$SESSION_FILE" "TASK_TYPE")"
  work_type="$(kv_get "$SESSION_FILE" "WORK_TYPE")"
  goal="$(kv_get "$SESSION_FILE" "GOAL")"
  current_gate="$(kv_get "$SESSION_FILE" "CURRENT_GATE")"

  [[ -n "$spec_id" ]] || { echo "session SPEC_ID is empty" >&2; exit 1; }
  [[ -n "$task_type" ]] || { echo "session TASK_TYPE is empty" >&2; exit 1; }
  [[ -n "$work_type" ]] || { echo "session WORK_TYPE is empty" >&2; exit 1; }

  if [[ "$decision" != "approved" ]]; then
    upsert_kv "$SESSION_FILE" "STATUS" "blocked"
    upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:${norm_gate}:${decision}"
    upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"
    upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "等待 Founder 决策"
    print_card \
      "关键 Gate 人工决策" \
      "已记录拒绝结果：${norm_gate}" \
      "阻断" \
      "给出新取舍（缩范围/延期/fast-track）" \
      "AI 等待你的决策后继续"
    exit 1
  fi

  local transition current_role next_role

  case "$norm_gate" in
    gate0)
      [[ "$current_gate" == "Gate 0" ]] || { echo "Gate 0 approval is only valid when CURRENT_GATE=Gate 0 (current: $current_gate)" >&2; exit 1; }
      transition="$(transition_for_stage "$task_type" gate2)"
      current_role="${transition%%|*}"
      next_role="${transition##*|}"
      update_current_task_transition "$spec_id" "$task_type" "$work_type" "Gate 2" "$current_role" "$next_role" "等待批准 Gate 2"

      upsert_kv "$SESSION_FILE" "CURRENT_GATE" "Gate 2"
      upsert_kv "$SESSION_FILE" "CURRENT_ROLE" "$current_role"
      upsert_kv "$SESSION_FILE" "NEXT_ROLE" "$next_role"
      upsert_kv "$SESSION_FILE" "APPROVAL_GATE_0" "approved"
      upsert_kv "$SESSION_FILE" "STATUS" "waiting_gate_2"
      upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:gate0"
      upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"

      print_card \
        "完成需求/设计草案并进入架构确认" \
        "已记录 Gate 0 批准，AI 推进到 Gate 2" \
        "Gate 2 待批准" \
        "批准 Gate 2" \
        "AI 自动推进 Planner 拆解并等待 Gate 3"
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
      else
        upsert_kv "$SESSION_FILE" "STATUS" "repair_required"
        upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:gate3:repair-required"
        upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"
        upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "接受修复方案 A/B"
        upsert_kv "$CURRENT_TASK_FILE" "UPDATED_AT" "$(now_utc)"

        print_card \
          "实现阶段门禁自检" \
          "发现阻断项，已进入 Observe/Repair" \
          "失败（阻断）" \
          "接受修复方案 A/B" \
          "AI 修复后重跑门禁并再次请求 Gate 3"
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
      else
        upsert_kv "$SESSION_FILE" "STATUS" "repair_required"
        upsert_kv "$SESSION_FILE" "LAST_ACTION" "approve:release:repair-required"
        upsert_kv "$SESSION_FILE" "LAST_UPDATED" "$(now_utc)"
        upsert_kv "$CURRENT_TASK_FILE" "NEXT_ACTION" "接受修复方案 A/B"
        upsert_kv "$CURRENT_TASK_FILE" "UPDATED_AT" "$(now_utc)"

        print_card \
          "发布前全量门禁" \
          "发现阻断项，发布被拒绝" \
          "失败（阻断）" \
          "接受修复方案 A/B" \
          "AI 修复后重跑门禁并再次请求批准发布"
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
    waiting_gate_0)
      one_action="批准 Gate 0"
      next_step="AI 推进 PM/Architect 草案"
      ;;
    waiting_gate_2)
      one_action="批准 Gate 2"
      next_step="AI 推进 Planner 拆解"
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
}

main() {
  local command="${1:-}"
  if [[ -z "$command" ]]; then
    usage >&2
    exit 1
  fi
  shift || true

  case "$command" in
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
