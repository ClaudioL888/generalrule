# AGENTS

项目：{{project_name}}
目标ID：{{goal_id}}

## 强制循环

Plan -> Edit -> Run tools -> Observe -> Repair -> Update docs/status -> Repeat

## 读取顺序（强制）

1. `AGENTS.md`
2. `docs/NORMS.md`
3. 相关 `docs/standards/*.md`
4. 相关 `docs/prompts/*.md`
5. 当前角色绑定的 standards profile 与 evidence 状态
5. 当前任务的 `spec/design/plan/current-task`

## Standards Enforcement（默认严格）

1. `standards-binding` 默认是 `strict`，不是 `mixed`。
2. 默认情况下，所有角色缺 standards 绑定、缺证据、缺偏差记录都会被阻断。
3. 只有显式设置 `STANDARDS_ENFORCEMENT=mixed` 或 `STANDARDS_ENFORCEMENT=warn` 时，才允许降级。
4. 进入 Gate 3 或批准发布前，优先检查 `ROLE_DOD_STATUS=met`、`EVIDENCE_STATUS=complete`，否则会被 standards gate 阻断。

## 黑盒半自动入口

1. 人类唯一必填输入：`开始任务：<一句话目标>`。
2. Gate 0 前必须先运行 brainstorming skill 并记录结论（需求、约束、技术选型）。
3. Gate 0 / Gate 2 前必须完成 spec quality 审查；默认允许 `degraded + unavailable` 降级通过，`SPEC_WORKFLOW_REQUIRED=strict` 时必须 `approved + passed`。
4. Gate 0 前必须更新 `docs/design/<SPEC_ID>-design.md` 并同步 `DESIGN_SYNC_STATUS=synced`。
5. Gate 2 前必须更新 `docs/plans/<SPEC_ID>-plan.md` 并同步 `PLAN_SYNC_STATUS=synced`。
6. 人类仅在关键节点批准：`批准 Gate 0`、`批准 Gate 2`、`批准 Gate 3`、`批准发布`。
7. AI 必须每阶段输出固定卡片：`阶段目标`、`AI 已完成`、`硬门禁状态`、`你只需做一件事`、`下一步`。
8. 推荐使用 `bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh` 执行半自动流程。

## 交互与反馈约束（强制）

1. 除关键决策外，优先用“提案 + 默认推进”替代“是否继续”式请示。
2. 每轮响应必须至少给出一个“可评价对象”，例如：判断、方案、最小样例、结构草案、差异对比、局部实现。
3. 低风险、低成本、可回退的内容默认直接推进；高风险、不可逆、范围扩大的内容才停下来确认。
4. 每轮必须显式暴露不确定性：已知事实、当前假设、假设风险、较稳妥路径。
5. 每轮只处理一类相近问题，不把结构、逻辑、风格、实现混在一轮大改。
6. 每次任务结束除说明“下一步做什么”外，还要沉淀至少一条可复用经验。

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
6. 角色交接必须同时引用当前/下一角色的 standards，并写明证据状态与偏差状态。
6. 每个新 `SPEC_ID` 必须绑定独立文档：
   - `docs/specs/<SPEC_ID>.md`
   - `docs/design/<SPEC_ID>-design.md`
   - `docs/plans/<SPEC_ID>-plan.md`
7. 修改 `docs/prd/`、`docs/design/`、`docs/adr/`、`docs/specs/` 时，必须补齐结构化引用块 `## 引用与依据`，且至少包含一条 `primary` 或 `internal` 来源。
8. 任何例外都必须记录 `EXCEPTION` 文档并给出 `FOLLOWUP_DEADLINE`。
9. 每次任务结束都必须告诉用户“下一步做什么”。

## NORMS / Standards / Prompts

1. `docs/NORMS.md` 是最短真值，优先于长文档说明。
2. `docs/standards/*.md` 定义 discovery/design/planning/coding/testing/security/observability/release/documentation 的长期标准。
3. `docs/prompts/*.md` 定义角色提示资产，用于稳定角色行为而不是临场发挥。
4. `docs/governance/ROLE_STANDARD_MATRIX.md` 与 `docs/governance/TASK_TYPE_STANDARD_PROFILES.md` 定义角色和任务类型的 standards 绑定规则。
4. 当实现与标准冲突时，必须记录 exception 或 ADR，而不是直接绕过。
5. `ROLE_HANDOFF` 不只检查文件存在；还会检查固定章节、角色 prompt 引用，以及当前角色必须交出的主产物链接。

## Codex 运行时配置约束

1. 仓库内强制层位于 `.codex/config.toml` 与 `.codex/rules/default.rules`。
2. `.codex/config.toml` 默认声明项目级 `spec-workflow` MCP，参数中的 `"."` 必须指向当前项目根目录，不要写死其他项目的绝对路径。
3. 高风险操作默认使用 `codex --profile strict`。
4. 发布窗口操作建议使用 `codex --profile release`。
5. 运行时约束是前置补强，不替代现有 PR/CI 门禁。

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
6. 任何 fast-track 都必须带 `EXCEPTION` 记录与追补期限。

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
