#!/bin/zsh
# Bulk push Cloudflare Worker secrets for API and Web using Wrangler
# Usage:
#   ./scripts/cloudflare/secrets-bulk.sh staging
#   ./scripts/cloudflare/secrets-bulk.sh production
#
# Provide secrets via environment variables before running:
#
# For staging (suffix _STAGING):
#   API: STRIPE_SECRET_KEY_STAGING, STRIPE_WEBHOOK_SECRET_STAGING, ADMIN_API_KEY_STAGING, JWT_SECRET_STAGING,
#        CF_TURN_KEY_ID_STAGING, CF_TURN_API_TOKEN_STAGING, KEK_V1_STAGING
#   WEB: AUTH_SECRET_STAGING, GOOGLE_CLIENT_SECRET_STAGING, GITHUB_CLIENT_SECRET_STAGING
#
# For production (suffix _PRODUCTION):
#   API: STRIPE_SECRET_KEY_PRODUCTION, STRIPE_WEBHOOK_SECRET_PRODUCTION, ADMIN_API_KEY_PRODUCTION, JWT_SECRET_PRODUCTION,
#        CF_TURN_KEY_ID_PRODUCTION, CF_TURN_API_TOKEN_PRODUCTION, KEK_V1_PRODUCTION
#   WEB: AUTH_SECRET_PRODUCTION, GOOGLE_CLIENT_SECRET_PRODUCTION, GITHUB_CLIENT_SECRET_PRODUCTION
#
# Notes:
# - This script never prints secret values. It only lists the secret names being pushed.
# - Requires wrangler login OR CLOUDFLARE_API_TOKEN/CLOUDFLARE_ACCOUNT_ID exported in environment.
# - Workers names are taken from the wrangler.toml files.

set -euo pipefail

ENV_TARGET=${1:-}
if [[ -z "$ENV_TARGET" ]]; then
  echo "Usage: $0 staging|production" >&2
  exit 1
fi
if [[ "$ENV_TARGET" != "staging" && "$ENV_TARGET" != "production" ]]; then
  echo "Error: ENV must be 'staging' or 'production'" >&2
  exit 1
fi

# Resolve suffix based on env
if [[ "$ENV_TARGET" == "staging" ]]; then
  SUF="STAGING"
else
  SUF="PRODUCTION"
fi

# Workers directories
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
API_DIR="$ROOT_DIR/luna-proxy-api"
WEB_DIR="$ROOT_DIR/luna-proxy-web"

# Verify directories
[[ -d "$API_DIR" ]] || { echo "Missing $API_DIR"; exit 1; }
[[ -d "$WEB_DIR" ]] || { echo "Missing $WEB_DIR"; exit 1; }

# Helper: build JSON file from env map (key:env_var_name)
# Args: output_json_path, array_name
function build_json() {
  local out_file="$1"
  local -n arr="$2"
  echo "{" > "$out_file"
  local first=1
  for kv in "${arr[@]}"; do
    local name="${kv%%=*}"
    local envname="${kv#*=}"
    local val="${(P)envname:-}"
    if [[ -n "$val" ]]; then
      if [[ $first -eq 0 ]]; then echo "," >> "$out_file"; fi
      printf '  "%s": %q' "$name" "$val" >> "$out_file"
      first=0
    fi
  done
  echo "\n}" >> "$out_file"
}

# API secrets map (name -> ENV var)
API_SECRETS=(
  "STRIPE_SECRET_KEY=STRIPE_SECRET_KEY_${SUF}"
  "STRIPE_WEBHOOK_SECRET=STRIPE_WEBHOOK_SECRET_${SUF}"
  "ADMIN_API_KEY=ADMIN_API_KEY_${SUF}"
  "JWT_SECRET=JWT_SECRET_${SUF}"
  "CF_TURN_KEY_ID=CF_TURN_KEY_ID_${SUF}"
  "CF_TURN_API_TOKEN=CF_TURN_API_TOKEN_${SUF}"
  "KEK_V1=KEK_V1_${SUF}"
)

# WEB secrets map (name -> ENV var)
WEB_SECRETS=(
  "AUTH_SECRET=AUTH_SECRET_${SUF}"
  "GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET_${SUF}"
  "GITHUB_CLIENT_SECRET=GITHUB_CLIENT_SECRET_${SUF}"
)

TMP_API_JSON="${TMPDIR:-/tmp}/api-secrets-${ENV_TARGET}.json"
TMP_WEB_JSON="${TMPDIR:-/tmp}/web-secrets-${ENV_TARGET}.json"

# Build JSON payloads
build_json "$TMP_API_JSON" API_SECRETS
build_json "$TMP_WEB_JSON" WEB_SECRETS

# Display which keys will be pushed (names only)
echo "Will push API secrets ($ENV_TARGET):"
for kv in "${API_SECRETS[@]}"; do echo "  - ${kv%%=*}"; done

echo "Will push WEB secrets ($ENV_TARGET):"
for kv in "${WEB_SECRETS[@]}"; do echo "  - ${kv%%=*}"; done

# Push API secrets
cd "$API_DIR"
echo "\nPushing API secrets from $TMP_API_JSON ..."
npx wrangler secret bulk "$TMP_API_JSON" --env="$ENV_TARGET"

echo "API secrets pushed. Listing names:"
npx wrangler secret list --env="$ENV_TARGET"

# Push WEB secrets
cd "$WEB_DIR"
echo "\nPushing WEB secrets from $TMP_WEB_JSON ..."
npx wrangler secret bulk "$TMP_WEB_JSON" --env="$ENV_TARGET"

echo "WEB secrets pushed. Listing names:"
npx wrangler secret list --env="$ENV_TARGET"

echo "\nDone."
