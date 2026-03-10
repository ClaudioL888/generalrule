# Security Standards

## Scope

Applies to dependency changes, permission changes, interface changes, and data-access changes.

## Hard Rules

1. Never commit keys, tokens, or plaintext credentials.
2. Every new input must have validation and error handling.
3. Permission-boundary changes must be documented in design or an ADR.
4. Dependency changes must describe risk and rollback.
5. Changes involving execution privileges, network access, or deployment must include approval evidence.

## Minimum Acceptance

1. `incident-playbook` exists and can be referenced.
2. `RELEASE_NOTES.md` reflects security impact and rollback.
3. Any exceptional security decision is captured in an exception or ADR.
