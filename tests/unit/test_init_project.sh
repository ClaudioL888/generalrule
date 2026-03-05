#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INIT_SCRIPT="$ROOT_DIR/scripts/init-project.sh"

if [[ ! -x "$INIT_SCRIPT" ]]; then
  echo "missing executable script: $INIT_SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

seed_ok="$tmp_dir/seed-ok.md"
cat > "$seed_ok" <<'SEED'
# Seed

<!-- START_SEED_KV -->
- project_code: generalrule-demo
- goal_id: goal-mvp-0001
- work_type: full
- phase: MVP
- problem_statement: 用户无法快速完成首次关键动作
- target_persona: 独立开发者
- core_use_case: 10分钟内完成首次发布
- task_1: 建立最小可运行路径
- acceptance_1: 核心流程一次通过
- test_point_1: 核心命令无错误
- role: Dev
- current_gate: Gate 4
- test_commands: npm test && npm run lint
- test_result: unit=pass;integration=pass;e2e=pass
- next_action: handoff to QA
<!-- END_SEED_KV -->
SEED

output_dir="$tmp_dir/project"
"$INIT_SCRIPT" --output "$output_dir" --seed "$seed_ok"

required_files=(
  ".codex/config.toml"
  ".codex/rules/default.rules"
  "AGENTS.md"
  "docs/prd/0001-problem-statement.md"
  "docs/design/0001-architecture-overview.md"
  "docs/adr/0001-initial-decision.md"
  "docs/plans/0001-implementation-plan.md"
  "docs/test-plan/0001-test-plan.md"
  "docs/release/CHANGELOG.md"
  "docs/release/RELEASE_NOTES.md"
  "docs/status/current-task.md"
  "scripts/ci/check-codex-capabilities.sh"
  "scripts/ci/validate-governance.sh"
  "scripts/ci/validate-doc-links.sh"
  ".github/PULL_REQUEST_TEMPLATE.md"
  ".github/workflows/ci.yml"
)

for f in "${required_files[@]}"; do
  if [[ ! -f "$output_dir/$f" ]]; then
    echo "missing generated file: $output_dir/$f"
    exit 1
  fi
done

if [[ ! -x "$output_dir/scripts/ci/check-codex-capabilities.sh" ]]; then
  echo "generated capability script is not executable"
  exit 1
fi

for key in TASK_ID ROLE WORK_TYPE CURRENT_GATE TEST_COMMANDS TEST_RESULT UPDATED_AT NEXT_ACTION; do
  grep -q "^- $key: " "$output_dir/docs/status/current-task.md" || {
    echo "missing key in current-task.md: $key"
    exit 1
  }
done
if grep -q 'TODO(test_result)' "$output_dir/docs/status/current-task.md"; then
  echo "current-task required fields should not fallback to TODO"
  exit 1
fi

pr_file="$tmp_dir/pr.md"
cat > "$pr_file" <<'PR'
## Governance Metadata
- WORK_TYPE: full
- PRD_LINK: docs/prd/0001-problem-statement.md
- DESIGN_LINK: docs/design/0001-architecture-overview.md
- PLAN_LINK: docs/plans/0001-implementation-plan.md
- TASK_STATE_LINK: docs/status/current-task.md
- TEST_RESULTS: unit=pass;integration=pass;e2e=pass
- APPROVAL_EXECUTION: approved
- APPROVAL_DEPENDENCY: approved
- APPROVAL_PERMISSION: approved
PR

changed_files=$'docs/prd/0001-problem-statement.md\ndocs/design/0001-architecture-overview.md\ndocs/plans/0001-implementation-plan.md\ndocs/status/current-task.md'
(
  cd "$output_dir"
  mock_codex_bin="$tmp_dir/mock-codex"
  mkdir -p "$mock_codex_bin"
  cat > "$mock_codex_bin/codex" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == "execpolicy" && "$2" == "check" && "$3" == "--help" ]]; then
  echo "Usage: codex execpolicy check [OPTIONS] --rules <PATH> <COMMAND>..."
  exit 0
fi
if [[ "$1" == "execpolicy" && "$2" == "check" ]]; then
  echo '{"decision":"allow"}'
  exit 0
fi
exit 1
MOCK
  chmod +x "$mock_codex_bin/codex"
  PATH="$mock_codex_bin:/usr/bin:/bin" bash scripts/ci/check-codex-capabilities.sh
  CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_file" bash scripts/ci/validate-governance.sh
  DOCS_ROOT=docs bash scripts/ci/validate-doc-links.sh
)

if "$INIT_SCRIPT" --output "$output_dir" --seed "$seed_ok" >/dev/null 2>&1; then
  echo "expected failure when output directory is non-empty without --force"
  exit 1
fi

"$INIT_SCRIPT" --output "$output_dir" --seed "$seed_ok" --force

seed_bad="$tmp_dir/seed-bad.md"
cat > "$seed_bad" <<'SEED'
# Bad Seed

<!-- START_SEED_KV -->
- project_code: broken
- work_type: full
- phase: MVP
<!-- END_SEED_KV -->
SEED

if "$INIT_SCRIPT" --output "$tmp_dir/bad-output" --seed "$seed_bad" >/dev/null 2>&1; then
  echo "expected failure when required keys are missing"
  exit 1
fi

if rg -n "templates/|example/repo-skeleton" "$ROOT_DIR/README.md" "$ROOT_DIR/tests" \
  --glob '!tests/unit/test_init_project.sh' >/dev/null 2>&1; then
  echo "README/tests must not reference templates or example/repo-skeleton"
  exit 1
fi

echo "test_init_project.sh passed"
