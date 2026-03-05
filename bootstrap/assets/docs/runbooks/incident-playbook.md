---
artifact_type: runbook
owner_role: Release-Ops
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "事后归因争议"
acceptance_metrics:
  - "事故响应时间"
risks:
  - "告警噪音导致漏报"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Incident Playbook

## 1. 触发条件

- 错误率超过阈值：{{alert_thresholds}}
- 关键链路不可用
- 成本异常飙升

## 2. 响应分级

- P0：全站不可用/数据损坏风险
- P1：核心功能不可用
- P2：局部功能受影响

## 3. 处置步骤

1. 确认告警真实性
2. 建立 incident channel
3. 指派 incident commander
4. 执行降级/回滚：{{rollback_strategy}}
5. 记录时间线与影响范围

## 4. 恢复与复盘

- 恢复标准：核心指标恢复正常
- 24h 内输出复盘与改进项
