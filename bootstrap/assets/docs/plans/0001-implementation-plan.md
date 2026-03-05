---
artifact_type: implementation-plan
owner_role: Planner
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "跨任务顺手重构"
acceptance_metrics:
  - "任务按验收条件通过率"
risks:
  - "任务粒度过大"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# 实施计划模板

## 0. 计划类型

- WORK_TYPE: `full | mini | fast-track`
- 原因：{{work_type_reason}}

## 1. 范围说明

- 本计划目标：{{plan_goal}}
- 本计划不做：{{plan_non_goal}}

## 2. 任务分解（强制：单任务进行中）

| Task ID | 描述 | 状态 | 验收条件 | 测试点 | 负责人 |
| --- | --- | --- | --- | --- | --- |
| T1 | {{task_1}} | todo | {{acceptance_1}} | {{test_point_1}} | Dev |
| T2 | {{task_2}} | todo | {{acceptance_2}} | {{test_point_2}} | Dev |

规则：同一时刻最多 1 个 `in-progress`。

## 3. 每任务执行模板（可复制）

### Task {{task_id}}

- 输入：{{task_input}}
- 编辑边界：{{edit_boundary}}
- 测试命令：{{test_command}}
- 预期结果：{{expected_result}}
- 文档更新：{{docs_update_path}}
- 禁止项：跨任务重构

## 4. 风险与应对

- 风险：{{risk_1}}
- 触发条件：{{trigger_1}}
- 应对动作：{{mitigation_1}}

## 5. 完成标准

- [ ] 所有任务有测试点与验收条件
- [ ] 每个任务附测试结果
- [ ] docs/status 与 docs/release 已同步更新
