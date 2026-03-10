---
artifact_type: runbook
owner_role: Release-Ops
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Replace the production backup system"
acceptance_metrics:
  - "Restore success rate"
risks:
  - "Backups are unavailable"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Backup & Restore

## 1. Backup Strategy

- Backup frequency: daily
- Retention: 30 days
- Backup location: primary storage + remote copy

## 2. Restore Steps

1. Select the most recent usable backup
2. Rehearse the restore in an isolated environment
3. Verify the integrity of key data
4. Switch traffic and observe

## 3. Secondary Fallback Plan

- If restore fails, execute: {{rollback_summary}}
- If data is inconsistent, enter manual correction flow
