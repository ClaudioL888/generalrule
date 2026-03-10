---
artifact_type: exception-log
owner_role: Reviewer
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Turn temporary exceptions into permanent rules"
acceptance_metrics:
  - "Every exception has a clear follow-up deadline"
risks:
  - "Uncontrolled exceptions undermine the standards"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Exception Log {{spec_id}}

- EXCEPTION_ID: EXC-{{spec_id}}
- SPEC_ID: {{spec_id}}
- STATUS: pending
- REASON: {{exception_reason}}
- SCOPE: {{exception_scope}}
- MITIGATION: {{mitigation_1}}
- FOLLOWUP_DEADLINE: {{followup_deadline}}
- ADR_LINK: {{adr_link}}
