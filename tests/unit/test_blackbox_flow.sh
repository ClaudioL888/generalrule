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

cat > "$work_dir/.codex/bin/spec-workflow.sh" <<'MOCKSW'
#!/usr/bin/env bash
cat >/dev/null &
printf '%s\n' '{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2025-03-26","serverInfo":{"name":"spec-workflow-mcp","version":"2.2.5"},"capabilities":{"tools":{},"prompts":{"listChanged":true}}}}'
printf '%s\n' '{"jsonrpc":"2.0","id":2,"result":{"tools":[{"name":"spec-workflow-guide"},{"name":"spec-status"}]}}'
printf '%s\n' '{"jsonrpc":"2.0","id":3,"result":{"prompts":[{"name":"create-spec"},{"name":"spec-status"}]}}'
printf '%s\n' '{"jsonrpc":"2.0","id":4,"result":{"message":"guide loaded","nextSteps":["Requirements","Design","Tasks"]}}'
sleep 10
MOCKSW
chmod +x "$work_dir/.codex/bin/spec-workflow.sh"

pushd "$work_dir" >/dev/null

PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh start \
  --goal "做一个让新用户10分钟内完成首次发布的流程" \
  --task-type feature \
  --work-type full \
  --spec-id SPEC-0099-blackbox > "$tmp_dir/start.out"

[[ -f docs/status/blackbox-session.md ]] || { echo "missing blackbox-session.md"; exit 1; }

grep -q '^-[[:space:]]*SPEC_ID:[[:space:]]*SPEC-0099-blackbox$' docs/status/blackbox-session.md || {
  echo "SPEC_ID not set in blackbox-session"
  exit 1
}

grep -q '^-[[:space:]]*CURRENT_GATE:[[:space:]]*Gate 0$' docs/status/blackbox-session.md || {
  echo "CURRENT_GATE should be Gate 0 after start"
  exit 1
}

grep -q '^-[[:space:]]*CURRENT_GATE:[[:space:]]*Gate 0$' docs/status/current-task.md || {
  echo "current-task CURRENT_GATE should be Gate 0 after start"
  exit 1
}

[[ -f docs/design/SPEC-0099-blackbox-design.md ]] || {
  echo "missing generated design file after start"
  exit 1
}

[[ -f docs/plans/SPEC-0099-blackbox-plan.md ]] || {
  echo "missing generated plan file after start"
  exit 1
}

grep -q '^-[[:space:]]*BRAINSTORMING_STATUS:[[:space:]]*pending$' docs/status/current-task.md || {
  echo "BRAINSTORMING_STATUS should be pending after start"
  exit 1
}

grep -q '^-[[:space:]]*DESIGN_SYNC_STATUS:[[:space:]]*pending$' docs/status/current-task.md || {
  echo "DESIGN_SYNC_STATUS should be pending after start"
  exit 1
}

grep -q '^-[[:space:]]*PLAN_SYNC_STATUS:[[:space:]]*pending$' docs/status/current-task.md || {
  echo "PLAN_SYNC_STATUS should be pending after start"
  exit 1
}

grep -q '^-[[:space:]]*SPEC_QUALITY_STATUS:[[:space:]]*pending$' docs/status/current-task.md || {
  echo "SPEC_QUALITY_STATUS should be pending after start"
  exit 1
}

grep -q '^-[[:space:]]*SPEC_WORKFLOW_STATUS:[[:space:]]*pending$' docs/status/current-task.md || {
  echo "SPEC_WORKFLOW_STATUS should be pending after start"
  exit 1
}

grep -q '\[blackbox-card\]' "$tmp_dir/start.out" || {
  echo "start output must contain blackbox card"
  exit 1
}

if PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 0"; then
  echo "Gate 0 approval should fail before brainstorming"
  exit 1
fi

brainstorm_note="$(sed -n -E 's/^-[[:space:]]*BRAINSTORMING_LINK:[[:space:]]*(.*)$/\1/p' docs/status/current-task.md | tail -n1)"
[[ -n "$brainstorm_note" && -f "$brainstorm_note" ]] || {
  echo "missing brainstorming note after start"
  exit 1
}

PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh brainstorm --note "$brainstorm_note"
grep -q '^-[[:space:]]*BRAINSTORMING_STATUS:[[:space:]]*done$' docs/status/current-task.md || {
  echo "BRAINSTORMING_STATUS should be done after brainstorm command"
  exit 1
}

if PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 0"; then
  echo "Gate 0 approval should fail before design sync"
  exit 1
fi

spec_quality_note="$(sed -n -E 's/^-[[:space:]]*SPEC_WORKFLOW_LINK:[[:space:]]*(.*)$/\1/p' docs/status/current-task.md | tail -n1)"
[[ -n "$spec_quality_note" && -f "$spec_quality_note" ]] || {
  echo "missing spec quality note after start"
  exit 1
}

PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh spec-quality \
  --auto \
  --status approved \
  --note "$spec_quality_note"

grep -q '^-[[:space:]]*SPEC_QUALITY_STATUS:[[:space:]]*approved$' docs/status/current-task.md || {
  echo "SPEC_QUALITY_STATUS should be approved after spec-quality command"
  exit 1
}

grep -q '^-[[:space:]]*SPEC_WORKFLOW_STATUS:[[:space:]]*passed$' docs/status/current-task.md || {
  echo "SPEC_WORKFLOW_STATUS should be passed after spec-quality command"
  exit 1
}

grep -q '^-[[:space:]]*Tools:[[:space:]]*spec-workflow-guide, spec-status$' "$spec_quality_note" || {
  echo "spec quality note should include tool summary from spec-workflow review"
  exit 1
}

sed -i.bak -E 's/^- DESIGN_SYNC_STATUS:.*$/- DESIGN_SYNC_STATUS: synced/' docs/status/current-task.md
rm -f docs/status/current-task.md.bak

PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 0"
grep -q '^-[[:space:]]*CURRENT_GATE:[[:space:]]*Gate 2$' docs/status/current-task.md || {
  echo "current-task CURRENT_GATE should be Gate 2 after Gate 0 approval"
  exit 1
}

if PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 2"; then
  echo "Gate 2 approval should fail before plan sync"
  exit 1
fi

sed -i.bak -E 's/^- PLAN_SYNC_STATUS:.*$/- PLAN_SYNC_STATUS: synced/' docs/status/current-task.md
rm -f docs/status/current-task.md.bak

PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 2"
grep -q '^-[[:space:]]*CURRENT_GATE:[[:space:]]*Gate 3$' docs/status/current-task.md || {
  echo "current-task CURRENT_GATE should be Gate 3 after Gate 2 approval"
  exit 1
}

PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 3"
grep -q '^-[[:space:]]*CURRENT_GATE:[[:space:]]*Gate 6$' docs/status/current-task.md || {
  echo "current-task CURRENT_GATE should be Gate 6 after Gate 3 approval"
  exit 1
}

grep -q '^-[[:space:]]*STATUS:[[:space:]]*waiting_release_approval$' docs/status/blackbox-session.md || {
  echo "session should wait release approval after Gate 3"
  exit 1
}

PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "发布"
grep -q '^-[[:space:]]*STATUS:[[:space:]]*released$' docs/status/blackbox-session.md || {
  echo "session should be released after release approval"
  exit 1
}

grep -q '^-[[:space:]]*APPROVAL_RELEASE:[[:space:]]*approved$' docs/status/blackbox-session.md || {
  echo "release approval should be approved"
  exit 1
}

PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh status > "$tmp_dir/status.out"
grep -q '\[blackbox-card\]' "$tmp_dir/status.out" || {
  echo "status output must contain blackbox card"
  exit 1
}

grep -q 'released' "$tmp_dir/status.out" || {
  echo "status output should mention released"
  exit 1
}

popd >/dev/null

echo "test_blackbox_flow.sh passed"
