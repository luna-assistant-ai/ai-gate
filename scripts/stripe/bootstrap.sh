#!/bin/zsh
# Bootstrap Stripe products and prices for AI Gate plans
# Usage: ./scripts/stripe-bootstrap.sh [test|live] [--force]
# Requires: stripe CLI, jq

set -euo pipefail

MODE=${1:-test}
FORCE=${2:-}

if [[ "$MODE" != "test" && "$MODE" != "live" ]]; then
  echo "Error: mode must be 'test' or 'live'"
  exit 1
fi

IDS_FILE="scripts/stripe-ids.${MODE}.json"

echo "==> Stripe bootstrap (${MODE})"

if [[ -f "$IDS_FILE" && "$FORCE" != "--force" ]]; then
  echo "Found $IDS_FILE. To recreate, run with --force."
  cat "$IDS_FILE"
  exit 0
fi

tmpfile=$(mktemp)

# Helper to write/update JSON file
write_json() {
  local key=$1
  local value=$2
  if [[ -f "$IDS_FILE" ]]; then
    cat "$IDS_FILE" | jq --arg k "$key" --arg v "$value" '.[$k]=$v' > "$tmpfile"
  else
    printf '{}' | jq --arg k "$key" --arg v "$value" '.[$k]=$v' > "$tmpfile"
  fi
  mv "$tmpfile" "$IDS_FILE"
}

create_product() {
  local name="$1"
  echo "Creating product: $name"
  local prod_json
  prod_json=$(stripe products create --name "$name" --active true)
  echo "$prod_json" | jq -r '.id'
}

create_base_price() {
  local product_id=$1
  local amount_cents=$2
  local nickname=$3
  echo "Creating base price: $nickname ($((amount_cents)) cents/month)"
  stripe prices create \
    --product "$product_id" \
    --currency usd \
    --unit_amount "$amount_cents" \
    --nickname "$nickname" \
    --recurring interval=month | jq -r '.id'
}

create_overage_price() {
  local product_id=$1
  local included_minutes=$2
  local overage_unit_amount_decimal_cents=$3 # e.g. 1.2 means $0.012
  local nickname=$4
  echo "Creating overage price: $nickname (included $included_minutes min, overage ${overage_unit_amount_decimal_cents} cents/min)"
  # Build tiers JSON
  local tiers_json
  tiers_json=$(jq -n \
    --argjson up_to "$included_minutes" \
    --arg overage "$overage_unit_amount_decimal_cents" \
    '[{"up_to": $up_to, "unit_amount": 0}, {"up_to": "inf", "unit_amount_decimal": $overage}]')

  stripe prices create \
    --product "$product_id" \
    --currency usd \
    --billing_scheme tiered \
    --tiers_mode graduated \
    --recurring interval=month,usage_type=metered,aggregate_usage=sum \
    --tiers "$tiers_json" \
    --nickname "$nickname" | jq -r '.id'
}

# Plans configuration: name, base cents, included minutes, overage cents (decimal)
# Starter: $9, 1500 min, $0.012/min => 1.2 cents
# Build:   $19, 3000 min, $0.011/min => 1.1 cents
# Pro:     $39, 8000 min, $0.009/min => 0.9 cents
# Agency:  $99, 25000 min, $0.008/min => 0.8 cents

PLANS=(
  "Starter|900|1500|1.2"
  "Build|1900|3000|1.1"
  "Pro|3900|8000|0.9"
  "Agency|9900|25000|0.8"
)

for plan in ${PLANS[@]}; do
  NAME=${plan%%|*}
  rest=${plan#*|}
  BASE_CENTS=${rest%%|*}
  rest=${rest#*|}
  INCLUDED=${rest%%|*}
  OVERAGE_DEC=${rest#*|}

  PRODUCT_NAME="AI Gate - ${NAME}"
  echo "\n-- Plan $NAME --"
  PROD_ID=$(create_product "$PRODUCT_NAME")
  write_json "product_${NAME}" "$PROD_ID"

  BASE_PRICE_ID=$(create_base_price "$PROD_ID" "$BASE_CENTS" "${NAME} base monthly")
  write_json "price_${NAME}_base" "$BASE_PRICE_ID"

  OVER_PRICE_ID=$(create_overage_price "$PROD_ID" "$INCLUDED" "$OVERAGE_DEC" "${NAME} overage per minute")
  write_json "price_${NAME}_overage" "$OVER_PRICE_ID"

done

echo "\n==> Done. IDs stored in $IDS_FILE"
cat "$IDS_FILE"
