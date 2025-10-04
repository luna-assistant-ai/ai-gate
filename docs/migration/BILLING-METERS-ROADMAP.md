# Billing Meters Migration Roadmap

> **Status**: Planning Phase
> **Current**: Fixed monthly pricing with hard caps
> **Target**: Stripe Billing Meters with automatic overage
> **Timeline**: Q2 2025 (when Stripe API matures)

---

## 🎯 Current State (MVP - Launched)

### Pricing Model
**Fixed monthly plans with backend-enforced quotas**

| Plan    | Price   | Minutes | Overage Strategy |
|---------|---------|---------|------------------|
| Free    | $0      | 200     | Hard cap → Upgrade prompt |
| Starter | $9/mo   | 1,500   | Hard cap → Upgrade prompt |
| Build   | $19/mo  | 3,000   | Hard cap → Upgrade prompt |
| Pro     | $39/mo  | 8,000   | Hard cap → Upgrade prompt |
| Agency  | $99/mo  | 25,000  | Hard cap → Upgrade prompt |

### Implementation
```typescript
// Backend quota check
if (project.usage_this_month >= project.plan_quota) {
  return {
    error: 'quota_exceeded',
    message: 'Upgrade your plan for more minutes',
    upgrade_url: `/dashboard/billing?upgrade=${next_plan}`
  };
}
```

### Advantages
- ✅ Simple and stable
- ✅ Predictable revenue
- ✅ No complex billing logic
- ✅ Works with current Stripe API
- ✅ Easy to test and debug

