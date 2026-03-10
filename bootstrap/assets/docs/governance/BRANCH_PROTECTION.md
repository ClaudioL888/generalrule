# Branch Protection Baseline

> This document provides configuration guidance plus checkable items. It does not call the GitHub API to change repository settings automatically.

## Target Branches

- Default branch: `main` (if the project uses `master`, apply equivalent settings)

## Recommended Required Settings

1. Require a pull request before merging
2. Require approvals (at least 1)
3. Dismiss stale approvals when new commits are pushed
4. Require review from Code Owners
5. Require status checks to pass before merging
6. Require branches to be up to date before merging
7. Restrict who can push to matching branches (follow org policy)
8. Do not allow bypassing the settings above

## Required Status Checks (Suggested Names)

- `governance-check`
- `security-policy-gate`
- `secret-scan`
- `dependency-review`

Note: `spec-pack`, `role-flow`, and `api-frontend-sync` run as hard-blocking steps inside the `governance-check` job.

## Recommended Change Process

1. Validate the rule combination in a test repository first
2. Enable it in the production repository second
3. Review branch protection and CODEOWNERS alignment once per month
