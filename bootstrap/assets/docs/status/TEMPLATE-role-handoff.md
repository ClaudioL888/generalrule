---
artifact_type: role-handoff
owner_role: Planner
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Cross-task side refactors"
acceptance_metrics:
  - "Handoff completeness"
risks:
  - "Handoff information is missing"
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
- Current constraints: {{edit_boundary}}
- Current role prompt asset: {{current_role_prompt}}
- Next role prompt asset: {{next_role_prompt}}

## Outputs

- Primary artifact link: {{primary_artifact_link}}
- Secondary artifact link: {{secondary_artifact_link}}
- Artifact summary: {{task_output_link}}
- Test Evidence: {{test_result}}
- Risk Summary: {{risk_1}}

## Applicable Standards

- Current role standards: {{current_role_standards}}
- Next role standards: {{next_role_standards}}
- Deviation note: {{deviation_reason}}

## Evidence Summary

- Primary evidence: {{primary_evidence_link}}
- Secondary evidence: {{secondary_evidence_link}}
- Test Evidence: {{test_result}}
- Risk evidence: {{risk_evidence}}
- Documentation sync evidence: {{docs_sync_evidence}}

## Definition of Done

- [ ] Acceptance criteria met: {{acceptance_1}}
- [ ] Test points covered: {{test_point_1}}
- [ ] Documentation synchronized (spec/plan/status/release)

## Handoff To

- Recipient: {{next_role}}
- Next action: {{next_action}}
