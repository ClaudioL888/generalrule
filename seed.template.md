# Seed Input Template (Official Path Baseline)

> Purpose: read by `scripts/init-project.sh` to generate the official path skeleton for a target project.
> Rule: only key-value pairs between `START_SEED_KV` and `END_SEED_KV` are parsed.

## 1. Machine-Readable Keys (Layered Contract)

### L1_BASE_REQUIRED (Required for all work types)

<!-- START_SEED_KV -->
- project_code: your-project-code
- goal_id: goal-mvp-0001
- work_type: full
- phase: MVP
- problem_statement: Describe the most important current problem
- target_persona: Target user persona
- core_use_case: The scenario in which the user receives the core value
- spec_id: SPEC-0001-core-flow
- task_type: feature
- task_1: The first executable task
- acceptance_1: The acceptance criteria for the first task
- test_point_1: The test point for the first task
- role: Dev
- current_role: Dev
- next_role: QA
- handoff_link: docs/status/TEMPLATE-role-handoff.md
- api_surface_changed: yes
- frontend_surface_changed: yes
- contract_sync_status: synced
- current_gate: Gate 4
- test_commands: npm test && npm run lint
- test_result: unit=pass;integration=pass;e2e=pass
- next_action: handoff to QA

### L2_FULL_REQUIRED (Enabled only when `work_type=full`)
# Compatibility mode (default): missing keys warn but do not block
# Strict mode (`STRICT_SEED=1` or `--strict-seed`): missing keys fail immediately
- chosen_stack: typescript-node-postgresql
- api_contract: OpenAPI 3.1 + versioned REST
- entity_definitions: three core entities: user/order/session
- io_schema: zod request/response schema
- api_change_policy: backward-compatible first + deprecation window
- frontend_binding_policy: generated types + contract tests
- contract_review_owner: architect-oncall
- security_boundary: public-api/private-worker/admin-console
- security_1: OAuth2 + RBAC + least-privilege
- observability_plan: logs-metrics-traces + error budget
- alert_thresholds: error_rate>1%,p95_latency>400ms,cost_day>200
- release_owner: release-ops-oncall
- rollback_strategy: blue-green rollback within 10min
- rollback_summary: db migration backward-compatible + feature flag fallback

### L3_OPTIONAL (Missing keys fall back to `TODO(key)`)
- project_name: Human-readable project name (defaults to `project_code` when omitted)
- non_goal_1: Work that is explicitly out of scope for this phase
- value_proposition: Value proposition
- business_constraints: Business constraints
- compliance_constraints: Compliance constraints
- external_dependencies: External dependencies
- risk_1: Primary risk
- mitigation_1: Risk mitigation
<!-- END_SEED_KV -->

## 2. Layered Validation Rules

- `L1_BASE_REQUIRED`: always required; missing keys fail immediately.
- `L2_FULL_REQUIRED`:
  - default compatibility mode: for `work_type=full`, missing keys only warn.
  - strict mode: for `work_type=full`, missing keys fail with `missing full-strict seed key: <key>`.
- `L3_OPTIONAL`: missing keys do not fail; the generator fills them with `TODO(key)`.

Strict mode can be enabled in either of these ways:

- `STRICT_SEED=1 bash scripts/init-project.sh ...`
- `bash scripts/init-project.sh ... --strict-seed`

## 3. L1 Required Field List

- `project_code`
- `goal_id`
- `work_type` (`full|mini|fast-track`)
- `phase`
- `problem_statement`
- `target_persona`
- `core_use_case`
- `spec_id`
- `task_type` (`feature|bugfix|refactor|ops|content`)
- `task_1`
- `acceptance_1`
- `test_point_1`
- `role`
- `current_role`
- `next_role`
- `handoff_link`
- `api_surface_changed`
- `frontend_surface_changed`
- `contract_sync_status`
- `current_gate`
- `test_commands`
- `test_result`
- `next_action`

## 4. L2 Required Field List (`full` + strict)

- `chosen_stack`
- `api_contract`
- `entity_definitions`
- `io_schema`
- `api_change_policy`
- `frontend_binding_policy`
- `contract_review_owner`
- `security_boundary`
- `security_1`
- `observability_plan`
- `alert_thresholds`
- `release_owner`
- `rollback_strategy`
- `rollback_summary`

## 5. Generation Mapping

- `.codex/config.toml` <- fixed baseline content
- `.codex/rules/default.rules` <- fixed baseline content
- `AGENTS.md` <- `project_name`, `goal_id`
- `docs/NORMS.md` <- fixed baseline content
- `docs/standards/*.md` <- fixed baseline content
- `docs/prompts/*.md` <- fixed baseline content
- `docs/prd/0001-problem-statement.md` <- `goal_id`, `problem_statement`, `target_persona`, `core_use_case`
- `docs/design/0001-architecture-overview.md` <- `chosen_stack`, `api_contract`, `entity_definitions`, `io_schema`
- `docs/adr/0001-initial-decision.md` <- `security_boundary`, `security_1`, `decision_*`
- `docs/plans/0001-implementation-plan.md` <- `work_type`, `task_1`, `acceptance_1`, `test_point_1`
- `docs/test-plan/0001-test-plan.md` <- `observability_plan`, `alert_thresholds`
- `docs/release/RELEASE_NOTES.md` <- `release_owner`, `rollback_strategy`, `rollback_summary`
- `docs/specs/TEMPLATE-feature-spec.md` <- `spec_id`, `task_type`, `api_change_policy`, `frontend_binding_policy`, `contract_review_owner`
- `docs/contracts/TEMPLATE-api-frontend-map.md` <- `spec_id`, `api_contract`, `io_schema`, `contract_sync_status`, `contract_review_owner`
- `docs/status/TEMPLATE-role-handoff.md` <- `task_type`, `current_role`, `next_role`, `next_action`
- `docs/status/current-task.md` <- `task_1`, `spec_id`, `task_type`, `role`, `current_role`, `next_role`, `handoff_link`, `api_surface_changed`, `frontend_surface_changed`, `contract_sync_status`, `work_type`, `current_gate`, `test_commands`, `test_result`, `next_action`
- `docs/governance/EXCEPTIONS.md` <- fixed baseline content
- `docs/metrics/ENGINEERING_METRICS.md` <- fixed baseline content
- `.pre-commit-config.yaml` <- fixed baseline content

## 6. Initialization Command Examples

Compatibility mode (default):

```bash
bash scripts/init-project.sh   --output /absolute/path/to/new-project   --seed ./seed.template.md
```

Strict mode (recommended for production `full` projects):

```bash
STRICT_SEED=1 bash scripts/init-project.sh   --output /absolute/path/to/new-project   --seed ./seed.template.md
```

Or:

```bash
bash scripts/init-project.sh   --output /absolute/path/to/new-project   --seed ./seed.template.md   --strict-seed
```
