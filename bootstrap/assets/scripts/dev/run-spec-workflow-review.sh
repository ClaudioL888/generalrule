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
    print("The upstream spec-workflow is reachable, but its public tools and prompts mainly provide workflow guidance, status, and approvals rather than a direct spec-quality score. The final approved/degraded decision is still owned by this repository's governance flow.")
else:
    err = data.get("error", "unknown error")
    stage = data.get("stage", "unknown stage")
    print(f"spec-workflow {stage} failed: {err}")
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
  - "Replace the full PRD/Design/Plan set"
acceptance_metrics:
  - "Key spec ambiguities are converged"
risks:
  - "Missing spec quality review causes implementation drift"
approvals_required:
  - founder
last_updated: "${LAST_UPDATED}"
---

# Spec Quality Review ${SPEC_ID}

## 1. Review Context

- SPEC_ID: ${SPEC_ID}
- Review method: spec-workflow runtime review
- Review conclusion: to be filled by the governance flow as approved or degraded
- MCP status: ${SPEC_WORKFLOW_STATUS}
- Server: ${SERVER_NAME}@${SERVER_VERSION}

## 2. Upstream Capability Summary

- Tools: ${TOOLS_SUMMARY}
- Prompts: ${PROMPTS_SUMMARY}
- Guide summary: ${GUIDE_SUMMARY}

## 3. Decision

- Recommended action: judge manually, using brainstorming/design/plan, whether the spec can enter the next gate
- Allowed to enter Gate 0 / Gate 2: to be filled by the governance flow
- Downgrade reason (if any): ${FALLBACK_REASON}

## 4. Evidence and References

- SOURCE: ${NOTE_FILE} | TYPE: internal | NOTE: spec-workflow runtime review trace
EOF

printf 'SPEC_WORKFLOW_STATUS=%s\n' "$SPEC_WORKFLOW_STATUS"
printf 'SPEC_WORKFLOW_LINK=%s\n' "$NOTE_FILE"
printf 'SPEC_WORKFLOW_SUMMARY=%s\n' "$GUIDE_SUMMARY"
