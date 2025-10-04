# Stripe scripts for AI Gate

These helper scripts use Stripe CLI to create products, prices and webhooks for your multi-plan metered billing.

Prereqs
- Install Stripe CLI: brew install stripe/stripe-cli/stripe
- Login: stripe login (choose test or live environment)
- jq installed: brew install jq
- macOS / zsh

Scripts
- stripe-bootstrap.sh [test|live] [--force]
  - Creates products and prices for plans: Starter, Build, Pro, Agency
  - Base monthly price + metered graduated overage (tier 1 = included minutes at $0)
  - Stores IDs in scripts/stripe-ids.<mode>.json
- stripe-webhook-setup.sh [test|live]
  - Creates webhook endpoint for staging (test) or production (live)
  - Appends webhook id and signing secret to scripts/stripe-ids.<mode>.json (if returned by CLI)
- stripe-export-ids.sh [test|live]
  - Prints wrangler secret put commands to populate secrets in luna-proxy-api

Plan configuration
- Currency: USD
- Plans:
  - Starter: $9/mo, 1500 min included, overage $0.012/min
  - Build:   $19/mo, 3000 min included, overage $0.011/min
  - Pro:     $39/mo, 8000 min included, overage $0.009/min
  - Agency:  $99/mo, 25000 min included, overage $0.008/min
- Free plan: enforced app-side (hard stop at 200 min). Enterprise: custom.

Usage
1) Test mode bootstrap
```sh
./scripts/stripe-bootstrap.sh test
```
2) Test mode webhook
```sh
./scripts/stripe-webhook-setup.sh test
```
3) Export commands to set secrets
```sh
./scripts/stripe-export-ids.sh test
```
4) Repeat for live
```sh
./scripts/stripe-bootstrap.sh live
./scripts/stripe-webhook-setup.sh live
./scripts/stripe-export-ids.sh live
```

Notes
- If the CLI does not return the webhook signing secret, grab it from Stripe Dashboard and add it to scripts/stripe-ids.<mode>.json manually (key: webhook_<mode>_secret).
- Report usage: send usage_records in minutes at end-of-session with idempotency. Prefer aggregate_usage=sum and a periodic flush (1–5 min).
