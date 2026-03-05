# Seed 输入模板（官方路径基线）

> 用途：给 `scripts/init-project.sh` 读取，生成目标项目的官方路径骨架。
> 规则：只解析 `START_SEED_KV` 与 `END_SEED_KV` 之间的键值。

## 1. 机器可解析键值（必填区）

<!-- START_SEED_KV -->
- project_code: your-project-code
- goal_id: goal-mvp-0001
- work_type: full
- phase: MVP
- problem_statement: 描述当前最核心的问题
- target_persona: 目标用户画像
- core_use_case: 用户完成核心价值的场景
- task_1: 第一个可执行任务
- acceptance_1: 第一个任务的验收条件
- test_point_1: 第一个任务的测试点
- role: Dev
- current_gate: Gate 4
- test_commands: npm test && npm run lint
- test_result: unit=pass;integration=pass;e2e=pass
- next_action: handoff to QA

# 可选键（缺失会被填充为 TODO(key)）
- project_name: 可读项目名（不填默认使用 project_code）
- non_goal_1: 本阶段不做事项
- value_proposition: 价值主张
- stack_selected: 已选技术栈
- risk_1: 主要风险
<!-- END_SEED_KV -->

## 2. 必填字段表（缺任一项会失败）

- `project_code`
- `goal_id`
- `work_type`
- `phase`
- `problem_statement`
- `target_persona`
- `core_use_case`
- `task_1`
- `acceptance_1`
- `test_point_1`
- `role`
- `current_gate`
- `test_commands`
- `test_result`
- `next_action`

## 3. 生成映射表

- `.codex/config.toml` <- 基线固定内容
- `.codex/rules/default.rules` <- 基线固定内容
- `AGENTS.md` <- `project_name`, `goal_id`
- `docs/prd/0001-problem-statement.md` <- `goal_id`, `problem_statement`, `target_persona`, `core_use_case`
- `docs/design/0001-architecture-overview.md` <- `goal_id`, `stack_selected`
- `docs/plans/0001-implementation-plan.md` <- `work_type`, `task_1`, `acceptance_1`, `test_point_1`
- `docs/status/current-task.md` <- `task_1`, `role`, `work_type`, `current_gate`, `test_commands`, `test_result`, `next_action`

## 4. 初始化命令示例

```bash
bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.template.md
```

覆盖已存在目录：

```bash
bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.template.md \
  --force
```
