# Luna Proxy - Shared Scripts

> **Location**: Part of [luna-proxy-projects](https://github.com/luna-assistant-ai/luna-proxy-projects) monorepo

These helper scripts are shared across Luna Proxy projects.

## 📋 Prerequisites

- Install Stripe CLI: `brew install stripe/stripe-cli/stripe`
- Login: `stripe login` (choose test or live environment)
- jq installed: `brew install jq`
- macOS / zsh

## 🛠️ Available Scripts

### Stripe Setup

#### `stripe-bootstrap.sh [test|live] [--force]`
- Creates products and prices for plans: Starter, Build, Pro, Agency
- Base monthly price + metered graduated overage (tier 1 = included minutes at $0)
- Stores IDs in `scripts/stripe-ids.<mode>.json`

#### `stripe-webhook-setup.sh [test|live]`
- Creates webhook endpoint for staging (test) or production (live)
- Appends webhook id and signing secret to `scripts/stripe-ids.<mode>.json` (if returned by CLI)

#### `stripe-export-ids.sh [test|live]`
- Prints wrangler secret put commands to populate secrets in luna-proxy-api

### Domain Migration

#### `cf-migrate-domain.sh`
- Cloudflare domain migration helper script

## 💰 Plan Configuration
- Currency: USD
- Plans:
  - Starter: $9/mo, 1500 min included, overage $0.012/min
  - Build:   $19/mo, 3000 min included, overage $0.011/min
  - Pro:     $39/mo, 8000 min included, overage $0.009/min
  - Agency:  $99/mo, 25000 min included, overage $0.008/min
- Free plan: enforced app-side (hard stop at 200 min). Enterprise: custom.

## 🚀 Usage

### Test Mode Setup

1. **Bootstrap products and prices**
   ```bash
   ./scripts/stripe-bootstrap.sh test
   ```

2. **Setup webhooks**
   ```bash
   ./scripts/stripe-webhook-setup.sh test
   ```

3. **Export commands to set secrets**
   ```bash
   ./scripts/stripe-export-ids.sh test
   ```

### Production Setup

Repeat the same steps for live mode:
```bash
./scripts/stripe-bootstrap.sh live
./scripts/stripe-webhook-setup.sh live
./scripts/stripe-export-ids.sh live
```

## 📝 Notes
- If the CLI does not return the webhook signing secret, grab it from Stripe Dashboard and add it to scripts/stripe-ids.<mode>.json manually (key: webhook_<mode>_secret).
- Report usage: send usage_records in minutes at end-of-session with idempotency. Prefer aggregate_usage=sum and a periodic flush (1–5 min).
