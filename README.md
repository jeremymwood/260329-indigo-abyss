# Indigo Abyss
[![CI](https://github.com/jeremymwood/260329-indigo-abyss/actions/workflows/ci.yml/badge.svg)](https://github.com/jeremymwood/260329-indigo-abyss/actions/workflows/ci.yml)

A Ruby on Rails storefront for a denim brand, wired to Shopify Storefront API.

## Stack

- Ruby 3.3+
- Rails 8
- SQLite (default development database)
- Shopify Storefront GraphQL API

## Local setup

1. Install gems:
   ```bash
   bundle install
   ```
2. Copy env template and fill in Shopify values:
   ```bash
   copy .env.example .env
   ```
3. Create the database:
   ```bash
   bin/rails db:prepare
   ```
4. Start the app:
   ```bash
   bin/rails server
   ```
5. Open `http://localhost:3000`.

## Shopify configuration

Set these values in your environment (or `.env` via your preferred loader):

- `SHOPIFY_STORE_DOMAIN` (example: `your-store.myshopify.com`)
- `SHOPIFY_STOREFRONT_ACCESS_TOKEN`

If these are missing, the homepage runs in showcase mode with curated sample denim products.
The fallback product source is maintained in `config/fallback_products.yml`.
Accelerated checkout implementation notes: [Accelerated Checkout Decision](docs/accelerated-checkout.md).

## Optional pre-push checks

Install project git hooks once:

```bash
ruby bin/install-hooks
```

Then every `git push` runs:

- `bin/rubocop`
- `bin/rails test`

## Local Developer Commands

- Start server: `bin/rails server`
- Run tests: `bin/rails test`
- Run lint: `bin/rubocop`
- Run security scan: `bin/brakeman --no-pager`
- Run pre-push checks manually: `ruby bin/prepush`

Full workflow + troubleshooting: [Developer Runbook](docs/developer-runbook.md)

## Environment Variable Safety

- Do not commit `.env` or token files.
- Keep secrets in local environment variables or GitHub repository secrets.
- Rotate tokens immediately if they are exposed.
- Review guardrails in [Secrets and Environment Safety](docs/security-secrets.md).

## Current app behavior

- `/` renders a branded Indigo Abyss homepage.
- It requests featured products from Shopify using Storefront GraphQL.
- If Shopify credentials are unavailable or API calls fail, it falls back to sample products so the UI still works.
