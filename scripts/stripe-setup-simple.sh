#!/bin/bash
# AI Gate - Stripe Setup (Fixed Pricing - MVP)
# Simple monthly plans with hard caps (no metered overage)
set -e

STRIPE=~/bin/stripe

echo "🚀 AI Gate - Stripe Setup (Test Mode)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Strategy: Fixed monthly plans with hard caps"
echo "   - No metered overage (simpler, stable)"
echo "   - Backend enforces quotas"
echo "   - Users upgrade for more minutes"
echo ""

# Clean up test products first
echo "🧹 Cleaning up existing test products..."
$STRIPE products list --limit 100 | jq -r '.data[] | select(.name | startswith("AI Gate")) | .id' | while read -r prod_id; do
  echo "   Archiving: $prod_id"
  $STRIPE products update $prod_id --active=false >/dev/null 2>&1 || true
done
echo ""

# Starter Plan - $9/month, 1500 min
echo "📦 Creating: AI Gate - Starter ($9/month)"
STARTER_PROD=$($STRIPE products create \
  --name "AI Gate - Starter" \
  --description "1,500 minutes per month included" \
  --active | jq -r '.id')
echo "   Product ID: $STARTER_PROD"

STARTER_PRICE=$($STRIPE prices create \
  --product "$STARTER_PROD" \
  --currency usd \
  --unit-amount 900 \
  --recurring.interval month \
  --nickname "Starter Monthly" | jq -r '.id')
echo "   Price ID: $STARTER_PRICE"
echo "   ✅ $9/month • 1,500 min included"
echo ""

# Build Plan - $19/month, 3000 min
echo "📦 Creating: AI Gate - Build ($19/month)"
BUILD_PROD=$($STRIPE products create \
  --name "AI Gate - Build" \
  --description "3,000 minutes per month included" \
  --active | jq -r '.id')
echo "   Product ID: $BUILD_PROD"

BUILD_PRICE=$($STRIPE prices create \
  --product "$BUILD_PROD" \
  --currency usd \
  --unit-amount 1900 \
  --recurring.interval month \
  --nickname "Build Monthly" | jq -r '.id')
echo "   Price ID: $BUILD_PRICE"
echo "   ✅ $19/month • 3,000 min included"
echo ""

# Pro Plan - $39/month, 8000 min
echo "📦 Creating: AI Gate - Pro ($39/month)"
PRO_PROD=$($STRIPE products create \
  --name "AI Gate - Pro" \
  --description "8,000 minutes per month included" \
  --active | jq -r '.id')
echo "   Product ID: $PRO_PROD"

PRO_PRICE=$($STRIPE prices create \
  --product "$PRO_PROD" \
  --currency usd \
  --unit-amount 3900 \
  --recurring.interval month \
  --nickname "Pro Monthly" | jq -r '.id')
echo "   Price ID: $PRO_PRICE"
echo "   ✅ $39/month • 8,000 min included"
echo ""

# Agency Plan - $99/month, 25000 min
echo "📦 Creating: AI Gate - Agency ($99/month)"
AGENCY_PROD=$($STRIPE products create \
  --name "AI Gate - Agency" \
  --description "25,000 minutes per month included" \
  --active | jq -r '.id')
echo "   Product ID: $AGENCY_PROD"

AGENCY_PRICE=$($STRIPE prices create \
  --product "$AGENCY_PROD" \
  --currency usd \
  --unit-amount 9900 \
  --recurring.interval month \
  --nickname "Agency Monthly" | jq -r '.id')
echo "   Price ID: $AGENCY_PRICE"
echo "   ✅ $99/month • 25,000 min included"
echo ""

# Save to JSON
echo "💾 Saving IDs to scripts/stripe-ids.test.json"
cat > scripts/stripe-ids.test.json <<EOF
{
  "mode": "test",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "pricing_model": "fixed_monthly_with_hard_caps",
  "products": {
    "starter": {
      "product_id": "$STARTER_PROD",
      "price_id": "$STARTER_PRICE",
      "amount_usd": 9,
      "minutes_included": 1500
    },
    "build": {
      "product_id": "$BUILD_PROD",
      "price_id": "$BUILD_PRICE",
      "amount_usd": 19,
      "minutes_included": 3000
    },
    "pro": {
      "product_id": "$PRO_PROD",
      "price_id": "$PRO_PRICE",
      "amount_usd": 39,
      "minutes_included": 8000
    },
    "agency": {
      "product_id": "$AGENCY_PROD",
      "price_id": "$AGENCY_PRICE",
      "amount_usd": 99,
      "minutes_included": 25000
    }
  },
  "notes": {
    "free_plan": "Enforced backend-side, 200 min/month hard cap",
    "overage": "Not supported - users must upgrade plan",
    "future_migration": "Billing Meters (Stripe 2025 API) when ready"
  }
}
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Stripe Setup Complete!"
echo ""
echo "📋 Products Created:"
echo "   • Starter: $9/mo  (1,500 min)"
echo "   • Build:   $19/mo (3,000 min)"
echo "   • Pro:     $39/mo (8,000 min)"
echo "   • Agency:  $99/mo (25,000 min)"
echo ""
echo "💾 IDs saved to: scripts/stripe-ids.test.json"
echo ""
echo "📝 Next Steps:"
echo "   1. Configure Wrangler secrets (see stripe-ids.test.json)"
echo "   2. Implement backend quota enforcement"
echo "   3. Add upgrade flow in dashboard"
echo "   4. Test checkout flow"
echo ""
echo "🔮 Future: Migrate to Billing Meters for automatic overage"
echo ""
