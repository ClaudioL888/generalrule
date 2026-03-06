---
artifact_type: design-doc
owner_role: Architect
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "{{non_goal_1}}"
acceptance_metrics:
  - "{{design_metric_1}}"
risks:
  - "{{risk_1}}"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Design Doc 模板

## 1. 背景与目标

- 背景：{{context}}
- 设计目标：{{design_goal}}
- 设计非目标：{{design_non_goal}}

## 2. 技术选型决策表（必填）

| 维度 | 方案 A | 方案 B | 选择 | 理由 |
| --- | --- | --- | --- | --- |
| 框架 | {{stack_a}} | {{stack_b}} | {{chosen_stack}} | {{tradeoff_reason}} |
| 数据层 | {{data_a}} | {{data_b}} | {{chosen_data}} | {{decision_tradeoff}} |
| 可观测 | {{obs_a}} | {{obs_b}} | {{chosen_obs}} | {{ops_reason}} |

## 3. 架构与模块

- 架构图：{{architecture_diagram_link}}
- 核心模块：{{core_components}}
- 数据流：{{data_flow}}

## 4. 接口与契约

- API/事件：{{api_contract}}
- 输入输出：{{io_schema}}
- 版本兼容策略：{{compat_strategy}}

## 5. 数据模型

- 实体定义：{{entity_definitions}}
- 索引与约束：{{constraints}}
- 迁移策略：{{migration_strategy}}

## 6. 边界情况与失败模式（必填）

- 边界情况：{{edge_case_1}}
- 错误处理：{{error_handling}}
- 降级策略：{{degrade_strategy}}
- 回滚策略：{{rollback_strategy}}

## 7. 可观测性与安全边界

- 指标/日志/追踪：{{observability_plan}}
- 告警阈值：{{alert_thresholds}}
- 权限与密钥边界：{{security_boundary}}

## 8. 测试策略对齐

- 单测重点：{{unit_focus}}
- 集成测试重点：{{integration_focus}}
- E2E 范围：{{e2e_scope}}

## 9. 验收清单

- [ ] 选型有对比与取舍说明
- [ ] 边界情况与错误处理完整
- [ ] 可观测性与安全边界明确
- [ ] Founder 批准

## 10. 引用与依据

- SOURCE: TODO(citation_source_1) | TYPE: primary | NOTE: TODO(citation_note_1)
- SOURCE: TODO(citation_source_2) | TYPE: internal | NOTE: TODO(citation_note_2)
