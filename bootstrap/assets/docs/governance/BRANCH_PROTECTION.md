# Branch Protection 配置基线

> 本文件提供“配置指引 + 可检查项”，不自动调用 GitHub API 修改仓库设置。

## 目标分支

- 默认分支：`main`（如项目使用 `master`，请等价配置）

## 推荐强制项

1. Require a pull request before merging
2. Require approvals（至少 1 位）
3. Dismiss stale approvals when new commits are pushed
4. Require review from Code Owners
5. Require status checks to pass before merging
6. Require branches to be up to date before merging
7. Restrict who can push to matching branches（按组织策略）
8. Do not allow bypassing above settings

## 必须通过的状态检查（建议名称）

- `governance-check`
- `security-policy-gate`
- `secret-scan`
- `dependency-review`

说明：`spec-pack`、`role-flow`、`api-frontend-sync` 作为 `governance-check` job 内的硬阻断步骤执行。

## 变更流程建议

1. 先在测试仓库验证规则组合
2. 再在正式仓库启用
3. 每月复查一次分支保护设置与 CODEOWNERS 对齐情况
