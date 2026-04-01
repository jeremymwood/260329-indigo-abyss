# Agent Issue-to-PR Workflow

This playbook defines how `status:ready` issues are executed by Codex and moved through project status lanes.

## 1) Issue readiness rules

Issue must include:

- Clear scope and acceptance criteria
- Labels: `type:*`, `priority:*`, `area:*`, `status:ready`
- Verification command(s), typically `ruby bin/prepush`

## 2) Branch naming convention

Use this format:

- `issue-<number>-<short-kebab-summary>`

Examples:

- `issue-12-session-cart`
- `issue-18-expand-fallback-catalog`

## 3) PR title and body conventions

PR title:

- `<type>: <short summary>`

PR body must include:

- `## Summary` with concrete file/behavior changes
- `## Testing` with exact commands run
- `Closes #<issue-number>` so issue auto-closes on merge

Use `.github/pull_request_template.md` for consistency.

## 4) Status movement expectations

- `status:ready` -> `status:in-progress` when implementation starts
- `status:review` when PR opens
- `status:done` when PR merges

Project board status sync is automated by `.github/workflows/project-status-sync.yml`.

## 5) Required checks and merge gates

Before merge, require green:

- `CI` workflow on the PR branch
- `Project Status Sync` workflow run on PR events

Local gate before pushing:

- `ruby bin/prepush`

## 6) Codex execution prompt template

Use this prompt pattern when assigning an issue:

```text
Implement issue #<number> in this repo.

Requirements:
- Follow acceptance criteria from the issue.
- Branch: issue-<number>-<short-name>.
- Update issue label to status:in-progress at start.
- Run ruby bin/prepush before pushing.
- Open PR to main with:
  - clear Summary
  - Testing commands/results
  - Closes #<number>
- Ensure Kanban/project status moves correctly.
```

## 7) Suggested review checklist

- Scope matches issue and no unrelated refactors
- Tests added/updated for new behavior
- Security/secrets handling unchanged or improved
- CI and automation runs are green
