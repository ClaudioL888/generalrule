# NORMS

本文件是最短、最硬、最稳定的项目级规则摘要。

## Hard Rules

1. 无 `spec` 不改 `src/`。
2. 大功能无 `design` 与 `plan` 不进入实现。
3. 每次只推进一个计划项，不跨任务顺手重构。
4. 所有实现必须附测试证据，不接受“我觉得可以”。
5. API 或前端表面变化必须同步 `docs/contracts/`。
6. 每轮循环必须更新 `docs/status/current-task.md`。
7. 发布前必须同步 `CHANGELOG.md` 与 `RELEASE_NOTES.md`。
8. `docs/prd/`、`docs/design/`、`docs/adr/`、`docs/specs/` 的变更必须带 `引用与依据`。
9. 任何例外都必须记录 `EXCEPTION` 文档并附后续追补时间。
10. 每次任务结束必须明确告诉用户“下一步做什么”。
11. Gate 0 前必须完成 brainstorming 与 spec quality 审查。
12. Gate 0 前必须同步 design；Gate 2 前必须同步 plan。
13. 运行时约束不替代脚本与 CI 门禁；脚本与 CI 门禁才是最终真值。
14. 角色交接必须同时引用 prompts、standards 与证据，不接受“只有流程没有标准”。
15. 每轮响应必须提供一个“可评价对象”，不允许只输出程序性确认动作。
16. 除关键决策外，优先用“提案 + 默认推进”替代“请确认是否继续”。
17. 低风险、低成本、可回退的内容默认推进；高风险、不可逆、显著扩范围的内容必须确认。
18. 任何不确定性都必须显式写出：已知事实、当前假设、假设风险、较稳妥路径。
19. 每次任务结束除给出“下一步做什么”，还必须沉淀至少一条可复用经验或反模式。

## Read Order

1. `AGENTS.md`
2. `docs/NORMS.md`
3. `docs/standards/*.md`
4. `docs/prompts/*.md`
