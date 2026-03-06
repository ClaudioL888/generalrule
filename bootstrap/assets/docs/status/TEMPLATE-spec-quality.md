---
artifact_type: spec-quality-review
owner_role: Architect
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "替代完整 PRD/Design/Plan"
acceptance_metrics:
  - "Spec 关键歧义已收敛"
risks:
  - "Spec 质量审查缺失导致实现跑偏"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Spec Quality Review {{spec_id}}

## 1. 审查上下文

- SPEC_ID: {{spec_id}}
- 审查方式：{{spec_workflow_method}}
- 审查结论：{{spec_quality_status}}
- MCP 状态：{{spec_workflow_status}}

## 2. 关键发现

- 歧义点：{{spec_gap_1}}
- 缺失项：{{spec_gap_2}}
- 契约风险：{{spec_gap_3}}

## 3. 处置结论

- 建议动作：{{spec_quality_action}}
- 是否允许进入 Gate 0 / Gate 2：{{spec_quality_gate_decision}}
- 降级原因（如有）：{{spec_workflow_fallback_reason}}

## 4. 证据与引用

- SOURCE: {{spec_workflow_link_source}} | TYPE: internal | NOTE: spec quality review trace
