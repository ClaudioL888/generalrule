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

4. 正式 `full` 项目建议开启 strict seed 模式（强制 L2 进阶字段）：

```bash
STRICT_SEED=1 bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.my-project.md
```

或：

```bash
bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.my-project.md \
  --strict-seed
```

5. 如果目标目录已存在且非空，明确允许覆盖时使用：

```bash
bash scripts/init-project.sh \
  --output /absolute/path/to/new-project \
  --seed ./seed.my-project.md \
  --force
```

6. 初始化后第一步安装本地 hooks（启用 pre-push 阻断）：

```bash
cd /absolute/path/to/new-project
bash scripts/dev/install-hooks.sh
```

7. Skill 驱动策略（推荐）：

```bash
# 默认：vibe-governance 会隐式触发（主流程）
# 按需显式触发：
$vibe-task-pack
$vibe-quality-gates
$vibe-governance
```

## 4. 生成结果说明

生成后会包含以下官方路径结构：

- `.codex/config.toml`
- `.codex/rules/default.rules`
- `.agents/skills/vibe-governance/*`
- `.agents/skills/vibe-task-pack/*`
- `.agents/skills/vibe-quality-gates/*`
- `AGENTS.md`
- `.github/CODEOWNERS`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/workflows/ci.yml`
- `.github/workflows/security.yml`
- `.github/workflows/release.yml`
- `.github/workflows/scheduled-maintenance.yml`
- `docs/prd/0001-problem-statement.md`
- `docs/design/0001-architecture-overview.md`
- `docs/adr/0001-initial-decision.md`
- `docs/governance/BRANCH_PROTECTION.md`
- `docs/governance/ROLE_ROUTING.md`
- `docs/plans/0001-implementation-plan.md`
- `docs/test-plan/0001-test-plan.md`
- `docs/specs/TEMPLATE-feature-spec.md`
- `docs/design/TEMPLATE-feature-design.md`
- `docs/plans/TEMPLATE-feature-plan.md`
- `docs/contracts/TEMPLATE-api-frontend-map.md`
- `docs/runbooks/incident-playbook.md`
- `docs/runbooks/backup-restore.md`
- `docs/runbooks/oncall-checklist.md`
- `docs/metrics/TEMPLATE-dora-aarrr.md`
- `docs/status/TEMPLATE-weekly-maintenance.md`
- `docs/status/TEMPLATE-monthly-maintenance.md`
- `docs/status/TEMPLATE-role-handoff.md`
- `docs/status/TEMPLATE-blackbox-session.md`
- `docs/status/TEMPLATE-brainstorming.md`
- `docs/release/CHANGELOG.md`
- `docs/release/RELEASE_NOTES.md`
- `docs/status/current-task.md`
- `.githooks/pre-push`
- `scripts/ci/check-codex-capabilities.sh`
- `scripts/ci/validate-spec-pack.sh`
- `scripts/ci/validate-role-flow.sh`
- `scripts/ci/validate-api-frontend-sync.sh`
- `scripts/ci/validate-governance.sh`
- `scripts/ci/validate-doc-links.sh`
- `scripts/ci/validate-permissions-gate.sh`
- `scripts/ci/validate-security-gate.sh`
- `scripts/ci/validate-release-readiness.sh`
- `scripts/ci/validate-observability-gate.sh`
- `scripts/dev/install-hooks.sh`

说明：

- `.codex/*`、CI 脚本等属于固定基线。
- 文档中的 `{{token}}` 会由 seed 键填充；未提供的非关键键会写成 `TODO(key)`。
- 默认是兼容模式：`work_type=full` 缺 L2 键会告警不阻断；strict 模式下会阻断。

## 4.1 Seed 严格模式与迁移建议

迁移建议：

1. 先用兼容模式跑通初始化，观察缺失的 L2 告警列表。
2. 在你的 seed 中补齐技术、安全、可观测、发布四类 L2 字段。
3. 切到 strict 模式并保持通过，作为正式项目默认流程。

## 5. 日常开发与门禁流程

建议本地每次改动后按顺序执行：

```bash
bash scripts/ci/check-codex-capabilities.sh
LOCAL_MODE=1 bash scripts/ci/validate-spec-pack.sh
LOCAL_MODE=1 bash scripts/ci/validate-role-flow.sh
LOCAL_MODE=1 bash scripts/ci/validate-api-frontend-sync.sh
LOCAL_MODE=1 bash scripts/ci/validate-permissions-gate.sh
bash scripts/ci/validate-security-gate.sh
LOCAL_MODE=1 bash scripts/ci/validate-governance.sh
bash scripts/ci/validate-release-readiness.sh
bash scripts/ci/validate-observability-gate.sh
bash scripts/ci/validate-doc-links.sh
```

### 5.1 Skill 驱动开发（推荐）

当你希望按固定流程执行时，优先调用：

```bash
bash .agents/skills/vibe-task-pack/scripts/new-task-pack.sh \
  --spec-id SPEC-0001-core-flow \
  --task-type feature \
  --current-role Dev \
  --next-role QA

bash .agents/skills/vibe-quality-gates/scripts/run-local-gates.sh

bash .agents/skills/vibe-governance/scripts/run-full-loop.sh \
  --spec-id SPEC-0001-core-flow \
  --task-type feature \
  --current-role Dev \
  --next-role QA \
  --work-type full
```

说明：

- `validate-governance.sh` 会在 `src/` 变更时强制检查 `docs/release/*` 与 `docs/status/current-task.md`。
- `validate-spec-pack.sh` 会在 `src/` 变更时强制检查 `SPEC_LINK`、Design/Plan 变更、Spec 结构完整性。
- `validate-role-flow.sh` 会强制校验 `TASK_TYPE` 的角色流转与 handoff 文档。
- `validate-api-frontend-sync.sh` 会强制校验 API/前端契约映射与 `CONTRACT_SYNC_STATUS`。
- PR/CI 中会再次执行同类校验，不满足则阻断合并。
- `validate-observability-gate.sh` 默认是告警模式，可通过 `OBS_ENFORCEMENT=strict` 切换为硬阻断。

### 5.2 黑盒半自动开发（你只做 Gate 批准）

当你希望“人类只输入一句话目标，AI 自动推进其余流程”时，使用：

```bash
bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh start \
  --goal "做一个让新用户 10 分钟内完成首次发布的流程" \
  --task-type feature \
  --work-type full

bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh brainstorm \
  --note "docs/status/brainstorming/spec-0001-core-flow.md"

bash -lc 'sed -i.bak -E "s/^- DESIGN_SYNC_STATUS:.*$/- DESIGN_SYNC_STATUS: synced/" docs/status/current-task.md && rm -f docs/status/current-task.md.bak'

bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 0"

bash -lc 'sed -i.bak -E "s/^- PLAN_SYNC_STATUS:.*$/- PLAN_SYNC_STATUS: synced/" docs/status/current-task.md && rm -f docs/status/current-task.md.bak'

bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 2"
bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "Gate 3"
bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh approve --gate "发布"
```

说明：

- 你唯一任务入口是 `--goal`（一句话目标）。
- Gate 0 前必须完成 brainstorming（需求/选型前期准备），否则脚本会阻断批准。
- Gate 0 前还必须更新 `docs/design/<SPEC_ID>-design.md`，并把 `DESIGN_SYNC_STATUS` 设为 `synced`。
- Gate 2 前必须更新 `docs/plans/<SPEC_ID>-plan.md`，并把 `PLAN_SYNC_STATUS` 设为 `synced`。
- 人类只在 `Gate 0/Gate 2/Gate 3/发布` 进行批准。
- 每次执行会输出固定卡片：`阶段目标`、`AI 已完成`、`硬门禁状态`、`你只需做一件事`、`下一步`。
- 会话状态写入 `docs/status/blackbox-session.md`，任务状态写入 `docs/status/current-task.md`。

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
- `SPEC_ID`
- `TASK_TYPE`
- `ROLE`
- `WORK_TYPE`
- `CURRENT_GATE`
- `CURRENT_ROLE`
- `NEXT_ROLE`
- `HANDOFF_LINK`
- `API_SURFACE_CHANGED`
- `FRONTEND_SURFACE_CHANGED`
- `CONTRACT_SYNC_STATUS`
- `TEST_COMMANDS`
- `TEST_RESULT`
- `UPDATED_AT`
- `NEXT_ACTION`

### 6.5 `missing full-strict seed key: <key>`

原因：你启用了 strict seed，且 `work_type=full` 时缺少 L2 进阶字段。

修复：补齐 `seed.template.md` 的 L2_FULL_REQUIRED 字段，或暂时改回兼容模式。

### 6.6 `CODEOWNERS missing required path rule pattern`

原因：`.github/CODEOWNERS` 未覆盖核心路径规则（`docs/`、`scripts/ci/`、`.codex/`、`.github/`）。

修复：补齐对应路径与 owner 规则（可先用占位符 owner，后续替换为真实团队）。

### 6.7 `src changes require docs/release/RELEASE_NOTES.md update for security impact disclosure`

原因：有 `src/` 变更但未在 release notes 体现安全影响说明。

修复：更新 `docs/release/RELEASE_NOTES.md`，明确安全边界影响与回滚要点。

### 6.8 `CURRENT_GATE must be at least Gate 6 before release`

原因：发布就绪检查要求 `current-task` 已进入 Gate 6 及以上。

修复：先完成测试/文档/发布前检查，再将 `CURRENT_GATE` 更新到 `Gate 6` 或更高。

### 6.9 `illegal role transition`

原因：`CURRENT_ROLE -> NEXT_ROLE` 不符合 `TASK_TYPE` 对应角色链。

修复：按 `docs/governance/ROLE_ROUTING.md` 修正流转并更新 handoff 文档。

### 6.10 `API_FRONTEND_MAP_LINK must be updated`

原因：代码改动涉及 API/前端契约，但映射文档未同步更新。

修复：更新 `docs/contracts/*` 并将 `CONTRACT_SYNC_STATUS` 置为 `synced`。

### 6.11 `Gate approval is only valid when CURRENT_GATE=...`

原因：批准指令与当前阶段不匹配（例如还在 `Gate 0` 却执行了 `批准发布`）。

修复：先运行 `bash .agents/skills/vibe-governance/scripts/run-blackbox-flow.sh status` 查看当前阶段，再按顺序批准。

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
