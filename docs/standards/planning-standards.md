# Planning Standards

## Scope

Applies to Planner-stage task breakdown, acceptance criteria, test points, and execution order.

## Hard Rules

1. Only one plan item may be in progress at a time.
2. Every task must include acceptance criteria and test points.
3. The plan must state which documents need synchronized updates.
4. Cross-task refactors may not be hidden inside the current plan item.
5. Task breakdown must not skip failure paths or rollback considerations.

## Recommended Rules

1. Target task size should stay within half a day to one day of work.
2. Acceptance criteria should be observable and testable.
3. Schedule risk-reducing and uncertainty-closing tasks first.

## Minimum Acceptance

1. The document referenced by `PLAN_LINK` exists and matches the active `SPEC_ID`.
2. The current task has explicit `TASK_ID`, `acceptance`, and `test_point` entries.
3. After Planner handoff, Dev does not need to break the task down again.
