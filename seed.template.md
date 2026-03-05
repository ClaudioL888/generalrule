# Seed 输入模板（官方路径基线）

> 用途：给 `scripts/init-project.sh` 读取，生成目标项目的官方路径骨架。
> 规则：只解析 `START_SEED_KV` 与 `END_SEED_KV` 之间的键值。

## 1. 机器可解析键值（分层契约）

### L1_BASE_REQUIRED（所有 work_type 必填）

<!-- START_SEED_KV -->
- project_code: your-project-code
- goal_id: goal-mvp-0001
- work_type: full
- phase: MVP
- problem_statement: 描述当前最核心的问题
- target_persona: 目标用户画像
- core_use_case: 用户完成核心价值的场景
- spec_id: SPEC-0001-core-flow
- task_type: feature
- task_1: 第一个可执行任务
- acceptance_1: 第一个任务的验收条件
- test_point_1: 第一个任务的测试点
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

### L2_FULL_REQUIRED（仅 work_type=full 时启用）
# 兼容模式（默认）：缺失会告警，但不阻断
# 严格模式（STRICT_SEED=1 或 --strict-seed）：缺失即失败
- chosen_stack: typescript-node-postgresql
- api_contract: OpenAPI 3.1 + versioned REST
- entity_definitions: user/order/session 三个核心实体
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

### L3_OPTIONAL（缺失会填充 TODO(key)）
- project_name: 可读项目名（不填默认使用 project_code）
- non_goal_1: 本阶段不做事项
- value_proposition: 价值主张
- business_constraints: 业务约束
- compliance_constraints: 合规约束
- external_dependencies: 外部依赖
- risk_1: 主要风险
- mitigation_1: 风险缓解
<!-- END_SEED_KV -->

## 2. 分层校验规则

- `L1_BASE_REQUIRED`：始终必填，缺失直接失败。
- `L2_FULL_REQUIRED`：
  - 默认兼容模式：`work_type=full` 且缺失时仅告警。
  - 严格模式：`work_type=full` 且缺失时失败，报错 `missing full-strict seed key: <key>`。
- `L3_OPTIONAL`：缺失不会失败，生成器用 `TODO(key)` 回填。

严格模式开启方式（二选一）：

- `STRICT_SEED=1 bash scripts/init-project.sh ...`
- `bash scripts/init-project.sh ... --strict-seed`

## 3. L1 必填字段表

- `project_code`
- `goal_id`
- `work_type`（`full|mini|fast-track`）
- `phase`
- `problem_statement`
- `target_persona`
- `core_use_case`
- `spec_id`
- `task_type`（`feature|bugfix|refactor|ops|content`）
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

## 4. L2（full + strict）必填字段表

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

## 5. 生成映射表

- `.codex/config.toml` <- 基线固定内容
- `.codex/rules/default.rules` <- 基线固定内容
- `AGENTS.md` <- `project_name`, `goal_id`
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

## 6. 初始化命令示例

兼容模式（默认）：

```bash
bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.template.md
```

严格模式（推荐用于正式 full 项目）：

```bash
STRICT_SEED=1 bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.template.md
```

或：

```bash
bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.template.md \
  --strict-seed
```
