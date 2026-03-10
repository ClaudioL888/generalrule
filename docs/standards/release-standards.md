# Release Standards

## Scope

Applies to Reviewer and Release-Ops work on release notes, rollback, monitoring, and release decisions.

## Hard Rules

1. `CHANGELOG.md` and `RELEASE_NOTES.md` must exist before release.
2. The release must describe the rollback strategy and the secondary fallback path.
3. Key test results and contract sync state must be confirmed before release.
4. Monitoring and alert checks must be traceable in the release path.
5. Every fast-track release must leave an exception record and a follow-up record.

## Recommended Rules

1. Organize release notes by user-visible change, not by file list.
2. Call out security impact, operations impact, and cost impact separately.
3. Keep release-window actions minimal and reversible.

## Minimum Acceptance

1. `CURRENT_GATE` has reached at least `Gate 6`.
2. `TEST_RESULT`, `CONTRACT_SYNC_STATUS`, and rollback notes are all non-empty.
3. Post-release review can trace back to the current handoff and release documents.
