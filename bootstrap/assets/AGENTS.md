# AGENTS

项目：{{project_name}}
目标ID：{{goal_id}}

## 强制循环

Plan -> Edit -> Run tools -> Observe -> Repair -> Update docs/status -> Repeat

## 强制规则

1. 不允许跳过 PRD/Design/Plan 直接改大功能。
2. 每次只做一个计划项，跨范围必须先更新 Plan 并重新批准。
3. 必须运行并报告测试结果，不接受“我觉得可以”。
4. 任何改动必须更新对应文档与发布说明。
5. 执行命令、依赖安装、权限变更必须进入 approval。

## Codex 运行时配置约束

1. 仓库内强制层位于 `.codex/config.toml` 与 `.codex/rules/default.rules`。
2. 高风险操作默认使用 `codex --profile strict`。
3. 发布窗口操作建议使用 `codex --profile release`。
4. 运行时约束是前置补强，不替代现有 PR/CI 门禁。

## 官方运行时能力门槛

1. 必须通过 `scripts/ci/check-codex-capabilities.sh`。
2. 必须支持 `codex execpolicy check --rules`。
3. 规则文件必须支持 `prefix_rule(..., justification = "...")`。
4. 不满足能力门槛时，本地校验与 CI 一律阻断。
