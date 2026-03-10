#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/ci/collect-metrics.sh [--output <file> | --stdout]
USAGE
}

OUTPUT_FILE=""
STDOUT_MODE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_FILE="${2:-}"
      shift 2
      ;;
    --stdout)
      STDOUT_MODE=1
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

if [[ -n "$OUTPUT_FILE" && "$STDOUT_MODE" == "1" ]]; then
  echo "--output and --stdout cannot be used together" >&2
  exit 1
fi

if [[ -z "$OUTPUT_FILE" && "$STDOUT_MODE" == "0" ]]; then
  OUTPUT_FILE="docs/status/$(date -u +%Y-%m-%d)-metrics-weekly.md"
fi

since_date() {
  if date -u -d '7 days ago' +%Y-%m-%d >/dev/null 2>&1; then
    date -u -d '7 days ago' +%Y-%m-%d
  else
    date -u -v-7d +%Y-%m-%d
  fi
}

SINCE="$(since_date)"
COMMITS_LAST_7D="$(git log --since="$SINCE" --pretty=oneline 2>/dev/null | wc -l | tr -d ' ')"
REWORK_COMMITS="$(git log --since="$SINCE" --pretty='%s' 2>/dev/null | grep -Eic 'fix|hotfix|rework|revert' || true)"
HOTFIX_COMMITS="$(git log --since="$SINCE" --pretty='%s' 2>/dev/null | grep -Eic 'hotfix' || true)"
CI_FAILURE_RATE="${CI_FAILURE_RATE:-manual}"
CHANGE_FAILURE_RATE="${CHANGE_FAILURE_RATE:-manual}"
DEPLOY_FREQUENCY="${DEPLOY_FREQUENCY:-manual}"
RESTORE_TIME="${RESTORE_TIME:-manual}"
LEAD_TIME="${LEAD_TIME:-manual}"
AARRR_FOCUS="${AARRR_FOCUS:-manual}"
METRICS_NOTE="${METRICS_NOTE:-update with current sprint context}"

report() {
  cat <<REPORT
---
artifact_type: metrics-weekly
owner_role: Release-Ops
status: draft
linked_goal_id: manual
non_goals:
  - "替代月度复盘"
acceptance_metrics:
  - "每周至少更新一次工程指标"
risks:
  - "指标缺失导致流程改进失焦"
approvals_required:
  - founder
last_updated: "$(date -u +%Y-%m-%d)"
---

# Weekly Metrics Snapshot $(date -u +%Y-%m-%d)

## DORA

- Lead Time: ${LEAD_TIME}
- Deploy Frequency: ${DEPLOY_FREQUENCY}
- Change Failure Rate: ${CHANGE_FAILURE_RATE}
- Restore Time: ${RESTORE_TIME}

## Engineering

- Commits Last 7 Days: ${COMMITS_LAST_7D}
- CI Failure Rate: ${CI_FAILURE_RATE}
- Rework Ratio: ${REWORK_COMMITS}
- Hotfix Ratio: ${HOTFIX_COMMITS}

## Product

- AARRR Focus: ${AARRR_FOCUS}
- Notes: ${METRICS_NOTE}
REPORT
}

if [[ "$STDOUT_MODE" == "1" ]]; then
  report
  exit 0
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"
report > "$OUTPUT_FILE"
echo "metrics snapshot written: $OUTPUT_FILE"
