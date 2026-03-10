---
artifact_type: feature-spec
owner_role: PM-Discovery
status: approved
linked_goal_id: "goal-baseline-english-0001"
non_goals:
  - "Convert the repository into a bilingual baseline"
acceptance_metrics:
  - "Tracked Chinese text count reaches zero"
risks:
  - "Some validator-facing literals remain untranslated"
approvals_required:
  - founder
last_updated: "2026-03-10"
---

# Feature Spec SPEC-20260310-english-localization

## 1. Goals and Non-Goals

- Goal: Translate the repository-wide governance baseline into English while preserving every machine-facing path, placeholder, key, and runtime contract.
- Non-goal: Change repository structure, identifiers, or workflow semantics.

## 2. User Stories

- Target persona: Maintainers and downstream project teams adopting this baseline
- Core scenario: Consume and operate the baseline entirely in English, including generated docs and gate output
- User value: Reduce onboarding friction and eliminate a manual translation step for every new project

## 3. API Changes

- API_SURFACE_CHANGED: no
- API change policy: no runtime API surface change; validator wording only
- Contract versioning strategy: preserve current script interfaces and metadata keys

## 4. Frontend Changes

- FRONTEND_SURFACE_CHANGED: no
- Frontend binding strategy: not applicable; docs and templates only
- Page/component impact: root docs, bootstrap docs, prompts, skills, validators, and tests are updated to English wording

## 5. Acceptance Criteria

- Acceptance criteria: all tracked Chinese text is replaced with approved English wording and the unit suite passes
- Test point: `git ls-files | xargs rg -n "[\p{Han}]"` returns no tracked matches after approved exceptions
- Metric: unit gate pass rate remains 100% for the repository test suite

## 6. Risks

- Primary risk: shell validators and tests may still expect Chinese headings or labels after the doc layer changes
- Mitigation action: update all validator/test literals in the same change and rerun the relevant tests plus the full suite

## 7. Rollback Plan

- Rollback strategy: revert the translation branch as one coherent change if gate or consumer compatibility issues appear
- Rollback summary: restore pre-translation wording while preserving any unrelated upstream work in the base branch
- Release owner: repository maintainer
- Contract review owner: baseline maintainer

## 8. References and Evidence

- SOURCE: docs/prd/0001-problem-statement.md | TYPE: internal | NOTE: Product framing for the English baseline effort
- SOURCE: AGENTS.md | TYPE: internal | NOTE: Governance constraints that translation must preserve
