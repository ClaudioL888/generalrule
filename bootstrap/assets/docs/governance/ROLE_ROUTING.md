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

- When `WORK_TYPE=fast-track`, `TASK_TYPE` must be `ops`.
- Follow-up documents and regression records must be completed within 24 hours.
