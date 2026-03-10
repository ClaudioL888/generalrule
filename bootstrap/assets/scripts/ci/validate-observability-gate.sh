#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[observability-gate] $1" >&2
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

if [[ ! -f "docs/metrics/ENGINEERING_METRICS.md" ]]; then
  issues+=("missing docs/metrics/ENGINEERING_METRICS.md")
fi

if [[ ! -d "docs/status" ]]; then
  issues+=("missing docs/status directory")
else
  weekly_count="$(find docs/status -maxdepth 1 -type f -name '*weekly*.md' ! -name 'TEMPLATE-*' | wc -l | tr -d ' ')"
  monthly_count="$(find docs/status -maxdepth 1 -type f -name '*monthly*.md' ! -name 'TEMPLATE-*' | wc -l | tr -d ' ')"
  metrics_weekly_count="$(find docs/status -maxdepth 1 -type f -name '*metrics-weekly*.md' ! -name 'TEMPLATE-*' | wc -l | tr -d ' ')"

  if [[ "$weekly_count" == "0" ]]; then
    issues+=("no weekly maintenance record found in docs/status")
  fi

  if [[ "$monthly_count" == "0" ]]; then
    issues+=("no monthly maintenance record found in docs/status")
  fi

  if [[ "$metrics_weekly_count" == "0" ]]; then
    issues+=("no weekly metrics record found in docs/status")
  fi
fi

if [[ "${#issues[@]}" -eq 0 ]]; then
  echo "[observability-gate] PASS"
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
