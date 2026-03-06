---
artifact_type: feature-design
owner_role: Architect
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "{{non_goal_1}}"
acceptance_metrics:
  - "{{acceptance_1}}"
risks:
  - "{{risk_1}}"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Feature Design {{spec_id}}

## 1. 设计目标

- 目标：{{problem_statement}}
- 非目标：{{non_goal_1}}

## 2. 技术方案

- 选型：{{chosen_stack}}
- 接口契约：{{api_contract}}
- 输入输出模型：{{io_schema}}

## 3. 数据与状态

- 实体定义：{{entity_definitions}}
- 状态流：{{state_strategy}}
- 兼容策略：{{compat_strategy}}

## 4. 安全与边界

- 安全边界：{{security_boundary}}
- 权限边界：{{authz_boundary}}
- 数据访问边界：{{data_access_boundary}}

## 5. 可观测性

- 观测方案：{{observability_plan}}
- 告警阈值：{{alert_thresholds}}
- 关键指标：{{design_metric_1}}

## 6. 设计取舍

- 关键取舍：{{decision_tradeoff}}
- 风险：{{risk_1}}
- 缓解：{{mitigation_1}}
