# Indigo Abyss

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

## Optional pre-push checks

Install project git hooks once:

```bash
ruby bin/install-hooks
```

Then every `git push` runs:

- `bin/rubocop`
- `bin/rails test`

## Current app behavior

- `/` renders a branded Indigo Abyss homepage.
- It requests featured products from Shopify using Storefront GraphQL.
- If Shopify credentials are unavailable or API calls fail, it falls back to sample products so the UI still works.
