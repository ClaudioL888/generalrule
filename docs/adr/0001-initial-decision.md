---
artifact_type: adr
owner_role: Architect
status: accepted
linked_goal_id: "goal-baseline-english-0001"
non_goals:
  - "A freeform rewrite of repository structure"
acceptance_metrics:
  - "Validator-facing wording stays synchronized across the repository"
risks:
  - "Different English terms drift across root and bootstrap assets"
approvals_required:
  - founder
last_updated: "2026-03-10"
---

# ADR ADR-0001: Use Structure-Preserving English Localization for the Baseline

## Status

`accepted`

## Context

The repository mixes English structure with Chinese prose across root docs, mirrored bootstrap assets, validators, tests, and skill metadata. A direct translation is required, but the baseline also has machine-facing wording checks that must remain aligned.

## Decision

Translate repository text assets into English while preserving paths, filenames, placeholders, metadata keys, environment variables, and command interfaces. Validator and test literals that depend on human-facing wording are updated in the same change.

## Security Boundary

security_boundary: repository content and gate wording only
- Authentication and authorization: unchanged
- Data classification and access: unchanged
- External dependencies and trust boundary: unchanged; no new third-party runtime dependency is introduced for localization

## Alternatives Considered

1. Translate only markdown files - simpler upfront, but it leaves validator/test drift and breaks the baseline contract.
2. Keep a bilingual repository - reduces immediate breakage risk, but doubles long-term maintenance cost and leaves inconsistent downstream output.

## Consequences

- Positive impact: downstream projects receive a single English governance baseline and validators stay aligned
- Negative impact: the change touches many files at once and requires broad regression verification
- Operations impact: gate and test outputs become English, which simplifies maintenance for English-speaking teams

## Review Plan (Monthly)

- Review date: 2026-04-10
- Review conclusion: `continue`

## References and Evidence

- SOURCE: docs/design/SPEC-20260310-english-localization-design.md | TYPE: internal | NOTE: Localization implementation design and tradeoffs
- SOURCE: docs/specs/SPEC-20260310-english-localization.md | TYPE: internal | NOTE: Scope and acceptance criteria for the repository-wide translation
