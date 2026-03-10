# Pull Request

## Summary

- Change summary: {{change_summary}}
- Linked goal: {{linked_goal}}

## Scope Check

- [ ] This PR covers only one plan item
- [ ] No side refactors were slipped in across tasks

## Required Evidence

- [ ] Tests/build/lint were run and the result summary is attached
- [ ] `docs/status` was updated
- [ ] `docs/status/current-task.md` was updated with complete fields
- [ ] The corresponding SPEC doc under `docs/specs` was updated
- [ ] The spec quality review doc was updated or the downgrade reason was recorded
- [ ] The corresponding Design doc under `docs/design` was updated
- [ ] The corresponding Plan doc under `docs/plans` was updated
- [ ] The API/frontend mapping doc under `docs/contracts` was updated
- [ ] The role handoff doc was updated
- [ ] The exception doc was updated or `EXCEPTION_STATUS=none` is explicit
- [ ] `docs/release/CHANGELOG.md` was updated
- [ ] `docs/release/RELEASE_NOTES.md` was updated

## Governance Metadata (Required, parsed by CI)

- WORK_TYPE: full
- TASK_TYPE: feature
- PRD_LINK: docs/prd/0001-problem-statement.md
- DESIGN_LINK: docs/design/SPEC-0001-core-flow-design.md
- PLAN_LINK: docs/plans/SPEC-0001-core-flow-plan.md
- TASK_STATE_LINK: docs/status/current-task.md
- SPEC_LINK: docs/specs/SPEC-0001-core-flow.md
- SPEC_QUALITY_STATUS: approved
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/SPEC-0001-core-flow.md
- API_FRONTEND_MAP_LINK: docs/contracts/SPEC-0001-core-flow-api-frontend-map.md
- ROLE_HANDOFF_LINK: docs/status/handoffs/SPEC-0001-core-flow-dev-to-qa.md
- CURRENT_ROLE: Dev
- NEXT_ROLE: QA
- STANDARDS_PROFILE: feature:full
- ROLE_DOD_STATUS: met
- EVIDENCE_STATUS: complete
- DEVIATION_STATUS: none
- CONTRACT_SYNC_STATUS: synced
- EXCEPTION_STATUS: none
- EXCEPTION_LINK: N/A
- REWORK_RISK: medium
- METRICS_IMPACT: engineering
- MINI_PLAN_LINK: N/A
- INCIDENT_LINK: N/A
- FAST_TRACK_FOLLOWUP_LINK: N/A
- TEST_RESULTS: unit=pass;integration=pass;e2e=pass
- APPROVAL_EXECUTION: approved
- APPROVAL_DEPENDENCY: approved
- APPROVAL_PERMISSION: approved
- CODEOWNER_REVIEW: approved
- SECURITY_REVIEW: approved
- RELEASE_REVIEW: approved
- APPROVAL_EVIDENCE: {{approval_reference}}

## Test Output Summary

```text
{{paste_test_output_here}}
```

## Risk and Rollback

- Risk: {{risk_summary}}
- Rollback plan: {{rollback_summary}}
