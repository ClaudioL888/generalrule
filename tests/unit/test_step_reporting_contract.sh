#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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

assert_step_report_fields() {
  local file="$1"
  grep -q '\[step-report\]' "$file" || { echo "missing [step-report] in $file"; exit 1; }
  for field in STEP_ID STEP_NAME ACTIONS FILES_CREATED FILES_UPDATED COMMANDS_RUN GATE_STATUS RESULT_SUMMARY NEXT_ACTION; do
    grep -q "^- ${field}: " "$file" || { echo "missing field ${field} in $file"; exit 1; }
  done

  while IFS= read -r line; do
    status="${line#- GATE_STATUS: }"
    case "$status" in
      pass|fail|warn|skip)
        ;;
      *)
        echo "invalid GATE_STATUS value: $status"
        exit 1
        ;;
    esac
  done < <(grep '^- GATE_STATUS: ' "$file")
}

pushd "$work_dir" >/dev/null

PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh prepare \
  --goal "验证 step report 契约" \
  --task-type feature \
  --work-type full \
  --spec-id SPEC-0098-report > "$tmp_dir/prepare.out"
assert_step_report_fields "$tmp_dir/prepare.out"

PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 0" \
  --goal "验证 step report 契约" \
  --task-type feature \
  --work-type full \
  --spec-id SPEC-0098-report > "$tmp_dir/approve0.out"
assert_step_report_fields "$tmp_dir/approve0.out"

PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh start > "$tmp_dir/start.out"
assert_step_report_fields "$tmp_dir/start.out"

# Hard-mode script should not fully disable step-report when STEP_REPORT_MODE=off.
STEP_REPORT_MODE=off PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-task-pack/scripts/new-task-pack.sh \
  --spec-id SPEC-0098-report \
  --task-type feature \
  --current-role Dev \
  --next-role QA > "$tmp_dir/task-pack.out"
assert_step_report_fields "$tmp_dir/task-pack.out"

changed_files=$'docs/status/current-task.md'
STEP_REPORT_MODE=off PATH="$mock_bin:/usr/bin:/bin" CHANGED_FILES="$changed_files" bash .agents/skills/vibe-quality-gates/scripts/run-local-gates.sh > "$tmp_dir/local-gates.out"
assert_step_report_fields "$tmp_dir/local-gates.out"

popd >/dev/null

echo "test_step_reporting_contract.sh passed"
