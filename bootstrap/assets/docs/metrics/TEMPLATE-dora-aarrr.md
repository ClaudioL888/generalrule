---
artifact_type: metrics-dashboard
owner_role: PM-Discovery
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Replace the BI system"
acceptance_metrics:
  - "Metric completeness"
risks:
  - "Inconsistent metric definitions"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# DORA + AARRR Metrics

## DORA

- Lead Time for Changes: {{design_metric_1}}
- Deployment Frequency: {{release_time}}
- Change Failure Rate: {{risk_summary}}
- Time to Restore Service: {{rollback_strategy}}

## AARRR

- Acquisition: {{metric_acquisition}}
- Activation: {{metric_activation}}
- Retention: {{metric_retention}}
- Revenue: {{metric_revenue}}
- Referral: {{metric_referral}}
