#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run-full-loop.sh --spec-id <id> --task-type <type> --current-role <role> --next-role <role> --work-type <full|mini|fast-track>
USAGE
}

SPEC_ID=""
TASK_TYPE=""
CURRENT_ROLE=""
NEXT_ROLE=""
WORK_TYPE=""

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
    --work-type)
      WORK_TYPE="${2:-}"
      shift 2
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

if [[ -z "$SPEC_ID" || -z "$TASK_TYPE" || -z "$CURRENT_ROLE" || -z "$NEXT_ROLE" || -z "$WORK_TYPE" ]]; then
  usage >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$ROOT_DIR"

spec_file="docs/specs/${SPEC_ID}.md"
map_file="docs/contracts/${SPEC_ID}-api-frontend-map.md"
design_file="docs/design/${SPEC_ID}-design.md"
plan_file="docs/plans/${SPEC_ID}-plan.md"

if [[ ! -f "$spec_file" || ! -f "$map_file" || ! -f "$design_file" || ! -f "$plan_file" ]]; then
  bash .agents/skills/vibe-task-pack/scripts/new-task-pack.sh \
    --spec-id "$SPEC_ID" \
    --task-type "$TASK_TYPE" \
    --current-role "$CURRENT_ROLE" \
    --next-role "$NEXT_ROLE"
fi

sed -i.bak -E "s|^-[[:space:]]+WORK_TYPE:[[:space:]]*.*$|- WORK_TYPE: ${WORK_TYPE}|" docs/status/current-task.md || true
rm -f docs/status/current-task.md.bak

bash .agents/skills/vibe-quality-gates/scripts/run-local-gates.sh

echo "[vibe-governance] next handoff: ${CURRENT_ROLE} -> ${NEXT_ROLE}"
