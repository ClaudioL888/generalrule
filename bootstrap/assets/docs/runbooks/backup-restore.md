---
artifact_type: runbook
owner_role: Release-Ops
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "替代生产备份系统"
acceptance_metrics:
  - "恢复成功率"
risks:
  - "备份不可用"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Backup & Restore

## 1. 备份策略

- 备份频率：每日
- 保存周期：30 天
- 备份位置：主存储 + 异地副本

## 2. 恢复步骤

1. 选择最近可用备份
2. 在隔离环境演练恢复
3. 校验关键数据完整性
4. 切换流量并观察

## 3. 二级回退方案

- 若恢复失败，执行：{{rollback_summary}}
- 若数据不一致，进入人工校正流程
