---
artifact_type: api-frontend-map
owner_role: Architect
status: draft
linked_goal_id: "goal-baseline-english-0001"
non_goals:
  - "Claim runtime API changes where none exist"
acceptance_metrics:
  - "Contract-sync doc explains why this refactor has no API/frontend surface change"
risks:
  - "Internal-only repository changes are mistaken for product surface changes"
approvals_required:
  - founder
last_updated: "2026-03-10"
---

# API-Frontend Mapping SPEC-20260310-english-localization

- SPEC_ID: SPEC-20260310-english-localization
- CONTRACT_SYNC_STATUS: synced
- API_SURFACE_CHANGED: no
- FRONTEND_SURFACE_CHANGED: no
- N/A_REASON: This refactor localizes repository governance assets and validator wording only; it does not change any product-facing API or frontend surface.
- INTERNAL_ONLY_REASON: Documentation, template, validator, and test literals are synchronized to English while preserving machine-facing contracts.

## Mapping Table

| Endpoint / Event | DTO / Schema | Frontend Page / Component | State Management | Test Point | Notes |
| --- | --- | --- | --- | --- | --- |
| N/A | N/A | N/A | N/A | Tracked-file Chinese string audit and repository unit suite | Internal repository localization only |

## Review Conclusion

- REVIEW_OWNER: baseline maintainer
- RESULT: `synced`
