#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  new-task-pack.sh --spec-id <id> --task-type <feature|bugfix|refactor|ops|content> --current-role <role> --next-role <role> [--force]
USAGE
}

SPEC_ID=""
TASK_TYPE=""
CURRENT_ROLE=""
NEXT_ROLE=""
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec-id)
      SPEC_ID="${2:-}"
      shift 2
      ;;
    --task-type)
      TASK_TYPE="${2:-}"
      shift 2
      ;;
    --current-role)
      CURRENT_ROLE="${2:-}"
      shift 2
      ;;
    --next-role)
      NEXT_ROLE="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$SPEC_ID" || -z "$TASK_TYPE" || -z "$CURRENT_ROLE" || -z "$NEXT_ROLE" ]]; then
  usage >&2
  exit 1
fi

case "$TASK_TYPE" in
  feature|bugfix|refactor|ops|content)
    ;;
  *)
    echo "invalid --task-type: $TASK_TYPE" >&2
    exit 1
    ;;
esac

for required in docs/specs/TEMPLATE-feature-spec.md docs/contracts/TEMPLATE-api-frontend-map.md docs/status/TEMPLATE-role-handoff.md docs/status/current-task.md; do
  [[ -f "$required" ]] || { echo "missing required file: $required" >&2; exit 1; }
done

mkdir -p docs/specs docs/contracts docs/status/handoffs

spec_file="docs/specs/${SPEC_ID}.md"
map_file="docs/contracts/${SPEC_ID}-api-frontend-map.md"
spec_slug="$(printf '%s' "$SPEC_ID" | tr '[:upper:]' '[:lower:]')"
from_slug="$(printf '%s' "$CURRENT_ROLE" | tr '[:upper:] ' '[:lower:]-' | sed 's/[^a-z0-9-]//g')"
to_slug="$(printf '%s' "$NEXT_ROLE" | tr '[:upper:] ' '[:lower:]-' | sed 's/[^a-z0-9-]//g')"
handoff_file="docs/status/handoffs/${spec_slug}-${from_slug}-to-${to_slug}.md"

maybe_copy() {
  local src="$1"
  local dst="$2"
  if [[ -f "$dst" && "$FORCE" != "1" ]]; then
    return
  fi
  cp "$src" "$dst"
}

maybe_copy docs/specs/TEMPLATE-feature-spec.md "$spec_file"
maybe_copy docs/contracts/TEMPLATE-api-frontend-map.md "$map_file"
maybe_copy docs/status/TEMPLATE-role-handoff.md "$handoff_file"

replace_token_file() {
  local file="$1"
  local key="$2"
  local value="$3"
  local escaped
  escaped="$(printf '%s' "$value" | sed -e 's/[\|&]/\\&/g')"
  sed -i.bak "s|{{${key}}}|${escaped}|g" "$file"
  rm -f "${file}.bak"
}

for f in "$spec_file" "$map_file" "$handoff_file"; do
  replace_token_file "$f" "spec_id" "$SPEC_ID"
  replace_token_file "$f" "task_type" "$TASK_TYPE"
  replace_token_file "$f" "current_role" "$CURRENT_ROLE"
  replace_token_file "$f" "next_role" "$NEXT_ROLE"
done

upsert_kv() {
  local file="$1"
  local key="$2"
  local value="$3"
  local escaped
  escaped="$(printf '%s' "$value" | sed -e 's/[\|&]/\\&/g')"
  if grep -Eq "^-[[:space:]]+${key}:[[:space:]]*" "$file"; then
    sed -i.bak -E "s|^-[[:space:]]+${key}:[[:space:]]*.*$|- ${key}: ${escaped}|" "$file"
    rm -f "${file}.bak"
  else
    printf -- "- %s: %s\n" "$key" "$value" >> "$file"
  fi
}

current_task="docs/status/current-task.md"
upsert_kv "$current_task" "SPEC_ID" "$SPEC_ID"
upsert_kv "$current_task" "TASK_TYPE" "$TASK_TYPE"
upsert_kv "$current_task" "CURRENT_ROLE" "$CURRENT_ROLE"
upsert_kv "$current_task" "NEXT_ROLE" "$NEXT_ROLE"
upsert_kv "$current_task" "HANDOFF_LINK" "$handoff_file"
upsert_kv "$current_task" "ROLE" "$CURRENT_ROLE"
upsert_kv "$current_task" "API_SURFACE_CHANGED" "no"
upsert_kv "$current_task" "FRONTEND_SURFACE_CHANGED" "no"
upsert_kv "$current_task" "CONTRACT_SYNC_STATUS" "pending"
upsert_kv "$current_task" "UPDATED_AT" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

printf 'task pack ready\n'
printf '  SPEC: %s\n' "$spec_file"
printf '  MAP: %s\n' "$map_file"
printf '  HANDOFF: %s\n' "$handoff_file"
