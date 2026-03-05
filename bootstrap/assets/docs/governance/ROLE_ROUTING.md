# Role Routing Matrix

## Task Type -> Allowed Role Flow

### feature

Founder -> PM -> Architect -> Planner -> Dev -> QA -> Reviewer -> Release-Ops -> Growth -> PM

### bugfix

Planner -> Dev -> QA -> Reviewer -> Release-Ops -> Planner

### refactor

Architect -> Planner -> Dev -> QA -> Reviewer -> Release-Ops -> Architect

### ops

Planner -> Dev -> QA -> Reviewer -> Release-Ops -> Planner

### content

PM -> Content-Growth -> Reviewer -> PM

## Fast-Track Rule

- 当 `WORK_TYPE=fast-track` 时，`TASK_TYPE` 必须为 `ops`。
- 必须在 24h 内补齐 follow-up 文档与回归记录。
