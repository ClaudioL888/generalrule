---
artifact_type: feature-design
owner_role: Architect
status: approved
linked_goal_id: "goal-baseline-english-0001"
non_goals:
  - "Restructure the repository"
acceptance_metrics:
  - "All validator-facing headings remain machine-checkable after translation"
risks:
  - "Terminology drift between root docs, bootstrap assets, and tests"
approvals_required:
  - founder
last_updated: "2026-03-10"
---

# Feature Design SPEC-20260310-english-localization

## 1. Design Goals

- Goal: Produce a single English wording layer across root docs, bootstrap docs, skill assets, validators, and tests.
- Non-goal: Change file layout, metadata keys, placeholder syntax, or command-line behavior.

## 2. Technical Approach

- Chosen stack: existing shell, markdown, YAML, and repository test harness
- Interface contract: preserve all command names, environment variables, metadata keys, and placeholders
- Input/output model: tracked text files are rewritten in place; validators and tests are updated only where they depend on translated literals

## 3. Data and State

- Entity definitions: root source-of-truth docs, mirrored bootstrap assets, and validator/test literals
- State flow: translate source docs first, mirror bootstrap assets second, then synchronize validator and test expectations
- Compatibility strategy: wording changes only; structural and runtime contracts remain stable

## 4. Security and Boundaries

- Security boundary: translation must not weaken approval, permission, exception, or release rules
- Authorization boundary: unchanged from the current baseline
- Data-access boundary: no data-path changes; repository content only

## 5. Observability

- Observability plan: rely on repository unit tests and string audits to detect drift
- Alert thresholds: tracked Chinese-text audit must return zero matches after approved exceptions
- Key metrics: pass/fail state for the local test suite and targeted gate checks

## 6. Design Tradeoffs

- Key tradeoff: choose structure-preserving translation instead of freer rewriting so validators and generated assets stay aligned
- Risk: a few literals may remain Chinese inside scripts or fixtures
- Mitigation: scan the entire tracked tree after translation and fix residual matches before completion

## 7. References and Evidence

- SOURCE: docs/specs/SPEC-20260310-english-localization.md | TYPE: internal | NOTE: Approved scope and acceptance criteria for the translation work
- SOURCE: docs/USAGE.md | TYPE: internal | NOTE: Gate workflow that the translated repository must continue to satisfy
