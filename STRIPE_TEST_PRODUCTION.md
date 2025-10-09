# Stripe Configuration - Test vs Production

## 🧪 Staging (Test Mode)

### Products & Prices
- **Starter Plan**
  - Product ID: `prod_TCZMnCE71ibzRl`
  - Price ID: `price_1SGAFYD10JtvEUh4hrROqN7p`
  - Amount: $29.00/month
  - Sessions: 5,000/month

- **Growth Plan**
  - Product ID: `prod_TCZMNwoe1VXZ9I`
  - Price ID: `price_1SGAFhD10JtvEUh47Hn3QBkl`
  - Amount: $99.00/month
  - Sessions: 20,000/month

### API Keys (Test Mode)
- Secret Key: `sk_test_51SENumD10JtvEUh4...` (configured in secrets)
- Publishable Key: `pk_test_51SENumD10JtvEUh4...` (configured in secrets)

### Webhook (Test Mode)
- Endpoint ID: `we_1SGAGRD10JtvEUh48R4DXnca`
- URL: `https://staging.ai-gate.dev/webhook/stripe`
- Secret: `whsec_t7UFRQ3uMeD8idMGcUth9Uy5jHKF0RVl`
- Events:
  - `customer.subscription.created`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
  - `checkout.session.completed`

### Secrets Configured
**API Staging** (`luna-proxy-api-staging`):
- ✅ `STRIPE_SECRET_KEY` - Test mode secret key
- ✅ `STRIPE_PRICE_STARTER` - Test Starter price ID
- ✅ `STRIPE_PRICE_GROWTH` - Test Growth price ID
- ✅ `STRIPE_WEBHOOK_SECRET` - Test webhook signing secret

**Web Staging** (`luna-proxy-web-frontend-staging`):
- ✅ `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` - Test mode publishable key

---

## 🚀 Production (Live Mode)

### Products & Prices
- Production uses **live mode** Stripe keys
- Products and prices are configured in production secrets
- Different product/price IDs from test mode

### API Keys (Live Mode)
- Secret Key: Configured in production secrets
- Publishable Key: Configured in production secrets

### Webhook (Live Mode)
- Endpoint: `https://api.ai-gate.dev/webhook/stripe`
- Secret: Configured in production secrets
- Same event types as test mode

### Secrets Configured
**API Production** (`luna-proxy-api`):
- ✅ `STRIPE_SECRET_KEY` - Live mode secret key
- ✅ `STRIPE_PRICE_STARTER` - Live Starter price ID
- ✅ `STRIPE_PRICE_GROWTH` - Live Growth price ID
- ✅ `STRIPE_WEBHOOK_SECRET` - Live webhook signing secret

**Web Production** (`luna-proxy-web-frontend`):
- ✅ `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` - Live mode publishable key

---

## Testing Checkout on Staging

Use Stripe test cards on staging environment:

### Successful Payments
- **Basic success**: `4242 4242 4242 4242`
- **3D Secure auth**: `4000 0025 0000 3155`

### Card Details
- **Expiry**: Any future date (e.g., 12/34)
- **CVC**: Any 3 digits (e.g., 123)
- **ZIP**: Any 5 digits (e.g., 12345)

### Failed Payments
- **Card declined**: `4000 0000 0000 0002`
- **Insufficient funds**: `4000 0000 0000 9995`
- **Processing error**: `4000 0000 0000 0119`

### Test Flow
1. Visit `https://staging-app.ai-gate.dev`
2. Sign in with Google/GitHub OAuth
3. Navigate to Dashboard → Upgrade to Starter
4. Use test card `4242 4242 4242 4242`
5. Verify checkout completes
6. Check webhook receives `checkout.session.completed` event
7. Verify subscription shows in dashboard

---

## Environment Separation

| Feature | Staging | Production |
|---------|---------|------------|
| Stripe Mode | **Test** | **Live** |
| API Keys | `sk_test_*` / `pk_test_*` | `sk_live_*` / `pk_live_*` |
| Products | Test products | Live products |
| Webhooks | Test endpoint | Live endpoint |
| D1 Database | `luna-proxy-users-staging` | `luna-proxy-users` |
| KV Namespace | `RATE_LIMIT_STAGING` | `RATE_LIMIT` |
| Domain | `staging-app.ai-gate.dev` | `www.ai-gate.dev` |
| Real Charges | ❌ No | ✅ Yes |

✅ **Complete separation** - staging uses Stripe test mode, production uses live mode

---

## Commands Used

### Create Test Products
```bash
stripe products create -d "name=Starter Plan" -d "description=5,000 sessions per month"
stripe products create -d "name=Growth Plan" -d "description=20,000 sessions per month"
```

### Create Test Prices
```bash
stripe prices create --product=prod_TCZMnCE71ibzRl --unit-amount=2900 --currency=usd --recurring.interval=month
stripe prices create --product=prod_TCZMNwoe1VXZ9I --unit-amount=9900 --currency=usd --recurring.interval=month
```

### Create Test Webhook
```bash
stripe webhook_endpoints create \
  --url="https://staging.ai-gate.dev/webhook/stripe" \
  --enabled-events="customer.subscription.created" \
  --enabled-events="customer.subscription.updated" \
  --enabled-events="customer.subscription.deleted" \
  --enabled-events="checkout.session.completed"
```

### Configure Secrets
```bash
# API Staging
echo "sk_test_..." | wrangler secret put STRIPE_SECRET_KEY --env staging
echo "price_..." | wrangler secret put STRIPE_PRICE_STARTER --env staging
echo "price_..." | wrangler secret put STRIPE_PRICE_GROWTH --env staging
echo "whsec_..." | wrangler secret put STRIPE_WEBHOOK_SECRET --env staging

# Web Staging
echo "pk_test_..." | wrangler secret put NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY --env staging
```
