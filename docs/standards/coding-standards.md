# Coding Standards

## Scope

Applies to all code changes, script changes, and configuration changes.

## Hard Rules

1. Default to the smallest possible diff. Avoid unrelated refactors.
2. Every file change must map to the active `SPEC_ID`.
3. Add tests for new logic before writing the implementation when practical.
4. Small comments are allowed for complex logic, but comment noise is forbidden.
5. Names must express business meaning. Avoid generic names such as `tmp`, `misc`, or `helper`.
6. Every change must consider rollback paths and failure modes.
7. Do not introduce unexplained global side effects.

## Recommended Rules

1. Prefer local changes within a single task over broad cross-cutting edits.
2. Reuse existing scripts and templates before introducing new structures.
3. Keep external interfaces backward compatible whenever possible.

## Minimum Acceptance

1. The change maps to a single plan item.
2. Tests and documentation were updated together.
3. During review, the implementer can explain why the change is the minimum necessary diff.
