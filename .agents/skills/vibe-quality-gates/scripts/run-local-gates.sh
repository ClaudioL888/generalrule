#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$ROOT_DIR"

if [[ -z "${CHANGED_FILES:-}" ]]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
      upstream_ref="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')"
      base_commit="$(git merge-base HEAD "$upstream_ref")"
      CHANGED_FILES="$(git diff --name-only "$base_commit...HEAD")"
    elif git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
      CHANGED_FILES="$(git diff --name-only HEAD~1...HEAD)"
    else
      CHANGED_FILES="$(git diff --name-only HEAD)"
    fi
  else
    CHANGED_FILES="docs/status/current-task.md"
  fi
fi

export CHANGED_FILES

run_step() {
  local title="$1"
  shift
  echo "[quality-gates] running: $title"
  "$@"
}

run_step "codex capabilities" bash scripts/ci/check-codex-capabilities.sh
run_step "spec pack" env LOCAL_MODE=1 bash scripts/ci/validate-spec-pack.sh
run_step "spec quality" bash scripts/ci/validate-spec-quality.sh
run_step "citation quality" bash scripts/ci/validate-citation-quality.sh
run_step "role flow" env LOCAL_MODE=1 bash scripts/ci/validate-role-flow.sh
run_step "standards binding" env LOCAL_MODE=1 bash scripts/ci/validate-standards-binding.sh
run_step "api/frontend sync" env LOCAL_MODE=1 bash scripts/ci/validate-api-frontend-sync.sh
run_step "exception" env LOCAL_MODE=1 bash scripts/ci/validate-exception-gate.sh
run_step "permissions" env LOCAL_MODE=1 bash scripts/ci/validate-permissions-gate.sh
run_step "security" bash scripts/ci/validate-security-gate.sh
run_step "governance" env LOCAL_MODE=1 bash scripts/ci/validate-governance.sh
run_step "release readiness" bash scripts/ci/validate-release-readiness.sh
run_step "observability" bash scripts/ci/validate-observability-gate.sh
run_step "doc links" bash scripts/ci/validate-doc-links.sh

echo "[quality-gates] PASS"
