# 使用手册（Generalrule Baseline）

## 1. 项目定位与适用场景

本仓库是“官方路径基线 + 一键初始化器”，用于把治理规范嫁接到任意新项目。

它提供的是：

- Codex 运行时约束基线（`.codex/`）
- 文档与门禁脚本基线（`docs/`、`scripts/ci/`、`.github/`）
- 基于 seed 的项目骨架生成器（`scripts/init-project.sh`）
- `NORMS + standards + prompts` 三层规范资产

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

## 3. 快速开始（5 分钟）

1. 复制 seed 模板：

```bash
cp seed.template.md seed.my-project.md
```

2. 编辑 `seed.my-project.md`，填写 `START_SEED_KV` 与 `END_SEED_KV` 之间的必填键。

3. 生成目标项目骨架：

```bash
bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.my-project.md
```

4. 正式 `full` 项目建议启用 strict seed：

```bash
STRICT_SEED=1 bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.my-project.md
```

5. 初始化后安装本地 hooks：

```bash
cd /absolute/path/to/new-project
bash scripts/dev/install-hooks.sh
```

6. 安装 pre-commit（可选但推荐）：

```bash
bash scripts/dev/install-pre-commit.sh
```

7. 如果项目会启用 `spec-workflow` MCP，再执行一次预热安装：

```bash
bash scripts/dev/install-spec-workflow.sh
```

## 4. 生成结果说明

生成后会包含以下新增规范层：

- `docs/NORMS.md`
- `docs/standards/*.md`
- `docs/prompts/*.md`
- `docs/governance/ROLE_STANDARD_MATRIX.md`
- `docs/governance/TASK_TYPE_STANDARD_PROFILES.md`
- `docs/governance/EXCEPTIONS.md`
- `docs/metrics/ENGINEERING_METRICS.md`
- `docs/status/TEMPLATE-exception-log.md`
- `docs/status/TEMPLATE-metrics-weekly.md`
- `.pre-commit-config.yaml`
- `scripts/dev/install-pre-commit.sh`
- `scripts/ci/validate-exception-gate.sh`
- `scripts/ci/collect-metrics.sh`

说明：

- `docs/NORMS.md` 是最短硬规则真值。
- `docs/standards/*.md` 是长期标准，不随单个任务频繁改动。
- `docs/prompts/*.md` 是角色提示资产，用于稳定角色行为。
- `spec/design/plan/current-task` 是任务级真值。

## 5. 日常开发与门禁流程

建议本地每次改动后按顺序执行：

```bash
bash scripts/ci/check-codex-capabilities.sh
LOCAL_MODE=1 bash scripts/ci/validate-spec-pack.sh
bash scripts/ci/validate-spec-quality.sh
bash scripts/ci/validate-citation-quality.sh
LOCAL_MODE=1 bash scripts/ci/validate-role-flow.sh
LOCAL_MODE=1 bash scripts/ci/validate-standards-binding.sh
LOCAL_MODE=1 bash scripts/ci/validate-api-frontend-sync.sh
LOCAL_MODE=1 bash scripts/ci/validate-exception-gate.sh
LOCAL_MODE=1 bash scripts/ci/validate-permissions-gate.sh
bash scripts/ci/validate-security-gate.sh
LOCAL_MODE=1 bash scripts/ci/validate-governance.sh
bash scripts/ci/validate-release-readiness.sh
bash scripts/ci/validate-observability-gate.sh
bash scripts/ci/validate-doc-links.sh
```

### 5.1 Skill 驱动开发（推荐）

优先通过以下入口驱动：

```bash
$vibe-governance
$vibe-task-pack
$vibe-quality-gates
```

### 5.2 规范读取顺序

新会话或新任务开始时，建议先读：

1. `AGENTS.md`
2. `docs/NORMS.md`
3. 当前任务相关的 `docs/standards/*.md`
4. 当前角色对应的 `docs/prompts/*.md`
5. `docs/governance/ROLE_STANDARD_MATRIX.md` 与 `docs/governance/TASK_TYPE_STANDARD_PROFILES.md`
6. 当前 `spec/design/plan/current-task`

