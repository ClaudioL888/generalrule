---
artifact_type: adr
owner_role: Architect
status: proposed
linked_goal_id: "{{goal_id}}"
non_goals:
  - "{{non_goal_1}}"
acceptance_metrics:
  - "{{decision_quality_metric}}"
risks:
  - "{{risk_1}}"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# ADR {{adr_id}}: {{decision_title}}

## 状态

`proposed | accepted | superseded | rejected`

## 背景

{{decision_context}}

## 决策

{{decision}}

## 备选方案

1. {{alternative_1}} - {{alternative_1_tradeoff}}
2. {{alternative_2}} - {{alternative_2_tradeoff}}

## 后果

- 正向影响：{{positive_consequence}}
- 负向影响：{{negative_consequence}}
- 运维影响：{{ops_impact}}

## 复查计划（月度）

- 复查日期：{{review_date}}
- 复查结论：`继续 | 修正 | 废弃`
