---
artifact_type: runbook
owner_role: Release-Ops
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Postmortem blame debates"
acceptance_metrics:
  - "Incident response time"
risks:
  - "Alert noise causes missed incidents"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Incident Playbook

## 1. Trigger Conditions

- Error rate exceeds threshold: {{alert_thresholds}}
- A critical path is unavailable
- Costs spike abnormally

## 2. Response Severity

- P0: site-wide outage or risk of data corruption
- P1: core functionality unavailable
- P2: partial functionality impacted

## 3. Response Steps

1. Confirm the alert is real
2. Open an incident channel
3. Assign an incident commander
4. Execute degradation or rollback: {{rollback_strategy}}
5. Record the timeline and impact scope

## 4. Recovery and Retrospective

- Recovery standard: core metrics return to normal
- Publish the retrospective and improvement items within 24 hours
