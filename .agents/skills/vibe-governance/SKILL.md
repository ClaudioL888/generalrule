---
name: vibe-governance
description: 使用 Spec 驱动 + 角色路由 + 本地门禁执行完整 Vibe Coding 循环，防止开发跑偏。
---

# Vibe Governance Skill

## Use When

- 你要开始一个新功能或新任务
- 你要执行完整循环：Spec -> Role -> Edit -> Run tools -> Observe -> Repair -> Update docs/status
- 你要在合并前做本地全量门禁检查
- 你要使用“黑盒半自动”方式：一句话目标 + Gate 批准

## Do Not Use When

- 仅需要回答概念问题且不涉及仓库改动
- 仅需单条命令检查，与治理循环无关

## Hard Rules

1. 无 spec 不得改 `src/`
2. 无测试证据不得宣称完成
3. 角色流转不符合矩阵不得继续
4. docs/status/release 不同步不得进入发布
5. Gate 0 前必须完成 brainstorming 并留下笔记链接

## Workflow

1. 先执行 brainstorming（确认需求、约束、技术选型）
2. 确认 `SPEC_ID`, `TASK_TYPE`, `CURRENT_ROLE`, `NEXT_ROLE`, `WORK_TYPE`
3. 运行 `vibe-task-pack` 创建/更新 `spec/design/plan/map/handoff`
4. Gate 0 前同步 `docs/design/<SPEC_ID>-design.md`
5. Gate 2 前同步 `docs/plans/<SPEC_ID>-plan.md`
6. 执行 `vibe-quality-gates` 跑本地门禁
7. 若失败，进入 Observe/Repair 并重跑
8. 更新 `docs/status/current-task.md` 与交接文档

## Blackbox 半自动模式（推荐给非规则维护者）

最小交互：

1. 任务入口：一句话目标
2. 人类先完成 brainstorming 标记：`run-blackbox-flow.sh brainstorm --note <path>`
3. Gate 0 前同步 design，并把 `DESIGN_SYNC_STATUS` 设为 `synced`
4. Gate 2 前同步 plan，并把 `PLAN_SYNC_STATUS` 设为 `synced`
5. 人类只确认：`Gate 0`、`Gate 2`、`Gate 3`、`发布`
6. 其余流程由 AI 自动推进并输出阶段卡片

阶段卡片固定字段：

- `阶段目标`
- `AI 已完成`
- `硬门禁状态`
- `你只需做一件事`
- `下一步`

## Commands

完整循环：

```bash
bash .agents/skills/vibe-governance/scripts/run-full-loop.sh \
  --spec-id SPEC-0001-core-flow \
  --task-type feature \
  --current-role Dev \
  --next-role QA \
  --work-type full
```

黑盒半自动：

```bash
bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh start \
  --goal "做一个让新用户 10 分钟内完成首次发布的流程" \
  --task-type feature \
  --work-type full

bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh brainstorm \
  --note "docs/status/brainstorming/spec-0001-core-flow.md"

bash -lc 'sed -i.bak -E "s/^- DESIGN_SYNC_STATUS:.*$/- DESIGN_SYNC_STATUS: synced/" docs/status/current-task.md && rm -f docs/status/current-task.md.bak'

bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 0"

bash -lc 'sed -i.bak -E "s/^- PLAN_SYNC_STATUS:.*$/- PLAN_SYNC_STATUS: synced/" docs/status/current-task.md && rm -f docs/status/current-task.md.bak'

bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 2"
bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 3"
bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "发布"
```
