---
artifact_type: implementation-plan
owner_role: Planner
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Cross-task side refactors"
acceptance_metrics:
  - "Task pass rate against acceptance criteria"
risks:
  - "Task granularity is too large"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Implementation Plan Template

## 0. Plan Type

- WORK_TYPE: `full | mini | fast-track`
- Reason: {{work_type_reason}}

## 1. Scope

- Plan goal: {{plan_goal}}
- Out of scope for this plan: {{plan_non_goal}}

## 2. Task Breakdown (Required: Single Task In Progress)

| Task ID | Description | Status | Acceptance Criteria | Test Point | Owner |
| --- | --- | --- | --- | --- | --- |
| T1 | {{task_1}} | todo | {{acceptance_1}} | {{test_point_1}} | Dev |
| T2 | {{task_2}} | todo | {{acceptance_2}} | {{test_point_2}} | Dev |

Rule: only one item may be `in-progress` at a time.

## 3. Per-Task Execution Template (Copy as Needed)

### Task {{task_id}}

- Inputs: {{task_input}}
- Edit boundary: {{edit_boundary}}
- Test command: {{test_command}}
- Expected result: {{expected_result}}
- Documentation updates: {{docs_update_path}}
- Forbidden: cross-task refactors

## 4. Risks and Response

- Risk: {{risk_1}}
- Trigger: {{trigger_1}}
- Mitigation action: {{mitigation_1}}

## 5. Done Criteria

- [ ] Every task has test points and acceptance criteria
- [ ] Every task records test results
- [ ] `docs/status` and `docs/release` are synchronized
