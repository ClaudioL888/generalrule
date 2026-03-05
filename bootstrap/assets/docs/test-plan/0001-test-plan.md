---
artifact_type: test-plan
owner_role: QA
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "仅做冒烟测试"
acceptance_metrics:
  - "回归缺陷检出率"
risks:
  - "测试覆盖失衡"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Test Plan 模板

## 1. 测试目标

{{test_goal}}

## 2. 测试金字塔分配

- Unit: {{unit_scope}}（建议占比 >= 70%）
- Integration: {{integration_scope}}（建议占比 <= 20%）
- E2E: {{e2e_scope}}（建议占比 <= 10%）

## 3. 覆盖矩阵

| 场景 | 层级 | 用例 | 通过标准 |
| --- | --- | --- | --- |
| 核心路径 | Unit | {{case_1}} | {{pass_criteria_1}} |
| 跨模块流程 | Integration | {{case_2}} | {{pass_criteria_2}} |
| 用户关键旅程 | E2E | {{case_3}} | {{pass_criteria_3}} |

## 4. 边界与异常场景

- 边界：{{edge_case_1}}
- 异常：{{error_case_1}}
- 回归重点：{{regression_focus}}

## 5. 结果报告模板

- 执行时间：{{execution_time}}
- 执行命令：{{commands}}
- 结果摘要：{{result_summary}}
- 风险结论：{{risk_summary}}
