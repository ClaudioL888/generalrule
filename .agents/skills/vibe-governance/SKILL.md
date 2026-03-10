---
name: vibe-governance
description: Run the full Vibe Coding loop with spec-driven execution, role routing, and local gates so implementation does not drift.
---

# Vibe Governance Skill

## Use When

- You are starting a new feature or task
- You need to run the full loop: Spec -> Role -> Edit -> Run tools -> Observe -> Repair -> Update docs/status
- You want to run the full local gate chain before merging
- You want the blackbox semi-automatic mode: one-sentence goal plus gate approvals

## Do Not Use When

- You only need to answer a conceptual question with no repository change
- You only need a single command check unrelated to the governance loop

## Hard Rules

1. Never modify `src/` without a spec.
2. Never claim completion without test evidence.
3. If the role flow does not match the matrix, stop.
4. If docs/status/release are not synchronized, do not enter release.
5. Brainstorming must be complete with a note link before Gate 0.
6. Spec quality review must be complete with a review record before Gate 0 and Gate 2.
7. Every response must contain at least one evaluable object such as a proposal, minimal example, structure draft, diff comparison, or partial implementation.
8. Outside key decisions, prefer "proposal + default progress" over procedural confirmation.
9. Low-risk work advances by default; high-risk, irreversible, or scope-expanding work must pause for confirmation.
10. Every uncertainty must be explicit: known facts, current assumptions, assumption risk, and the safer path.

## Workflow

1. Run brainstorming first to confirm requirements, constraints, and technical choices.
2. Confirm `SPEC_ID`, `TASK_TYPE`, `CURRENT_ROLE`, `NEXT_ROLE`, and `WORK_TYPE`.
3. Run `vibe-task-pack` to create or update `spec/design/plan/map/handoff`.
4. Record spec quality before Gate 0 and Gate 2. Downgrades are allowed by default, but strict mode must pass the workflow.
5. Sync `docs/design/<SPEC_ID>-design.md` before Gate 0.
6. Sync `docs/plans/<SPEC_ID>-plan.md` before Gate 2.
7. Run `vibe-quality-gates` to execute the local gate chain.
8. If any gate fails, enter Observe/Repair and rerun.
9. Update `docs/status/current-task.md` and the handoff documents.
10. In every output round, prefer providing an evaluable object instead of only asking whether to continue.
11. At task closure, record at least one lesson or anti-pattern in addition to the next step.

## Blackbox Semi-Automatic Mode

Minimal interaction:

1. Task entry: one-sentence goal
2. Human completes brainstorming and records it with `run-blackbox-flow.sh brainstorm --note <path>`
3. Human records spec-quality before Gate 0 and Gate 2
4. Before Gate 0, sync design and set `DESIGN_SYNC_STATUS` to `synced`
5. Before Gate 2, sync plan and set `PLAN_SYNC_STATUS` to `synced`
6. Human only approves `Gate 0`, `Gate 2`, `Gate 3`, and `release`
7. AI advances everything else and prints fixed phase cards

Fixed card fields:

- `Phase Goal`
- `AI Completed`
- `Hard Gate Status`
- `You Only Need To Do One Thing`
- `Next Step`

Additional interaction requirements:

- `AI Completed` should ideally contain something evaluable.
- If human approval is not needed, continue low-risk work by default.
- If uncertainty exists, state the assumptions and risks explicitly in the card.

## Commands

Full loop:

```bash
bash .agents/skills/vibe-governance/scripts/run-full-loop.sh   --spec-id SPEC-0001-core-flow   --task-type feature   --current-role Dev   --next-role QA   --work-type full
```

Blackbox semi-automatic:

```bash
bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh start   --goal "Create a path that lets new users finish their first release within 10 minutes"   --task-type feature   --work-type full

bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh brainstorm   --note "docs/status/brainstorming/spec-0001-core-flow.md"

bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh spec-quality   --auto   --status approved   --note "docs/status/spec-quality/spec-0001-core-flow.md"

bash -lc 'sed -i.bak -E "s/^- DESIGN_SYNC_STATUS:.*$/- DESIGN_SYNC_STATUS: synced/" docs/status/current-task.md && rm -f docs/status/current-task.md.bak'

bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 0"

bash -lc 'sed -i.bak -E "s/^- PLAN_SYNC_STATUS:.*$/- PLAN_SYNC_STATUS: synced/" docs/status/current-task.md && rm -f docs/status/current-task.md.bak'

bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 2"
bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 3"
bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "release"
```
