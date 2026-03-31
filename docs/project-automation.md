# Project Automation Setup

This repo includes `.github/workflows/project-status-sync.yml` to sync issue status in GitHub Projects.

## Behavior

- Issue event (`assigned` or label `status:in-progress`): moves issue to `In progress`.
- Pull request opened / ready for review: linked issues move to `In review`.
- Pull request merged: linked issues move to `Done`.

Linked issues are detected from PR text using closing keywords, e.g.:

- `Closes #12`
- `Fixes #34`
- `Resolves #56`

## Required Repo Variables

Set these in: `Settings -> Secrets and variables -> Actions -> Variables`

- `PROJECT_NUMBER`: your GitHub Project number (integer).
- `PROJECT_OWNER` (optional): owner login for the project. Defaults to repo owner.
- `STATUS_FIELD_NAME` (optional): defaults to `Status`.
- `STATUS_IN_PROGRESS` (optional): defaults to `In progress`.
- `STATUS_IN_REVIEW` (optional): defaults to `In review`.
- `STATUS_DONE` (optional): defaults to `Done`.

## Token

The workflow uses:

- `secrets.PROJECT_AUTOMATION_TOKEN` if present
- otherwise `github.token`

If status updates fail with permission errors, add `PROJECT_AUTOMATION_TOKEN` as a classic PAT with:

- `repo`
- `project`

## Suggested Team Convention

When Codex starts work, assign the issue (or apply `status:in-progress`) to trigger `In progress` automatically.
When opening a PR, include `Closes #<issue_number>` so status moves to `In review`, and later to `Done` on merge.
