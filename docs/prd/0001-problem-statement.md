---
artifact_type: prd
owner_role: PM-Discovery
status: approved
linked_goal_id: "goal-baseline-english-0001"
non_goals:
  - "Rename files, paths, placeholders, or environment variables"
acceptance_metrics:
  - "Zero tracked Chinese strings remain in the repository after approved exceptions are accounted for"
risks:
  - "Validator literals drift away from translated documents"
approvals_required:
  - founder
last_updated: "2026-03-10"
---

# PRD: Repository-Wide English Localization Baseline

## 1. Problem Definition

- Current state: The repository mixes English structure with large amounts of Chinese prose across documentation, templates, skill assets, validators, and tests.
- Problem: The baseline is difficult to reuse across teams that expect an English governance surface, and validator literals currently depend on Chinese headings and labels.
- Why now: This repository is the seed baseline for other projects, so localization drift here propagates into every generated workspace.

## 2. Target Users

- Target persona: Maintainers and adopters of the Generalrule governance baseline
- Core scenario: Initialize a new project and work entirely with English governance docs, prompts, templates, and gate output
- Key pain points: Mixed-language artifacts, mismatched validator expectations, and extra onboarding cost for non-Chinese-speaking users

## 3. Value Proposition

- User value: Provide one consistent English baseline that can be copied into new projects without manual translation work
- Differentiation: Documentation, templates, skill assets, gates, and tests stay synchronized instead of translating only the human-facing layer

## 4. Goals and Non-Goals

- Goals:
  - Translate all tracked repository text assets into English while preserving structure
  - Keep validators, tests, and generated assets aligned with the translated wording
  - Preserve file paths, identifiers, placeholders, and command contracts
- Non-goals:
  - Rename files or directories
  - Redesign the governance model
  - Introduce bilingual maintenance overhead

## 5. Acceptance Metrics (AARRR)

- Acquisition: New adopters can initialize an English-only governance baseline without post-processing
- Activation: Root and generated docs read naturally in English and pass the existing validation chain
- Retention: Future maintenance can update a single English baseline instead of dual-language assets
- Revenue: N/A for this infrastructure repository
- Referral: Maintainers can share the baseline with teams that require English governance assets

## 6. Constraints and Dependencies

- Business constraints: Keep the baseline compatible with current initializer and gate flow
- Compliance constraints: Do not remove approval, exception, or evidence requirements during translation
- External dependencies: Existing shell validators, unit tests, and initializer templates

## 7. Risks and Assumptions

- Assumption: Preserving document structure while translating wording is sufficient for downstream usability
- Risk: Validator strings or tests may still point at Chinese headings after the markdown layer is translated
- Mitigation: Translate validator/test literals in the same change and run the full unit suite

## 8. Acceptance Checklist

- [ ] All tracked human-facing markdown is in English
- [ ] Validator and test literals are synchronized with the translated headings and labels
- [ ] Founder approval captured through this execution request

## 9. References and Evidence

- SOURCE: docs/USAGE.md | TYPE: internal | NOTE: Repository-level usage and gate workflow requirements
- SOURCE: AGENTS.md | TYPE: internal | NOTE: Governing rules for translation scope and gate synchronization
