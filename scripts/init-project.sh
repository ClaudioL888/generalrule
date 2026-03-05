#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/init-project.sh --output <dir> --seed <seed.md> [--force] [--project-name <name>] [--strict-seed]

Options:
  --output <dir>       Target project directory (required)
  --seed <file>        Markdown seed file with machine-readable key section (required)
  --project-name <n>   Optional override for project_name
  --strict-seed        Enable strict seed validation (enforce L2 keys for full work_type)
  --force              Allow overwriting non-empty target directory
  -h, --help           Show this help

Environment:
  STRICT_SEED=1        Equivalent to --strict-seed
USAGE
}

OUTPUT_DIR=""
SEED_FILE=""
FORCE=0
PROJECT_NAME_OVERRIDE=""
STRICT_SEED_MODE="${STRICT_SEED:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    --seed)
      SEED_FILE="${2:-}"
      shift 2
      ;;
    --project-name)
      PROJECT_NAME_OVERRIDE="${2:-}"
      shift 2
      ;;
    --strict-seed)
      STRICT_SEED_MODE=1
      shift
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
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$OUTPUT_DIR" || -z "$SEED_FILE" ]]; then
  echo "--output and --seed are required" >&2
  usage >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS_DIR="$ROOT_DIR/bootstrap/assets"

if [[ ! -d "$ASSETS_DIR" ]]; then
  echo "Missing assets directory: $ASSETS_DIR" >&2
  exit 1
fi

if [[ ! -f "$SEED_FILE" ]]; then
  echo "Seed file not found: $SEED_FILE" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_DIR")"
if [[ -d "$OUTPUT_DIR" ]]; then
  if find "$OUTPUT_DIR" -mindepth 1 -print -quit | grep -q .; then
    if [[ "$FORCE" -ne 1 ]]; then
      echo "Output directory is not empty: $OUTPUT_DIR (use --force to overwrite)" >&2
      exit 1
    fi
    rm -rf "$OUTPUT_DIR"
  fi
fi
mkdir -p "$OUTPUT_DIR"

if ! grep -q '<!-- START_SEED_KV -->' "$SEED_FILE" || ! grep -q '<!-- END_SEED_KV -->' "$SEED_FILE"; then
  echo "Seed file must include <!-- START_SEED_KV --> and <!-- END_SEED_KV --> markers" >&2
  exit 1
fi

KV_FILE="$(mktemp)"
TOKENS_USED_FILE="$(mktemp)"
MISSING_OPTIONAL_FILE="$(mktemp)"
UNUSED_KEYS_FILE="$(mktemp)"
cleanup() {
  rm -f "$KV_FILE" "$TOKENS_USED_FILE" "$MISSING_OPTIONAL_FILE" "$UNUSED_KEYS_FILE" "${MISSING_FULL_FILE:-}"
}
trap cleanup EXIT

in_seed_kv=0
while IFS= read -r line; do
  if [[ "$line" == *"<!-- START_SEED_KV -->"* ]]; then
    in_seed_kv=1
    continue
  fi
  if [[ "$line" == *"<!-- END_SEED_KV -->"* ]]; then
    in_seed_kv=0
    break
  fi
  if [[ "$in_seed_kv" -eq 1 ]]; then
    if [[ "$line" =~ ^-[[:space:]]*([a-z0-9_]+):[[:space:]]*(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      val="$(printf '%s' "$val" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
      val="$(printf '%s' "$val" | sed -E 's/^`(.*)`$/\1/')"
      printf '%s\t%s\n' "$key" "$val" >> "$KV_FILE"
    fi
  fi
done < "$SEED_FILE"

kv_get() {
  local key="$1"
  awk -F '\t' -v k="$key" '$1==k {v=$2} END {print v}' "$KV_FILE"
}

normalize_bool() {
  local raw="$1"
  local lowered
  lowered="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
  case "$lowered" in
    1|true|yes|on)
      printf '1\n'
      ;;
    0|false|no|off|'')
      printf '0\n'
      ;;
    *)
      echo "invalid STRICT_SEED value: $raw (use 0/1/true/false)" >&2
      exit 1
      ;;
  esac
}

STRICT_SEED_MODE="$(normalize_bool "$STRICT_SEED_MODE")"

required_keys=(
  project_code
  goal_id
  work_type
  phase
  problem_statement
  target_persona
  core_use_case
  spec_id
  task_type
  task_1
  acceptance_1
  test_point_1
  role
  current_role
  next_role
  handoff_link
  api_surface_changed
  frontend_surface_changed
  contract_sync_status
  current_gate
  test_commands
  test_result
  next_action
)

full_required_keys=(
  chosen_stack
  api_contract
  entity_definitions
  io_schema
  api_change_policy
  frontend_binding_policy
  contract_review_owner
  security_boundary
  security_1
  observability_plan
  alert_thresholds
  release_owner
  rollback_strategy
  rollback_summary
)

