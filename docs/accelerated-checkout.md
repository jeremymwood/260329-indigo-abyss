# Accelerated Checkout Decision

## Current implementation

Indigo Abyss uses Shopify cart permalink handoff:

- `POST /cart/checkout` builds `https://<store>.myshopify.com/cart/<variant_id>:<qty>?checkout`
- User is redirected to Shopify-hosted checkout

This is the canonical and lowest-risk path for a Rails storefront using Shopify Storefront API.

## Accelerated payment options

Shop Pay, Apple Pay, Google Pay, and PayPal are not activated by Rails app code directly.
They appear on Shopify-hosted checkout when enabled in store/admin payment settings.

What this app does:

- Clearly communicates accelerated options on the cart page
- Sends users to the Shopify-hosted checkout where those options can render

## Error and fallback behavior

- If cart lines cannot produce valid variant IDs, checkout handoff is rejected safely.
- User is redirected back to cart with a clear alert message.
- If Shopify store domain is not configured, checkout is blocked with a clear message.

## Follow-up options

- Add a shop-domain-specific help link to payment setup docs.
- Add analytics events for checkout handoff and checkout failures.
