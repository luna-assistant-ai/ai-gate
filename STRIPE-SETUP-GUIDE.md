# Stripe Setup Guide - AI Gate

## 🎯 Quick Start (5 minutes)

### 1. Create Stripe Account
1. Go to https://stripe.com
2. Sign up / Log in
3. Activate test mode (toggle in top right)

---

## 📦 Step 1: Create Products and Prices (CLI recommended)

This project uses monthly plans with included minutes and graduated metered overage.

Use the helper scripts:

```sh
# Test mode
./scripts/stripe-bootstrap.sh test
# Live mode
./scripts/stripe-bootstrap.sh live
```

Plans created (USD):
- Starter: $9/mo, 1500 min included, overage $0.012/min
- Build:   $19/mo, 3000 min included, overage $0.011/min
- Pro:     $39/mo, 8000 min included, overage $0.009/min
- Agency:  $99/mo, 25000 min included, overage $0.008/min

Outputs: scripts/stripe-ids.<mode>.json with product_*/price_* IDs.

---

## 🔑 Step 2: Configure Secrets (Wrangler)

Use the export helper to print copy-paste commands:

```sh
./scripts/stripe-export-ids.sh test   # for staging
./scripts/stripe-export-ids.sh live   # for production
```

Then set them inside luna-proxy-api:

```bash
cd luna-proxy-api

# Stripe secret key
wrangler secret put STRIPE_SECRET_KEY [--env staging]
# sk_test_... or sk_live_...

# Webhook signing secret
wrangler secret put STRIPE_WEBHOOK_SECRET [--env staging]
# whsec_...

# Base and overage price IDs
wrangler secret put STRIPE_PRICE_STARTER_BASE [--env staging]
wrangler secret put STRIPE_PRICE_STARTER_OVERAGE [--env staging]
wrangler secret put STRIPE_PRICE_BUILD_BASE [--env staging]
wrangler secret put STRIPE_PRICE_BUILD_OVERAGE [--env staging]
wrangler secret put STRIPE_PRICE_PRO_BASE [--env staging]
wrangler secret put STRIPE_PRICE_PRO_OVERAGE [--env staging]
wrangler secret put STRIPE_PRICE_AGENCY_BASE [--env staging]
wrangler secret put STRIPE_PRICE_AGENCY_OVERAGE [--env staging]
```

---

## 🪝 Step 3: Setup Webhooks

Create webhook endpoints with the script:

```sh
./scripts/stripe-webhook-setup.sh test   # staging URL
./scripts/stripe-webhook-setup.sh live   # production URL
```

Events:
- checkout.session.completed
- customer.subscription.created
- customer.subscription.updated
- customer.subscription.deleted
- invoice.finalized
- invoice.paid
- invoice.payment_failed

The script appends webhook id and, if returned by the CLI, the signing secret to scripts/stripe-ids.<mode>.json.

---

## ✅ Step 4: Verify Setup

### Test with cURL (example)

```bash
# 1. Test checkout endpoint (adapt to your API)
curl -X POST https://api.ai-gate.dev/billing/checkout \
  -H "Content-Type: application/json" \
  -d '{
    "plan": "starter",
    "user_id": "test_user_123",
    "email": "test@example.com"
  }'

# Expected: { "url": "https://checkout.stripe.com/..." }

# 2. Test usage endpoint (if exposed)
curl https://api.ai-gate.dev/billing/usage?user_id=test_user_123
```

### Test Webhooks with Stripe CLI

```bash
brew install stripe/stripe-cli/stripe
stripe login
stripe listen --forward-to https://luna-proxy-api-staging.joffrey-vanasten.workers.dev/webhooks/stripe
stripe trigger checkout.session.completed
```

---

## 📊 Monitoring

- Stripe Dashboard → Payments / Subscriptions / Webhooks
- D1 queries for webhook events and usage reconciliation

---

## 🔒 Security Checklist

- Webhook signing secret configured per environment
- API keys stored as secrets
- Webhook signature verified
- Test mode enabled for staging
- Never commit keys
- Stripe Dashboard 2FA enabled

---

## 🚨 Troubleshooting

- STRIPE_SECRET_KEY not configured → wrangler secret put STRIPE_SECRET_KEY
- Invalid signature on webhooks → verify STRIPE_WEBHOOK_SECRET
- Checkout URL fails → check price IDs
- Customer not found → ensure checkout flow creates customer

---

## 📝 Next Steps

- Configure secrets
- Create webhook endpoint
- Test checkout and usage
- Add billing UI to dashboard
- Set up monthly usage reporting

---

**Setup Time:** ~10 minutes
**Status:** Ready for testing
