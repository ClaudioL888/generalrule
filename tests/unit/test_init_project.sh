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
- spec_id: SPEC-0001-core-flow
- task_type: feature
- task_1: 建立最小可运行路径
- acceptance_1: 核心流程一次通过
- test_point_1: 核心命令无错误
- role: Dev
- current_role: Dev
- next_role: QA
- handoff_link: docs/status/TEMPLATE-role-handoff.md
- api_surface_changed: yes
- frontend_surface_changed: yes
- contract_sync_status: synced
- current_gate: Gate 6
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
  ".agents/skills/vibe-governance/SKILL.md"
  ".agents/skills/vibe-governance/agents/openai.yaml"
  ".agents/skills/vibe-governance/scripts/run-full-loop.sh"
  ".agents/skills/vibe-governance/scripts/run-blackbox-flow.sh"
  ".agents/skills/vibe-task-pack/SKILL.md"
  ".agents/skills/vibe-task-pack/agents/openai.yaml"
  ".agents/skills/vibe-task-pack/scripts/new-task-pack.sh"
  ".agents/skills/vibe-quality-gates/SKILL.md"
  ".agents/skills/vibe-quality-gates/agents/openai.yaml"
  ".agents/skills/vibe-quality-gates/scripts/run-local-gates.sh"
  "AGENTS.md"
  "docs/prd/0001-problem-statement.md"
  "docs/design/0001-architecture-overview.md"
  "docs/adr/0001-initial-decision.md"
  "docs/governance/BRANCH_PROTECTION.md"
  "docs/governance/ROLE_ROUTING.md"
  "docs/plans/0001-implementation-plan.md"
  "docs/test-plan/0001-test-plan.md"
  "docs/specs/TEMPLATE-feature-spec.md"
  "docs/design/TEMPLATE-feature-design.md"
  "docs/plans/TEMPLATE-feature-plan.md"
  "docs/contracts/TEMPLATE-api-frontend-map.md"
  "docs/runbooks/incident-playbook.md"
  "docs/runbooks/backup-restore.md"
  "docs/runbooks/oncall-checklist.md"
  "docs/metrics/TEMPLATE-dora-aarrr.md"
  "docs/status/TEMPLATE-weekly-maintenance.md"
  "docs/status/TEMPLATE-monthly-maintenance.md"
  "docs/status/TEMPLATE-role-handoff.md"
  "docs/status/TEMPLATE-blackbox-session.md"
  "docs/status/TEMPLATE-brainstorming.md"
  "docs/status/TEMPLATE-spec-quality.md"
  "docs/release/CHANGELOG.md"
  "docs/release/RELEASE_NOTES.md"
  "docs/status/current-task.md"
  ".github/CODEOWNERS"
  ".githooks/pre-push"
  "scripts/ci/check-codex-capabilities.sh"
  "scripts/ci/validate-spec-pack.sh"
  "scripts/ci/validate-spec-quality.sh"
  "scripts/ci/validate-citation-quality.sh"
  "scripts/ci/validate-role-flow.sh"
  "scripts/ci/validate-api-frontend-sync.sh"
  "scripts/ci/validate-permissions-gate.sh"
  "scripts/ci/validate-security-gate.sh"
  "scripts/ci/validate-release-readiness.sh"
  "scripts/ci/validate-observability-gate.sh"
  "scripts/ci/validate-governance.sh"
  "scripts/ci/validate-doc-links.sh"
  "scripts/dev/install-hooks.sh"
  "scripts/dev/install-spec-workflow.sh"
  "scripts/dev/run-spec-workflow-review.sh"
  ".github/PULL_REQUEST_TEMPLATE.md"
  ".github/workflows/ci.yml"
  ".github/workflows/security.yml"
  ".github/workflows/release.yml"
  ".github/workflows/scheduled-maintenance.yml"
)

for f in "${required_files[@]}"; do
  if [[ ! -f "$output_dir/$f" ]]; then
    echo "missing generated file: $output_dir/$f"
    exit 1
  fi
done

