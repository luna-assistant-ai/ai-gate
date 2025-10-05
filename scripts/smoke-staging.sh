#!/usr/bin/env bash
set -euo pipefail

# Smoke test for staging: signup -> login -> create/delete project
# Requirements:
#  - curl, jq available in PATH
#  - Environment variable OPENAI_TEST_KEY set to a valid OpenAI key (used once)
#  - Staging deployment live at https://luna-proxy-web-frontend-staging.joffrey-vanasten.workers.dev

API_BASE="https://luna-proxy-web-frontend-staging.joffrey-vanasten.workers.dev"
EMAIL="smoke-$(date +%s)@example.com"
PASSWORD="StrongPass123!"
OPENAI_KEY="${OPENAI_TEST_KEY:-}" # expect caller to provide

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

if [[ -z "$OPENAI_KEY" ]]; then
  echo "OPENAI_TEST_KEY environment variable must be set" >&2
  exit 1
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
COOKIES="$WORKDIR/cookies.txt"
HEADERS="$WORKDIR/headers.txt"
CSRF_JSON="$WORKDIR/csrf.json"

log() {
  printf '>>> %s\n' "$1"
}

# 1. Signup
log "Signing up $EMAIL"
response=$(curl -sS -X POST "$API_BASE/api/auth/signup" \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"Smoke Test\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

success=$(echo "$response" | jq -r '.success // false')
if [[ "$success" != "true" ]]; then
  echo "Signup failed: $response" >&2
  exit 1
fi

# 2. Fetch CSRF token
log "Fetching CSRF token"
curl -sS -c "$COOKIES" -o "$CSRF_JSON" "$API_BASE/api/auth/csrf?json=true"
csrf_token=$(jq -r '.csrfToken' "$CSRF_JSON")
csrf_cookie=$(awk '$6=="__Host-authjs.csrf-token" {print $6"="$7}' "$COOKIES")
callback_cookie=$(awk '$6=="__Secure-authjs.callback-url" {print $6"="$7}' "$COOKIES")

if [[ -z "$csrf_token" || -z "$csrf_cookie" ]]; then
  echo "Failed to obtain CSRF token" >&2
  exit 1
fi

# 3. Login and grab session cookie
log "Signing in"
curl -sS -D "$HEADERS" -o /dev/null \
  "$API_BASE/api/auth/callback/credentials?json=true" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H "Cookie: $csrf_cookie; $callback_cookie" \
  --data-urlencode "csrfToken=$csrf_token" \
  --data-urlencode "email=$EMAIL" \
  --data-urlencode "password=$PASSWORD" \
  --data-urlencode "callbackUrl=$API_BASE/dashboard" \
  --data-urlencode "json=true" \
  --data-urlencode "redirect=false"

session_cookie=$(grep -i '__Secure-authjs.session-token' "$HEADERS" | tr -d '\r' | sed -n 's/^[Ss]et-[Cc]ookie:[[:space:]]*\([^;]*\).*/\1/p')
if [[ -z "$session_cookie" ]]; then
  echo "--- raw headers ---" >&2
  cat "$HEADERS" >&2 || true
  echo "-------------------" >&2
  echo "Failed to capture session cookie" >&2
  exit 1
fi

# 4. Create project with real key
log "Creating project"
create_response=$(curl -sS -X POST "$API_BASE/api/projects" \
  -H 'Content-Type: application/json' \
  -H "Cookie: $session_cookie" \
  -d "{\"project_name\":\"Smoke QA\",\"openai_key\":\"$OPENAI_KEY\"}")

project_id=$(echo "$create_response" | jq -r '.project.project_id // empty')
if [[ -z "$project_id" ]]; then
  echo "Project creation failed: $create_response" >&2
  exit 1
fi
log "Created project $project_id"

# 5. Delete project
log "Deleting project"
delete_response=$(curl -sS -X DELETE "$API_BASE/api/projects/$project_id" \
  -H "Cookie: $session_cookie")

success=$(echo "$delete_response" | jq -r '.success // false')
if [[ "$success" != "true" ]]; then
  echo "Project deletion failed: $delete_response" >&2
  exit 1
fi

log "Smoke test successful"
