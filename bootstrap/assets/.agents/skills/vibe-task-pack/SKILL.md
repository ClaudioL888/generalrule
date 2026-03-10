---
name: vibe-task-pack
description: Create or update the Spec/Design/Plan/API-Frontend mapping/role handoff and key current-task fields for a single task.
---

# Vibe Task Pack Skill

## Use When

- Before starting a new feature or task
- The current task is missing spec/design/plan/map/handoff documents
- You need to correct task identity or role information in `current-task`

## Do Not Use When

- You are only running gates and do not need to update the task pack

## Required Inputs

- `SPEC_ID`
- `TASK_TYPE` (`feature|bugfix|refactor|ops|content`)
- `CURRENT_ROLE`
- `NEXT_ROLE`

## Commands

```bash
bash .agents/skills/vibe-task-pack/scripts/new-task-pack.sh   --spec-id SPEC-0001-core-flow   --task-type feature   --current-role Dev   --next-role QA
```

The script creates these artifacts together:

- `docs/specs/<SPEC_ID>.md`
- `docs/design/<SPEC_ID>-design.md`
- `docs/plans/<SPEC_ID>-plan.md`
- `docs/contracts/<SPEC_ID>-api-frontend-map.md`
- `docs/status/handoffs/*.md`
