#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run-spec-workflow-review.sh --spec-id <SPEC-...> --note <path>
USAGE
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

SPEC_ID=""
NOTE_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec-id)
      SPEC_ID="${2:-}"
      shift 2
      ;;
    --note)
      NOTE_FILE="${2:-}"
      shift 2
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

[[ -n "$SPEC_ID" ]] || { echo "--spec-id is required" >&2; exit 1; }
[[ -n "$NOTE_FILE" ]] || { echo "--note is required" >&2; exit 1; }

mkdir -p "$(dirname "$NOTE_FILE")"

JSON_OUTPUT="$(
node <<'NODE'
const { spawn } = require('child_process');

const cwd = process.cwd();
const child = spawn('bash', ['.codex/bin/spec-workflow.sh', '.'], {
  cwd,
  env: { ...process.env, SPEC_WORKFLOW_HOME: process.env.SPEC_WORKFLOW_HOME || '.spec-workflow-mcp' },
  stdio: ['pipe', 'pipe', 'pipe'],
});

let responses = [];
let stderr = '';
let settled = false;

function finish(obj, code = 0) {
  if (settled) return;
  settled = true;
  try { child.kill('SIGTERM'); } catch {}
  process.stdout.write(JSON.stringify(obj));
  process.exit(code);
}

child.stdout.on('data', (chunk) => {
  const text = chunk.toString();
  for (const line of text.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    try {
      responses.push(JSON.parse(trimmed));
    } catch {}
  }
});

child.stderr.on('data', (chunk) => {
  stderr += chunk.toString();
});

child.on('error', (error) => {
  finish({ ok: false, stage: 'spawn', error: error.message, stderr }, 0);
});

child.on('exit', (code, signal) => {
  if (!settled) {
    finish({ ok: false, stage: 'exit', error: `unexpected exit code=${code} signal=${signal}`, stderr }, 0);
  }
});

function send(msg) {
  child.stdin.write(JSON.stringify(msg) + '\n');
}

setTimeout(() => {
  send({
    jsonrpc: '2.0',
    id: 1,
    method: 'initialize',
    params: {
      protocolVersion: '2025-03-26',
      capabilities: {},
      clientInfo: { name: 'generalrule-spec-review', version: '1.0' },
    },
  });
}, 200);

setTimeout(() => {
  send({ jsonrpc: '2.0', method: 'notifications/initialized', params: {} });
  send({ jsonrpc: '2.0', id: 2, method: 'tools/list', params: {} });
  send({ jsonrpc: '2.0', id: 3, method: 'prompts/list', params: {} });
  send({ jsonrpc: '2.0', id: 4, method: 'tools/call', params: { name: 'spec-workflow-guide', arguments: {} } });
}, 500);

setTimeout(() => {
  const init = responses.find((msg) => msg.id === 1 && msg.result && msg.result.protocolVersion);
  const tools = responses.find((msg) => msg.id === 2 && msg.result && Array.isArray(msg.result.tools));
  const prompts = responses.find((msg) => msg.id === 3 && msg.result && Array.isArray(msg.result.prompts));
  const guide = responses.find((msg) => msg.id === 4 && msg.result);
  if (!init || !tools || !prompts || !guide) {
    finish({
      ok: false,
      stage: 'handshake',
      error: 'missing initialize/tools/prompts/guide response',
      stderr,
      responses,
    }, 0);
    return;
  }
  finish({
    ok: true,
    protocolVersion: init.result.protocolVersion,
    serverInfo: init.result.serverInfo || {},
    tools: tools.result.tools.map((tool) => tool.name),
    prompts: prompts.result.prompts.map((prompt) => prompt.name),
    guideMessage: guide.result.message || '',
    guideNextSteps: Array.isArray(guide.result.nextSteps) ? guide.result.nextSteps : [],
    stderr,
  }, 0);
}, 4000);
NODE
)"

