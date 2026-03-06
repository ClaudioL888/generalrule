# AGENTS

本仓库用于维护“官方路径基线 + 一键初始化器”，用于把治理规范嫁接到任意项目。

## 仓库职责

1. 维护仓库级 Codex 官方配置（`.codex/config.toml`、`.codex/rules/default.rules`）。
2. 维护初始化资产源（`bootstrap/assets/`），确保输出目录遵循官方路径。
3. 维护初始化器（`scripts/init-project.sh`）与 seed 输入契约（`seed.template.md`）。
4. 维护回归测试（`tests/unit/*`），保证生成器与门禁脚本稳定可用。

## 强制循环

Plan -> Edit -> Run tools -> Observe -> Repair -> Update docs/status -> Repeat

## 黑盒半自动入口

1. 人类唯一必填输入：`开始任务：<一句话目标>`。
2. Gate 0 前必须先运行 brainstorming skill 并记录结论（需求、约束、技术选型）。
3. Gate 0 前必须更新 `docs/design/<SPEC_ID>-design.md` 并同步 `DESIGN_SYNC_STATUS=synced`。
4. Gate 2 前必须更新 `docs/plans/<SPEC_ID>-plan.md` 并同步 `PLAN_SYNC_STATUS=synced`。
5. 人类仅在关键节点批准：`批准 Gate 0`、`批准 Gate 2`、`批准 Gate 3`、`批准发布`。
6. AI 必须每阶段输出固定卡片：`阶段目标`、`AI 已完成`、`硬门禁状态`、`你只需做一件事`、`下一步`。
7. 除关键批准外，AI 自动推进角色链并自检，失败时进入 Observe/Repair 并给出可执行修复动作。

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
2. 高风险操作默认使用 `codex --profile strict`（更高审批与只读沙箱）。
3. 发布窗口操作建议使用 `codex --profile release`（保留审批并锁定网络访问）。
4. 运行时约束是前置补强，不替代现有 PR/CI 门禁。

## 官方运行时能力门槛

1. 必须通过 `scripts/ci/check-codex-capabilities.sh`。
2. 必须支持 `codex execpolicy check --rules`。
3. 规则文件必须支持 `prefix_rule(..., justification = "...")`。
4. 不满足能力门槛时，本地校验与 CI 一律阻断。
