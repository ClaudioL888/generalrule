# Brainstorming Brief SPEC-20260310-english-localization

- SPEC_ID: SPEC-20260310-english-localization
- GOAL: Translate the entire repository governance baseline into English without changing file-system or runtime contracts.

## 1. Goals and Non-Goals

- Goals: deliver a fully English root baseline, mirrored bootstrap assets, and synchronized validator/test wording
- Non-goals: rename files, keys, placeholders, environment variables, or directory structure

## 2. Users and Scenarios

- Target users: maintainers and downstream teams adopting this repository as a governance baseline
- Core scenario: initialize and operate a project entirely with English governance assets
- Pain points: mixed-language docs, validator drift, extra onboarding work

## 3. Technical Choice Candidates

- Option A: translate only markdown
- Option B: translate markdown plus validator/test literals
- Key tradeoff: Option B is larger but keeps the repository self-consistent and gate-safe

## 4. Risks and Boundaries

- Risks: hidden Chinese literals remain in scripts or tests
- Constraints: preserve all machine-facing contracts and existing workflow semantics
- Security boundaries: no change to approval, permission, release, or exception behavior

## 5. Decision Summary (Before Gate 0)

- Recommended option: translate the full tracked repository text surface with structure-preserving wording
- Reason: downstream consumers need one English baseline, and partial translation breaks gate alignment
- Open questions: none remaining after the approved execution plan
