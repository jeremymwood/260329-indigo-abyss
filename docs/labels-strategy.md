# Labels Strategy

This label system is optimized for human triage and agentic execution.

## Label Groups

### Type (exactly one)
- `type:feature` - net-new capability.
- `type:bug` - broken behavior or regression.
- `type:chore` - maintenance, infra, docs, refactor.
- `type:security` - auth/secrets/vulnerability hardening.

### Priority (exactly one)
- `priority:p0` - production down or data/security risk.
- `priority:p1` - high-impact user or revenue blocker.
- `priority:p2` - important, planned next.
- `priority:p3` - nice-to-have or cleanup.

### Status (exactly one)
- `status:triage` - not yet sized/refined.
- `status:ready` - ready for implementation.
- `status:in-progress` - active implementation.
- `status:blocked` - waiting on dependency/decision.
- `status:review` - PR open, awaiting review.
- `status:done` - merged and verified.

### Area (one or more)
- `area:storefront-ui`
- `area:shopify-api`
- `area:checkout`
- `area:tests`
- `area:ci-cd`
- `area:security`
- `area:docs`

### Effort (optional)
- `effort:xs` (<=1h)
- `effort:s` (<=1 day)
- `effort:m` (2-3 days)
- `effort:l` (4+ days)

## Conventions
- Every issue must have: one `type:*`, one `priority:*`, one `status:*`, and at least one `area:*`.
- Move issues to `status:ready` only when acceptance criteria and test plan are explicit.
- For agentic execution, include exact file targets and commands in issue body.

## Recommended Initial Label Set
Create these labels in GitHub first:

`type:feature`, `type:bug`, `type:chore`, `type:security`

`priority:p0`, `priority:p1`, `priority:p2`, `priority:p3`

`status:triage`, `status:ready`, `status:in-progress`, `status:blocked`, `status:review`, `status:done`

`area:storefront-ui`, `area:shopify-api`, `area:checkout`, `area:tests`, `area:ci-cd`, `area:security`, `area:docs`

`effort:xs`, `effort:s`, `effort:m`, `effort:l`
