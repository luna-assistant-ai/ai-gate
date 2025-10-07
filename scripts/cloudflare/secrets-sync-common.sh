#!/bin/zsh
# Sync common secrets (same value for staging and production) for API and Web Workers.
# Usage:
#   ./scripts/cloudflare/secrets-sync-common.sh
#
# Provide the following environment variables (set only those you want to push):
# API (luna-proxy-api):
#   CF_TURN_KEY_ID
#   CF_TURN_API_TOKEN
#   (optional) CF_AUTH_EMAIL
#   (optional) CF_AUTH_KEY
#
# WEB (luna-proxy-web):
#   (optional) AUTH_SECRET
#   (optional) GOOGLE_CLIENT_SECRET
#   (optional) GITHUB_CLIENT_SECRET
#
# Notes:
# - This script pushes the same values to BOTH staging and production.
# - It never prints secret values.
# - Requires `wrangler login` OR CLOUDFLARE_API_TOKEN/CLOUDFLARE_ACCOUNT_ID exported.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
API_DIR="$ROOT_DIR/luna-proxy-api"
WEB_DIR="$ROOT_DIR/luna-proxy-web"

[[ -d "$API_DIR" ]] || { echo "Missing $API_DIR"; exit 1; }
[[ -d "$WEB_DIR" ]] || { echo "Missing $WEB_DIR"; exit 1; }

# Helper: build JSON file from given env var names (include only set vars)
# Args: output_json_path, array of names
function build_json_from_env() {
  local out_file="$1"; shift
  echo "{" > "$out_file"
  local first=1
  local name val
  for name in "$@"; do
    val="${(P)name:-}"
    if [[ -n "$val" ]]; then
      if [[ $first -eq 0 ]]; then echo "," >> "$out_file"; fi
      printf '  "%s": %q' "$name" "$val" >> "$out_file"
      first=0
    fi
  done
  echo "\n}" >> "$out_file"
}

TMP_API_JSON="${TMPDIR:-/tmp}/api-secrets-common.json"
TMP_WEB_JSON="${TMPDIR:-/tmp}/web-secrets-common.json"

# Build API payload (TURN + optional legacy)
build_json_from_env "$TMP_API_JSON" \
  CF_TURN_KEY_ID \
  CF_TURN_API_TOKEN \
  CF_AUTH_EMAIL \
  CF_AUTH_KEY

# Build WEB payload (optional OAuth/AuthJS)
build_json_from_env "$TMP_WEB_JSON" \
  AUTH_SECRET \
  GOOGLE_CLIENT_SECRET \
  GITHUB_CLIENT_SECRET

# Show which secret names will be pushed (names only)
echo "API common secrets to push (same for staging & production):"
[[ -s "$TMP_API_JSON" ]] && jq -r 'keys[]' "$TMP_API_JSON" | sed 's/^/  - /' || echo "  (none)"

echo "WEB common secrets to push (same for staging & production):"
[[ -s "$TMP_WEB_JSON" ]] && jq -r 'keys[]' "$TMP_WEB_JSON" | sed 's/^/  - /' || echo "  (none)"

# Function to bulk push for a dir+env if JSON not empty
function bulk_push_if_any() {
  local dir="$1"; local env="$2"; local json="$3"; local label="$4"
  if [[ -s "$json" ]]; then
    cd "$dir"
    echo "\nPushing $label secrets to $env ..."
    npx wrangler secret bulk "$json" --env="$env"
    echo "$label secrets in $env:"; npx wrangler secret list --env="$env"
  else
    echo "\nNo $label secrets to push for $env. Skipping."
  fi
}

# Push for staging and production
bulk_push_if_any "$API_DIR" "staging" "$TMP_API_JSON" "API"
bulk_push_if_any "$API_DIR" "production" "$TMP_API_JSON" "API"

bulk_push_if_any "$WEB_DIR" "staging" "$TMP_WEB_JSON" "WEB"
bulk_push_if_any "$WEB_DIR" "production" "$TMP_WEB_JSON" "WEB"

echo "\nDone syncing common secrets to staging and production."
