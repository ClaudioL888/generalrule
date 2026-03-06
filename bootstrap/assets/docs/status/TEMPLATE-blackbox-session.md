---
artifact_type: blackbox-session
owner_role: Founder
status: active
linked_goal_id: "{{goal_id}}"
non_goals:
  - "跨多个目标并行推进"
acceptance_metrics:
  - "关键 Gate 批准流转完整率"
risks:
  - "黑盒流程卡在未批准 Gate"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Blackbox Session 模板

> 半自动模式：人类只做关键 Gate 批准，其余由 AI 推进。

- GOAL: {{problem_statement}}
- SPEC_ID: {{spec_id}}
- TASK_TYPE: {{task_type}}
- WORK_TYPE: {{work_type}}
- CURRENT_GATE: Gate 0
- CURRENT_ROLE: Founder
- NEXT_ROLE: PM
- DESIGN_LINK: docs/design/{{spec_id}}-design.md
- PLAN_LINK: docs/plans/{{spec_id}}-plan.md
- APPROVAL_GATE_0: pending
- APPROVAL_GATE_2: pending
- APPROVAL_GATE_3: pending
- APPROVAL_RELEASE: pending
- DESIGN_SYNC_STATUS: pending
- PLAN_SYNC_STATUS: pending
- SPEC_QUALITY_STATUS: pending
- SPEC_WORKFLOW_STATUS: pending
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/{{spec_id}}.md
- BRAINSTORMING_STATUS: pending
- BRAINSTORMING_LINK: docs/status/brainstorming/{{spec_id}}.md
- STATUS: waiting_gate_0
- LAST_ACTION: start
- LAST_UPDATED: {{updated_at_iso8601}}

## 人类输入契约

1. `开始任务：<一句话目标>`
2. 运行 brainstorming 并执行：`run-blackbox-flow.sh brainstorm --note <path>`
3. 运行 spec quality 审查并执行：`run-blackbox-flow.sh spec-quality --status approved|degraded --workflow-status passed|unavailable --note <path>`
4. 更新 `docs/design/<SPEC_ID>-design.md`，并把 `DESIGN_SYNC_STATUS` 设为 `synced`
5. `批准 Gate 0`
6. 更新 `docs/plans/<SPEC_ID>-plan.md`，并把 `PLAN_SYNC_STATUS` 设为 `synced`
7. `批准 Gate 2`
8. `批准 Gate 3`
9. `批准发布`

## 阶段卡片固定字段

1. 阶段目标
2. AI 已完成
3. 硬门禁状态
4. 你只需做一件事
5. 下一步
