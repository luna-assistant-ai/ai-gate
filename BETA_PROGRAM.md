# Beta Program

AI Gate is currently in **active development** and beta testing phase. We are carefully onboarding early adopters to ensure the best experience and gather valuable feedback.

## Current Status

**Free Plan:** ✅ Available for everyone
- 100 sessions/month
- Full access to playground
- Dashboard with real-time metrics
- Vault-encrypted BYOK

**Paid Plans (Starter & Growth):** 🎯 Beta Access Required
- Not yet available for public signup
- Requires beta tester application and approval
- Exclusive benefits for beta testers

## Beta Tester Benefits

### 1. Early Access
- Get Starter ($29/mo) or Growth ($99/mo) plans before public launch
- Exclusive beta pricing (grandfathered when we go public)
- Priority feature requests

### 2. Direct Communication
- Direct channel with development team
- Influence product roadmap
- Early access to new features

### 3. Priority Support
- Fast response times (24-48h)
- Direct bug reporting
- Feature request priority

### 4. Grandfathered Pricing
- Lock in beta pricing permanently
- No price increases when we launch publicly
- Best value for early supporters

## How to Apply

### Application Process

1. **Visit Application Page**
   - Go to https://www.ai-gate.dev/beta
   - Fill out the application form

2. **Required Information**
   - Full name and email
   - Company/project name (optional)
   - Use case description
   - Estimated monthly sessions

3. **Review Process**
   - Applications reviewed within 48-72 hours
   - Selection based on use case fit and capacity
   - You'll receive email confirmation if approved

### Application Form Fields

```
Name: [Required]
Email: [Required]
Company/Project: [Optional]
Use Case: [Required - Tell us how you plan to use AI Gate]
Estimated Sessions: [Select range: 0-100, 100-5K, 5K-20K, 20K+]
```

## Beta Program Pages

All upgrade CTAs redirect to beta application:

### Website Pages
- **Homepage** (`/`) - Pricing section buttons → `/beta`
- **Pricing Page** (`/pricing`) - Starter & Growth buttons → `/beta`
- **Dashboard** (`/dashboard`) - Upgrade button → `/beta`

### Application Flow
1. User clicks "Apply for Beta Access" (any page)
2. Redirects to `/beta` application form
3. Fills out form and submits
4. Request logged and sent to support@ai-gate.dev
5. Team reviews and contacts user within 48-72h

## Implementation Details

### Frontend Changes

**Files Modified:**
- `src/app/beta/page.tsx` - Beta application page
- `src/app/api/beta-request/route.ts` - API endpoint for submissions
- `src/components/BillingPanel.tsx` - Dashboard beta banner
- `src/app/page.tsx` - Homepage pricing CTAs
- `src/app/pricing/page.tsx` - Pricing page buttons

### Beta Application Page (`/beta`)

**Features:**
- Professional application form
- Success/error handling
- Direct mailto link to support@ai-gate.dev
- Lists beta tester benefits
- Clean, on-brand design

**Form Validation:**
- Name: Required
- Email: Required + regex validation
- Use case: Required
- Company: Optional
- Estimated sessions: Optional dropdown

### API Endpoint (`/api/beta-request`)

**Method:** POST

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "company": "Acme Inc",
  "useCase": "Voice AI for customer support",
  "estimatedSessions": "5000-20000"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Application submitted successfully"
}
```

**Current Implementation:**
- Logs to console (visible in Wrangler logs)
- Ready for webhook integration (Slack/Discord)
- Can be extended to store in D1 database

### Dashboard Banner

**Location:** `BillingPanel.tsx` (top of dashboard)

**Content:**
- 🚀 Emoji indicator
- "AI Gate is Currently in Beta" headline
- Explanation of current status
- "Apply for Beta Access" CTA button
- Professional gradient design

## Timeline

### Phase 1: Beta Launch (Current)
- ✅ Free plan available to all
- ✅ Beta application form live
- ✅ Manual approval process
- ✅ All paid plan CTAs redirect to `/beta`

### Phase 2: Beta Testing (1-3 months)
- Review and approve qualified applications
- Onboard beta testers gradually
- Gather feedback and iterate
- Fix bugs and improve UX
- Test billing and webhooks at scale

### Phase 3: Public Launch (TBD)
- Open Starter & Growth plans to public
- Remove beta application requirement
- Honor grandfathered pricing for beta testers
- Announce publicly

## Managing Beta Testers

### Approval Process

1. **Review Application**
   - Check email and use case
   - Verify sessions estimate matches plan
   - Assess product-market fit

2. **Manual Enablement**
   - Create Stripe customer manually
   - Set up subscription in Stripe Dashboard
   - Send welcome email with setup instructions

3. **Onboarding**
   - Provide direct support channel
   - Monitor early usage
   - Collect feedback regularly

### Monitoring

**Application Logs:**
```bash
# View beta applications
wrangler tail --env production | grep "Beta application"
```

**Metrics to Track:**
- Applications received per week
- Approval rate
- Conversion to paid (if approved)
- Feedback quality
- Bug reports

## FAQ

### Why Beta Access Required?

We're carefully onboarding users to:
- Ensure platform stability
- Provide excellent support during development
- Gather targeted feedback
- Avoid overwhelming early infrastructure
- Build strong relationships with first users

### What if My Application is Denied?

- You'll be notified via email
- You can reapply with more detail
- Free plan remains available
- You'll be first to know when we go public

### How Long is Beta Phase?

Estimated 1-3 months depending on:
- Platform stability
- Feature completeness
- Bug fix rate
- Beta tester feedback
- Infrastructure scaling readiness

### Will Pricing Change After Beta?

- Beta testers get grandfathered pricing (locked in)
- Public pricing may be different
- Free plan remains free forever

## Contact

**Questions about beta program:**
- Email: support@ai-gate.dev
- Application page: https://www.ai-gate.dev/beta

**General inquiries:**
- GitHub: https://github.com/luna-assistant-ai
- Documentation: https://github.com/luna-assistant-ai/luna-proxy-api