SPEC_WORKFLOW_STATUS="$(python3 - <<'PY' "$JSON_OUTPUT"
import json
import sys
data = json.loads(sys.argv[1])
print("passed" if data.get("ok") else "unavailable")
PY
)"

SERVER_NAME="$(python3 - <<'PY' "$JSON_OUTPUT"
import json
import sys
data = json.loads(sys.argv[1])
print(data.get("serverInfo", {}).get("name", "spec-workflow-mcp"))
PY
)"

SERVER_VERSION="$(python3 - <<'PY' "$JSON_OUTPUT"
import json
import sys
data = json.loads(sys.argv[1])
print(data.get("serverInfo", {}).get("version", "unknown"))
PY
)"

TOOLS_SUMMARY="$(python3 - <<'PY' "$JSON_OUTPUT"
import json
import sys
data = json.loads(sys.argv[1])
print(", ".join(data.get("tools", [])) or "none")
PY
)"

PROMPTS_SUMMARY="$(python3 - <<'PY' "$JSON_OUTPUT"
import json
import sys
data = json.loads(sys.argv[1])
print(", ".join(data.get("prompts", [])) or "none")
PY
)"

GUIDE_SUMMARY="$(python3 - <<'PY' "$JSON_OUTPUT"
import json
import sys
data = json.loads(sys.argv[1])
message = data.get("guideMessage") or ""
steps = data.get("guideNextSteps") or []
summary = message
if steps:
    summary = (summary + " | " if summary else "") + "; ".join(steps[:3])
print(summary or "spec-workflow guide unavailable")
PY
)"

FALLBACK_REASON="$(python3 - <<'PY' "$JSON_OUTPUT"
import json
import sys
data = json.loads(sys.argv[1])
if data.get("ok"):
    print("上游 spec-workflow 可连通，但其公开 tool/prompt 主要提供 workflow 指南、状态和审批，不直接输出 spec 质量评分。最终 approved/degraded 仍由本仓库治理流程决定。")
else:
    err = data.get("error", "unknown error")
    stage = data.get("stage", "unknown stage")
    print(f"spec-workflow {stage} 失败: {err}")
PY
)"

LAST_UPDATED="$(date -u +%Y-%m-%d)"

cat > "$NOTE_FILE" <<EOF
---
artifact_type: spec-quality-review
owner_role: Architect
status: draft
linked_goal_id: "${SPEC_ID}"
non_goals:
  - "替代完整 PRD/Design/Plan"
acceptance_metrics:
  - "Spec 关键歧义已收敛"
risks:
  - "Spec 质量审查缺失导致实现跑偏"
approvals_required:
  - founder
last_updated: "${LAST_UPDATED}"
---

# Spec Quality Review ${SPEC_ID}

## 1. 审查上下文

- SPEC_ID: ${SPEC_ID}
- 审查方式：spec-workflow runtime review
- 审查结论：待由治理流程填写 approved 或 degraded
- MCP 状态：${SPEC_WORKFLOW_STATUS}
- Server: ${SERVER_NAME}@${SERVER_VERSION}

## 2. 上游能力摘要

- Tools: ${TOOLS_SUMMARY}
- Prompts: ${PROMPTS_SUMMARY}
- Guide 摘要：${GUIDE_SUMMARY}

## 3. 处置结论

- 建议动作：结合 brainstorming / design / plan 手动判定 spec 是否可进入下一 Gate
- 是否允许进入 Gate 0 / Gate 2：待由治理流程填写
- 降级原因（如有）：${FALLBACK_REASON}

## 4. 证据与引用

- SOURCE: ${NOTE_FILE} | TYPE: internal | NOTE: spec-workflow runtime review trace
EOF

printf 'SPEC_WORKFLOW_STATUS=%s\n' "$SPEC_WORKFLOW_STATUS"
printf 'SPEC_WORKFLOW_LINK=%s\n' "$NOTE_FILE"
printf 'SPEC_WORKFLOW_SUMMARY=%s\n' "$GUIDE_SUMMARY"
