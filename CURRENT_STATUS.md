# Current Status - AI Gate

**Last Updated:** October 9, 2025
**Version:** 1.2.0 (Beta)

## Production Status

### ✅ Live Services

| Service | Status | URL |
|---------|--------|-----|
| **Web Frontend** | ✅ Deployed | https://www.ai-gate.dev |
| **API Backend** | ✅ Healthy | https://api.ai-gate.dev |
| **Staging Web** | ✅ Active | https://staging-app.ai-gate.dev |
| **Staging API** | ✅ Active | https://staging.ai-gate.dev |

### 🎯 Beta Program Status

**Current Phase:** Beta Testing
**Public Availability:**
- ✅ Free Plan (100 sessions/month) - Available to all
- 🎯 Starter Plan ($29/mo) - Beta access required
- 🎯 Growth Plan ($99/mo) - Beta access required

**Beta Application:** https://www.ai-gate.dev/beta

## Infrastructure

### Cloudflare Workers

**Production:**
- API: `luna-proxy-api` + `luna-proxy-api.joffrey-vanasten.workers.dev`
- Web: `luna-proxy-web-frontend`
- Custom domains: ✅ Configured
- Workers.dev enabled: ✅ Yes (for worker-to-worker calls)

**Staging:**
- API: `luna-proxy-api-staging`
- Web: `luna-proxy-web-frontend-staging`
- Custom domain: ✅ `staging-app.ai-gate.dev`
- Workers.dev enabled: ✅ Yes

### Databases

**Production:**
- D1 Database: `luna-proxy-users` (ID: `41200dfb-f5e3-476d-a423-729b7be79789`)
- Audit DB: `luna-proxy-audit` (ID: `ca7610ce-3cc1-4499-b17f-14458303e241`)
- KV Namespaces: CLIENTS, METRICS, RATE_LIMITER

**Staging:**
- D1 Database: `luna-proxy-users-staging` (ID: `5ecb0455-e99a-4fa7-ba4d-e286574968e0`)
- Audit DB: `luna-proxy-audit-staging` (ID: `fe91c742-20b1-4780-82d9-8cb145f395a5`)
- KV Namespaces: CLIENTS_STAGING, METRICS_STAGING, RATE_LIMITER_STAGING

### Stripe Integration

**Production (Live Mode):**
- Starter Plan: $29/mo - 5,000 sessions
- Growth Plan: $99/mo - 20,000 sessions
- Webhook: `https://api.ai-gate.dev/webhook/stripe`
- Status: ⚠️ Beta access required (not publicly available)

**Staging (Test Mode):**
- Starter Product: `prod_TCZMnCE71ibzRl`
- Growth Product: `prod_TCZMNwoe1VXZ9I`
- Starter Price: `price_1SGAFYD10JtvEUh4hrROqN7p`
- Growth Price: `price_1SGAFhD10JtvEUh47Hn3QBkl`
- Webhook: `https://staging.ai-gate.dev/webhook/stripe`
- Status: ✅ Active (test cards accepted)

### Authentication

**OAuth Providers:**
- ✅ Google OAuth (production + staging)
- ✅ GitHub OAuth (production + staging)

**Sessions:**
- NextAuth v5 with JWT
- Cookie domain: `.ai-gate.dev`
- SameSite: `lax`
- Secure: `true` (HTTPS only)

## Recent Changes

### October 9, 2025

**Beta Program Launch:**
- ✅ Created `/beta` application page
- ✅ API endpoint `/api/beta-request` for submissions
- ✅ Dashboard banner announcing beta status
- ✅ All paid plan CTAs redirect to `/beta`
- ✅ Documentation: `BETA_PROGRAM.md`

**Worker-to-Worker Fix:**
- ✅ Enabled `workers_dev = true` for API production
- ✅ Changed `INTERNAL_API_URL` to workers.dev URL
- ✅ Fixed HTTP 522 timeout on dashboard metrics
- ✅ Dashboard now loads correctly with real metrics

**Stripe Test/Production Separation:**
- ✅ Staging uses Stripe test mode
- ✅ Production uses Stripe live mode
- ✅ Created test products and prices for staging
- ✅ Configured test webhook for staging
- ✅ Documentation: `STRIPE_TEST_PRODUCTION.md`

