---
artifact_type: feature-spec
owner_role: PM-Discovery
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "{{non_goal_1}}"
acceptance_metrics:
  - "{{acceptance_1}}"
risks:
  - "{{risk_1}}"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Feature Spec {{spec_id}}

## 1. Goals and Non-Goals

- Goal: {{problem_statement}}
- Non-goal: {{non_goal_1}}

## 2. User Stories

- Target persona: {{target_persona}}
- Core scenario: {{core_use_case}}
- User value: {{value_proposition}}

## 3. API Changes

- API_SURFACE_CHANGED: {{api_surface_changed}}
- API change policy: {{api_change_policy}}
- Contract versioning strategy: {{api_contract}}

## 4. Frontend Changes

- FRONTEND_SURFACE_CHANGED: {{frontend_surface_changed}}
- Frontend binding strategy: {{frontend_binding_policy}}
- Page/component impact: {{feature_summary}}

## 5. Acceptance Criteria

- Acceptance criteria: {{acceptance_1}}
- Test point: {{test_point_1}}
- Metric: {{design_metric_1}}

## 6. Risks

- Primary risk: {{risk_1}}
- Mitigation action: {{mitigation_1}}

## 7. Rollback Plan

- Rollback strategy: {{rollback_strategy}}
- Rollback summary: {{rollback_summary}}
- Release owner: {{release_owner}}
- Contract review owner: {{contract_review_owner}}

## 8. References and Evidence

- SOURCE: TODO(citation_source_1) | TYPE: primary | NOTE: TODO(citation_note_1)
- SOURCE: TODO(citation_source_2) | TYPE: internal | NOTE: TODO(citation_note_2)
