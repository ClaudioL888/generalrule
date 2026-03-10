# Design Standards

## Scope

Applies to Architect-stage design for interfaces, data models, boundaries, security, and observability.

## Hard Rules

1. Design must describe system boundaries, component relationships, and key data flows.
2. External interfaces, I/O shapes, and failure modes must be explicit.
3. Design must cover both security boundaries and observability boundaries.
4. If implementation diverges from design, update the design first before continuing.
5. Key decisions must include tradeoffs, not just conclusions.

## Recommended Rules

1. Use the smallest architecture that supports the current task. Do not over-design for the future.
2. State clearly which modules are reusable and which should stay unabstracted for now.
3. Define shared naming and versioning strategy for frontend/backend contracts.

## Minimum Acceptance

1. The document referenced by `DESIGN_LINK` exists and matches the active `SPEC_ID`.
2. Interface, model, security, and observability each have at least one explicit entry.
3. The design gives Planner enough clarity to break work into testable tasks.
