#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_PACK_SCRIPT="$ROOT_DIR/.agents/skills/vibe-task-pack/scripts/new-task-pack.sh"
GATES_SCRIPT="$ROOT_DIR/.agents/skills/vibe-quality-gates/scripts/run-local-gates.sh"

[[ -x "$TASK_PACK_SCRIPT" ]] || { echo "missing executable script: $TASK_PACK_SCRIPT"; exit 1; }
[[ -x "$GATES_SCRIPT" ]] || { echo "missing executable script: $GATES_SCRIPT"; exit 1; }

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

work_dir="$tmp_dir/work"
mkdir -p "$work_dir"
cp -R "$ROOT_DIR/bootstrap/assets"/. "$work_dir"/
cp -R "$ROOT_DIR/.agents" "$work_dir"/

mock_bin="$tmp_dir/mock-codex"
mkdir -p "$mock_bin"
cat > "$mock_bin/codex" <<'MOCK'
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
chmod +x "$mock_bin/codex"

pushd "$work_dir" >/dev/null

if bash .agents/skills/vibe-task-pack/scripts/new-task-pack.sh --spec-id SPEC-0002-test --task-type invalid --current-role Dev --next-role QA; then
  echo "expected failure for invalid task type"
  exit 1
fi

bash .agents/skills/vibe-task-pack/scripts/new-task-pack.sh \
  --spec-id SPEC-0002-test \
  --task-type feature \
  --current-role Dev \
  --next-role QA

[[ -f "docs/specs/SPEC-0002-test.md" ]] || { echo "missing generated spec"; exit 1; }
[[ -f "docs/contracts/SPEC-0002-test-api-frontend-map.md" ]] || { echo "missing generated map"; exit 1; }
[[ -f "docs/design/SPEC-0002-test-design.md" ]] || { echo "missing generated design"; exit 1; }
[[ -f "docs/plans/SPEC-0002-test-plan.md" ]] || { echo "missing generated plan"; exit 1; }

handoff_file="$(sed -n -E 's/^- HANDOFF_LINK:[[:space:]]*(.*)$/\1/p' docs/status/current-task.md | tail -n1)"
[[ -n "$handoff_file" && -f "$handoff_file" ]] || { echo "missing generated handoff file"; exit 1; }

mkdir -p src docs/specs docs/contracts
cat > src/app.ts <<'TS'
export const ok = true;
TS

cp docs/specs/TEMPLATE-feature-spec.md docs/specs/SPEC-0002-test.md
cp docs/contracts/TEMPLATE-api-frontend-map.md docs/contracts/SPEC-0002-test-api-frontend-map.md
mkdir -p docs/status/spec-quality
cat > docs/status/spec-quality/spec-0002-test.md <<'MD'
# Spec Quality Review SPEC-0002-test

## 1. Review Context
- SPEC_ID: SPEC-0002-test
- Review method: manual fallback
- Review conclusion: approved
- MCP status: unavailable

## 2. Key Findings
- Ambiguity: none
- Missing item: none
- Contract risk: low

## 3. Decision
- Recommended action: proceed
- Allowed to enter Gate 0 / Gate 2: yes
- Downgrade reason (if any): spec-workflow MCP unavailable in test environment
MD
mkdir -p docs/status/brainstorming
cat > docs/status/brainstorming/SPEC-0002-test.md <<'MD'
# Brainstorming SPEC-0002-test
MD
sed -i.bak \
  -e 's|TODO(citation_source_1)|https://docs.example.com/spec|' \
  -e 's|TODO(citation_note_1)|official product specification|' \
  -e 's|TODO(citation_source_2)|docs/prd/0001-problem-statement.md|' \
  -e 's|TODO(citation_note_2)|approved problem framing|' \
  docs/specs/SPEC-0002-test.md
rm -f docs/specs/SPEC-0002-test.md.bak
sed -i.bak \
  -e 's|TODO(citation_source_1)|https://docs.example.com/architecture|' \
  -e 's|TODO(citation_note_1)|official architecture constraints|' \
  -e 's|TODO(citation_source_2)|docs/specs/SPEC-0002-test.md|' \
  -e 's|TODO(citation_note_2)|design derived from current spec|' \
  docs/design/SPEC-0002-test-design.md
rm -f docs/design/SPEC-0002-test-design.md.bak

