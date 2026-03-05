---
artifact_type: current-task-status
owner_role: Planner
status: active
linked_goal_id: "{{goal_id}}"
non_goals:
  - "跨任务一次性汇总报告"
acceptance_metrics:
  - "每轮循环状态更新完整率"
risks:
  - "任务状态过期导致执行偏差"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Current Task 模板

> 每次进入循环都要更新，尤其是 `UPDATED_AT` 和 `TEST_RESULT`。

- TASK_ID: {{task_1}}
- ROLE: {{role}}
- WORK_TYPE: {{work_type}}
- CURRENT_GATE: {{current_gate}}
- TEST_COMMANDS: {{test_commands}}
- TEST_RESULT: {{test_result}}
- UPDATED_AT: {{updated_at_iso8601}}
- NEXT_ACTION: {{next_action}}

## 填写说明

1. `TASK_ID`：必须和计划文档中的任务 ID 一致。
2. `ROLE`：当前执行角色（Dev/QA/Reviewer/Release-Ops）。
3. `WORK_TYPE`：`full | mini | fast-track`。
4. `CURRENT_GATE`：当前门禁阶段（Gate 0-6）。
5. `TEST_COMMANDS`：本轮执行过的测试命令。
6. `TEST_RESULT`：必须是可读结果摘要（例如 `unit=pass;integration=pass;e2e=pass`）。
7. `UPDATED_AT`：ISO8601 时间戳。
8. `NEXT_ACTION`：下一步动作或交接对象。
