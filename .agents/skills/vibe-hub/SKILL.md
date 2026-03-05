---
name: vibe-hub
description: 单入口编排 skill，统一路由到治理流程、任务包与本地门禁。
---

# Vibe Hub Skill

## Use When

- 你希望只用一个入口驱动完整规范流程
- 你要在会话中快速进入 start/status/task-pack/gates/full-loop

## Do Not Use When

- 仅需单条独立脚本检查且不需要流程路由

## Commands

```bash
bash .agents/skills/vibe-hub/scripts/run.sh start --goal "一句话目标" --task-type feature --work-type full --spec-id SPEC-0001-core-flow
bash .agents/skills/vibe-hub/scripts/run.sh status
bash .agents/skills/vibe-hub/scripts/run.sh task-pack --spec-id SPEC-0001-core-flow --task-type feature --current-role Dev --next-role QA
bash .agents/skills/vibe-hub/scripts/run.sh gates
bash .agents/skills/vibe-hub/scripts/run.sh full-loop --spec-id SPEC-0001-core-flow --task-type feature --current-role Dev --next-role QA --work-type full
```

## Routing Contract

- `start` -> `run-blackbox-flow.sh prepare -> approve Gate 0 -> start`
- `status` -> `run-blackbox-flow.sh status`
- `task-pack` -> `new-task-pack.sh`
- `gates` -> `run-local-gates.sh`
- `full-loop` -> `run-full-loop.sh`

所有路由步骤应保留并传递 `[step-report]` 输出。
