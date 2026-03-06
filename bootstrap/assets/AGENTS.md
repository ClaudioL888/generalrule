# AGENTS

项目：{{project_name}}
目标ID：{{goal_id}}

## 强制循环

Plan -> Edit -> Run tools -> Observe -> Repair -> Update docs/status -> Repeat

## 黑盒半自动入口

1. 人类唯一必填输入：`开始任务：<一句话目标>`。
2. Gate 0 前必须先运行 brainstorming skill 并记录结论（需求、约束、技术选型）。
3. Gate 0 前必须更新 `docs/design/<SPEC_ID>-design.md` 并同步 `DESIGN_SYNC_STATUS=synced`。
4. Gate 2 前必须更新 `docs/plans/<SPEC_ID>-plan.md` 并同步 `PLAN_SYNC_STATUS=synced`。
5. 人类仅在关键节点批准：`批准 Gate 0`、`批准 Gate 2`、`批准 Gate 3`、`批准发布`。
6. AI 必须每阶段输出固定卡片：`阶段目标`、`AI 已完成`、`硬门禁状态`、`你只需做一件事`、`下一步`。
7. 推荐使用 `bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh` 执行半自动流程。

## Skill 调用提醒（强制）

1. `vibe-governance` 作为默认主流程 skill，允许隐式触发（自动进入规范流程，并先提示 brainstorming）。
2. `vibe-task-pack` 与 `vibe-quality-gates` 保持显式触发，避免误触发重型检查。
3. 每次收到新任务时，AI 必须先说明当前将走 `vibe-governance` 主流程，并给出可选显式命令。
4. 用户明确回复“跳过 skill”后，AI 才可继续，但必须提示风险（可能偏离标准流程或漏掉门禁）。

## 强制规则

1. 不允许跳过 PRD/Design/Plan 直接改大功能。
2. 每次只做一个计划项，跨范围必须先更新 Plan 并重新批准。
3. 必须运行并报告测试结果，不接受“我觉得可以”。
4. 任何改动必须更新对应文档与发布说明。
5. 执行命令、依赖安装、权限变更必须进入 approval。
6. 每个新 `SPEC_ID` 必须绑定独立文档：
   - `docs/specs/<SPEC_ID>.md`
   - `docs/design/<SPEC_ID>-design.md`
   - `docs/plans/<SPEC_ID>-plan.md`

## Codex 运行时配置约束

1. 仓库内强制层位于 `.codex/config.toml` 与 `.codex/rules/default.rules`。
2. 高风险操作默认使用 `codex --profile strict`。
3. 发布窗口操作建议使用 `codex --profile release`。
4. 运行时约束是前置补强，不替代现有 PR/CI 门禁。

## 任务级执行约束

1. 每个功能必须绑定独立 `SPEC_ID`，并维护 `docs/specs/<SPEC_ID>.md`。
2. `TASK_TYPE` 必须声明为：`feature|bugfix|refactor|ops|content`。
3. 角色流转必须符合 `docs/governance/ROLE_ROUTING.md`，否则阻断。
4. 任何 `src/` 变更都必须同步：
   - `docs/specs/*`
   - `docs/contracts/*`（API/前端映射）
   - `docs/status/current-task.md`
   - `docs/status/handoffs/*`
5. 发布前 `CONTRACT_SYNC_STATUS` 必须为 `synced`。

## Skills 优先建议

1. 推荐优先使用 `.agents/skills` 进行流程编排：
   - `$vibe-task-pack`：建立/更新任务包
   - `$vibe-quality-gates`：执行本地门禁链路
   - `$vibe-governance`：执行完整循环
2. skills 用于前置执行一致性，不能替代 CI/PR 硬门禁。

## 官方运行时能力门槛

1. 必须通过 `scripts/ci/check-codex-capabilities.sh`。
2. 必须支持 `codex execpolicy check --rules`。
3. 规则文件必须支持 `prefix_rule(..., justification = "...")`。
4. 不满足能力门槛时，本地校验与 CI 一律阻断。
