# 使用手册（Generalrule Baseline）

## 1. 项目定位与适用场景

本仓库是“官方路径基线 + 一键初始化器”，用于把治理规范嫁接到任意新项目。

它提供的是：

- Codex 运行时约束基线（`.codex/`）
- 文档与门禁脚本基线（`docs/`、`scripts/ci/`、`.github/`）
- 基于 seed 的项目骨架生成器（`scripts/init-project.sh`）

它不是业务模板市场，不负责生成具体业务代码。

## 2. 前置条件

开始前请确认：

1. 已安装 `codex` 命令行。
2. 当前 Codex 满足严格能力门槛：
   - 支持 `codex execpolicy check --rules ...`
   - 支持 `prefix_rule(..., justification = "...")`
3. 在仓库根目录执行通过：

```bash
bash scripts/ci/check-codex-capabilities.sh
```

如果失败，先升级 Codex CLI 再继续。

## 3. 快速开始（5 分钟）

1. 复制 seed 模板为你的项目 seed 文件：

```bash
cp seed.template.md seed.my-project.md
```

2. 编辑 `seed.my-project.md`，填写 `START_SEED_KV` 到 `END_SEED_KV` 之间的必填键。

3. 生成目标项目骨架：

```bash
bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.my-project.md
```

4. 如果目标目录已存在且非空，明确允许覆盖时使用：

```bash
bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.my-project.md \
  --force
```

## 4. 生成结果说明

生成后会包含以下官方路径结构：

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

说明：

- `.codex/*`、CI 脚本等属于固定基线。
- 文档中的 `{{token}}` 会由 seed 键填充；未提供的非关键键会写成 `TODO(key)`。

## 5. 日常开发与门禁流程

建议本地每次改动后按顺序执行：

```bash
bash scripts/ci/check-codex-capabilities.sh
bash scripts/ci/validate-governance.sh
bash scripts/ci/validate-doc-links.sh
```

说明：

- `validate-governance.sh` 会在 `src/` 变更时强制检查 `docs/release/*` 与 `docs/status/current-task.md`。
- PR/CI 中会再次执行同类校验，不满足则阻断合并。

## 6. 常见失败与修复

### 6.1 `missing required seed key`

原因：seed 缺少必填键。

修复：补齐 `seed.template.md` 列出的必填键后重试。

### 6.2 `output directory is not empty`

原因：输出目录非空且未传 `--force`。

修复：换一个空目录，或确认覆盖后加 `--force`。

### 6.3 `codex execpolicy check does not support --rules`

原因：Codex 版本过旧，不满足严格能力门槛。

修复：升级 Codex CLI 后重试能力检查脚本。

### 6.4 `current-task ... is required`

原因：`docs/status/current-task.md` 缺少必填字段或未更新。

修复：补齐并更新以下字段：

- `TASK_ID`
- `ROLE`
- `WORK_TYPE`
- `CURRENT_GATE`
- `TEST_COMMANDS`
- `TEST_RESULT`
- `UPDATED_AT`
- `NEXT_ACTION`

## 7. 版本升级与回归验证

升级 Codex CLI：

```bash
npm install -g @openai/codex@latest
hash -r
codex --version
```

执行全量回归：

```bash
bash tests/unit/test_check_codex_capabilities.sh
bash tests/unit/test_validate_governance.sh
bash tests/unit/test_validate_doc_links.sh
bash tests/unit/test_init_project.sh
bash tests/unit/test_codex_runtime_config.sh
```

## 8. FAQ

### 8.1 什么时候用 `--force`？

仅在你明确要覆盖目标目录原内容时使用。默认不覆盖是为了避免误删。

### 8.2 为什么会出现很多 `TODO(key)`？

因为你没有在 seed 中提供对应可选键。生成器会保留占位提醒，避免静默丢字段。

### 8.3 为什么严格门槛会阻断旧版 Codex？

本仓库选择“官方严格语义”，要求 `--rules` 与 `justification` 可用；不满足时必须先升级，保证本地与 CI 行为一致。
