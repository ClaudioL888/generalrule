#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

for base in "$ROOT_DIR/.agents/skills" "$ROOT_DIR/bootstrap/assets/.agents/skills"; do
  [[ -d "$base" ]] || { echo "missing skills directory: $base"; exit 1; }

  for skill in vibe-hub vibe-governance vibe-task-pack vibe-quality-gates; do
    skill_dir="$base/$skill"
    [[ -d "$skill_dir" ]] || { echo "missing skill directory: $skill_dir"; exit 1; }
    [[ -f "$skill_dir/SKILL.md" ]] || { echo "missing SKILL.md: $skill_dir/SKILL.md"; exit 1; }
    [[ -f "$skill_dir/agents/openai.yaml" ]] || { echo "missing openai.yaml: $skill_dir/agents/openai.yaml"; exit 1; }

    rg -q '^name:' "$skill_dir/SKILL.md" || { echo "SKILL.md missing name: $skill_dir/SKILL.md"; exit 1; }
    rg -q '^description:' "$skill_dir/SKILL.md" || { echo "SKILL.md missing description: $skill_dir/SKILL.md"; exit 1; }

    case "$skill" in
      vibe-hub)
        rg -q 'allow_implicit_invocation:[[:space:]]*true' "$skill_dir/agents/openai.yaml" || {
          echo "vibe-hub must set allow_implicit_invocation: true: $skill_dir/agents/openai.yaml"
          exit 1
        }
        ;;
      vibe-governance|vibe-task-pack|vibe-quality-gates)
        rg -q 'allow_implicit_invocation:[[:space:]]*false' "$skill_dir/agents/openai.yaml" || {
          echo "${skill} must set allow_implicit_invocation: false: $skill_dir/agents/openai.yaml"
          exit 1
        }
        ;;
    esac
  done

  for script in \
    "$base/vibe-hub/scripts/run.sh" \
    "$base/vibe-governance/scripts/run-full-loop.sh" \
    "$base/vibe-governance/scripts/run-blackbox-flow.sh" \
    "$base/vibe-task-pack/scripts/new-task-pack.sh" \
    "$base/vibe-quality-gates/scripts/run-local-gates.sh"; do
    [[ -x "$script" ]] || { echo "skill script is not executable: $script"; exit 1; }
  done
done

root_files="$(cd "$ROOT_DIR/.agents/skills" && find . -type f | sort)"
bootstrap_files="$(cd "$ROOT_DIR/bootstrap/assets/.agents/skills" && find . -type f | sort)"
[[ "$root_files" == "$bootstrap_files" ]] || {
  echo "root .agents/skills and bootstrap/assets/.agents/skills file sets must match"
  exit 1
}

echo "test_skill_assets.sh passed"
