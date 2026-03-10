# Documentation Standards

## Scope

Applies to all governance documents, including spec, design, plan, contract, status, and release docs.

## Hard Rules

1. Documentation must be updated in the same repository and the same PR as the code.
2. Every task must bind to a unique `SPEC_ID`.
3. Key conclusions must trace back to sources, standards, or upstream documents.
4. Status fields must use agreed values. Free-form substitutes are not allowed.
5. If documents drift from reality, update the documents first. Do not rely on oral context over time.

## Recommended Rules

1. Overview documents describe long-term evolution; task documents close a single loop.
2. Express the current truth with the shortest verifiable wording possible.
3. Reuse the existing naming and directory structure when adding documents.

## Minimum Acceptance

1. `current-task`, `handoff`, and `spec/design/plan` can trace to one another.
2. Required fields are complete and links resolve.
3. Document updates explain what changed, why it changed, and what happens next.
