---
artifact_type: blackbox-session
owner_role: Founder
status: active
linked_goal_id: "{{goal_id}}"
non_goals:
  - "Advance multiple goals in parallel"
acceptance_metrics:
  - "Key gate approval flow completeness"
risks:
  - "Blackbox flow stalls on an unapproved gate"
approvals_required:
  - founder
last_updated: "{{YYYY-MM-DD}}"
---

# Blackbox Session Template

> Semi-automatic mode: humans approve only key gates; AI advances everything else.

- GOAL: {{problem_statement}}
- SPEC_ID: {{spec_id}}
- TASK_TYPE: {{task_type}}
- WORK_TYPE: {{work_type}}
- CURRENT_GATE: Gate 0
- CURRENT_ROLE: Founder
- NEXT_ROLE: PM
- STANDARDS_PROFILE: {{task_type}}:{{work_type}}
- CURRENT_ROLE_STANDARDS: {{current_role_standards}}
- NEXT_ROLE_STANDARDS: {{next_role_standards}}
- ROLE_DOD_STATUS: pending
- EVIDENCE_STATUS: pending
- DEVIATION_STATUS: none
- DESIGN_LINK: docs/design/{{spec_id}}-design.md
- PLAN_LINK: docs/plans/{{spec_id}}-plan.md
- APPROVAL_GATE_0: pending
- APPROVAL_GATE_2: pending
- APPROVAL_GATE_3: pending
- APPROVAL_RELEASE: pending
- DESIGN_SYNC_STATUS: pending
- PLAN_SYNC_STATUS: pending
- SPEC_QUALITY_STATUS: pending
- SPEC_WORKFLOW_STATUS: pending
- SPEC_WORKFLOW_LINK: docs/status/spec-quality/{{spec_id}}.md
- BRAINSTORMING_STATUS: pending
- BRAINSTORMING_LINK: docs/status/brainstorming/{{spec_id}}.md
- STATUS: waiting_gate_0
- LAST_ACTION: start
- LAST_UPDATED: {{updated_at_iso8601}}

## Human Input Contract

1. `Start task: <one-sentence goal>`
2. Run brainstorming and record it with `run-blackbox-flow.sh brainstorm --note <path>`
3. Run spec quality review and record it with `run-blackbox-flow.sh spec-quality --status approved|degraded --workflow-status passed|unavailable --note <path>`
4. Update `docs/design/<SPEC_ID>-design.md` and set `DESIGN_SYNC_STATUS` to `synced`
5. `Approve Gate 0`
6. Update `docs/plans/<SPEC_ID>-plan.md` and set `PLAN_SYNC_STATUS` to `synced`
7. `Approve Gate 2`
8. `Approve Gate 3`
9. `Approve release`

## Fixed Phase Card Fields

1. Phase Goal
2. AI Completed
3. Hard Gate Status
4. You Only Need To Do One Thing
5. Next Step
