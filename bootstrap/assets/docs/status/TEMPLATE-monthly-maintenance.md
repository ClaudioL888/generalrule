---
artifact_type: maintenance-monthly
owner_role: Release-Ops
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Annual budget meetings"
acceptance_metrics:
  - "Monthly regression pass rate"
risks:
  - "Design drifts from reality"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Monthly Maintenance

- Month: {{YYYY-MM}}
- ADR deviation review: continue / revise / retire
- Security audit conclusion: {{security_1}}
- Backup and restore rehearsal result: {{rollback_summary}}
- Cost audit conclusion: {{ops_reason}}
- Improvements for next month: {{next_action}}
