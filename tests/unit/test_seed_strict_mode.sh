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

seed_l1_full="$tmp_dir/seed-l1-full.md"
cat > "$seed_l1_full" <<'SEED'
# L1 full

<!-- START_SEED_KV -->
- project_code: demo-full
- goal_id: goal-full-1
- work_type: full
- phase: MVP
- problem_statement: problem
- target_persona: persona
- core_use_case: use case
- spec_id: SPEC-0001-core-flow
- task_type: feature
- task_1: task one
- acceptance_1: acceptance one
- test_point_1: test point one
- role: Dev
- current_role: Dev
- next_role: QA
- handoff_link: docs/status/TEMPLATE-role-handoff.md
- api_surface_changed: yes
- frontend_surface_changed: yes
- contract_sync_status: synced
- current_gate: Gate 4
- test_commands: npm test
- test_result: unit=pass;integration=pass;e2e=pass
- next_action: handoff to QA
<!-- END_SEED_KV -->
SEED

out_default="$tmp_dir/out-default"
default_output="$($INIT_SCRIPT --output "$out_default" --seed "$seed_l1_full" 2>&1)"
if ! grep -q 'Compatibility mode warning: full work_type is missing advanced keys' <<<"$default_output"; then
  echo "expected compatibility warning for missing L2 keys in default mode"
  exit 1
fi

strict_fail_log="$tmp_dir/strict-fail.log"
if STRICT_SEED=1 "$INIT_SCRIPT" --output "$tmp_dir/out-strict-fail" --seed "$seed_l1_full" >"$strict_fail_log" 2>&1; then
  echo "expected strict mode failure for missing L2 keys"
  exit 1
fi
if ! grep -q 'missing full-strict seed key' "$strict_fail_log"; then
  echo "expected missing full-strict seed key error message"
  exit 1
fi

seed_full_complete="$tmp_dir/seed-full-complete.md"
cat > "$seed_full_complete" <<'SEED'
# Full strict

<!-- START_SEED_KV -->
- project_code: demo-full-complete
- goal_id: goal-full-2
- work_type: full
- phase: MVP
- problem_statement: problem
- target_persona: persona
- core_use_case: use case
- spec_id: SPEC-0001-core-flow
- task_type: feature
- task_1: task one
- acceptance_1: acceptance one
- test_point_1: test point one
- role: Dev
- current_role: Dev
- next_role: QA
- handoff_link: docs/status/TEMPLATE-role-handoff.md
- api_surface_changed: yes
- frontend_surface_changed: yes
- contract_sync_status: synced
- current_gate: Gate 4
- test_commands: npm test
- test_result: unit=pass;integration=pass;e2e=pass
- next_action: handoff to QA
- chosen_stack: typescript-node-postgresql
- api_contract: OpenAPI 3.1
- entity_definitions: user/order/session
- io_schema: zod
- api_change_policy: backward-compatible-first
- frontend_binding_policy: generated-types
- contract_review_owner: architect-oncall
- security_boundary: public-api/private-worker/admin-console
- security_1: oauth2-rbac
- observability_plan: logs-metrics-traces
- alert_thresholds: error_rate>1%
- release_owner: release-ops
- rollback_strategy: blue-green
- rollback_summary: feature-flag-db-rollback
<!-- END_SEED_KV -->
SEED

"$INIT_SCRIPT" --output "$tmp_dir/out-strict-pass" --seed "$seed_full_complete" --strict-seed

seed_l1_mini="$tmp_dir/seed-l1-mini.md"
cat > "$seed_l1_mini" <<'SEED'
# L1 mini

<!-- START_SEED_KV -->
- project_code: demo-mini
- goal_id: goal-mini-1
- work_type: mini
- phase: MVP
- problem_statement: problem
- target_persona: persona
- core_use_case: use case
- spec_id: SPEC-0002-mini
- task_type: bugfix
- task_1: task one
- acceptance_1: acceptance one
- test_point_1: test point one
- role: Dev
- current_role: Dev
- next_role: QA
- handoff_link: docs/status/TEMPLATE-role-handoff.md
- api_surface_changed: no
- frontend_surface_changed: no
- contract_sync_status: pending
- current_gate: Gate 3
- test_commands: npm test
- test_result: unit=pass;integration=pass;e2e=pass
- next_action: handoff to QA
<!-- END_SEED_KV -->
SEED

mini_output="$($INIT_SCRIPT --output "$tmp_dir/out-mini-strict" --seed "$seed_l1_mini" --strict-seed 2>&1)"
if grep -q 'missing full-strict seed key' <<<"$mini_output"; then
  echo "mini work_type should not require L2 keys in strict mode"
  exit 1
fi

echo "test_seed_strict_mode.sh passed"
