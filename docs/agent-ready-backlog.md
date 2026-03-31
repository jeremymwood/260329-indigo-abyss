# Agent-Ready Backlog (First 10 Issues)

Each issue is scoped to be executable by a coding agent with clear acceptance criteria and verification steps.

## 1) Product Detail Page Route + View
- Title: `feat: add product detail page with Shopify product lookup`
- Labels: `type:feature`, `priority:p1`, `status:ready`, `area:storefront-ui`, `area:shopify-api`, `effort:m`
- Scope: Add `/products/:id` page using Storefront API by product ID/handle.
- Acceptance Criteria:
  - [ ] Route and controller action added.
  - [ ] Product title, image, description, and price render.
  - [ ] Missing product returns 404 page.
- File Targets: `config/routes.rb`, `app/controllers/storefront_controller.rb`, `app/services/shopify/*`, `app/views/storefront/*`
- Verification: `bin/rails test`

## 2) Collection Page with Pagination
- Title: `feat: add /shop collection page with paginated products`
- Labels: `type:feature`, `priority:p1`, `status:ready`, `area:storefront-ui`, `area:shopify-api`, `effort:m`
- Scope: New `/shop` page with cursor-based pagination from Shopify GraphQL.
- Acceptance Criteria:
  - [ ] Shows first page of products.
  - [ ] Next/Previous controls work.
  - [ ] Handles empty collection state.
- Verification: request tests + manual paging check.

## 3) Cart Session Model (Local)
- Title: `feat: implement session-backed cart object`
- Labels: `type:feature`, `priority:p1`, `status:ready`, `area:checkout`, `area:tests`, `effort:m`
- Scope: Session cart with add/remove/update quantity behavior.
- Acceptance Criteria:
  - [ ] Cart persists in session.
  - [ ] Quantity updates and removals work.
  - [ ] Cart totals are computed correctly.
- File Targets: `app/models/` or `app/services/`, `app/controllers/`, `config/routes.rb`
- Verification: unit + request tests.

## 4) Shopify Checkout Handoff
- Title: `feat: create checkout URL from cart lines`
- Labels: `type:feature`, `priority:p1`, `status:ready`, `area:checkout`, `area:shopify-api`, `effort:m`
- Scope: Build Shopify checkout/cart URL from selected variants and quantities.
- Acceptance Criteria:
  - [ ] Checkout button redirects to valid Shopify checkout/cart.
  - [ ] Invalid lines are rejected safely.
  - [ ] User gets clear error feedback on failure.
- Verification: request test for redirect URL generation.

## 5) Replace Hardcoded Fallback Images/Data with Fixtures
- Title: `chore: move fallback product data into structured fixtures`
- Labels: `type:chore`, `priority:p2`, `status:ready`, `area:docs`, `area:tests`, `effort:s`
- Scope: Refactor fallback product definitions into a dedicated file/fixture for maintainability.
- Acceptance Criteria:
  - [ ] No hardcoded fallback array in service class.
  - [ ] Fallback data source documented.
  - [ ] Tests cover fallback rendering path.

## 6) Robust Shopify Error Handling + Logging
- Title: `fix: improve storefront API error handling and observability`
- Labels: `type:bug`, `priority:p1`, `status:ready`, `area:shopify-api`, `area:security`, `effort:m`
- Scope: Handle timeout/HTTP/API errors explicitly and log safe context.
- Acceptance Criteria:
  - [ ] Network timeout is handled gracefully.
  - [ ] Non-200 and GraphQL errors are logged without token leakage.
  - [ ] UI falls back safely with user-friendly message.

## 7) Security Hardening for Secret Handling
- Title: `chore: audit secret handling and add guardrails`
- Labels: `type:security`, `priority:p1`, `status:ready`, `area:security`, `area:ci-cd`, `effort:s`
- Scope: Add secret scanning baseline and docs to prevent accidental commits.
- Acceptance Criteria:
  - [ ] `.gitignore` and docs explicitly protect sensitive files.
  - [ ] CI includes secret scan step (e.g., gitleaks action or equivalent).
  - [ ] README has environment variable safety section.

## 8) Test Coverage Baseline for Storefront Flow
- Title: `chore: add request and service tests for storefront and catalog service`
- Labels: `type:chore`, `priority:p1`, `status:ready`, `area:tests`, `effort:m`
- Scope: Add tests for homepage rendering and Shopify service behavior (success + fallback).
- Acceptance Criteria:
  - [ ] Request spec/test for `/`.
  - [ ] Service tests for success path and fallback path.
  - [ ] CI passes with new tests.

## 9) Add CI Badge + Developer Runbook
- Title: `chore: document local workflow and add CI badge`
- Labels: `type:chore`, `priority:p2`, `status:ready`, `area:docs`, `area:ci-cd`, `effort:xs`
- Scope: README updates for setup, test, lint, and troubleshooting.
- Acceptance Criteria:
  - [ ] CI badge visible in README.
  - [ ] Local dev commands documented clearly.
  - [ ] Common Windows troubleshooting section included.

## 10) Agentic Issue-to-PR Workflow Spec
- Title: `feat: define issue-to-PR agent workflow using labels and templates`
- Labels: `type:feature`, `priority:p2`, `status:ready`, `area:ci-cd`, `area:docs`, `effort:s`
- Scope: Create playbook for turning `status:ready` issues into Codex-driven PRs.
- Acceptance Criteria:
  - [ ] Document branch naming and PR template conventions.
  - [ ] Define required checks and merge gates.
  - [ ] Include prompt template for Codex issue execution.
