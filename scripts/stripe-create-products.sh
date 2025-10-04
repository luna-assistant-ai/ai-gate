#!/bin/bash
# Simple Stripe products creation for AI Gate
# Usage: ./scripts/stripe-create-products.sh

set -e

STRIPE=~/bin/stripe

echo "🚀 Creating AI Gate Stripe Products (Test Mode)"
echo ""

# Starter Plan
echo "📦 Creating: AI Gate - Starter"
STARTER_PROD=$($STRIPE products create --name "AI Gate - Starter" --active | jq -r '.id')
echo "   Product ID: $STARTER_PROD"

STARTER_BASE=$($STRIPE prices create \
  --product "$STARTER_PROD" \
  --currency usd \
  --unit-amount 900 \
  --recurring interval=month \
  | jq -r '.id')
echo "   Base Price ID: $STARTER_BASE ($9/month)"

STARTER_OVERAGE=$($STRIPE prices create \
  --product "$STARTER_PROD" \
  --currency usd \
  --billing-scheme tiered \
  --tiers-mode graduated \
  --recurring interval=month,usage_type=metered,aggregate_usage=sum \
  -d 'tiers[0][up_to]=1500' \
  -d 'tiers[0][unit_amount]=0' \
  -d 'tiers[1][up_to]=inf' \
  -d 'tiers[1][unit_amount_decimal]=1.2' \
  | jq -r '.id')
echo "   Overage Price ID: $STARTER_OVERAGE (1500 min included, $0.012/min overage)"
echo ""

# Build Plan
echo "📦 Creating: AI Gate - Build"
BUILD_PROD=$($STRIPE products create --name "AI Gate - Build" --active | jq -r '.id')
echo "   Product ID: $BUILD_PROD"

BUILD_BASE=$($STRIPE prices create \
  --product "$BUILD_PROD" \
  --currency usd \
  --unit-amount 1900 \
  --recurring interval=month \
  | jq -r '.id')
echo "   Base Price ID: $BUILD_BASE ($19/month)"

BUILD_OVERAGE=$($STRIPE prices create \
  --product "$BUILD_PROD" \
  --currency usd \
  --billing-scheme tiered \
  --tiers-mode graduated \
  --recurring interval=month,usage_type=metered,aggregate_usage=sum \
  -d 'tiers[0][up_to]=3000' \
  -d 'tiers[0][unit_amount]=0' \
  -d 'tiers[1][up_to]=inf' \
  -d 'tiers[1][unit_amount_decimal]=1.1' \
  | jq -r '.id')
echo "   Overage Price ID: $BUILD_OVERAGE (3000 min included, $0.011/min overage)"
echo ""

# Pro Plan
echo "📦 Creating: AI Gate - Pro"
PRO_PROD=$($STRIPE products create --name "AI Gate - Pro" --active | jq -r '.id')
echo "   Product ID: $PRO_PROD"

PRO_BASE=$($STRIPE prices create \
  --product "$PRO_PROD" \
  --currency usd \
  --unit-amount 3900 \
  --recurring interval=month \
  | jq -r '.id')
echo "   Base Price ID: $PRO_BASE ($39/month)"

PRO_OVERAGE=$($STRIPE prices create \
  --product "$PRO_PROD" \
  --currency usd \
  --billing-scheme tiered \
  --tiers-mode graduated \
  --recurring interval=month,usage_type=metered,aggregate_usage=sum \
  -d 'tiers[0][up_to]=8000' \
  -d 'tiers[0][unit_amount]=0' \
  -d 'tiers[1][up_to]=inf' \
  -d 'tiers[1][unit_amount_decimal]=0.9' \
  | jq -r '.id')
echo "   Overage Price ID: $PRO_OVERAGE (8000 min included, $0.009/min overage)"
echo ""

# Agency Plan
echo "📦 Creating: AI Gate - Agency"
AGENCY_PROD=$($STRIPE products create --name "AI Gate - Agency" --active | jq -r '.id')
echo "   Product ID: $AGENCY_PROD"

AGENCY_BASE=$($STRIPE prices create \
  --product "$AGENCY_PROD" \
  --currency usd \
  --unit-amount 9900 \
  --recurring interval=month \
  | jq -r '.id')
echo "   Base Price ID: $AGENCY_BASE ($99/month)"

AGENCY_OVERAGE=$($STRIPE prices create \
  --product "$AGENCY_PROD" \
  --currency usd \
  --billing-scheme tiered \
  --tiers-mode graduated \
  --recurring interval=month,usage_type=metered,aggregate_usage=sum \
  -d 'tiers[0][up_to]=25000' \
  -d 'tiers[0][unit_amount]=0' \
  -d 'tiers[1][up_to]=inf' \
  -d 'tiers[1][unit_amount_decimal]=0.8' \
  | jq -r '.id')
echo "   Overage Price ID: $AGENCY_OVERAGE (25000 min included, $0.008/min overage)"
echo ""

# Save IDs to JSON file
echo "💾 Saving IDs to scripts/stripe-ids.test.json"
cat > scripts/stripe-ids.test.json <<EOF
{
  "product_Starter": "$STARTER_PROD",
  "price_Starter_base": "$STARTER_BASE",
  "price_Starter_overage": "$STARTER_OVERAGE",
  "product_Build": "$BUILD_PROD",
  "price_Build_base": "$BUILD_BASE",
  "price_Build_overage": "$BUILD_OVERAGE",
  "product_Pro": "$PRO_PROD",
  "price_Pro_base": "$PRO_BASE",
  "price_Pro_overage": "$PRO_OVERAGE",
  "product_Agency": "$AGENCY_PROD",
  "price_Agency_base": "$AGENCY_BASE",
  "price_Agency_overage": "$AGENCY_OVERAGE"
}
EOF

echo ""
echo "✅ Done! Products and prices created."
echo ""
echo "📋 IDs saved to: scripts/stripe-ids.test.json"
cat scripts/stripe-ids.test.json
