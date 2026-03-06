---
artifact_type: feature-plan
owner_role: Planner
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "{{plan_non_goal}}"
acceptance_metrics:
  - "{{acceptance_1}}"
risks:
  - "{{risk_1}}"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Feature Plan {{spec_id}}

## 1. 计划目标

- 目标：{{plan_goal}}
- 范围：{{core_use_case}}
- 当前阶段：{{work_type}}

## 2. 任务拆解

- 任务1：{{task_1}}
- 任务2：{{task_2}}

## 3. 验收条件

- 验收1：{{acceptance_1}}
- 验收2：{{acceptance_2}}

## 4. 测试点

- 测试点1：{{test_point_1}}
- 测试点2：{{test_point_2}}

## 5. 执行约束

- 不跨任务顺手重构
- 每次只推进一个计划项
- 失败必须回到 Observe/Repair

## 6. 风险与回退

- 风险：{{risk_1}}
- 缓解：{{mitigation_1}}
- 回滚策略：{{rollback_strategy}}
