---
artifact_type: runbook
owner_role: Release-Ops
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "替代值班系统"
acceptance_metrics:
  - "交接完整率"
risks:
  - "值班责任不清"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# On-Call Checklist

## 每周值班前

- [ ] 告警渠道可用
- [ ] 值班联系方式更新
- [ ] 回滚权限可用
- [ ] Runbook 可访问

## 值班交接

- [ ] 未关闭告警清单
- [ ] 当前风险项
- [ ] 本周变更摘要
