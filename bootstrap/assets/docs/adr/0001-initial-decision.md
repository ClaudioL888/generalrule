---
artifact_type: adr
owner_role: Architect
status: proposed
linked_goal_id: "{{goal_id}}"
non_goals:
  - "{{non_goal_1}}"
acceptance_metrics:
  - "{{decision_quality_metric}}"
risks:
  - "{{risk_1}}"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# ADR {{adr_id}}: {{decision_title}}

## Status

`proposed | accepted | superseded | rejected`

## Context

{{decision_context}}

## Decision

{{decision}}

## Security Boundary

security_boundary: {{security_boundary}}
- Authentication and authorization: {{authz_boundary}}
- Data classification and access: {{data_access_boundary}}
- External dependencies and trust boundary: {{third_party_boundary}}

## Alternatives Considered

1. {{alternative_1}} - {{alternative_1_tradeoff}}
2. {{alternative_2}} - {{alternative_2_tradeoff}}

## Consequences

- Positive impact: {{positive_consequence}}
- Negative impact: {{negative_consequence}}
- Operations impact: {{ops_impact}}

## Review Plan (Monthly)

- Review date: {{review_date}}
- Review conclusion: `continue | revise | retire`

## References and Evidence

- SOURCE: TODO(citation_source_1) | TYPE: primary | NOTE: TODO(citation_note_1)
- SOURCE: TODO(citation_source_2) | TYPE: internal | NOTE: TODO(citation_note_2)
