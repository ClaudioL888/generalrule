---
name: vibe-quality-gates
description: Run the local governance gate chain and report blockers before submission.
---

# Vibe Quality Gates Skill

## Use When

- You need local self-checks before submission
- You need to find the current blockers quickly

## Do Not Use When

- The task pack has not been created yet; run `vibe-task-pack` first

## Gate Order

1. capabilities
2. spec-pack
3. spec quality
4. citation quality
5. role-flow
6. api/frontend sync
7. permissions
8. security
9. governance
10. release readiness
11. observability
12. doc links

## Commands

```bash
bash .agents/skills/vibe-quality-gates/scripts/run-local-gates.sh
```
