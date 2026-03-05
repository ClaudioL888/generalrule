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
3. role-flow
4. api/frontend sync
5. permissions
6. security
7. governance
8. release readiness
9. observability
10. doc links

## Commands

```bash
bash .agents/skills/vibe-quality-gates/scripts/run-local-gates.sh
```
