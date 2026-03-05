---
artifact_type: api-frontend-map
owner_role: Architect
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "跨模块隐式改造"
acceptance_metrics:
  - "API/前端映射完整率"
risks:
  - "契约漂移"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# API-Frontend Mapping {{spec_id}}

- SPEC_ID: {{spec_id}}
- CONTRACT_SYNC_STATUS: {{contract_sync_status}}
- API_SURFACE_CHANGED: {{api_surface_changed}}
- FRONTEND_SURFACE_CHANGED: {{frontend_surface_changed}}
- N/A_REASON: {{na_reason}}
- INTERNAL_ONLY_REASON: {{internal_only_reason}}

## Mapping Table

| Endpoint / Event | DTO / Schema | Frontend 页面/组件 | 状态管理 | 测试点 | 备注 |
| --- | --- | --- | --- | --- | --- |
| {{api_contract}} | {{io_schema}} | {{core_use_case}} | {{state_strategy}} | {{test_point_1}} | {{decision_tradeoff}} |

## 审查结论

- REVIEW_OWNER: {{contract_review_owner}}
- RESULT: `synced | pending`
