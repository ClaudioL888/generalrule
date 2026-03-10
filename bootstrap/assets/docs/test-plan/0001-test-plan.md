---
artifact_type: test-plan
owner_role: QA
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Smoke testing only"
acceptance_metrics:
  - "Regression defect detection rate"
risks:
  - "Unbalanced test coverage"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Test Plan Template

## 1. Testing Goal

{{test_goal}}

## 2. Test Pyramid Allocation

- Unit: {{unit_scope}} (recommended share >= 70%)
- Integration: {{integration_scope}} (recommended share <= 20%)
- E2E: {{e2e_scope}} (recommended share <= 10%)

## 3. Coverage Matrix

| Scenario | Layer | Case | Pass Criteria |
| --- | --- | --- | --- |
| Core path | Unit | {{case_1}} | {{pass_criteria_1}} |
| Cross-module flow | Integration | {{case_2}} | {{pass_criteria_2}} |
| Critical user journey | E2E | {{case_3}} | {{pass_criteria_3}} |

## 4. Boundary and Error Scenarios

- Boundary: {{edge_case_1}}
- Error: {{error_case_1}}
- Regression focus: {{regression_focus}}

## 5. Result Report Template

- Execution time: {{execution_time}}
- Commands: {{commands}}
- Result summary: {{result_summary}}
- Risk conclusion: {{risk_summary}}
