---
artifact_type: metrics-weekly
owner_role: Release-Ops
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Replace the monthly review"
acceptance_metrics:
  - "Engineering metrics are updated at least once per week"
risks:
  - "Metric drift goes unaddressed"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Weekly Metrics Snapshot {{YYYY-MM-DD}}

## DORA

- Lead Time: {{dora_lead_time}}
- Deploy Frequency: {{dora_deploy_frequency}}
- Change Failure Rate: {{dora_change_failure_rate}}
- Restore Time: {{dora_restore_time}}

## Engineering

- CI Failure Rate: {{ci_failure_rate}}
- Rework Ratio: {{rework_ratio}}
- Hotfix Ratio: {{hotfix_ratio}}

## Product

- AARRR Focus: {{aarrr_focus}}
- Notes: {{metrics_note}}
