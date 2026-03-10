---
artifact_type: current-task-status
owner_role: Planner
status: active
linked_goal_id: "{{goal_id}}"
non_goals:
  - "One-off summary reports across multiple tasks"
acceptance_metrics:
  - "Current loop status update completeness"
risks:
  - "Stale task state causes execution drift"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Current Task Template

> Update this every time the loop advances, especially `UPDATED_AT`, `TEST_RESULT`, and `NEXT_ACTION`.

- TASK_ID: {{task_1}}
- SPEC_ID: {{spec_id}}
- TASK_TYPE: {{task_type}}
- ROLE: {{role}}
- WORK_TYPE: {{work_type}}
- CURRENT_GATE: {{current_gate}}
- CURRENT_ROLE: {{current_role}}
- NEXT_ROLE: {{next_role}}
- STANDARDS_PROFILE: {{task_type}}:{{work_type}}
- CURRENT_ROLE_STANDARDS: {{current_role_standards}}
- NEXT_ROLE_STANDARDS: {{next_role_standards}}
- ROLE_DOD_STATUS: pending
- EVIDENCE_STATUS: pending
- DEVIATION_STATUS: none
- DESIGN_LINK: docs/design/{{spec_id}}-design.md
- PLAN_LINK: docs/plans/{{spec_id}}-plan.md
- HANDOFF_LINK: {{handoff_link}}
- DESIGN_SYNC_STATUS: pending
- PLAN_SYNC_STATUS: pending
- SPEC_QUALITY_STATUS: pending
- SPEC_WORKFLOW_STATUS: pending
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/{{spec_id}}.md
- API_SURFACE_CHANGED: {{api_surface_changed}}
- FRONTEND_SURFACE_CHANGED: {{frontend_surface_changed}}
- CONTRACT_SYNC_STATUS: {{contract_sync_status}}
- EXCEPTION_STATUS: none
- EXCEPTION_LINK: N/A
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
- BRAINSTORMING_STATUS: pending
- BRAINSTORMING_LINK: docs/status/brainstorming/{{spec_id}}.md
- TEST_COMMANDS: {{test_commands}}
- TEST_RESULT: {{test_result}}
- UPDATED_AT: {{updated_at_iso8601}}
- NEXT_ACTION: {{next_action}}

## Field Notes

1. `TASK_ID` must match the task ID in the plan document.
2. `SPEC_ID` must match the filename of `docs/specs/<SPEC_ID>.md`.
3. `TASK_TYPE`: `feature | bugfix | refactor | ops | content`.
4. `WORK_TYPE`: `full | mini | fast-track`.
5. `DESIGN_SYNC_STATUS`: `synced | pending`; must be `synced` before Gate 0.
6. `PLAN_SYNC_STATUS`: `synced | pending`; must be `synced` before Gate 2.
7. `STANDARDS_PROFILE` must use the format `<task_type>:<work_type>`.
8. `CURRENT_ROLE_STANDARDS` and `NEXT_ROLE_STANDARDS` are comma-separated relative paths and must match the role matrix.
9. `ROLE_DOD_STATUS`: `pending | met`.
10. `EVIDENCE_STATUS`: `pending | complete`.
11. `DEVIATION_STATUS`: `none | documented | required`.
12. `SPEC_QUALITY_STATUS`: `approved | degraded | pending`.
13. `SPEC_WORKFLOW_STATUS`: `passed | unavailable | pending`.
14. `CONTRACT_SYNC_STATUS`: `synced | pending`; it must be `synced` before release.
15. `EXCEPTION_STATUS`: `none | required | approved`. `fast-track` may not use `none`.
16. `EXCEPTION_LINK` is required when `EXCEPTION_STATUS != none` and must point to the exception document.
17. `REWORK_RISK`: `low | medium | high`.
18. `METRICS_IMPACT`: `none | engineering | product | both`.
19. `BRAINSTORMING_STATUS`: `pending | done`; must be `done` before Gate 0.
20. `NEXT_ACTION` must describe the one next action the user should take.
