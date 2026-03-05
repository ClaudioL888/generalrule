# Generalrule Baseline

这个仓库是“官方路径基线 + 一键初始化器”，用于把治理规范嫁接到任意新项目。

详细使用说明见：[docs/USAGE.md](./docs/USAGE.md)。

## 仓库职责

1. 维护官方路径运行时配置（`.codex/`）。
2. 维护初始化资产源（`bootstrap/assets/`）。
3. 通过 `scripts/init-project.sh` 根据 seed 生成目标项目骨架。
4. 通过 `tests/unit/*` 保证基线与生成流程不退化。

## 基线真值（本仓库）

- `.codex/config.toml`
- `.codex/rules/default.rules`
- `AGENTS.md`
- `seed.template.md`
- `bootstrap/assets/`
- `scripts/init-project.sh`

## 生成新项目

```bash
bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.template.md
```

覆盖非空目录：

```bash
bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.template.md \
  --force
```

## 生成后默认结构

- `.codex/config.toml`
- `.codex/rules/default.rules`
- `AGENTS.md`
- `docs/prd/0001-problem-statement.md`
- `docs/design/0001-architecture-overview.md`
- `docs/adr/0001-initial-decision.md`
- `docs/plans/0001-implementation-plan.md`
- `docs/test-plan/0001-test-plan.md`
- `docs/release/CHANGELOG.md`
- `docs/release/RELEASE_NOTES.md`
- `docs/status/current-task.md`
- `scripts/ci/check-codex-capabilities.sh`
- `scripts/ci/validate-governance.sh`
- `scripts/ci/validate-doc-links.sh`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/workflows/ci.yml`

## 官方 Codex 配置

当前仓库已按官方方式启用项目级配置：

- `.codex/config.toml`
- `.codex/rules/default.rules`

Profile 示例：

- `codex --profile strict`
- `codex --profile release`

官方能力门槛（严格模式）：

- 必须支持 `codex execpolicy check --rules ...`
- 必须支持 `prefix_rule(..., justification = "...")`
- 不满足能力门槛时本地与 CI 都阻断

本地检查命令：

- `bash scripts/ci/check-codex-capabilities.sh`

规则验证示例：

- `codex execpolicy check --pretty --rules .codex/rules/default.rules -- git reset --hard`
- `codex execpolicy check --pretty --rules .codex/rules/default.rules -- git status`
