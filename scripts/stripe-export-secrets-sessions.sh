#!/bin/bash
# Export Stripe Price IDs for Session-based Pricing
# Usage: ./scripts/stripe-export-secrets-sessions.sh [test|live]

MODE=${1:-test}
IDS_FILE="scripts/stripe-ids-sessions.${MODE}.json"

if [[ ! -f "$IDS_FILE" ]]; then
  echo "Error: $IDS_FILE not found"
  echo "Run ./scripts/stripe-setup-sessions.sh first to create products"
  exit 1
fi

echo "📋 Stripe Price IDs Export - ${MODE} mode (Session-based)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Copy and run these commands in luna-proxy-api/:"
echo ""

STARTER_PRICE=$(jq -r '.plans.starter.price_id' "$IDS_FILE")
GROWTH_PRICE=$(jq -r '.plans.growth.price_id' "$IDS_FILE")

ENV_FLAG=""
if [[ "$MODE" == "test" ]]; then
  ENV_FLAG=" --env staging"
fi

echo "cd luna-proxy-api"
echo ""
echo "# Stripe Price IDs (${MODE} mode - Session-based)"
echo "wrangler secret put STRIPE_PRICE_STARTER${ENV_FLAG}"
echo "# Paste: $STARTER_PRICE"
echo ""
echo "wrangler secret put STRIPE_PRICE_GROWTH${ENV_FLAG}"
echo "# Paste: $GROWTH_PRICE"
echo ""
echo "# Stripe Secret Key (get from dashboard)"
echo "wrangler secret put STRIPE_SECRET_KEY${ENV_FLAG}"
echo "# Paste: sk_${MODE}_... (from Stripe Dashboard)"
echo ""
echo "# Stripe Webhook Secret (get after creating webhook)"
echo "wrangler secret put STRIPE_WEBHOOK_SECRET${ENV_FLAG}"
echo "# Paste: whsec_... (from Stripe Dashboard)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 For quick copy-paste (.env or .dev.vars):"
echo ""
echo "STRIPE_PRICE_STARTER='$STARTER_PRICE'"
echo "STRIPE_PRICE_GROWTH='$GROWTH_PRICE'"
echo ""
echo "📊 Plan Summary:"
jq -r '.plans | to_entries[] | "  • \(.key | ascii_upcase): $\(.value.amount_usd)/mo - \(.value.sessions_quota) sessions (~\(.value.estimated_minutes) min)"' "$IDS_FILE"
echo ""
echo "🎯 Next Steps:"
echo "  1. Run the wrangler secret put commands above"
echo "  2. Update your .dev.vars for local development"
echo "  3. Deploy: cd luna-proxy-api && wrangler deploy"
echo "  4. Create webhook in Stripe Dashboard:"
echo "     - URL: https://api.ai-gate.dev/webhooks/stripe"
echo "     - Events: checkout.session.completed, customer.subscription.*"
echo ""
