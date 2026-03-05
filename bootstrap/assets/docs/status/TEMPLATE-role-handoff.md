---
artifact_type: role-handoff
owner_role: Planner
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "跨任务顺手重构"
acceptance_metrics:
  - "交接完整率"
risks:
  - "交接信息遗漏"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Role Handoff {{spec_id}}

- TASK_TYPE: {{task_type}}
- CURRENT_ROLE: {{current_role}}
- NEXT_ROLE: {{next_role}}

## Inputs

- {{task_input}}
- 当前约束：{{edit_boundary}}

## Outputs

- 产物链接：{{task_output_link}}
- 测试证据：{{test_result}}

## Definition of Done

- [ ] 验收条件达成：{{acceptance_1}}
- [ ] 测试点覆盖：{{test_point_1}}
- [ ] 文档已同步（spec/plan/status/release）

## Handoff To

- 交接对象：{{next_role}}
- 下一动作：{{next_action}}
