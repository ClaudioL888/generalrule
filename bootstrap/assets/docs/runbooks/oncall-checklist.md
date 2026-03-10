---
artifact_type: runbook
owner_role: Release-Ops
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Replace the paging system"
acceptance_metrics:
  - "Handoff completeness"
risks:
  - "On-call ownership is unclear"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# On-Call Checklist

## Before the Weekly Shift

- [ ] Alert channels are reachable
- [ ] On-call contact information is updated
- [ ] Rollback permissions are available
- [ ] Runbooks are accessible

## Handoff Between Shifts

- [ ] Open alert list
- [ ] Current risk items
- [ ] Summary of this week's changes
