# Step Reporting 规范

## 目标

为关键脚本提供统一、可读、可校验的执行回报，确保用户在每一步都知道：

- 做了什么
- 改了什么
- 结果如何
- 下一步是什么

## 输出契约

```text
[step-report]
- STEP_ID: <id>
- STEP_NAME: <name>
- ACTIONS: <做了什么>
- FILES_CREATED: <path1,path2|none>
- FILES_UPDATED: <path1,path2|none>
- COMMANDS_RUN: <cmd1 ; cmd2|none>
- GATE_STATUS: <pass|fail|warn|skip>
- RESULT_SUMMARY: <一句话结果>
- NEXT_ACTION: <下一步>
```

补充要求：

- `NEXT_ACTION` 必须是可执行动作，不能留空。
- 任务完成时也必须给出下一步（例如：进入 QA、批准 Gate、启动下一轮目标）。

## 模式开关

- `STEP_REPORT_MODE=detailed|minimal|off`
- 默认：`detailed`

规则：

- 硬约束脚本中，`off` 会自动降级为 `minimal` 并告警。
- 软约束脚本中，`off` 允许关闭输出。

## 约束分级

硬约束（必须输出 `step-report`）：

- `.agents/skills/vibe-hub/scripts/run.sh`
- `.agents/skills/vibe-governance/scripts/run-blackbox-flow.sh`
- `.agents/skills/vibe-task-pack/scripts/new-task-pack.sh`
- `.agents/skills/vibe-quality-gates/scripts/run-local-gates.sh`

软约束（建议输出）：

- `scripts/init-project.sh`
- `scripts/ci/validate-*.sh`
