---
artifact_type: feature-plan
owner_role: Planner
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "{{plan_non_goal}}"
acceptance_metrics:
  - "{{acceptance_1}}"
risks:
  - "{{risk_1}}"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Feature Plan {{spec_id}}

## 1. Plan Goals

- Goal: {{plan_goal}}
- Scope: {{core_use_case}}
- Current phase: {{work_type}}

## 2. Task Breakdown

- Task 1: {{task_1}}
- Task 2: {{task_2}}

## 3. Acceptance Criteria

- Acceptance 1: {{acceptance_1}}
- Acceptance 2: {{acceptance_2}}

## 4. Test Points

- Test point 1: {{test_point_1}}
- Test point 2: {{test_point_2}}

## 5. Execution Constraints

- Do not slip in cross-task refactors
- Advance only one plan item at a time
- Failures must return to Observe/Repair

## 6. Risk and Rollback

- Risk: {{risk_1}}
- Mitigation: {{mitigation_1}}
- Rollback strategy: {{rollback_strategy}}
