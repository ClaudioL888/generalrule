---
artifact_type: test-plan
owner_role: QA
status: draft
linked_goal_id: "goal-baseline-english-0001"
non_goals:
  - "Rely only on smoke checks"
acceptance_metrics:
  - "Repository regression checks remain green after translation"
risks:
  - "Literal drift causes hidden gate failures"
approvals_required:
  - founder
last_updated: "2026-03-10"
---

# Test Plan: Repository-Wide English Localization

## 1. Testing Goal

Verify that the repository can operate entirely with English governance wording without breaking scripts, templates, or tests.

## 2. Test Pyramid Allocation

- Unit: repository shell tests and targeted validator fixtures (recommended share >= 70%)
- Integration: initializer output plus gate-script interactions (recommended share <= 20%)
- E2E: not applicable for this repository-level content refactor (recommended share <= 10%)

## 3. Coverage Matrix

| Scenario | Layer | Case | Pass Criteria |
| --- | --- | --- | --- |
| Core localization path | Unit | Tracked-file Chinese string audit | No tracked matches remain |
| Validator compatibility | Integration | Run targeted validator tests after literal updates | All updated gate tests pass |
| Initializer regression | Integration | `tests/unit/test_init_project.sh` | Generated project contains English assets and passes expectations |

## 4. Boundary and Error Scenarios

- Boundary: mirrored bootstrap assets stay aligned with root truth documents
- Error: validator literals still target Chinese section names or labels
- Regression focus: spec-pack, citation-quality, role-flow, api/frontend-sync, standards-binding, init-project, and skill-script tests

## 5. Result Report Template

- Execution time: 2026-03-10
- Commands: targeted tests + `for t in tests/unit/*.sh; do bash "$t"; done`
- Result summary: pending until execution
- Risk conclusion: medium until full verification is complete
