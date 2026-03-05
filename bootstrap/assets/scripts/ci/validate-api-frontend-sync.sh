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
  echo "[api-frontend-sync] $msg" >&2
  emit_step_report \
    "validate-api-frontend-sync" \
    "api frontend sync gate" \
    "校验 API 与前端契约映射同步" \
    "none" \
    "none" \
    "validate-api-frontend-sync.sh" \
    "fail" \
    "$msg" \
    "更新 contracts 映射并设为 synced 后重试"
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

has_changed_file() {
  local needle="$1"
  grep -Fxq "$needle" <<<"$NORMALIZED_CHANGED_FILES"
}

has_changed_prefix() {
  local prefix="$1"
  grep -Eq "^${prefix}" <<<"$NORMALIZED_CHANGED_FILES"
}

has_api_path_changes() {
  grep -Eq '^(src/api/|src/routes/|src/server/|docs/api/|openapi/)' <<<"$NORMALIZED_CHANGED_FILES"
}

has_frontend_path_changes() {
  grep -Eq '^(src/web/|src/ui/|src/pages/|src/components/|src/frontend/)' <<<"$NORMALIZED_CHANGED_FILES"
}

LOCAL_MODE="${LOCAL_MODE:-0}"
DEFAULT_CURRENT_TASK_FILE="docs/status/current-task.md"

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
fi

NORMALIZED_CHANGED_FILES="$(normalize_changed_files)"
CURRENT_TASK_FILE="${CURRENT_TASK_FILE:-$DEFAULT_CURRENT_TASK_FILE}"
[[ -f "$CURRENT_TASK_FILE" ]] || fail "current task file missing: $CURRENT_TASK_FILE"

spec_id="$(extract_meta "SPEC_ID" "$CURRENT_TASK_FILE")"
api_surface_changed="$(extract_meta "API_SURFACE_CHANGED" "$CURRENT_TASK_FILE")"
frontend_surface_changed="$(extract_meta "FRONTEND_SURFACE_CHANGED" "$CURRENT_TASK_FILE")"
contract_sync_status="$(extract_meta "CONTRACT_SYNC_STATUS" "$CURRENT_TASK_FILE")"

value_required "SPEC_ID" "$spec_id"
value_required "API_SURFACE_CHANGED" "$api_surface_changed"
value_required "FRONTEND_SURFACE_CHANGED" "$frontend_surface_changed"
value_required "CONTRACT_SYNC_STATUS" "$contract_sync_status"

case "$api_surface_changed" in
  yes|no)
    ;;
  *)
    fail "API_SURFACE_CHANGED must be yes or no"
    ;;
esac

case "$frontend_surface_changed" in
  yes|no)
    ;;
  *)
    fail "FRONTEND_SURFACE_CHANGED must be yes or no"
    ;;
esac

case "$contract_sync_status" in
  synced|pending)
    ;;
  *)
    fail "CONTRACT_SYNC_STATUS must be synced or pending"
    ;;
esac

map_file="${API_FRONTEND_MAP_FILE:-docs/contracts/${spec_id}-api-frontend-map.md}"
if [[ "$LOCAL_MODE" != "1" ]]; then
  map_file_meta="$(extract_meta "API_FRONTEND_MAP_LINK" "$PR_BODY_SOURCE")"
  contract_sync_meta="$(extract_meta "CONTRACT_SYNC_STATUS" "$PR_BODY_SOURCE")"
  value_required "API_FRONTEND_MAP_LINK" "$map_file_meta"
  value_required "CONTRACT_SYNC_STATUS(metadata)" "$contract_sync_meta"
  [[ "$contract_sync_meta" == "$contract_sync_status" ]] || fail "CONTRACT_SYNC_STATUS mismatch between metadata and current-task"
  map_file="$map_file_meta"
fi

src_changed=0
if has_changed_prefix "src/"; then
  src_changed=1
fi

api_detected=0
if has_api_path_changes; then
  api_detected=1
fi

frontend_detected=0
if has_frontend_path_changes; then
  frontend_detected=1
fi

if [[ "$api_detected" == "1" && "$api_surface_changed" != "yes" ]]; then
  fail "API paths changed but API_SURFACE_CHANGED is not yes"
fi

if [[ "$frontend_detected" == "1" && "$frontend_surface_changed" != "yes" ]]; then
  fail "Frontend paths changed but FRONTEND_SURFACE_CHANGED is not yes"
fi

if [[ "$src_changed" == "1" || "$api_surface_changed" == "yes" || "$frontend_surface_changed" == "yes" ]]; then
  [[ -f "$map_file" ]] || fail "API_FRONTEND_MAP_LINK file not found: $map_file"
  has_changed_file "$map_file" || fail "API_FRONTEND_MAP_LINK must be updated: $map_file"

  grep -Fq "## Mapping Table" "$map_file" || fail "map file missing Mapping Table section"
  grep -Fq "| Endpoint / Event | DTO / Schema | Frontend 页面/组件 | 状态管理 | 测试点 | 备注 |" "$map_file" || fail "map file missing required mapping table header"
fi

if [[ "$frontend_surface_changed" == "yes" && "$api_surface_changed" == "no" ]]; then
  grep -Eq '^- N/A_REASON:[[:space:]]*.+$' "$map_file" || fail "frontend-only changes require explicit N/A_REASON in map file"
fi

if [[ "$api_surface_changed" == "no" && "$frontend_surface_changed" == "no" && "$src_changed" == "1" ]]; then
  grep -Eq '^- INTERNAL_ONLY_REASON:[[:space:]]*.+$' "$map_file" || fail "internal-only src changes require INTERNAL_ONLY_REASON in map file"
fi

if [[ "$src_changed" == "1" && "$contract_sync_status" != "synced" ]]; then
  fail "CONTRACT_SYNC_STATUS must be synced for src changes"
fi

echo "[api-frontend-sync] PASS"
emit_step_report \
  "validate-api-frontend-sync" \
  "api frontend sync gate" \
  "校验 API 与前端契约映射同步" \
  "none" \
  "none" \
  "validate-api-frontend-sync.sh" \
  "pass" \
  "API/前端契约门禁通过" \
  "继续执行后续门禁"
