# AI Gate - Shared Scripts

> **Part of the [AI Gate](https://github.com/luna-assistant-ai/ai-gate) monorepo**

Shared utility scripts for AI Gate infrastructure and billing setup.

## 📋 Prerequisites

- **Stripe CLI**: `brew install stripe/stripe-cli/stripe`
- **Login**: `stripe login` (choose test or live environment)
- **jq**: `brew install jq`
- **Wrangler**: `npm install -g wrangler`

---

## 📁 Structure

```
scripts/
├── stripe/              # Stripe billing setup
│   ├── bootstrap.sh     # Create products and prices
│   ├── export-ids.sh    # Export IDs for wrangler secrets
│   └── webhook-setup.sh # Configure webhooks
└── cloudflare/          # Cloudflare utilities
    └── migrate-domain.sh # Domain migration helper
```

---

## 💳 Stripe Scripts

### 1. Bootstrap Products and Prices

Creates Stripe products and prices for all billing tiers.

```bash
# Test mode
./scripts/stripe/bootstrap.sh test

# Production mode
./scripts/stripe/bootstrap.sh live

# Force recreate (deletes existing)
./scripts/stripe/bootstrap.sh test --force
```

**What it creates:**
- 4 products: Starter, Build, Pro, Agency
- Each with base monthly price + metered overage
- Stores IDs in `scripts/stripe-ids.<mode>.json`

**Pricing:**
- **Starter**: $9/mo, 1500 min included, $0.012/min overage
- **Build**: $19/mo, 3000 min included, $0.011/min overage
- **Pro**: $39/mo, 8000 min included, $0.009/min overage
- **Agency**: $99/mo, 25000 min included, $0.008/min overage

### 2. Setup Webhooks

Creates webhook endpoints for AI Gate API.

```bash
# Test mode (staging)
./scripts/stripe/webhook-setup.sh test

# Production mode
./scripts/stripe/webhook-setup.sh live
```

**Events subscribed:**
- `checkout.session.completed`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.finalized`
- `invoice.paid`
- `invoice.payment_failed`

**Output**: Appends webhook ID and signing secret to `scripts/stripe-ids.<mode>.json`

### 3. Export IDs for Wrangler

Prints `wrangler secret put` commands to configure secrets in luna-proxy-api.

```bash
# Test mode
./scripts/stripe/export-ids.sh test

# Production mode
./scripts/stripe/export-ids.sh live
```

**Output example:**
```bash
cd luna-proxy-api
wrangler secret put STRIPE_PRICE_STARTER_BASE
# Paste: price_xxx
wrangler secret put STRIPE_PRICE_STARTER_OVERAGE
# Paste: price_yyy
...
```

---

## ☁️ Cloudflare Scripts

### Domain Migration

Helper script for migrating domains to Cloudflare.

```bash
./scripts/cloudflare/migrate-domain.sh
```

**Features:**
- DNS record migration
- Zone setup
- SSL/TLS configuration

---

## 📊 Pricing Configuration

All pricing is configured in USD with graduated metered billing:

| Plan    | Monthly | Included Minutes | Overage Rate |
|---------|---------|------------------|--------------|
| Free    | $0      | 200              | N/A (hard stop) |
| Starter | $9      | 1,500            | $0.012/min   |
| Build   | $19     | 3,000            | $0.011/min   |
| Pro     | $39     | 8,000            | $0.009/min   |
| Agency  | $99     | 25,000           | $0.008/min   |
| Enterprise | Custom | Custom        | Custom       |

**Notes:**
- Free plan: Enforced app-side (hard stop at 200 min)
- Enterprise: Custom pricing, contact sales
- Overage: Tier 1 = included minutes at $0, Tier 2 = additional minutes at overage rate

---

## 🚀 Complete Setup Workflow

### Initial Setup (Test Mode)

```bash
# 1. Bootstrap Stripe
./scripts/stripe/bootstrap.sh test

# 2. Setup webhooks
./scripts/stripe/webhook-setup.sh test

# 3. Export secrets
./scripts/stripe/export-ids.sh test

# 4. Copy the commands and run them in luna-proxy-api/
cd luna-proxy-api
# Paste and run the wrangler secret put commands

# 5. Add webhook secret
wrangler secret put STRIPE_WEBHOOK_SECRET --env staging
# Paste the webhook secret from scripts/stripe-ids.test.json

# 6. Add Stripe secret key
wrangler secret put STRIPE_SECRET_KEY --env staging
# Paste your Stripe test secret key (sk_test_...)
```

### Production Setup

```bash
# 1. Bootstrap Stripe (production)
./scripts/stripe/bootstrap.sh live

# 2. Setup webhooks
./scripts/stripe/webhook-setup.sh live

# 3. Export secrets
./scripts/stripe/export-ids.sh live

# 4. Configure secrets in production
cd luna-proxy-api
# Run the wrangler secret put commands (without --env flag)

# 5. Add webhook secret
wrangler secret put STRIPE_WEBHOOK_SECRET
# Paste from scripts/stripe-ids.live.json

# 6. Add Stripe live secret key
wrangler secret put STRIPE_SECRET_KEY
# Paste your Stripe live secret key (sk_live_...)
```

---

## 📝 Generated Files

Scripts generate the following files:

```
scripts/
├── stripe-ids.test.json     # Test mode IDs and secrets
└── stripe-ids.live.json     # Production IDs and secrets
```

**Format:**
```json
{
  "product_starter": "prod_xxx",
  "price_starter_base": "price_xxx",
  "price_starter_overage": "price_xxx",
  "webhook_test_id": "we_xxx",
  "webhook_test_secret": "whsec_xxx"
}
```

**⚠️ Security**: These files contain sensitive IDs. They are gitignored by default.

---

## 🔧 Troubleshooting

### Webhook secret not returned by CLI

If the Stripe CLI doesn't return the webhook signing secret:

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/webhooks)
2. Find your webhook endpoint
3. Click "Reveal" on the signing secret
4. Manually add it to `scripts/stripe-ids.<mode>.json`:
   ```json
   {
     "webhook_test_secret": "whsec_xxx"
   }
   ```

### Products already exist

If you get "product already exists" errors:

```bash
# Use --force to delete and recreate
./scripts/stripe/bootstrap.sh test --force
```

**⚠️ Warning**: This will delete existing products and subscriptions!

### Wrong Stripe account

Make sure you're logged into the correct Stripe account:

```bash
stripe login
# Follow the prompts to login to the correct account
```

---

## 📚 Documentation

For complete setup guides, see:

- [Stripe Setup Guide](../docs/setup/STRIPE-SETUP.md)
- [Deployment Guide](../docs/deployment/DEPLOYMENT.md)
- [Pricing Strategy](../docs/setup/PRICING-STRATEGY.md)

---

## 🔗 Links

- **Stripe Dashboard**: https://dashboard.stripe.com
- **Stripe CLI Docs**: https://stripe.com/docs/stripe-cli
- **AI Gate Docs**: https://github.com/luna-assistant-ai/ai-gate

---

<div align="center">
  <p>Part of <strong>AI Gate</strong> - Your gateway to AI APIs</p>
</div>
