#!/bin/bash
# AI Gate - Stripe Setup (Session-based Pricing)
# Session = one WebRTC connection
set -e

STRIPE=~/bin/stripe

echo "🚀 AI Gate - Stripe Setup (Session-Based Pricing)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Strategy: Sessions as billable unit"
echo "   - 1 session = 1 WebRTC connection"
echo "   - Minutes tracked internally for cost monitoring"
echo "   - Rate limits protect infrastructure"
echo ""

# Skip cleanup - let Stripe handle duplicates
echo "ℹ️  Note: If products already exist, this will create new versions"
echo ""

# Starter Plan - $29/month, 5000 sessions
echo "📦 Creating: AI Gate - Starter ($29/month)"
STARTER_PROD_JSON=$($STRIPE products create \
  --name "AI Gate - Starter" \
  --description "5,000 sessions per month (~10,000 minutes estimated)" \
  --metadata[plan]=starter \
  --metadata[sessions_quota]=5000 \
  --metadata[estimated_minutes]=10000 \
  --metadata[projects]=3 \
  --metadata[rate_limit_rpm]=1000 \
  --metadata[concurrent_limit]=10 \
  --active)
STARTER_PROD=$(echo "$STARTER_PROD_JSON" | jq -r '.id')
echo "   Product ID: $STARTER_PROD"

STARTER_PRICE_JSON=$($STRIPE prices create \
  --product "$STARTER_PROD" \
  --currency usd \
  --unit-amount 2900 \
  --recurring.interval month \
  --nickname "Starter Monthly")
STARTER_PRICE=$(echo "$STARTER_PRICE_JSON" | jq -r '.id')
echo "   Price ID: $STARTER_PRICE"
echo "   ✅ $29/month • 5,000 sessions • ~10,000 min estimated"
echo ""

# Growth Plan - $99/month, 20000 sessions
echo "📦 Creating: AI Gate - Growth ($99/month)"
GROWTH_PROD_JSON=$($STRIPE products create \
  --name "AI Gate - Growth" \
  --description "20,000 sessions per month (~40,000 minutes estimated)" \
  --metadata[plan]=growth \
  --metadata[sessions_quota]=20000 \
  --metadata[estimated_minutes]=40000 \
  --metadata[projects]=10 \
  --metadata[rate_limit_rpm]=10000 \
  --metadata[concurrent_limit]=50 \
  --metadata[sla]=99.9 \
  --active)
GROWTH_PROD=$(echo "$GROWTH_PROD_JSON" | jq -r '.id')
echo "   Product ID: $GROWTH_PROD"

GROWTH_PRICE_JSON=$($STRIPE prices create \
  --product "$GROWTH_PROD" \
  --currency usd \
  --unit-amount 9900 \
  --recurring.interval month \
  --nickname "Growth Monthly")
GROWTH_PRICE=$(echo "$GROWTH_PRICE_JSON" | jq -r '.id')
echo "   Price ID: $GROWTH_PRICE"
echo "   ✅ $99/month • 20,000 sessions • ~40,000 min estimated"
echo ""

# Save to JSON
echo "💾 Saving IDs to scripts/stripe-ids-sessions.test.json"
cat > scripts/stripe-ids-sessions.test.json <<EOF
{
  "mode": "test",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "pricing_model": "session_based_with_quotas",
  "plans": {
    "free": {
      "product_id": null,
      "price_id": null,
      "amount_usd": 0,
      "sessions_quota": 100,
      "estimated_minutes": 200,
      "projects": 1,
      "rate_limit_rpm": 100,
      "concurrent": 1,
      "features": {
        "badge_required": true,
        "support": "community"
      }
    },
    "starter": {
      "product_id": "$STARTER_PROD",
      "price_id": "$STARTER_PRICE",
      "amount_usd": 29,
      "sessions_quota": 5000,
      "estimated_minutes": 10000,
      "projects": 3,
      "rate_limit_rpm": 1000,
      "concurrent": 10,
      "features": {
        "badge_required": false,
        "support": "email-48h"
      }
    },
    "growth": {
      "product_id": "$GROWTH_PROD",
      "price_id": "$GROWTH_PRICE",
      "amount_usd": 99,
      "sessions_quota": 20000,
      "estimated_minutes": 40000,
      "projects": 10,
      "rate_limit_rpm": 10000,
      "concurrent": 50,
      "features": {
        "badge_required": false,
        "support": "email-24h",
        "sla": "99.9%"
      }
    }
  },
  "notes": {
    "billable_unit": "sessions (one WebRTC connection)",
    "internal_tracking": "minutes tracked for cost analysis only",
    "rate_limits": "protect infrastructure from abuse",
    "openai_costs": "Billed separately with user's own API key"
  }
}
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Stripe Setup Complete!"
echo ""
echo "📋 Plans Created:"
echo "   • FREE:    $0/mo     (100 sessions,   ~200 min)"
echo "   • STARTER: $29/mo  (5,000 sessions,  ~10k min)"
echo "   • GROWTH:  $99/mo (20,000 sessions, ~40k min)"
echo ""
echo "💾 IDs saved to: scripts/stripe-ids-sessions.test.json"
echo ""
echo "📝 Next Steps:"
echo "   1. Export secrets to Wrangler:"
echo "      ./scripts/stripe-export-secrets.sh"
echo "   2. Update .dev.vars with:"
echo "      STRIPE_PRICE_STARTER=$STARTER_PRICE"
echo "      STRIPE_PRICE_GROWTH=$GROWTH_PRICE"
echo "   3. Deploy to Cloudflare Workers"
echo "   4. Test checkout flow"
echo ""
echo "🎯 Session Tracking:"
echo "   - Track each ephemeral token creation as 1 session"
echo "   - Verify quota before allowing session creation"
echo "   - Apply rate limits based on plan tier"
echo ""