for script_path in \
  "scripts/ci/check-codex-capabilities.sh" \
  "scripts/ci/validate-spec-pack.sh" \
  "scripts/ci/validate-spec-quality.sh" \
  "scripts/ci/validate-citation-quality.sh" \
  "scripts/ci/validate-role-flow.sh" \
  "scripts/ci/validate-api-frontend-sync.sh" \
  "scripts/ci/validate-permissions-gate.sh" \
  "scripts/ci/validate-security-gate.sh" \
  "scripts/ci/validate-release-readiness.sh" \
  "scripts/ci/validate-observability-gate.sh" \
  "scripts/ci/validate-governance.sh" \
  "scripts/ci/validate-doc-links.sh" \
  "scripts/dev/install-hooks.sh" \
  "scripts/dev/install-spec-workflow.sh" \
  "scripts/dev/run-spec-workflow-review.sh" \
  ".agents/skills/vibe-governance/scripts/run-full-loop.sh" \
  ".agents/skills/vibe-governance/scripts/run-blackbox-flow.sh" \
  ".agents/skills/vibe-task-pack/scripts/new-task-pack.sh" \
  ".agents/skills/vibe-quality-gates/scripts/run-local-gates.sh"; do
  if [[ ! -x "$output_dir/$script_path" ]]; then
    echo "generated script is not executable: $output_dir/$script_path"
    exit 1
  fi
done

if [[ ! -x "$output_dir/.githooks/pre-push" ]]; then
  echo "generated hook is not executable: $output_dir/.githooks/pre-push"
  exit 1
fi

for key in \
  TASK_ID SPEC_ID TASK_TYPE ROLE WORK_TYPE CURRENT_GATE CURRENT_ROLE NEXT_ROLE HANDOFF_LINK \
  DESIGN_LINK PLAN_LINK DESIGN_SYNC_STATUS PLAN_SYNC_STATUS SPEC_QUALITY_STATUS SPEC_WORKFLOW_STATUS SPEC_WORKFLOW_LINK \
  API_SURFACE_CHANGED FRONTEND_SURFACE_CHANGED CONTRACT_SYNC_STATUS BRAINSTORMING_STATUS BRAINSTORMING_LINK \
  TEST_COMMANDS TEST_RESULT UPDATED_AT NEXT_ACTION; do
  grep -q "^- $key: " "$output_dir/docs/status/current-task.md" || {
    echo "missing key in current-task.md: $key"
    exit 1
  }
done
if grep -q 'TODO(test_result)' "$output_dir/docs/status/current-task.md"; then
  echo "current-task required fields should not fallback to TODO"
  exit 1
fi

cp "$output_dir/docs/specs/TEMPLATE-feature-spec.md" "$output_dir/docs/specs/SPEC-0001-core-flow.md"
cp "$output_dir/docs/contracts/TEMPLATE-api-frontend-map.md" "$output_dir/docs/contracts/SPEC-0001-core-flow-api-frontend-map.md"
cp "$output_dir/docs/design/TEMPLATE-feature-design.md" "$output_dir/docs/design/SPEC-0001-core-flow-design.md"
cp "$output_dir/docs/plans/TEMPLATE-feature-plan.md" "$output_dir/docs/plans/SPEC-0001-core-flow-plan.md"
sed -i.bak \
  -e 's|TODO(citation_source_1)|https://docs.example.com/problem|' \
  -e 's|TODO(citation_note_1)|official problem statement source|' \
  -e 's|TODO(citation_source_2)|docs/status/brainstorming/SPEC-0001-core-flow.md|' \
  -e 's|TODO(citation_note_2)|internal discovery context|' \
  "$output_dir/docs/prd/0001-problem-statement.md"
rm -f "$output_dir/docs/prd/0001-problem-statement.md.bak"
sed -i.bak \
  -e 's|TODO(citation_source_1)|https://docs.example.com/spec|' \
  -e 's|TODO(citation_note_1)|official feature contract|' \
  -e 's|TODO(citation_source_2)|docs/prd/0001-problem-statement.md|' \
  -e 's|TODO(citation_note_2)|feature traces to PRD|' \
  "$output_dir/docs/specs/SPEC-0001-core-flow.md"
rm -f "$output_dir/docs/specs/SPEC-0001-core-flow.md.bak"
sed -i.bak \
  -e 's|TODO(citation_source_1)|https://docs.example.com/design|' \
  -e 's|TODO(citation_note_1)|official architecture guidance|' \
  -e 's|TODO(citation_source_2)|docs/specs/SPEC-0001-core-flow.md|' \
  -e 's|TODO(citation_note_2)|design traces to spec|' \
  "$output_dir/docs/design/SPEC-0001-core-flow-design.md"
