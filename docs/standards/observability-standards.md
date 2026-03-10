# Observability Standards

## Scope

Applies to new business paths, releases, operations work, and regression verification.

## Hard Rules

1. Every new critical flow must define at least one of logs, metrics, or alerts.
2. Releases must state the observation window and rollback trigger conditions.
3. Weekly maintenance must review both engineering metrics and business metrics.
4. Significant drift must update a runbook or exception record.

## Recommended Metrics

1. DORA: lead time, deploy frequency, change failure rate, restore time.
2. Engineering: CI failure rate, rework ratio, hotfix ratio.
3. Business: core AARRR metrics.

## Minimum Acceptance

1. `docs/metrics/ENGINEERING_METRICS.md` exists.
2. At least one weekly metrics record exists.
3. A monthly maintenance record exists.