cat > docs/status/current-task.md <<'MD'
# Current Task
- TASK_ID: T1
- SPEC_ID: SPEC-0002-test
- TASK_TYPE: feature
- ROLE: Dev
- WORK_TYPE: full
- CURRENT_GATE: Gate 6
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- STANDARDS_PROFILE: feature:full
- CURRENT_ROLE_STANDARDS: docs/standards/coding-standards.md,docs/standards/testing-standards.md,docs/standards/documentation-standards.md
- NEXT_ROLE_STANDARDS: docs/standards/testing-standards.md,docs/standards/documentation-standards.md
- ROLE_DOD_STATUS: pending
- EVIDENCE_STATUS: pending
- DEVIATION_STATUS: none
- DESIGN_LINK: docs/design/SPEC-0002-test-design.md
- PLAN_LINK: docs/plans/SPEC-0002-test-plan.md
- HANDOFF_LINK: docs/status/handoffs/spec-0002-test-dev-to-qa.md
- DESIGN_SYNC_STATUS: synced
- PLAN_SYNC_STATUS: pending
- SPEC_QUALITY_STATUS: approved
- SPEC_WORKFLOW_STATUS: unavailable
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/spec-0002-test.md
- API_SURFACE_CHANGED: yes
- FRONTEND_SURFACE_CHANGED: yes
- CONTRACT_SYNC_STATUS: pending
- EXCEPTION_STATUS: none
- EXCEPTION_LINK: N/A
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
- BRAINSTORMING_STATUS: done
- BRAINSTORMING_LINK: docs/status/brainstorming/SPEC-0002-test.md
- TEST_COMMANDS: npm test
- TEST_RESULT: unit=pass;integration=pass;e2e=pass
- UPDATED_AT: 2026-03-05T00:00:00Z
- NEXT_ACTION: handoff to QA
MD

cat > docs/status/handoffs/spec-0002-test-dev-to-qa.md <<'MD'
# Role Handoff SPEC-0002-test
- TASK_TYPE: feature
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA

## Inputs

- Current role prompt asset: docs/prompts/dev.md
- Next role prompt asset: docs/prompts/qa.md

## Outputs

- Primary artifact link: docs/contracts/SPEC-0002-test-api-frontend-map.md
- Secondary artifact link: docs/status/current-task.md
- Artifact summary: feature slice implemented
- Test Evidence: unit=pass;integration=pass;e2e=pass
- Risk Summary: low

## Applicable Standards

- Current role standards: docs/standards/coding-standards.md,docs/standards/testing-standards.md,docs/standards/documentation-standards.md
- Next role standards: docs/standards/testing-standards.md,docs/standards/documentation-standards.md
- Deviation note: none

## Evidence Summary

- Primary evidence: docs/contracts/SPEC-0002-test-api-frontend-map.md
- Secondary evidence: docs/status/current-task.md
- Test Evidence: unit=pass;integration=pass;e2e=pass
- Risk evidence: low
- Documentation sync evidence: docs/status/current-task.md

## Definition of Done

- [ ] Acceptance criteria met: yes
- [ ] Test points covered: yes

## Handoff To

- Recipient: QA
- Next action: run regression checks
MD

changed_files=$'src/app.ts\ndocs/specs/SPEC-0002-test.md\ndocs/contracts/SPEC-0002-test-api-frontend-map.md\ndocs/design/SPEC-0002-test-design.md\ndocs/plans/SPEC-0002-test-plan.md\ndocs/status/current-task.md\ndocs/status/handoffs/spec-0002-test-dev-to-qa.md\ndocs/release/CHANGELOG.md\ndocs/release/RELEASE_NOTES.md'

if PATH="$mock_bin:/usr/bin:/bin" CHANGED_FILES="$changed_files" bash .agents/skills/vibe-quality-gates/scripts/run-local-gates.sh; then
  echo "expected failure when standards and contract state are pending"
  exit 1
fi

sed -i.bak -E 's/^- CONTRACT_SYNC_STATUS:.*$/- CONTRACT_SYNC_STATUS: synced/' docs/status/current-task.md
rm -f docs/status/current-task.md.bak
sed -i.bak -E 's/^- PLAN_SYNC_STATUS:.*$/- PLAN_SYNC_STATUS: synced/' docs/status/current-task.md
rm -f docs/status/current-task.md.bak
sed -i.bak -E 's/^- ROLE_DOD_STATUS:.*$/- ROLE_DOD_STATUS: met/' docs/status/current-task.md
rm -f docs/status/current-task.md.bak
sed -i.bak -E 's/^- EVIDENCE_STATUS:.*$/- EVIDENCE_STATUS: complete/' docs/status/current-task.md
rm -f docs/status/current-task.md.bak

PATH="$mock_bin:/usr/bin:/bin" CHANGED_FILES="$changed_files" bash .agents/skills/vibe-quality-gates/scripts/run-local-gates.sh

popd >/dev/null

echo "test_skill_scripts.sh passed"
