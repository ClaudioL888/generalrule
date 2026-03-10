---
artifact_type: release-notes
owner_role: Release-Ops
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Repeat the full changelog"
acceptance_metrics:
  - "User-understandable change notes"
risks:
  - "Known post-release risks are not disclosed"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# RELEASE NOTES Template

## Version Information

- Version: {{version}}
- Release time: {{release_time}}
- Release owner: {{release_owner}}

## User Value in This Release

{{user_value_summary}}

## Change Summary

- Features: {{feature_summary}}
- Fixes: {{fix_summary}}
- Compatibility: {{compat_summary}}

## Known Risks and Mitigation

- Risk: {{known_risk}}
- Mitigation: {{mitigation}}

## Release Checklist

- [ ] Test results attached
- [ ] Rollback plan validated
- [ ] Monitoring thresholds updated
