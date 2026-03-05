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
- APPROVAL_GATE_0: pending
- APPROVAL_GATE_2: pending
- APPROVAL_GATE_3: pending
- APPROVAL_RELEASE: pending
- STATUS: waiting_gate_0
- LAST_ACTION: start
- LAST_UPDATED: {{updated_at_iso8601}}

## 人类输入契约

1. `开始任务：<一句话目标>`
2. `批准 Gate 0`
3. `批准 Gate 2`
4. `批准 Gate 3`
5. `批准发布`

## 阶段卡片固定字段

1. 阶段目标
2. AI 已完成
3. 硬门禁状态
4. 你只需做一件事
5. 下一步
