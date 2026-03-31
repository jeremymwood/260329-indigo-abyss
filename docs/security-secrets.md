# Secrets and Environment Safety

This project uses Shopify credentials and automation tokens. Follow these rules to prevent leaks.

## What should never be committed

- `.env` files and other local environment files
- Rails key material (`config/master.key`, `config/credentials/*.key`)
- Private keys/certificates (`*.pem`, `*.p12`, `*.pfx`, `*.key`, `*.crt`, `*.cer`)
- Personal access tokens (PATs), Shopify access tokens, and API keys

## Safe local setup

1. Keep `.env` local and out of source control.
2. Use `.env.example` as the template for required variables.
3. Rotate any token immediately if it is pasted in logs, chat, or committed by mistake.
4. Use least-privilege scopes for GitHub and Shopify tokens.

## CI guardrails

- GitHub Actions runs `gitleaks` on every push and pull request.
- CI fails if potential secrets are detected.

## If a secret is exposed

1. Revoke/rotate the secret immediately.
2. Remove leaked values from repository history if needed.
3. Open a security incident issue with impacted systems and remediation steps.
