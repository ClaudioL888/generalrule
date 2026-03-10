---
artifact_type: feature-plan
owner_role: Planner
status: active
linked_goal_id: "goal-baseline-english-0001"
non_goals:
  - "Translate only the markdown layer and leave validators behind"
acceptance_metrics:
  - "Zero tracked Chinese strings and green unit suite"
risks:
  - "A partial translation leaves root and bootstrap content inconsistent"
approvals_required:
  - founder
last_updated: "2026-03-10"
---

# Feature Plan SPEC-20260310-english-localization

## 1. Plan Goals

- Goal: Deliver an English-only repository baseline on branch `codex/english-localization`
- Scope: root docs, bootstrap docs, skill assets, validator literals, tests, and governance artifacts for this task
- Current phase: full

## 2. Task Breakdown

- Task 1: Translate root source-of-truth documents, prompts, standards, skill docs, and task governance artifacts
- Task 2: Translate mirrored bootstrap assets and PR template content
- Task 3: Update validator and test literals, then run repository verification and push the branch

## 3. Acceptance Criteria

- Acceptance 1: Root source-of-truth docs and task artifacts are fully English and structurally intact
- Acceptance 2: Bootstrap assets mirror the translated wording where required
- Acceptance 3: Validators/tests pass with the new English headings and labels

## 4. Test Points

- Test point 1: Chinese text audit across tracked files returns zero matches
- Test point 2: Targeted validator and unit tests pass after literal synchronization
- Test point 3: Full `tests/unit/*.sh` loop passes

## 5. Execution Constraints

- Do not rename files, directories, placeholders, or metadata keys
- Advance one plan item at a time and keep changes structure-preserving
- Any failed gate or test sends the work back through Observe/Repair before proceeding

## 6. Risk and Rollback

- Risk: hidden Chinese literals remain in shell validators or fixtures
- Mitigation: perform a tracked-file string audit after each major phase
- Rollback strategy: revert the branch as a single localization slice if downstream issues appear
