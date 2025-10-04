# Stripe Pricing Strategy - AI Gate

## 🎯 Modèle innovant : Pay-What-Works

### Philosophy
**"Only pay for successful sessions"** - Alignement parfait entre coût et valeur.

---

## 💰 Pricing Tiers

### 1. **Free Tier** (No credit card)
- **100 sessions/month**
- **5 concurrent sessions max**
- **Community support** (GitHub Discussions)
- ✅ Perfect for: Testing, MVPs, hobbyists

### 2. **Pay-as-you-go** (Usage-based)
- **$0.10 per successful session**
- **Unlimited concurrent sessions**
- **Email support** (48h response)
- **Guarantee**: Failed sessions = $0 charged
  - Session drop (TURN fail)
  - Latency >2s on connection
  - OpenAI API error
- ✅ Perfect for: Startups, growing apps

### 3. **Pro Plan** (Volume discount)
- **$29/month** = 400 sessions included (~$0.073/session)
- **Then $0.07/session** after quota
- **Unlimited concurrent sessions**
- **Priority support** (24h response)
- **SLA 99.9% uptime**
- ✅ Perfect for: Production apps, scale-ups

---

## 🔧 Implementation Plan

### Phase 1: Free Tier (Already implemented)
- [x] Rate limiting (100 sessions/month via KV)
- [x] Concurrent sessions limit (5 max)
- [ ] Add counter in dashboard

### Phase 2: Pay-as-you-go (This sprint)
- [ ] Stripe Customer Portal
- [ ] Session success tracking (D1)
- [ ] Auto-charge at end of month
- [ ] Webhook: `invoice.payment_succeeded`

### Phase 3: Pro Plan (Later)
- [ ] Stripe subscription
- [ ] Quota tracking
- [ ] Overage billing

---

## 📊 Stripe Products Setup

### Free Tier
```json
{
  "name": "AI Gate Free",
  "description": "100 sessions/month - Perfect for testing",
  "metadata": {
    "plan": "free",
    "monthly_quota": "100",
    "concurrent_limit": "5"
  }
}
```

### Pay-as-you-go
```json
{
  "name": "AI Gate Pay-as-you-go",
  "type": "metered",
  "unit_amount": 10,
  "currency": "usd",
  "recurring": {
    "interval": "month",
    "usage_type": "metered"
  },
  "metadata": {
    "plan": "payg",
    "success_only": "true"
  }
}
```

### Pro Plan
```json
{
  "name": "AI Gate Pro",
  "type": "licensed",
  "unit_amount": 2900,
  "currency": "usd",
  "recurring": {
    "interval": "month"
  },
  "metadata": {
    "plan": "pro",
    "included_sessions": "400",
    "overage_price": "7"
  }
}
```

---

## 🛠️ Technical Architecture

### Database Schema (D1)

```sql
-- Customers table
CREATE TABLE IF NOT EXISTS stripe_customers (
  user_id TEXT PRIMARY KEY,
  stripe_customer_id TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  plan TEXT DEFAULT 'free', -- free, payg, pro
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Usage tracking
CREATE TABLE IF NOT EXISTS session_usage (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  session_id TEXT NOT NULL,
  status TEXT NOT NULL, -- success, failed, timeout
  duration_ms INTEGER,
  charged BOOLEAN DEFAULT 0,
  stripe_invoice_id TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES stripe_customers(user_id)
);

CREATE INDEX idx_usage_user_charged ON session_usage(user_id, charged);
CREATE INDEX idx_usage_created ON session_usage(created_at);
```

### API Endpoints

#### `/api/billing/checkout` (Create checkout session)
```typescript
POST /api/billing/checkout
Body: { plan: 'payg' | 'pro' }
Response: { url: 'https://checkout.stripe.com/...' }
```

#### `/api/billing/portal` (Customer portal)
```typescript
POST /api/billing/portal
Response: { url: 'https://billing.stripe.com/...' }
```

#### `/api/billing/usage` (Current usage)
```typescript
GET /api/billing/usage
Response: {
  plan: 'free',
  sessions_this_month: 42,
  quota: 100,
  estimated_cost: 0
}
```

#### `/api/webhooks/stripe` (Webhooks)
```typescript
POST /api/webhooks/stripe
Events:
  - customer.subscription.created
  - customer.subscription.deleted
  - invoice.payment_succeeded
  - invoice.payment_failed
```

---

## 🎨 UX Flow

### 1. User signs up
→ Create Stripe Customer (free tier by default)
→ Show dashboard with "100 free sessions"

### 2. User hits quota
→ Banner: "85/100 sessions used this month"
→ CTA: "Upgrade to Pay-as-you-go"

### 3. User clicks upgrade
→ Stripe Checkout
→ Choose: Pay-as-you-go ($0.10/session) or Pro ($29/mo)

### 4. Payment succeeds
→ Webhook updates plan in DB
→ User can create unlimited sessions
→ Usage tracked in D1

### 5. End of month
→ Stripe auto-generates invoice
→ Charge only successful sessions
→ Email receipt

---

## 💡 Innovation: "Success Guarantee"

### What counts as "successful"?
✅ Session created + audio exchanged for >5 seconds
✅ WebRTC connection established
✅ No TURN failures

❌ Not charged for:
- TURN connection timeout
- OpenAI API errors
- Session drop <5s

### Implementation
```typescript
// Mark session as billable
async function markSessionSuccess(sessionId: string, duration: number) {
  if (duration < 5000) return; // Don't charge if <5s

  await env.DB.prepare(`
    UPDATE session_usage
    SET status = 'success', duration_ms = ?
    WHERE session_id = ? AND status = 'pending'
  `).bind(duration, sessionId).run();
}
```

---

## 📈 Metrics to track

- **Conversion rate**: Free → Paid
- **Churn rate**: Monthly cancellations
- **ARPU**: Average revenue per user
- **Success rate**: Sessions charged / Sessions created
- **MRR**: Monthly recurring revenue

---

## 🚀 Launch Checklist

### MVP (This sprint)
- [ ] Stripe account setup
- [ ] Create products in Stripe Dashboard
- [ ] Implement checkout endpoint
- [ ] Implement webhook handler
- [ ] Basic usage tracking
- [ ] Dashboard billing section

### V2 (Later)
- [ ] Pro plan with quotas
- [ ] Volume discounts
- [ ] Enterprise custom pricing
- [ ] Detailed invoices (PDF)
- [ ] Tax handling (Stripe Tax)

---

**Start with**: Pay-as-you-go only (simplest)
**Pricing**: $0.10/session (success-only)
**Free tier**: 100 sessions/month (already working)
