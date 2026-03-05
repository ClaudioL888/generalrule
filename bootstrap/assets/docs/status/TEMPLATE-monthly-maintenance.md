---
artifact_type: maintenance-monthly
owner_role: Release-Ops
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "年度预算会议"
acceptance_metrics:
  - "月度回归通过率"
risks:
  - "设计与现实偏离"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Monthly Maintenance

- Month: {{YYYY-MM}}
- ADR 偏差复查：继续 / 修正 / 废弃
- 安全审计结论：{{security_1}}
- 备份恢复演练结果：{{rollback_summary}}
- 成本审计结论：{{ops_reason}}
- 下月改进项：{{next_action}}
