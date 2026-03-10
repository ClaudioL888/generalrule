---
artifact_type: spec-quality-review
owner_role: Architect
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Replace the full PRD/Design/Plan set"
acceptance_metrics:
  - "Key spec ambiguities are converged"
risks:
  - "Missing spec quality review causes implementation drift"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Spec Quality Review {{spec_id}}

## 1. Review Context

- SPEC_ID: {{spec_id}}
- Review method: {{spec_workflow_method}}
- Review conclusion: {{spec_quality_status}}
- MCP status: {{spec_workflow_status}}

## 2. Key Findings

- Ambiguity: {{spec_gap_1}}
- Missing item: {{spec_gap_2}}
- Contract risk: {{spec_gap_3}}

## 3. Decision

- Recommended action: {{spec_quality_action}}
- Allowed to enter Gate 0 / Gate 2: {{spec_quality_gate_decision}}
- Downgrade reason (if any): {{spec_workflow_fallback_reason}}

## 4. Evidence and References

- SOURCE: {{spec_workflow_link_source}} | TYPE: internal | NOTE: spec quality review trace
