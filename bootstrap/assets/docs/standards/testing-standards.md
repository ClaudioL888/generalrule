# Testing Standards

## Scope

Applies to unit, integration, E2E, and regression testing.

## Hard Rules

1. Every functional change must include test evidence.
2. Write a failing test first when practical, then the minimal implementation, then rerun verification.
3. Test names must describe behavior and expected result.
4. Critical paths must cover at least one success path and one failure path.
5. A readable test summary must be written into the PR or `current-task` before release.

## Test Pyramid

1. unit > integration > e2e.
2. E2E covers only critical journeys and does not replace lower-layer tests.
3. Integration tests should focus on APIs, data flow, and boundary conditions.

## Minimum Acceptance

1. `TEST_COMMANDS` is non-empty.
2. `TEST_RESULT` is non-empty and readable.
3. Regression risk points are traceable in the test plan or `current-task`.
