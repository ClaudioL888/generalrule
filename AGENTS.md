# AGENTS

This repository maintains the "official path baseline + one-command initializer" used to graft governance standards onto any project.

## Repository Responsibilities

1. Maintain the repository-level official Codex configuration (`.codex/config.toml`, `.codex/rules/default.rules`).
2. Maintain the initializer asset source (`bootstrap/assets/`) so generated output follows the official path layout.
3. Maintain the initializer (`scripts/init-project.sh`) and the seed input contract (`seed.template.md`).
4. Maintain regression tests (`tests/unit/*`) so the generator and gate scripts remain stable.

## Required Loop

Plan -> Edit -> Run tools -> Observe -> Repair -> Update docs/status -> Repeat

## Read Order (Required)

1. `AGENTS.md`
2. `docs/NORMS.md`
3. Relevant `docs/standards/*.md`
4. Relevant `docs/prompts/*.md`
5. The standards profile and evidence state bound to the current role
6. The current task's `spec/design/plan/current-task`

## Standards Enforcement (Strict by Default)

1. `standards-binding` defaults to `strict`, not `mixed`.
2. By default, any missing standards binding, missing evidence, or missing deviation record blocks progress for every role.
3. Downgrades are allowed only when `STANDARDS_ENFORCEMENT=mixed` or `STANDARDS_ENFORCEMENT=warn` is set explicitly.
4. Before Gate 3 or release approval, check `ROLE_DOD_STATUS=met` and `EVIDENCE_STATUS=complete` first, or the standards gate will block.

## Blackbox Semi-Automatic Entry

1. The only required human input is: `Start task: <one-sentence goal>`.
2. Before Gate 0, run the brainstorming skill and record the conclusions (requirements, constraints, technical choices).
3. Before Gate 0 and Gate 2, complete spec quality review. By default, `degraded + unavailable` may pass as a downgrade; when `SPEC_WORKFLOW_REQUIRED=strict`, the result must be `approved + passed`.
4. Before Gate 0, update `docs/design/<SPEC_ID>-design.md` and set `DESIGN_SYNC_STATUS=synced`.
5. Before Gate 2, update `docs/plans/<SPEC_ID>-plan.md` and set `PLAN_SYNC_STATUS=synced`.
6. Humans approve only at key checkpoints: `Approve Gate 0`, `Approve Gate 2`, `Approve Gate 3`, `Approve release`.
7. Every phase output from AI must include the fixed card fields: `Phase Goal`, `AI Completed`, `Hard Gate Status`, `You Only Need To Do One Thing`, `Next Step`.
8. Outside key approvals, AI advances the role chain and self-checks automatically; on failure it must enter Observe/Repair and provide executable remediation.

## Interaction and Feedback Constraints (Required)

1. Outside key decisions, prefer "proposal + default progress" over asking "should I continue".
2. Every response round must provide at least one evaluable object, such as a judgment, proposal, minimal sample, structure draft, diff comparison, or partial implementation.
3. Low-risk, low-cost, reversible work should progress by default; high-risk, irreversible, or scope-expanding work should stop for confirmation.
4. Every round must expose uncertainty explicitly: known facts, current assumptions, assumption risk, and the safer path.
5. Each round should handle only one cluster of related problems; do not mix structure, logic, style, and implementation in one large rewrite.
6. Every task closure must record at least one reusable lesson in addition to the next step.

## Skill Invocation Reminders (Required)

1. `vibe-governance` is the default main workflow skill and may be triggered implicitly.
2. `vibe-task-pack` and `vibe-quality-gates` stay explicit to avoid accidentally triggering heavyweight checks.
3. On every new task, AI must first state that it is following the `vibe-governance` main workflow and mention the optional explicit commands.
4. Only after the user explicitly says "skip skill" may AI continue without the skill, and it must warn about the risk of drifting from the standard process or missing gates.

## Mandatory Rules

1. You may not skip PRD/Design/Plan and go directly to major implementation.
2. Work on only one plan item at a time. Crossing scope requires a plan update and renewed approval first.
3. Tests must be run and results must be reported. "I think it is fine" is not acceptable.
4. Every change must update the corresponding docs and release notes.
5. Command execution, dependency installation, and permission changes must enter approval.
6. Every role handoff must cite the current and next role standards and state evidence status plus deviation status.
7. Every new `SPEC_ID` must bind its own documents:
   - `docs/specs/<SPEC_ID>.md`
   - `docs/design/<SPEC_ID>-design.md`
   - `docs/plans/<SPEC_ID>-plan.md`
8. Any changes under `docs/prd/`, `docs/design/`, `docs/adr/`, or `docs/specs/` must include a structured `## References and Evidence` block with at least one `primary` or `internal` source.
9. Every exception must be recorded in an `EXCEPTION` document with a `FOLLOWUP_DEADLINE`.
10. Every task closure must tell the user what to do next.

## NORMS / Standards / Prompts

1. `docs/NORMS.md` is the shortest source of truth and overrides longer explanations.
2. `docs/standards/*.md` define the long-term standards for discovery, design, planning, coding, testing, security, observability, release, and documentation.
3. `docs/prompts/*.md` define reusable role prompt assets so behavior stays stable rather than improvised.
4. `docs/governance/ROLE_STANDARD_MATRIX.md` and `docs/governance/TASK_TYPE_STANDARD_PROFILES.md` define standards binding rules for roles and task types.
5. When implementation conflicts with a standard, record an exception or ADR instead of bypassing the rule.
6. `ROLE_HANDOFF` checks more than file existence; it also checks required sections, role prompt references, and the primary artifact links that the current role must hand off.

## Codex Runtime Configuration Constraints

1. The repository-level enforcement layer lives in `.codex/config.toml` and `.codex/rules/default.rules`.
2. `.codex/config.toml` must declare the project-level `spec-workflow` MCP, and the `"."` argument must point to the current project root rather than a hard-coded absolute path to another project.
3. High-risk actions should default to `codex --profile strict`.
4. Release-window actions should prefer `codex --profile release`.
5. Runtime constraints are a front-loaded reinforcement and do not replace existing PR or CI gates.

## Official Runtime Capability Threshold

1. `scripts/ci/check-codex-capabilities.sh` must pass.
2. `codex execpolicy check --rules` must be supported.
3. Rule files must support `prefix_rule(..., justification = "...")`.
4. If the capability threshold is not met, both local validation and CI must block.
