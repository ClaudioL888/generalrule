# Task Type Standard Profiles

## Purpose

Defines which standards are enabled by default for each task type so that bugfix, refactor, ops, and content work do not all inherit feature-level intensity.

## Profiles

1. `feature`
- Strategy: full standards binding
- Meaning: follow the complete role matrix without trimming standards

2. `bugfix`
- Standards: `testing`, `documentation`, `release`
- Meaning: prioritize fix verification, regression traceability, and release notes

3. `refactor`
- Standards: `design`, `coding`, `testing`
- Meaning: prioritize design consistency, implementation boundaries, and regression verification

4. `ops`
- Standards: `release`, `observability`, `security`
- Meaning: prioritize releasable, monitorable, reversible operations work

5. `content`
- Standards: `documentation`, `metrics`
- Meaning: prioritize consistency between content assets and metrics/growth feedback
