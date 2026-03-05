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
- [ ] 已更新 docs/release/CHANGELOG.md
- [ ] 已更新 docs/release/RELEASE_NOTES.md

## Governance Metadata (必填，CI 解析)

- WORK_TYPE: full
- PRD_LINK: docs/prd/0001-problem-statement.md
- DESIGN_LINK: docs/design/0001-architecture-overview.md
- PLAN_LINK: docs/plans/0001-mvp-implementation-plan.md
- TASK_STATE_LINK: docs/status/current-task.md
- MINI_PLAN_LINK: N/A
- INCIDENT_LINK: N/A
- FAST_TRACK_FOLLOWUP_LINK: N/A
- TEST_RESULTS: unit=pass;integration=pass;e2e=pass
- APPROVAL_EXECUTION: approved
- APPROVAL_DEPENDENCY: approved
- APPROVAL_PERMISSION: approved
- APPROVAL_EVIDENCE: {{approval_reference}}

## Test Output Summary

```text
{{paste_test_output_here}}
```

## Risk and Rollback

- 风险：{{risk_summary}}
- 回滚方案：{{rollback_summary}}
