---
name: vibe-task-pack
description: 为单个任务创建或更新 Spec/API-Frontend 映射/角色交接与 current-task 关键字段。
---

# Vibe Task Pack Skill

## Use When

- 新功能或新任务开始前
- 当前任务缺少 spec/map/handoff 文档
- 需要修正 current-task 中任务标识与角色信息

## Do Not Use When

- 仅执行门禁，不需要更新任务包

## Required Inputs

- `SPEC_ID`
- `TASK_TYPE` (`feature|bugfix|refactor|ops|content`)
- `CURRENT_ROLE`
- `NEXT_ROLE`

## Commands

```bash
bash .agents/skills/vibe-task-pack/scripts/new-task-pack.sh \
  --spec-id SPEC-0001-core-flow \
  --task-type feature \
  --current-role Dev \
  --next-role QA
```
