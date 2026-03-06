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
- SPEC_ID: {{spec_id}}
- TASK_TYPE: {{task_type}}
- ROLE: {{role}}
- WORK_TYPE: {{work_type}}
- CURRENT_GATE: {{current_gate}}
- CURRENT_ROLE: {{current_role}}
- NEXT_ROLE: {{next_role}}
- DESIGN_LINK: docs/design/{{spec_id}}-design.md
- PLAN_LINK: docs/plans/{{spec_id}}-plan.md
- HANDOFF_LINK: {{handoff_link}}
- DESIGN_SYNC_STATUS: pending
- PLAN_SYNC_STATUS: pending
- API_SURFACE_CHANGED: {{api_surface_changed}}
- FRONTEND_SURFACE_CHANGED: {{frontend_surface_changed}}
- CONTRACT_SYNC_STATUS: {{contract_sync_status}}
- BRAINSTORMING_STATUS: pending
- BRAINSTORMING_LINK: docs/status/brainstorming/{{spec_id}}.md
- TEST_COMMANDS: {{test_commands}}
- TEST_RESULT: {{test_result}}
- UPDATED_AT: {{updated_at_iso8601}}
- NEXT_ACTION: {{next_action}}

## 填写说明

1. `TASK_ID`：必须和计划文档中的任务 ID 一致。
2. `SPEC_ID`：必须和 `docs/specs/<SPEC_ID>.md` 文件名一致。
3. `TASK_TYPE`：`feature | bugfix | refactor | ops | content`。
4. `ROLE`：当前执行角色（兼容字段，保留）。
5. `WORK_TYPE`：`full | mini | fast-track`。
6. `CURRENT_GATE`：当前门禁阶段（Gate 0-6）。
7. `CURRENT_ROLE/NEXT_ROLE`：必须符合角色路由规则。
8. `DESIGN_LINK`：本次任务绑定的设计文档路径，文件必须存在。
9. `PLAN_LINK`：本次任务绑定的计划文档路径，文件必须存在。
10. `HANDOFF_LINK`：交接文档路径，文件必须存在。
11. `DESIGN_SYNC_STATUS`：`synced | pending`，Gate 0 前必须 `synced`。
12. `PLAN_SYNC_STATUS`：`synced | pending`，Gate 2 前必须 `synced`。
13. `API_SURFACE_CHANGED/FRONTEND_SURFACE_CHANGED`：`yes | no`。
14. `CONTRACT_SYNC_STATUS`：`synced | pending`，进入发布前必须 `synced`。
15. `BRAINSTORMING_STATUS`：`pending | done`，Gate 0 前必须 `done`。
16. `BRAINSTORMING_LINK`：brainstorming 记录文档路径，文件必须存在。
17. `TEST_COMMANDS`：本轮执行过的测试命令。
18. `TEST_RESULT`：必须是可读结果摘要（例如 `unit=pass;integration=pass;e2e=pass`）。
19. `UPDATED_AT`：ISO8601 时间戳。
20. `NEXT_ACTION`：下一步动作或交接对象。
