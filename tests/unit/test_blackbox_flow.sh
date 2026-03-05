#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BLACKBOX_SCRIPT="$ROOT_DIR/.agents/skills/vibe-governance/scripts/run-blackbox-flow.sh"

[[ -x "$BLACKBOX_SCRIPT" ]] || {
  echo "missing executable blackbox script: $BLACKBOX_SCRIPT"
  exit 1
}

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

work_dir="$tmp_dir/work"
mkdir -p "$work_dir"
cp -R "$ROOT_DIR/bootstrap/assets"/. "$work_dir"/
cp -R "$ROOT_DIR/.agents" "$work_dir"/

mock_bin="$tmp_dir/mock-bin"
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
echo "unsupported mock codex command" >&2
exit 1
MOCK
chmod +x "$mock_bin/codex"

pushd "$work_dir" >/dev/null

PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh prepare \
  --goal "做一个让新用户10分钟内完成首次发布的流程" \
  --task-type feature \
  --work-type full \
  --spec-id SPEC-0099-blackbox > "$tmp_dir/prepare.out"

[[ ! -f docs/status/blackbox-session.md ]] || { echo "prepare must not create blackbox-session.md"; exit 1; }

grep -q '\[blackbox-card\]' "$tmp_dir/prepare.out" || {
  echo "prepare output must contain blackbox card"
  exit 1
}
grep -q '\[step-report\]' "$tmp_dir/prepare.out" || {
  echo "prepare output must contain step-report"
  exit 1
}
for field in STEP_ID STEP_NAME ACTIONS FILES_CREATED FILES_UPDATED COMMANDS_RUN GATE_STATUS RESULT_SUMMARY NEXT_ACTION; do
  grep -q "^- ${field}: " "$tmp_dir/prepare.out" || {
    echo "prepare step-report missing field: $field"
    exit 1
  }
done

PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 0" \
  --goal "做一个让新用户10分钟内完成首次发布的流程" \
  --task-type feature \
  --work-type full \
  --spec-id SPEC-0099-blackbox > "$tmp_dir/approve-gate0.out"

grep -q '\[step-report\]' "$tmp_dir/approve-gate0.out" || {
  echo "approve Gate 0 output must contain step-report"
  exit 1
}

[[ -f docs/status/blackbox-session.md ]] || { echo "missing blackbox-session.md"; exit 1; }

grep -q '^-[[:space:]]*SPEC_ID:[[:space:]]*SPEC-0099-blackbox$' docs/status/blackbox-session.md || {
  echo "SPEC_ID not set in blackbox-session"
  exit 1
}

grep -q '^-[[:space:]]*CURRENT_GATE:[[:space:]]*Gate 0$' docs/status/blackbox-session.md || {
  echo "CURRENT_GATE should be Gate 0 after start"
  exit 1
}

grep -q '^-[[:space:]]*STATUS:[[:space:]]*gate0_approved$' docs/status/blackbox-session.md || {
  echo "session should be gate0_approved after Gate 0 approval"
  exit 1
}

if PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 2" >/dev/null 2>&1; then
  echo "Gate 2 should not be approvable before start"
  exit 1
fi

PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh start > "$tmp_dir/start.out"

grep -q '^-[[:space:]]*CURRENT_GATE:[[:space:]]*Gate 2$' docs/status/current-task.md || {
  echo "current-task CURRENT_GATE should be Gate 2 after start"
  exit 1
}

grep -q '\[blackbox-card\]' "$tmp_dir/start.out" || {
  echo "start output must contain blackbox card"
  exit 1
}
grep -q '\[step-report\]' "$tmp_dir/start.out" || {
  echo "start output must contain step-report"
  exit 1
}
grep -q '^- FILES_CREATED: ' "$tmp_dir/start.out" || {
  echo "start step-report must include FILES_CREATED"
  exit 1
}

PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 2"
grep -q '^-[[:space:]]*CURRENT_GATE:[[:space:]]*Gate 3$' docs/status/current-task.md || {
  echo "current-task CURRENT_GATE should be Gate 3 after Gate 2 approval"
  exit 1
}

PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 3"
grep -q '^-[[:space:]]*CURRENT_GATE:[[:space:]]*Gate 6$' docs/status/current-task.md || {
  echo "current-task CURRENT_GATE should be Gate 6 after Gate 3 approval"
  exit 1
}

grep -q '^-[[:space:]]*STATUS:[[:space:]]*waiting_release_approval$' docs/status/blackbox-session.md || {
  echo "session should wait release approval after Gate 3"
  exit 1
}

PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "发布"
grep -q '^-[[:space:]]*STATUS:[[:space:]]*released$' docs/status/blackbox-session.md || {
  echo "session should be released after release approval"
  exit 1
}

grep -q '^-[[:space:]]*APPROVAL_RELEASE:[[:space:]]*approved$' docs/status/blackbox-session.md || {
  echo "release approval should be approved"
  exit 1
}

PATH="$mock_bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh status > "$tmp_dir/status.out"
grep -q '\[blackbox-card\]' "$tmp_dir/status.out" || {
  echo "status output must contain blackbox card"
  exit 1
}
grep -q '\[step-report\]' "$tmp_dir/status.out" || {
  echo "status output must contain step-report"
  exit 1
}

grep -q 'released' "$tmp_dir/status.out" || {
  echo "status output should mention released"
  exit 1
}

popd >/dev/null

echo "test_blackbox_flow.sh passed"
