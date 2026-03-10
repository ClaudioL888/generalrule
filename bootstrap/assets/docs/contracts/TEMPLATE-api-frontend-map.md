---
artifact_type: api-frontend-map
owner_role: Architect
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Implicit cross-module rewrites"
acceptance_metrics:
  - "API/frontend mapping completeness"
risks:
  - "Contract drift"
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

| Endpoint / Event | DTO / Schema | Frontend Page / Component | State Management | Test Point | Notes |
| --- | --- | --- | --- | --- | --- |
| {{api_contract}} | {{io_schema}} | {{core_use_case}} | {{state_strategy}} | {{test_point_1}} | {{decision_tradeoff}} |

## Review Conclusion

- REVIEW_OWNER: {{contract_review_owner}}
- RESULT: `synced | pending`
