# AI Gate – Shared Scripts

> **Part of the [AI Gate](https://github.com/luna-assistant-ai/ai-gate) monorepo**

Utility scripts used to provision billing (Stripe) and infrastructure (Cloudflare).

---

## 📋 Prerequisites

- **Stripe CLI** – `brew install stripe/stripe-cli/stripe`
- **jq** – `brew install jq`
- **Wrangler** – `npm install -g wrangler`
- Stripe CLI logged-in for each mode (`stripe login`, `stripe login --live`)

> The session scripts accept an optional `STRIPE` environment variable. Examples:
> ```bash
> ./scripts/stripe-setup-sessions.sh                  # uses ~/bin/stripe (default)
> STRIPE="stripe" ./scripts/stripe-setup-sessions.sh  # explicit cli
> STRIPE="stripe --live" ./scripts/stripe-setup-sessions.sh  # live mode
> ```

---

## 📁 Directory Overview

```
scripts/
├── stripe-setup-sessions.sh            # Create session-based products/prices (Starter + Growth)
├── stripe-export-secrets-sessions.sh   # Print wrangler commands (Starter/Growth)
├── stripe-ids-sessions.test.json       # Example output (test)
├── stripe-ids-sessions.live.json       # Example output (live)
├── STRIPE-PRODUCTS-MANUAL-SETUP.md     # Manual dashboard instructions
├── stripe/                             # Legacy minute-based scripts (bootstrap/export/webhook)
└── cloudflare/                         # Cloudflare utilities (domain migration, etc.)
```

Legacy helpers (`stripe/bootstrap.sh`, `stripe/export-ids.sh`, `stripe/webhook-setup.sh`) are kept for reference but new deployments should rely on the session scripts at the repository root.

---

## 💳 Session-Based Stripe Workflow

### 1. Create products & prices

```bash
./scripts/stripe-setup-sessions.sh             # writes stripe-ids-sessions.test.json
STRIPE="stripe --live" ./scripts/stripe-setup-sessions.sh   # optional live run
```

Plans created:
- **Starter** – $29/mo, 5 000 sessions (≈10 000 minutes), metadata (projects, rate limits, support)
- **Growth** – $99/mo, 20 000 sessions (≈40 000 minutes)
- Free plan handled côté code (pas de produit Stripe)

### 2. Export secrets for Wrangler

```bash
./scripts/stripe-export-secrets-sessions.sh test   # staging / test
./scripts/stripe-export-secrets-sessions.sh live   # production / live
```

The helper prints ready-to-paste commands:
- `STRIPE_PRICE_STARTER`
- `STRIPE_PRICE_GROWTH`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`

### 3. Configure webhooks (optional script)

```bash
./scripts/stripe/webhook-setup.sh test
./scripts/stripe/webhook-setup.sh live
```

Events subscribed: `checkout.session.completed`, `customer.subscription.*`, `invoice.*`. You can also follow the manual process described in [STRIPE-PRODUCTS-MANUAL-SETUP.md](../docs/STRIPE-PRODUCTS-MANUAL-SETUP.md).

---

## 📊 Pricing Snapshot

| Plan    | Price | Sessions/mo | Minutes estimate | Projects | Rate limit rpm | Concurrent | Support |
|---------|-------|-------------|------------------|----------|----------------|------------|---------|
| Free    | $0    | 100         | ~200             | 1        | 100            | 1          | Community |
| Starter | $29   | 5 000       | ~10 000          | 3        | 1 000          | 10         | Email 48h |
| Growth  | $99   | 20 000      | ~40 000          | 10       | 10 000         | 50         | Email 24h + SLA 99.9% |

All quotas are enforced inside the API (`checkQuotaRemaining`). Minutes are collected only for cost analytics (`minutes_used`).

---

## ☁️ Cloudflare Utilities

```bash
# Domain migration helper
./scripts/cloudflare/migrate-domain.sh
```

---

## 🚀 Complete Setup Checklist

1. **CLI login** – `stripe login` / `stripe login --live`.
2. **Create products** – `./scripts/stripe-setup-sessions.sh` (and optionally the live variant).
3. **Export secrets** – `./scripts/stripe-export-secrets-sessions.sh test|live`.
4. **Configure wrangler** – run each `wrangler secret put ...` in `luna-proxy-api/`.
5. **Provision webhooks** – script helper or dashboard.
6. **Deploy API** – `wrangler deploy --env staging` puis production.
7. **Validate checkout** – effectuer un paiement test et surveiller les webhooks.

---

## 🧾 Legacy Scripts (Minutes Model)

For historical reference, the previous minute-based workflow is still available inside `scripts/stripe/` (`bootstrap.sh`, `export-ids.sh`, `webhook-setup.sh`). Use only if you need to reproduce the legacy pricing for audits or migrations.
