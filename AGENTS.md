# AGENTS

本仓库用于维护“官方路径基线 + 一键初始化器”，用于把治理规范嫁接到任意项目。

## 仓库职责

1. 维护仓库级 Codex 官方配置（`.codex/config.toml`、`.codex/rules/default.rules`）。
2. 维护初始化资产源（`bootstrap/assets/`），确保输出目录遵循官方路径。
3. 维护初始化器（`scripts/init-project.sh`）与 seed 输入契约（`seed.template.md`）。
4. 维护回归测试（`tests/unit/*`），保证生成器与门禁脚本稳定可用。

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
2. 高风险操作默认使用 `codex --profile strict`（更高审批与只读沙箱）。
3. 发布窗口操作建议使用 `codex --profile release`（保留审批并锁定网络访问）。
4. 运行时约束是前置补强，不替代现有 PR/CI 门禁。

## 官方运行时能力门槛

1. 必须通过 `scripts/ci/check-codex-capabilities.sh`。
2. 必须支持 `codex execpolicy check --rules`。
3. 规则文件必须支持 `prefix_rule(..., justification = "...")`。
4. 不满足能力门槛时，本地校验与 CI 一律阻断。
