# Pull Request

## Summary

- 变更内容：{{change_summary}}
- 关联目标：{{linked_goal}}

## Scope Check

- [ ] 本 PR 只覆盖一个计划项
- [ ] 未进行跨任务顺手重构

## Required Evidence

- [ ] 已执行 tests/build/lint 并附结果摘要
- [ ] 已更新 docs/status
- [ ] 已更新 docs/status/current-task.md 且字段完整
- [ ] 已更新 docs/specs 对应 SPEC 文档
- [ ] 已更新 spec quality review 文档或记录降级原因
- [ ] 已更新 docs/design 对应 Design 文档
- [ ] 已更新 docs/plans 对应 Plan 文档
- [ ] 已更新 docs/contracts API/前端映射文档
- [ ] 已更新角色交接文档（handoff）
- [ ] 已更新 docs/release/CHANGELOG.md
- [ ] 已更新 docs/release/RELEASE_NOTES.md

## Governance Metadata (必填，CI 解析)

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
- CONTRACT_SYNC_STATUS: synced
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

- 风险：{{risk_summary}}
- 回滚方案：{{rollback_summary}}
