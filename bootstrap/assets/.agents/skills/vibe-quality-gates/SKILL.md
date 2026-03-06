---
name: vibe-quality-gates
description: 执行本地治理门禁链路并输出阻断项，确保提交前合规。
---

# Vibe Quality Gates Skill

## Use When

- 提交前本地自检
- 需要快速定位当前阻断项

## Do Not Use When

- 任务包尚未建立（先运行 `vibe-task-pack`）

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
