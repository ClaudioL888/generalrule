---
artifact_type: design-doc
owner_role: Architect
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "{{non_goal_1}}"
acceptance_metrics:
  - "{{design_metric_1}}"
risks:
  - "{{risk_1}}"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Design Doc Template

## 1. Context and Goals

- Context: {{context}}
- Design goal: {{design_goal}}
- Design non-goal: {{design_non_goal}}

## 2. Technical Choice Decision Table (Required)

| Dimension | Option A | Option B | Choice | Reason |
| --- | --- | --- | --- | --- |
| Framework | {{stack_a}} | {{stack_b}} | {{chosen_stack}} | {{tradeoff_reason}} |
| Data layer | {{data_a}} | {{data_b}} | {{chosen_data}} | {{decision_tradeoff}} |
| Observability | {{obs_a}} | {{obs_b}} | {{chosen_obs}} | {{ops_reason}} |

## 3. Architecture and Modules

- Architecture diagram: {{architecture_diagram_link}}
- Core modules: {{core_components}}
- Data flow: {{data_flow}}

## 4. Interfaces and Contracts

- API/events: {{api_contract}}
- Inputs/outputs: {{io_schema}}
- Compatibility strategy: {{compat_strategy}}

## 5. Data Model

- Entity definitions: {{entity_definitions}}
- Indexes and constraints: {{constraints}}
- Migration strategy: {{migration_strategy}}

## 6. Edge Cases and Failure Modes (Required)

- Edge cases: {{edge_case_1}}
- Error handling: {{error_handling}}
- Degradation strategy: {{degrade_strategy}}
- Rollback strategy: {{rollback_strategy}}

## 7. Observability and Security Boundaries

- Metrics/logs/traces: {{observability_plan}}
- Alert thresholds: {{alert_thresholds}}
- Permission and secret boundaries: {{security_boundary}}

## 8. Testing Strategy Alignment

- Unit focus: {{unit_focus}}
- Integration focus: {{integration_focus}}
- E2E scope: {{e2e_scope}}

## 9. Acceptance Checklist

- [ ] Choices include comparison and tradeoff notes
- [ ] Edge cases and error handling are complete
- [ ] Observability and security boundaries are clear
- [ ] Founder approved

## 10. References and Evidence

- SOURCE: TODO(citation_source_1) | TYPE: primary | NOTE: TODO(citation_note_1)
- SOURCE: TODO(citation_source_2) | TYPE: internal | NOTE: TODO(citation_note_2)
