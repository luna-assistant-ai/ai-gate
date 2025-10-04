#!/bin/zsh
# Export Wrangler secret commands based on collected Stripe IDs
# Usage: ./scripts/stripe-export-ids.sh [test|live]
# Requires: jq

set -euo pipefail

MODE=${1:-test}
if [[ "$MODE" != "test" && "$MODE" != "live" ]]; then
  echo "Error: mode must be 'test' or 'live'"
  exit 1
fi

IDS_FILE="scripts/stripe-ids.${MODE}.json"
if [[ ! -f "$IDS_FILE" ]]; then
  echo "Error: $IDS_FILE not found. Run bootstrap/webhook scripts first."
  exit 1
fi

# Print wrangler commands
if [[ "$MODE" == "test" ]]; then
  ENV_FLAG="--env staging"
else
  ENV_FLAG=""
fi

SECRET_KEY_VAR="STRIPE_SECRET_KEY"
WEBHOOK_SECRET_VAR="STRIPE_WEBHOOK_SECRET"

# Extract one representative overage price for PAYG-like usage (choose Starter overage by default for example)
STARTER_OVERAGE=$(jq -r '.price_Starter_overage // empty' "$IDS_FILE")
BUILD_OVERAGE=$(jq -r '.price_Build_overage // empty' "$IDS_FILE")
PRO_OVERAGE=$(jq -r '.price_Pro_overage // empty' "$IDS_FILE")
AGENCY_OVERAGE=$(jq -r '.price_Agency_overage // empty' "$IDS_FILE")

cat <<EOF
# Run these commands inside luna-proxy-api directory
cd luna-proxy-api

# API Keys
wrangler secret put $SECRET_KEY_VAR $ENV_FLAG
# paste sk_${MODE}_...

# Webhook secret
wrangler secret put $WEBHOOK_SECRET_VAR $ENV_FLAG
# paste whsec_... (from scripts/stripe-ids.${MODE}.json if available, or Dashboard)

# Price IDs per plan (base)
wrangler secret put STRIPE_PRICE_STARTER_BASE $ENV_FLAG
# paste: $(jq -r '.price_Starter_base' "$IDS_FILE")
wrangler secret put STRIPE_PRICE_BUILD_BASE $ENV_FLAG
# paste: $(jq -r '.price_Build_base' "$IDS_FILE")
wrangler secret put STRIPE_PRICE_PRO_BASE $ENV_FLAG
# paste: $(jq -r '.price_Pro_base' "$IDS_FILE")
wrangler secret put STRIPE_PRICE_AGENCY_BASE $ENV_FLAG
# paste: $(jq -r '.price_Agency_base' "$IDS_FILE")

# Price IDs per plan (overage metered)
wrangler secret put STRIPE_PRICE_STARTER_OVERAGE $ENV_FLAG
# paste: $STARTER_OVERAGE
wrangler secret put STRIPE_PRICE_BUILD_OVERAGE $ENV_FLAG
# paste: $BUILD_OVERAGE
wrangler secret put STRIPE_PRICE_PRO_OVERAGE $ENV_FLAG
# paste: $PRO_OVERAGE
wrangler secret put STRIPE_PRICE_AGENCY_OVERAGE $ENV_FLAG
# paste: $AGENCY_OVERAGE

cd - >/dev/null
EOF
