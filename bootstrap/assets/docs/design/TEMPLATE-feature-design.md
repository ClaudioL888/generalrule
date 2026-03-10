---
artifact_type: feature-design
owner_role: Architect
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

# Feature Design {{spec_id}}

## 1. Design Goals

- Goal: {{problem_statement}}
- Non-goal: {{non_goal_1}}

## 2. Technical Approach

- Chosen stack: {{chosen_stack}}
- Interface contract: {{api_contract}}
- Input/output model: {{io_schema}}

## 3. Data and State

- Entity definitions: {{entity_definitions}}
- State flow: {{state_strategy}}
- Compatibility strategy: {{compat_strategy}}

## 4. Security and Boundaries

- Security boundary: {{security_boundary}}
- Authorization boundary: {{authz_boundary}}
- Data-access boundary: {{data_access_boundary}}

## 5. Observability

- Observability plan: {{observability_plan}}
- Alert thresholds: {{alert_thresholds}}
- Key metrics: {{design_metric_1}}

## 6. Design Tradeoffs

- Key tradeoff: {{decision_tradeoff}}
- Risk: {{risk_1}}
- Mitigation: {{mitigation_1}}

## 7. References and Evidence

- SOURCE: TODO(citation_source_1) | TYPE: primary | NOTE: TODO(citation_note_1)
- SOURCE: TODO(citation_source_2) | TYPE: internal | NOTE: TODO(citation_note_2)
