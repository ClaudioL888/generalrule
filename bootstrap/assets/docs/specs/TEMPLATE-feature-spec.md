---
artifact_type: feature-spec
owner_role: PM-Discovery
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

# Feature Spec {{spec_id}}

## 1. 目标与非目标

- 目标：{{problem_statement}}
- 非目标：{{non_goal_1}}

## 2. 用户故事

- 目标用户：{{target_persona}}
- 核心场景：{{core_use_case}}
- 用户价值：{{value_proposition}}

## 3. API 变更

- API_SURFACE_CHANGED: {{api_surface_changed}}
- API 变更策略：{{api_change_policy}}
- 契约版本策略：{{api_contract}}

## 4. 前端变更

- FRONTEND_SURFACE_CHANGED: {{frontend_surface_changed}}
- 前端绑定策略：{{frontend_binding_policy}}
- 页面/组件影响：{{feature_summary}}

## 5. 验收标准

- 验收条件：{{acceptance_1}}
- 测试点：{{test_point_1}}
- 指标：{{design_metric_1}}

## 6. 风险

- 关键风险：{{risk_1}}
- 缓解动作：{{mitigation_1}}

## 7. 回滚方案

- 回滚策略：{{rollback_strategy}}
- 回滚摘要：{{rollback_summary}}
- 发布负责人：{{release_owner}}
- 契约评审责任人：{{contract_review_owner}}

## 8. 引用与依据

- SOURCE: TODO(citation_source_1) | TYPE: primary | NOTE: TODO(citation_note_1)
- SOURCE: TODO(citation_source_2) | TYPE: internal | NOTE: TODO(citation_note_2)