### Environment Variables

**Production Web:**
```
NEXT_PUBLIC_API_BASE=https://api.ai-gate.dev
NEXT_PUBLIC_API_URL=https://api.ai-gate.dev
INTERNAL_API_URL=https://luna-proxy-api.joffrey-vanasten.workers.dev
AUTH_URL=https://www.ai-gate.dev
NEXTAUTH_URL=https://www.ai-gate.dev
AUTH_COOKIE_DOMAIN=.ai-gate.dev
```

**Staging Web:**
```
NEXT_PUBLIC_API_BASE=https://staging.ai-gate.dev
NEXT_PUBLIC_API_URL=https://staging.ai-gate.dev
INTERNAL_API_URL=https://luna-proxy-api-staging.joffrey-vanasten.workers.dev
AUTH_URL=https://staging-app.ai-gate.dev
NEXTAUTH_URL=https://staging-app.ai-gate.dev
AUTH_COOKIE_DOMAIN=.ai-gate.dev
```

## Testing

### Test Accounts

**Free Plan:**
1. Visit https://www.ai-gate.dev/signup
2. Create account with Google/GitHub OAuth
3. Access dashboard and playground
4. 100 sessions/month quota

**Beta Testing (Staging):**
1. Visit https://staging-app.ai-gate.dev
2. Sign in with OAuth
3. Use test cards for checkout
4. Test card: `4242 4242 4242 4242`

### Health Checks

```bash
# Production
curl https://api.ai-gate.dev/health
curl https://www.ai-gate.dev/api/metrics

# Staging
curl https://staging.ai-gate.dev/health
curl https://staging-app.ai-gate.dev/api/metrics
```

## Monitoring

### Logs

```bash
# Production API logs
wrangler tail --env production

# Production Web logs
cd luna-proxy-web && wrangler tail --env production

# Staging
wrangler tail --env staging
```

### Metrics

**Dashboard:** https://www.ai-gate.dev/dashboard
- Total sessions
- Session success rate
- Average latency
- Audio minutes processed
- Cost estimation

**API Endpoint:** https://api.ai-gate.dev/metrics
- Public aggregated metrics (JSON)
- No authentication required

## Known Issues

### ✅ Recently Fixed

- ~~Dashboard stuck on "Loading..." - Fixed with workers.dev URL~~
- ~~HTTP 522 timeout on metrics - Fixed with INTERNAL_API_URL~~
- ~~Infinite checkout redirect loop - Fixed with checkoutRedirected flag~~
- ~~Stripe API version error - Fixed by removing hardcoded version~~

### 🔄 Current Limitations

**Beta Program:**
- Manual approval process for paid plans
- Applications reviewed within 48-72 hours
- Limited beta tester capacity

**Features:**
- Historical metrics not yet available (30-day data)
- No usage alerts or budget management
- No A/B testing for voice models

## Next Steps

### Short Term (1-2 weeks)

- [ ] Onboard first batch of beta testers
- [ ] Gather feedback from beta users
- [ ] Monitor billing and webhook flows
- [ ] Fix any critical bugs reported by beta testers
- [ ] Add beta application notification system (email/Slack)

### Medium Term (1-3 months)

- [ ] Implement historical metrics dashboard
- [ ] Add usage alerts and notifications
- [ ] Improve error handling and retry logic
- [ ] Enhanced security audit logging
- [ ] Performance optimizations

### Long Term (3-6 months)

- [ ] Public launch (remove beta requirement)
- [ ] Enterprise plan with custom pricing
- [ ] Advanced analytics and reporting
- [ ] Multi-region deployment
- [ ] API v2 with additional features

## Support

**Production Issues:**
- Email: support@ai-gate.dev
- Response time: 24-48 hours

**Beta Program:**
- Application: https://www.ai-gate.dev/beta
- Questions: support@ai-gate.dev

**Documentation:**
- Main README: `README.md`
- Beta Program: `BETA_PROGRAM.md`
- Stripe Setup: `STRIPE_TEST_PRODUCTION.md`
- API Docs: `luna-proxy-api/README.md`
- Web Docs: `luna-proxy-web/README.md`

---

**Last Deployment:**
- Date: October 9, 2025
- Version: 1.2.0-beta
- Commit: Latest on `chore/parent-ci-stripe`
