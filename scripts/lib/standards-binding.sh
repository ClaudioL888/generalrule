#!/usr/bin/env bash

standards_profile_for() {
  printf '%s:%s\n' "$1" "$2"
}

role_standard_categories() {
  local role="$1"
  case "$role" in
    Founder) printf 'norms\ndiscovery\ndocumentation\n' ;;
    PM) printf 'discovery\ndocumentation\n' ;;
    Architect) printf 'design\nsecurity\nobservability\n' ;;
    Planner) printf 'planning\ntesting\n' ;;
    Dev) printf 'coding\ntesting\ndocumentation\n' ;;
    QA) printf 'testing\ndocumentation\n' ;;
    Reviewer) printf 'documentation\nsecurity\n' ;;
    Release-Ops) printf 'release\nobservability\nsecurity\n' ;;
    Growth|Content-Growth) printf 'documentation\nmetrics\n' ;;
    *)
      echo "unsupported role for standards: $role" >&2
      return 1
      ;;
  esac
}

task_profile_categories() {
  local task_type="$1"
  case "$task_type" in
    feature) printf 'all\n' ;;
    bugfix) printf 'testing\ndocumentation\nrelease\n' ;;
    refactor) printf 'design\ncoding\ntesting\n' ;;
    ops) printf 'release\nobservability\nsecurity\n' ;;
    content) printf 'documentation\nmetrics\n' ;;
    *)
      echo "unsupported task type for standards profile: $task_type" >&2
      return 1
      ;;
  esac
}

standards_path_for_category() {
  local category="$1"
  case "$category" in
    norms) printf 'docs/NORMS.md\n' ;;
    discovery) printf 'docs/standards/discovery-standards.md\n' ;;
    design) printf 'docs/standards/design-standards.md\n' ;;
    planning) printf 'docs/standards/planning-standards.md\n' ;;
    release) printf 'docs/standards/release-standards.md\n' ;;
    documentation) printf 'docs/standards/documentation-standards.md\n' ;;
    coding) printf 'docs/standards/coding-standards.md\n' ;;
    testing) printf 'docs/standards/testing-standards.md\n' ;;
    security) printf 'docs/standards/security-standards.md\n' ;;
    observability) printf 'docs/standards/observability-standards.md\n' ;;
    metrics) printf 'docs/metrics/ENGINEERING_METRICS.md\n' ;;
    *)
      echo "unsupported standards category: $category" >&2
      return 1
      ;;
  esac
}

role_standards_for_task() {
  local role="$1"
  local task_type="$2"
  local role_categories task_categories category

  role_categories="$(role_standard_categories "$role")"
  task_categories="$(task_profile_categories "$task_type")"

  if [[ "$task_categories" == "all" ]]; then
    while IFS= read -r category; do
      [[ -n "$category" ]] || continue
      standards_path_for_category "$category"
    done <<< "$role_categories"
    return 0
  fi

  while IFS= read -r category; do
    [[ -n "$category" ]] || continue
    if grep -Fxq "$category" <<< "$task_categories"; then
      standards_path_for_category "$category"
    fi
  done <<< "$role_categories"
}

role_standards_csv() {
  local role="$1"
  local task_type="$2"
  role_standards_for_task "$role" "$task_type" | awk 'NF && !seen[$0]++ { print }' | paste -sd, -
}

csv_to_lines() {
  local csv="$1"
  printf '%s\n' "$csv" | tr ',' '\n' | sed '/^$/d'
}

role_gate_severity() {
  local role="$1"
  local enforcement="${2:-strict}"
  case "$enforcement" in
    warn)
      printf 'warn\n'
      ;;
    strict)
      printf 'hard\n'
      ;;
    mixed)
      case "$role" in
        Architect|Dev|QA|Release-Ops)
          printf 'hard\n'
          ;;
        *)
          printf 'warn\n'
          ;;
      esac
      ;;
    *)
      echo "invalid STANDARDS_ENFORCEMENT: $enforcement (use warn, mixed, or strict)" >&2
      return 1
      ;;
  esac
}
