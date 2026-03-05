---
artifact_type: release-notes
owner_role: Release-Ops
status: draft
linked_goal_id: "{{goal_id}}"
non_goals:
  - "重复 changelog 全量内容"
acceptance_metrics:
  - "用户可理解的变更说明"
risks:
  - "发布后已知风险未披露"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# RELEASE NOTES 模板

## 版本信息

- 版本：{{version}}
- 发布时间：{{release_time}}
- 发布负责人：{{release_owner}}

## 本次用户价值

{{user_value_summary}}

## 变更摘要

- 功能：{{feature_summary}}
- 修复：{{fix_summary}}
- 兼容性：{{compat_summary}}

## 已知风险与缓解

- 风险：{{known_risk}}
- 缓解：{{mitigation}}

## 发布检查

- [ ] 测试结果已附
- [ ] 回滚方案已验证
- [ ] 监控阈值已更新
