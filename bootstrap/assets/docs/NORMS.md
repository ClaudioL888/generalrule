# NORMS

This file is the shortest, hardest, and most stable summary of project-level rules.

## Hard Rules

1. Do not modify `src/` without a `spec`.
2. Do not enter implementation for major work without both `design` and `plan`.
3. Advance only one plan item at a time. Do not slip in side refactors across tasks.
4. Every implementation change must carry test evidence. "I think it works" is not acceptable.
5. API or frontend surface changes must update `docs/contracts/`.
6. Every loop must update `docs/status/current-task.md`.
7. Sync `CHANGELOG.md` and `RELEASE_NOTES.md` before release.
8. Changes under `docs/prd/`, `docs/design/`, `docs/adr/`, and `docs/specs/` must include a `References and Evidence` section.
9. Every exception must be recorded in an `EXCEPTION` document with a follow-up deadline.
10. Every task closure must tell the user exactly what to do next.
11. Brainstorming and spec quality review must be complete before Gate 0.
12. Design must be synced before Gate 0; plan must be synced before Gate 2.
13. Runtime constraints do not replace script or CI gates; script and CI gates remain the final source of truth.
14. Role handoffs must reference prompts, standards, and evidence. A flow without standards is not acceptable.
15. Every response loop must provide an object the user can evaluate. Procedural confirmations alone are not allowed.
16. Outside key decisions, prefer "proposal + default progress" over "please confirm whether to continue".
17. Low-risk, low-cost, reversible work should advance by default. High-risk, irreversible, or scope-expanding work must be confirmed.
18. Every uncertainty must be explicit: known facts, current assumptions, assumption risk, and the safer path.
19. Every task closure must also record at least one reusable lesson or anti-pattern.

## Read Order

1. `AGENTS.md`
2. `docs/NORMS.md`
3. `docs/standards/*.md`
4. `docs/prompts/*.md`