rm -f "$output_dir/docs/design/SPEC-0001-core-flow-design.md.bak"
sed -i.bak -E 's/^- DESIGN_SYNC_STATUS:.*$/- DESIGN_SYNC_STATUS: synced/' "$output_dir/docs/status/current-task.md"
rm -f "$output_dir/docs/status/current-task.md.bak"
sed -i.bak -E 's/^- PLAN_SYNC_STATUS:.*$/- PLAN_SYNC_STATUS: synced/' "$output_dir/docs/status/current-task.md"
rm -f "$output_dir/docs/status/current-task.md.bak"
sed -i.bak -E 's/^- SPEC_QUALITY_STATUS:.*$/- SPEC_QUALITY_STATUS: approved/' "$output_dir/docs/status/current-task.md"
rm -f "$output_dir/docs/status/current-task.md.bak"
sed -i.bak -E 's/^- SPEC_WORKFLOW_STATUS:.*$/- SPEC_WORKFLOW_STATUS: unavailable/' "$output_dir/docs/status/current-task.md"
rm -f "$output_dir/docs/status/current-task.md.bak"
mkdir -p "$output_dir/docs/status/spec-quality"
cat > "$output_dir/docs/status/spec-quality/spec-0001-core-flow.md" <<'MD'
# Spec Quality Review SPEC-0001-core-flow

## 1. 审查上下文
- SPEC_ID: SPEC-0001-core-flow
- 审查方式：manual fallback
- 审查结论：approved
- MCP 状态：unavailable

## 2. 关键发现
- 歧义点：none
- 缺失项：none
- 契约风险：low

## 3. 处置结论
- 建议动作：proceed
- 是否允许进入 Gate 0 / Gate 2：yes
- 降级原因（如有）：spec-workflow MCP unavailable in test environment
MD

pr_file="$tmp_dir/pr.md"
cat > "$pr_file" <<'PR'
## Governance Metadata
- WORK_TYPE: full
- TASK_TYPE: feature
- PRD_LINK: docs/prd/0001-problem-statement.md
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- SPEC_LINK: docs/specs/SPEC-0001-core-flow.md
- API_FRONTEND_MAP_LINK: docs/contracts/SPEC-0001-core-flow-api-frontend-map.md
- ROLE_HANDOFF_LINK: docs/status/TEMPLATE-role-handoff.md
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- CONTRACT_SYNC_STATUS: synced
- TASK_STATE_LINK: docs/status/current-task.md
- TEST_RESULTS: unit=pass;integration=pass;e2e=pass
- APPROVAL_EXECUTION: approved
- APPROVAL_DEPENDENCY: approved
- APPROVAL_PERMISSION: approved
- CODEOWNER_REVIEW: approved
- SECURITY_REVIEW: approved
- RELEASE_REVIEW: approved
PR

changed_files=$'src/app.ts\ndocs/release/CHANGELOG.md\ndocs/release/RELEASE_NOTES.md\ndocs/status/current-task.md\ndocs/status/TEMPLATE-role-handoff.md\ndocs/specs/SPEC-0001-core-flow.md\ndocs/contracts/SPEC-0001-core-flow-api-frontend-map.md\ndocs/prd/0001-problem-statement.md\ndocs/design/SPEC-0001-core-flow-design.md\ndocs/plans/SPEC-0001-core-flow-plan.md'
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
  CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_file" bash scripts/ci/validate-spec-pack.sh
  CHANGED_FILES="$changed_files" bash scripts/ci/validate-spec-quality.sh
  CHANGED_FILES="$changed_files" bash scripts/ci/validate-citation-quality.sh
  CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_file" bash scripts/ci/validate-role-flow.sh
  CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_file" bash scripts/ci/validate-api-frontend-sync.sh
  PR_BODY_FILE="$pr_file" bash scripts/ci/validate-permissions-gate.sh
  CHANGED_FILES="$changed_files" bash scripts/ci/validate-security-gate.sh
  CHANGED_FILES="$changed_files" bash scripts/ci/validate-release-readiness.sh
  OBS_ENFORCEMENT=warn bash scripts/ci/validate-observability-gate.sh
  CHANGED_FILES="$changed_files" PR_BODY_FILE="$pr_file" bash scripts/ci/validate-governance.sh
  DOCS_ROOT=docs bash scripts/ci/validate-doc-links.sh
  CHANGED_FILES="$changed_files" PATH="$mock_codex_bin:/usr/bin:/bin" bash .agents/skills/vibe-quality-gates/scripts/run-local-gates.sh
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
