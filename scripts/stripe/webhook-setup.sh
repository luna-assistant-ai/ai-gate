#!/bin/zsh
# Create Stripe webhook endpoints for staging and production
# Usage: ./scripts/stripe-webhook-setup.sh [test|live] [--force]
# Requires: stripe CLI, jq

set -euo pipefail

MODE=${1:-test}
FORCE=${2:-}

if [[ "$MODE" != "test" && "$MODE" != "live" ]]; then
  echo "Error: mode must be 'test' or 'live'"
  exit 1
fi

IDS_FILE="scripts/stripe-ids.${MODE}.json"

if [[ "$MODE" == "test" ]]; then
  WEBHOOK_URL="https://luna-proxy-api-staging.joffrey-vanasten.workers.dev/webhooks/stripe"
else
  WEBHOOK_URL="https://api.ai-gate.dev/webhooks/stripe"
fi

echo "==> Creating webhook endpoint (${MODE}) for $WEBHOOK_URL"

tmpfile=$(mktemp)
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

if [[ -f "$IDS_FILE" && "$FORCE" != "--force" ]]; then
  echo "Found $IDS_FILE. Will append webhook info. Use --force to recreate prices/products"
fi

WH_JSON=$(stripe webhook_endpoints create \
  --url "$WEBHOOK_URL" \
  --enabled_events checkout.session.completed customer.subscription.created customer.subscription.updated customer.subscription.deleted invoice.finalized invoice.paid invoice.payment_failed)

WH_ID=$(echo "$WH_JSON" | jq -r '.id')
WH_SECRET=$(echo "$WH_JSON" | jq -r '.secret // empty')

write_json "webhook_${MODE}_id" "$WH_ID"
if [[ -n "$WH_SECRET" ]]; then
  write_json "webhook_${MODE}_secret" "$WH_SECRET"
fi

echo "==> Webhook created: $WH_ID"
if [[ -n "$WH_SECRET" ]]; then
  echo "Signing secret captured in $IDS_FILE"
else
  echo "Note: Some CLI versions do not return the signing secret. Retrieve it from Dashboard and update $IDS_FILE manually as webhook_${MODE}_secret."
fi

cat "$IDS_FILE"