missing_required=0
for key in "${required_keys[@]}"; do
  value="$(kv_get "$key")"
  if [[ -z "$value" ]]; then
    echo "missing required seed key: $key" >&2
    missing_required=1
  fi
done
if [[ "$missing_required" -ne 0 ]]; then
  exit 1
fi

work_type="$(kv_get work_type)"
case "$work_type" in
  full|mini|fast-track)
    ;;
  *)
    echo "invalid work_type: $work_type (must be one of full|mini|fast-track)" >&2
    exit 1
    ;;
esac

MISSING_FULL_FILE="$(mktemp)"
if [[ "$work_type" == "full" ]]; then
  for key in "${full_required_keys[@]}"; do
    value="$(kv_get "$key")"
    if [[ -z "$value" ]]; then
      printf '%s\n' "$key" >> "$MISSING_FULL_FILE"
    fi
  done
fi

if [[ "$STRICT_SEED_MODE" == "1" && "$work_type" == "full" && -s "$MISSING_FULL_FILE" ]]; then
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    echo "missing full-strict seed key: $key" >&2
  done < "$MISSING_FULL_FILE"
  exit 1
fi

if [[ -n "$PROJECT_NAME_OVERRIDE" ]]; then
  printf 'project_name\t%s\n' "$PROJECT_NAME_OVERRIDE" >> "$KV_FILE"
else
  project_name="$(kv_get project_name)"
  if [[ -z "$project_name" ]]; then
    printf 'project_name\t%s\n' "$(kv_get project_code)" >> "$KV_FILE"
  fi
fi

cp -R "$ASSETS_DIR"/. "$OUTPUT_DIR"/

placeholder_keys="$(grep -Rho '{{[a-z0-9_]\+}}' "$OUTPUT_DIR" 2>/dev/null | sed -E 's/\{\{|\}\}//g' | sort -u || true)"

if [[ -n "$placeholder_keys" ]]; then
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    printf '%s\n' "$key" >> "$TOKENS_USED_FILE"
    value="$(kv_get "$key")"
    if [[ -z "$value" ]]; then
      value="TODO(${key})"
      printf '%s\n' "$key" >> "$MISSING_OPTIONAL_FILE"
    fi

    escaped_value="$(printf '%s' "$value" | sed -e 's/[\\|&]/\\\\&/g')"
    while IFS= read -r -d '' file; do
      tmp_file="${file}.tmp.$$"
      sed "s|{{${key}}}|${escaped_value}|g" "$file" > "$tmp_file"
      mv "$tmp_file" "$file"
    done < <(find "$OUTPUT_DIR" -type f -print0)
  done <<< "$placeholder_keys"
fi

# Ensure script executability is preserved after placeholder replacement rewrites.
if [[ -d "$OUTPUT_DIR/scripts" ]]; then
  while IFS= read -r -d '' shell_script; do
    chmod +x "$shell_script"
  done < <(find "$OUTPUT_DIR/scripts" -type f -name '*.sh' -print0)
fi

if [[ -d "$OUTPUT_DIR/.githooks" ]]; then
  while IFS= read -r -d '' hook_file; do
    chmod +x "$hook_file"
  done < <(find "$OUTPUT_DIR/.githooks" -type f -print0)
fi

if [[ -d "$OUTPUT_DIR/.agents/skills" ]]; then
  while IFS= read -r -d '' skill_script; do
    chmod +x "$skill_script"
  done < <(find "$OUTPUT_DIR/.agents/skills" -type f -path '*/scripts/*.sh' -print0)
fi

while IFS=$'\t' read -r key _; do
  [[ -z "$key" ]] && continue
  if ! grep -Fxq "$key" "$TOKENS_USED_FILE"; then
    printf '%s\n' "$key" >> "$UNUSED_KEYS_FILE"
  fi
done < "$KV_FILE"

echo "Generated project baseline at: $OUTPUT_DIR"

if [[ -s "$MISSING_OPTIONAL_FILE" ]]; then
  echo "Optional seed keys not provided (filled with TODO):"
  sort -u "$MISSING_OPTIONAL_FILE" | sed 's/^/  - /'
fi

if [[ -s "$UNUSED_KEYS_FILE" ]]; then
  echo "Seed keys provided but not used by current assets:"
  sort -u "$UNUSED_KEYS_FILE" | sed 's/^/  - /'
fi

if [[ "$STRICT_SEED_MODE" == "0" && "$work_type" == "full" && -s "$MISSING_FULL_FILE" ]]; then
  echo "Compatibility mode warning: full work_type is missing advanced keys (strict mode would fail):"
  sort -u "$MISSING_FULL_FILE" | sed 's/^/  - /'
fi
