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

cat > docs/status/blackbox-session.md <<'MD'
# Blackbox Session
- GOAL: test
- SPEC_ID: SPEC-0002-test
- TASK_TYPE: feature
- WORK_TYPE: full
- CURRENT_GATE: Gate 0
- CURRENT_ROLE: Founder
- NEXT_ROLE: PM
- APPROVAL_GATE_0: approved
- APPROVAL_GATE_2: pending
- APPROVAL_GATE_3: pending
- APPROVAL_RELEASE: pending
- STATUS: gate0_approved
- LAST_ACTION: approve:gate0
- LAST_UPDATED: 2026-03-05T00:00:00Z
MD

PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-task-pack/scripts/new-task-pack.sh \
  --spec-id SPEC-0002-test \
  --task-type feature \
  --current-role Dev \
  --next-role QA > "$tmp_dir/task-pack.out"

grep -q '\[step-report\]' "$tmp_dir/task-pack.out" || {
  echo "new-task-pack output must contain step-report"
  exit 1
}
grep -q '^- NEXT_ACTION: ' "$tmp_dir/task-pack.out" || {
  echo "new-task-pack step-report must include NEXT_ACTION"
  exit 1
}

[[ -f "docs/specs/SPEC-0002-test.md" ]] || { echo "missing generated spec"; exit 1; }
[[ -f "docs/contracts/SPEC-0002-test-api-frontend-map.md" ]] || { echo "missing generated map"; exit 1; }

handoff_file="$(sed -n -E 's/^- HANDOFF_LINK:[[:space:]]*(.*)$/\1/p' docs/status/current-task.md | tail -n1)"
[[ -n "$handoff_file" && -f "$handoff_file" ]] || { echo "missing generated handoff file"; exit 1; }

mkdir -p src docs/specs docs/contracts
cat > src/app.ts <<'TS'
export const ok = true;
TS

cp docs/specs/TEMPLATE-feature-spec.md docs/specs/SPEC-0002-test.md
cp docs/contracts/TEMPLATE-api-frontend-map.md docs/contracts/SPEC-0002-test-api-frontend-map.md

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
- HANDOFF_LINK: docs/status/handoffs/spec-0002-test-dev-to-qa.md
- API_SURFACE_CHANGED: yes
- FRONTEND_SURFACE_CHANGED: yes
- CONTRACT_SYNC_STATUS: pending
- TEST_COMMANDS: npm test
- TEST_RESULT: unit=pass;integration=pass;e2e=pass
- UPDATED_AT: 2026-03-05T00:00:00Z
- NEXT_ACTION: handoff to QA
MD

cp docs/status/TEMPLATE-role-handoff.md docs/status/handoffs/spec-0002-test-dev-to-qa.md

changed_files=$'src/app.ts\ndocs/specs/SPEC-0002-test.md\ndocs/contracts/SPEC-0002-test-api-frontend-map.md\ndocs/status/current-task.md\ndocs/status/handoffs/spec-0002-test-dev-to-qa.md\ndocs/design/0001-architecture-overview.md\ndocs/plans/0001-implementation-plan.md\ndocs/release/CHANGELOG.md\ndocs/release/RELEASE_NOTES.md'

if PATH="$mock_bin:/usr/bin:/bin" CHANGED_FILES="$changed_files" bash .agents/skills/vibe-quality-gates/scripts/run-local-gates.sh; then
  echo "expected failure when CONTRACT_SYNC_STATUS is pending"
  exit 1
fi

sed -i.bak -E 's/^- CONTRACT_SYNC_STATUS:.*$/- CONTRACT_SYNC_STATUS: synced/' docs/status/current-task.md
rm -f docs/status/current-task.md.bak

PATH="$mock_bin:/usr/bin:/bin" CHANGED_FILES="$changed_files" bash .agents/skills/vibe-quality-gates/scripts/run-local-gates.sh > "$tmp_dir/local-gates.out"

grep -q '\[step-report\]' "$tmp_dir/local-gates.out" || {
  echo "run-local-gates output must contain step-report"
  exit 1
}
grep -q '^- GATE_STATUS: pass' "$tmp_dir/local-gates.out" || {
  echo "run-local-gates should output pass step-report entries"
  exit 1
}

popd >/dev/null

echo "test_skill_scripts.sh passed"