### Limitations
- ❌ No automatic overage billing
- ❌ Users must manually upgrade
- ❌ Potential lost revenue (users hit limit but don't upgrade)
- ❌ Less flexible pricing

---

## 🔮 Future State (Billing Meters)

### Pricing Model
**Graduated metered usage with included minutes**

| Plan    | Base Price | Included (Tier 1) | Overage (Tier 2) |
|---------|------------|-------------------|------------------|
| Free    | $0         | 200 min @ $0      | N/A (hard cap)   |
| Starter | $9/mo      | 1,500 min @ $0    | $0.012/min       |
| Build   | $19/mo     | 3,000 min @ $0    | $0.011/min       |
| Pro     | $39/mo     | 8,000 min @ $0    | $0.009/min       |
| Agency  | $99/mo     | 25,000 min @ $0   | $0.008/min       |

### How Billing Meters Work

**1. Create a Billing Meter**
```bash
stripe meters create \
  --display-name "AI Gate - Session Minutes" \
  --event-name "session_minutes" \
  --default-aggregation.formula sum \
  --value-settings.event-payload-key minutes
```

**2. Report Usage Events**
```typescript
// After each session ends
await stripe.billing.meterEvents.create({
  event_name: 'session_minutes',
  payload: {
    stripe_customer_id: subscription.customer_id,
    value: session_duration_minutes,
  },
  timestamp: Math.floor(Date.now() / 1000),
});
```

**3. Create Metered Prices**
```bash
stripe prices create \
  --product prod_xxx \
  --currency usd \
  --billing_scheme tiered \
  --tiers_mode graduated \
  --recurring.interval month \
  --recurring.meter meter_xxx \
  -d 'tiers[0][up_to]=1500' \
  -d 'tiers[0][unit_amount]=0' \
  -d 'tiers[1][up_to]=inf' \
  -d 'tiers[1][unit_amount_decimal]=1.2'  # $0.012/min
```

**4. Subscribe with 2 Prices**
```typescript
// Subscription with base + metered
await stripe.subscriptions.create({
  customer: 'cus_xxx',
  items: [
    { price: 'price_starter_base' },      // $9/mo base
    { price: 'price_starter_metered' },   // Metered overage
  ],
});
```

### Advantages
- ✅ Automatic overage billing
- ✅ Pay-as-you-go flexibility
- ✅ Maximize revenue (no lost overages)
- ✅ Better user experience (no hard stops)
- ✅ Scalable long-term

### Challenges
- ⚠️ More complex billing logic
- ⚠️ Requires proper usage tracking
- ⚠️ Stripe API still evolving (2025)
- ⚠️ Need thorough testing
- ⚠️ Potential billing disputes

---

## 🛣️ Migration Roadmap

### Phase 0: Current (Q1 2025) ✅
**Status**: Completed

- [x] Fixed monthly pricing implemented
- [x] Stripe products created
- [x] Backend quota enforcement
- [x] Upgrade prompts in dashboard
- [x] Launch MVP

### Phase 1: Preparation (Q2 2025)
**Status**: Planning

**Goals:**
- Monitor Stripe Billing Meters API maturity
- Track usage patterns and revenue
- Identify overage opportunities

**Tasks:**
- [ ] Implement detailed usage analytics
- [ ] Track how often users hit quotas
- [ ] Calculate potential overage revenue
- [ ] Monitor Stripe API changelog
- [ ] Test Billing Meters in sandbox

**Deliverables:**
- Usage analytics dashboard
- Revenue projections for overage model
- Billing Meters test implementation

### Phase 2: Development (Q3 2025)
**Status**: Not started

**Goals:**
- Build Billing Meters integration
- Parallel run both systems
- Test thoroughly

**Tasks:**
- [ ] Create Billing Meters in Stripe
- [ ] Implement meter event reporting
- [ ] Create new metered prices
- [ ] Build migration scripts
- [ ] Test overage calculations
- [ ] Add overage preview in dashboard

**Deliverables:**
- Meter event reporting system
- Dual pricing system (old + new)
- Migration tooling
- Test coverage

### Phase 3: Testing & Rollout (Q4 2025)
**Status**: Not started

**Goals:**
- Migrate users gradually
- Monitor billing accuracy
- Ensure smooth transition

**Tasks:**
- [ ] Opt-in beta for new pricing
- [ ] Monitor beta user billing
- [ ] Fix any issues
- [ ] Communicate changes to users
- [ ] Migrate all users
- [ ] Deprecate old pricing

**Deliverables:**
- Beta program
- Migration communication
- Full rollout
- Old pricing sunset

---

## 🔧 Technical Implementation

### Current: Fixed Pricing

```typescript
// Quota check (backend)
async function checkQuota(projectId: string): Promise<boolean> {
  const usage = await getMonthlyUsage(projectId);
  const quota = await getProjectQuota(projectId);

  if (usage >= quota) {
    throw new QuotaExceededError({
      usage,
      quota,
      upgrade_url: `/dashboard/billing?upgrade=true`
    });
  }

  return true;
}

// Session creation
async function createSession(projectId: string) {
  await checkQuota(projectId);  // Hard stop if exceeded
  // ... create session
  await incrementUsage(projectId, session.duration_minutes);
}
```

### Future: Billing Meters

```typescript
// No hard quota check - let Stripe handle it
async function createSession(projectId: string) {
  const session = await openai.createSession(...);

  // Report usage to Stripe after session
  await reportUsageToStripe({
    customer_id: project.stripe_customer_id,
    minutes: session.duration_minutes,
    session_id: session.id,
  });

  return session;
}

// Report to Stripe Billing Meter
async function reportUsageToStripe({
  customer_id,
  minutes,
  session_id,
}: {
  customer_id: string;
  minutes: number;
  session_id: string;
}) {
  await stripe.billing.meterEvents.create({
    event_name: 'session_minutes',
    payload: {
      stripe_customer_id: customer_id,
      value: minutes,
    },
    identifier: session_id,  // Idempotency
    timestamp: Math.floor(Date.now() / 1000),
  });
}

// Soft quota warning (optional)
async function checkUsageWarning(projectId: string) {
  const usage = await getMonthlyUsage(projectId);
  const included = project.plan_included_minutes;

  if (usage > included * 0.8) {
    // Warn user they're approaching overage
    await sendEmail({
      to: project.owner_email,
      subject: 'Approaching your included minutes',
      body: `You've used ${usage}/${included} minutes. Overage charges apply beyond ${included} minutes.`
    });
  }
}
```

---

## 📊 Decision Criteria

### When to Migrate?

Migrate when **ALL** of these are true:

1. ✅ **Stripe API is stable**
   - Billing Meters fully documented
   - No breaking changes expected
   - Community adoption (other companies using it)

2. ✅ **Revenue justifies complexity**
   - >20% of users hitting quotas
   - Estimated overage revenue >$X/month
   - Cost/benefit analysis positive

3. ✅ **Technical readiness**
   - Usage tracking accurate and reliable
   - Test coverage >80%
   - Migration plan reviewed and approved

4. ✅ **User readiness**
   - Clear communication plan
   - Support team trained
   - FAQ and docs updated

### Risks to Monitor

- **Billing disputes**: Overage charges can surprise users
- **API instability**: Stripe Meters is new (2025)
- **Revenue impact**: Migration bugs could affect billing
- **Support load**: More complex = more support tickets

---

## 📚 Resources

### Stripe Documentation
- [Billing Meters Overview](https://stripe.com/docs/billing/subscriptions/usage-based/recording-usage)
- [Meter Events API](https://stripe.com/docs/api/billing/meter-event)
- [Graduated Pricing](https://stripe.com/docs/billing/prices-guide#graduated-pricing)

### Internal Docs
- [Current Stripe Setup](../setup/STRIPE-SETUP.md)
- [Pricing Strategy](../setup/PRICING-STRATEGY.md)

---

## ✅ Success Metrics

### Phase 1 (Preparation)
- [ ] Usage analytics dashboard live
- [ ] 3 months of usage data collected
- [ ] Billing Meters tested in sandbox
- [ ] Revenue projections documented

### Phase 2 (Development)
- [ ] Meter event reporting 99.9% accurate
- [ ] Overage calculations match manual calc
- [ ] Migration scripts tested on staging
- [ ] Beta users recruited

### Phase 3 (Rollout)
- [ ] 100% of users migrated
- [ ] Zero billing disputes from migration
- [ ] Overage revenue targets met
- [ ] Support tickets <5% increase

---

**Last Updated**: 2025-10-04
**Next Review**: 2025-04-01 (Q2 start)
**Owner**: Engineering Team

🚀 **AI Gate - Your gateway to AI APIs**