### 5.2.1 更细的角色交接检查

`validate-role-flow.sh` 现在不只检查角色跳转是否合法，还会检查：

1. handoff 是否包含 `Inputs / Outputs / Definition of Done / Handoff To`
2. handoff 是否引用当前角色与下一角色的 prompt 资产
3. handoff 是否包含当前角色必须交付的主产物链接
4. `Dev -> QA` 这类交接是否带可读测试证据

### 5.2.2 标准绑定门禁

`validate-standards-binding.sh` 负责检查：

1. `CURRENT_ROLE_STANDARDS` / `NEXT_ROLE_STANDARDS` 是否与角色矩阵一致
2. handoff 是否引用当前/下一角色 standards
3. `ROLE_DOD_STATUS` 与 `EVIDENCE_STATUS` 是否已完成
4. `DEVIATION_STATUS=documented` 时是否附 `EXCEPTION_LINK`

默认 `STANDARDS_ENFORCEMENT=strict`：

1. 所有角色缺标准或证据都会直接阻断
2. 需要降级时，显式设为 `mixed` 或 `warn`
3. `mixed` 下仅 `Architect / Dev / QA / Release-Ops` 继续硬阻断，其余角色告警通过

### 5.3 metrics 与例外

1. 需要破例时，先创建 `docs/status/TEMPLATE-exception-log.md` 的实例。
2. 每周至少生成一份 metrics 快照：

```bash
bash scripts/ci/collect-metrics.sh
```

3. fast-track 任务必须带 exception 记录与追补期限。

## 6. 常见失败与修复

### 6.1 `missing required seed key`

原因：seed 缺少必填键。

修复：补齐 `seed.template.md` 列出的必填键后重试。

### 6.2 `output directory is not empty`

原因：输出目录非空且未传 `--force`。

修复：换一个空目录，或确认覆盖后加 `--force`。

### 6.3 `codex execpolicy check does not support --rules`

原因：Codex 版本过旧。

修复：升级 Codex CLI 后重试能力检查。

### 6.4 `current-task ... is required`

原因：`docs/status/current-task.md` 缺少必填字段或未更新。

修复：补齐字段，并确认 `EXCEPTION_STATUS / REWORK_RISK / METRICS_IMPACT` 也已填写。

### 6.5 `EXCEPTION_STATUS mismatch` 或 `WORK_TYPE=fast-track requires EXCEPTION_STATUS`

原因：例外状态未同步，或 fast-track 未记录 exception。

修复：更新 `docs/status/current-task.md`、PR metadata 与 exception log。

### 6.6 `no weekly metrics record found`

原因：缺 weekly metrics 快照。

修复：执行 `bash scripts/ci/collect-metrics.sh` 并补充人工指标。

### 6.7 `standards-binding ...`

原因：handoff 缺 standards 引用、`ROLE_DOD_STATUS/EVIDENCE_STATUS` 未完成，或偏差未记录。

修复：

1. 更新 `docs/status/current-task.md` 中的 standards 与状态字段
2. 在 handoff 中补 `Applicable Standards` 与 `Evidence Summary`
3. 如有偏差，补 `EXCEPTION_LINK` 与具体偏差说明

## 7. 版本升级与回归验证

推荐回归命令：

```bash
for t in tests/unit/*.sh; do bash "$t"; done
```

如果升级了 Codex、skills 或 gate 脚本，优先重跑：

- `tests/unit/test_codex_runtime_config.sh`
- `tests/unit/test_init_project.sh`
- `tests/unit/test_validate_governance.sh`
- `tests/unit/test_validate_exception_gate.sh`
- `tests/unit/test_validate_observability_gate.sh`

## 8. FAQ

### 8.1 什么时候用 `--force`

当你明确允许覆盖非空输出目录时才用。

### 8.2 为什么会出现大量 `TODO(key)`

说明 seed 没填对应非关键键；这不是错误，但表示后续需要补全。

### 8.3 为什么旧版 Codex 会被阻断

因为这套基线依赖官方 `--rules` 与 `justification` 语义；旧版本不具备足够运行时约束能力。
