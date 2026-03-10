#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/bootstrap/assets/scripts/ci/validate-api-frontend-sync.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "missing executable script: $SCRIPT"
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/work/docs/status" "$tmp_dir/work/docs/contracts" "$tmp_dir/work/src/api" "$tmp_dir/work/src/components"

cat > "$tmp_dir/work/docs/contracts/SPEC-0001-core-flow-api-frontend-map.md" <<'MD'
# API-Frontend Mapping

- N/A_REASON: not-applicable
- INTERNAL_ONLY_REASON: none

## Mapping Table

| Endpoint / Event | DTO / Schema | Frontend Page / Component | State Management | Test Point | Notes |
| --- | --- | --- | --- | --- | --- |
| /v1/users | UserDTO | UserList | zustand | unit | synced |
MD

pr_ok="$tmp_dir/pr-ok.md"
cat > "$pr_ok" <<'PR'
## Governance Metadata
- API_FRONTEND_MAP_LINK: docs/contracts/SPEC-0001-core-flow-api-frontend-map.md
- CONTRACT_SYNC_STATUS: synced
PR

pushd "$tmp_dir/work" >/dev/null
cat > docs/status/current-task.md <<'MD'
# Current Task
- SPEC_ID: SPEC-0001-core-flow
- API_SURFACE_CHANGED: no
- FRONTEND_SURFACE_CHANGED: no
- CONTRACT_SYNC_STATUS: synced
MD
if CHANGED_FILES=$'src/api/user.ts\ndocs/contracts/SPEC-0001-core-flow-api-frontend-map.md' PR_BODY_FILE="$pr_ok" "$SCRIPT"; then
  echo "expected failure when api path changes but API_SURFACE_CHANGED=no"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- SPEC_ID: SPEC-0001-core-flow
- API_SURFACE_CHANGED: no
- FRONTEND_SURFACE_CHANGED: yes
- CONTRACT_SYNC_STATUS: synced
MD
cat > docs/contracts/SPEC-0001-core-flow-api-frontend-map.md <<'MD'
# API-Frontend Mapping

## Mapping Table

| Endpoint / Event | DTO / Schema | Frontend Page / Component | State Management | Test Point | Notes |
| --- | --- | --- | --- | --- | --- |
| N/A | N/A | UserList | zustand | unit | frontend only |
MD
if CHANGED_FILES=$'src/components/user.ts\ndocs/contracts/SPEC-0001-core-flow-api-frontend-map.md' PR_BODY_FILE="$pr_ok" "$SCRIPT"; then
  echo "expected failure for frontend-only change without N/A reason"
  exit 1
fi

cat > docs/status/current-task.md <<'MD'
# Current Task
- SPEC_ID: SPEC-0001-core-flow
- API_SURFACE_CHANGED: yes
- FRONTEND_SURFACE_CHANGED: yes
- CONTRACT_SYNC_STATUS: synced
MD
cat > docs/contracts/SPEC-0001-core-flow-api-frontend-map.md <<'MD'
# API-Frontend Mapping

- N/A_REASON: not-applicable
- INTERNAL_ONLY_REASON: none

## Mapping Table

| Endpoint / Event | DTO / Schema | Frontend Page / Component | State Management | Test Point | Notes |
| --- | --- | --- | --- | --- | --- |
| /v1/users | UserDTO | UserList | zustand | unit | synced |
MD

CHANGED_FILES=$'src/api/user.ts\nsrc/components/user.ts\ndocs/contracts/SPEC-0001-core-flow-api-frontend-map.md' PR_BODY_FILE="$pr_ok" "$SCRIPT"
popd >/dev/null

echo "test_validate_api_frontend_sync.sh passed"
