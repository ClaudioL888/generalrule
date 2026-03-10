# Exceptions Policy

## Principle

Exceptions may exist, but they must be traceable, explainable, and repayable.

## Hard Rules

1. When `EXCEPTION_STATUS` is not `none`, `EXCEPTION_LINK` is required.
2. `fast-track` work must record an exception document and a follow-up deadline.
3. Exception documents must state scope, risk, mitigation actions, and follow-up timing.
4. Exceptions are temporary by default and may not become long-term hidden rules.

## Required Fields

- `EXCEPTION_ID`
- `SPEC_ID`
- `REASON`
- `SCOPE`
- `MITIGATION`
- `FOLLOWUP_DEADLINE`
- `ADR_LINK`
