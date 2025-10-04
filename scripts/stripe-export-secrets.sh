#!/bin/bash
# Export Stripe Price IDs for Wrangler Secrets
# Usage: ./scripts/stripe-export-secrets.sh [test|live]

MODE=${1:-test}
IDS_FILE="scripts/stripe-ids.${MODE}.json"

if [[ ! -f "$IDS_FILE" ]]; then
  echo "Error: $IDS_FILE not found"
  echo "Run ./scripts/stripe-setup-simple.sh $MODE first"
  exit 1
fi

echo "📋 Stripe Price IDs Export - ${MODE} mode"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Copy and run these commands in luna-proxy-api/:"
echo ""

STARTER_PRICE=$(jq -r '.products.starter.price_id' "$IDS_FILE")
BUILD_PRICE=$(jq -r '.products.build.price_id' "$IDS_FILE")
PRO_PRICE=$(jq -r '.products.pro.price_id' "$IDS_FILE")
AGENCY_PRICE=$(jq -r '.products.agency.price_id' "$IDS_FILE")

ENV_FLAG=""
if [[ "$MODE" == "test" ]]; then
  ENV_FLAG=" --env staging"
fi

echo "cd luna-proxy-api"
echo ""
echo "# Stripe Price IDs (${MODE} mode)"
echo "wrangler secret put STRIPE_PRICE_STARTER${ENV_FLAG}"
echo "# Paste: $STARTER_PRICE"
echo ""
echo "wrangler secret put STRIPE_PRICE_BUILD${ENV_FLAG}"
echo "# Paste: $BUILD_PRICE"
echo ""
echo "wrangler secret put STRIPE_PRICE_PRO${ENV_FLAG}"
echo "# Paste: $PRO_PRICE"
echo ""
echo "wrangler secret put STRIPE_PRICE_AGENCY${ENV_FLAG}"
echo "# Paste: $AGENCY_PRICE"
echo ""
echo "# Stripe Secret Key (get from dashboard)"
echo "wrangler secret put STRIPE_SECRET_KEY${ENV_FLAG}"
echo "# Paste: sk_${MODE}_... (from Stripe Dashboard)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 For quick copy-paste:"
echo ""
echo "export STRIPE_PRICE_STARTER='$STARTER_PRICE'"
echo "export STRIPE_PRICE_BUILD='$BUILD_PRICE'"
echo "export STRIPE_PRICE_PRO='$PRO_PRICE'"
echo "export STRIPE_PRICE_AGENCY='$AGENCY_PRICE'"
echo ""
echo "Then in your code, use:"
echo "  env.STRIPE_PRICE_STARTER  // for Starter plan"
echo "  env.STRIPE_PRICE_BUILD    // for Build plan"
echo "  env.STRIPE_PRICE_PRO      // for Pro plan"
echo "  env.STRIPE_PRICE_AGENCY   // for Agency plan"
echo ""
