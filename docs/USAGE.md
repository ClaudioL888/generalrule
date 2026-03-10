# Usage Guide (Generalrule Baseline)

## 1. Positioning and Fit

This repository is the "official path baseline + one-command initializer" used to graft governance standards onto any new project.

It provides:

- Codex runtime baseline constraints (`.codex/`)
- Documentation and gate-script baselines (`docs/`, `scripts/ci/`, `.github/`)
- A seed-driven project skeleton generator (`scripts/init-project.sh`)
- A three-layer governance asset set: `NORMS + standards + prompts`

It is not a marketplace of business templates and does not generate domain-specific application code.

## 2. Prerequisites

Before you start, confirm the following:

1. The `codex` CLI is installed.
2. The current Codex runtime meets the strict capability threshold:
   - supports `codex execpolicy check --rules ...`
   - supports `prefix_rule(..., justification = "...")`
3. The following command passes from the repository root:

```bash
bash scripts/ci/check-codex-capabilities.sh
```

## 3. Quick Start (5 Minutes)

1. Copy the seed template:

```bash
cp seed.template.md seed.my-project.md
```

2. Edit `seed.my-project.md` and fill in the required keys between `START_SEED_KV` and `END_SEED_KV`.

3. Generate the target project skeleton:

```bash
bash scripts/init-project.sh   --output /absolute/path/to/new-project   --seed ./seed.my-project.md
```

4. For a production `full` project, strict seed mode is recommended:

```bash
STRICT_SEED=1 bash scripts/init-project.sh   --output /absolute/path/to/new-project   --seed ./seed.my-project.md
```

5. After initialization, install local hooks:

```bash
cd /absolute/path/to/new-project
bash scripts/dev/install-hooks.sh
```

6. Install pre-commit as well when possible:

```bash
bash scripts/dev/install-pre-commit.sh
```

7. If the project will use the `spec-workflow` MCP, warm it up once:

```bash
bash scripts/dev/install-spec-workflow.sh
```

## 4. What Gets Generated

After generation, the project includes these governance layers:

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

Notes:

- `docs/NORMS.md` is the shortest hard-rule source of truth.
- `docs/standards/*.md` are long-term standards and should not change frequently for a single task.
- `docs/prompts/*.md` are role prompt assets that stabilize behavior.
- `spec/design/plan/current-task` are the task-level source of truth.

## 5. Daily Development and Gate Flow

The recommended local gate order after each change is:

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

### 5.1 Skill-Driven Development (Recommended)

Prefer driving the workflow through these entry points:

```bash
$vibe-governance
$vibe-task-pack
$vibe-quality-gates
```

### 5.2 Recommended Read Order

When a new session or new task starts, read in this order:

1. `AGENTS.md`
2. `docs/NORMS.md`
3. Relevant `docs/standards/*.md` for the task
4. The current role prompt under `docs/prompts/*.md`
5. `docs/governance/ROLE_STANDARD_MATRIX.md` and `docs/governance/TASK_TYPE_STANDARD_PROFILES.md`
6. The current `spec/design/plan/current-task`

### 5.2.1 Finer-Grained Role Handoff Checks

`validate-role-flow.sh` now validates more than whether the role transition is legal. It also checks:

1. The handoff contains `Inputs / Outputs / Definition of Done / Handoff To`
2. The handoff references the current and next role prompt assets
3. The handoff contains the primary artifact link the current role must deliver
4. Handoffs such as `Dev -> QA` include readable test evidence

### 5.2.2 Standards-Binding Gate

`validate-standards-binding.sh` checks:

1. Whether `CURRENT_ROLE_STANDARDS` and `NEXT_ROLE_STANDARDS` match the role matrix
2. Whether the handoff references the current and next role standards
3. Whether `ROLE_DOD_STATUS` and `EVIDENCE_STATUS` are complete
4. Whether `DEVIATION_STATUS=documented` includes an `EXCEPTION_LINK`

`STANDARDS_ENFORCEMENT` defaults to `strict`:

1. Any role missing standards or evidence is blocked immediately.
2. To downgrade the gate, set it explicitly to `mixed` or `warn`.
3. Under `mixed`, only `Architect / Dev / QA / Release-Ops` remain hard-blocking; the rest become warnings.

### 5.3 Metrics and Exceptions

1. When an exception is needed, create an instance from `docs/status/TEMPLATE-exception-log.md` first.
2. Generate at least one weekly metrics snapshot every week:

```bash
bash scripts/ci/collect-metrics.sh
```

3. Fast-track work must include an exception record and a follow-up deadline.

## 6. Common Failures and Fixes

### 6.1 `missing required seed key`

Cause: the seed file is missing a required key.

Fix: fill in the required keys listed in `seed.template.md` and retry.

### 6.2 `output directory is not empty`

Cause: the output directory is not empty and `--force` was not passed.

Fix: choose an empty directory, or confirm overwrite and add `--force`.

### 6.3 `codex execpolicy check does not support --rules`

Cause: the Codex version is too old.

Fix: upgrade the Codex CLI and rerun the capability check.

### 6.4 `current-task ... is required`

Cause: `docs/status/current-task.md` is missing required fields or was not updated.

Fix: fill in the fields and confirm that `EXCEPTION_STATUS / REWORK_RISK / METRICS_IMPACT` are also populated.

### 6.5 `EXCEPTION_STATUS mismatch` or `WORK_TYPE=fast-track requires EXCEPTION_STATUS`

Cause: exception state was not synchronized, or a fast-track task has no exception record.

Fix: update `docs/status/current-task.md`, PR metadata, and the exception log.

### 6.6 `no weekly metrics record found`

Cause: the weekly metrics snapshot is missing.

Fix: run `bash scripts/ci/collect-metrics.sh` and add any manual metrics.

### 6.7 `standards-binding ...`

Cause: the handoff is missing standards references, `ROLE_DOD_STATUS/EVIDENCE_STATUS` are incomplete, or deviations were not recorded.

Fix:

1. Update standards and status fields in `docs/status/current-task.md`
2. Add `Applicable Standards` and `Evidence Summary` to the handoff
3. If a deviation exists, add `EXCEPTION_LINK` and the concrete deviation note

## 7. Version Upgrades and Regression Verification

Recommended regression command:

```bash
for t in tests/unit/*.sh; do bash "$t"; done
```

If you upgraded Codex, skills, or gate scripts, rerun these first:

- `tests/unit/test_codex_runtime_config.sh`
- `tests/unit/test_init_project.sh`
- `tests/unit/test_validate_governance.sh`
- `tests/unit/test_validate_exception_gate.sh`
- `tests/unit/test_validate_observability_gate.sh`
