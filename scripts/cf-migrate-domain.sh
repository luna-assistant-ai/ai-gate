#!/bin/bash
# Migrate www.ai-gate.dev from Cloudflare Pages to Workers (Custom Domain)
# Requires: Global API Key (X-Auth-Key) OR an API Token with Pages:Edit + Workers Scripts:Edit
# Safe to re-run (idempotent-ish): will ignore "already removed/exists" cases
#
# Usage:
#   export CF_EMAIL="joffrey.vanasten@gmail.com"             # Cloudflare account email
#   export CF_API_KEY="<GLOBAL_API_KEY>"                      # Or set CF_API_TOKEN instead
#   # Optional overrides (defaults set below):
#   # export CF_ACCOUNT_ID="602a3ee367f65632af4cab4ca55b46e7"
#   # export CF_ZONE_NAME="ai-gate.dev"
#   # export CF_PROJECT_NAME="luna-proxy-web-frontend"
#   # export CF_WORKER_SERVICE="luna-proxy-web-frontend"
#   # export CF_ENVIRONMENT="production"
#   # export CF_DOMAIN="www.ai-gate.dev"
#   ./scripts/cf-migrate-domain.sh

set -euo pipefail

CF_ACCOUNT_ID=${CF_ACCOUNT_ID:-"602a3ee367f65632af4cab4ca55b46e7"}
CF_ZONE_NAME=${CF_ZONE_NAME:-"ai-gate.dev"}
CF_PROJECT_NAME=${CF_PROJECT_NAME:-"luna-proxy-web-frontend"}
CF_WORKER_SERVICE=${CF_WORKER_SERVICE:-"luna-proxy-web-frontend"}
CF_ENVIRONMENT=${CF_ENVIRONMENT:-"production"}
CF_DOMAIN=${CF_DOMAIN:-"www.ai-gate.dev"}

# Auth: prefer API Token if provided, else Global API Key
AUTH_HEADERS=()
if [[ -n "${CF_API_TOKEN:-}" ]]; then
  AUTH_HEADERS=( -H "Authorization: Bearer ${CF_API_TOKEN}" )
elif [[ -n "${CF_EMAIL:-}" && -n "${CF_API_KEY:-}" ]]; then
  AUTH_HEADERS=( -H "X-Auth-Email: ${CF_EMAIL}" -H "X-Auth-Key: ${CF_API_KEY}" )
else
  echo "[ERROR] Provide CF_API_TOKEN or CF_EMAIL + CF_API_KEY for Cloudflare authentication" >&2
  exit 1
fi

API="https://api.cloudflare.com/client/v4"

say() { echo -e "$1"; }

api_call() {
  local method="$1"; shift
  local path="$1"; shift
  local data_json="${1:-}"
  if [[ -n "$data_json" ]]; then
    curl -fsSL -X "$method" "${API}${path}" \
      -H 'Content-Type: application/json' \
      "${AUTH_HEADERS[@]}" \
      --data "$data_json"
  else
    curl -fsSL -X "$method" "${API}${path}" \
      -H 'Content-Type: application/json' \
      "${AUTH_HEADERS[@]}"
  fi
}

json_get() {
  # Extract a simple JSON path using Python (jq-less)
  python3 - "$1" << 'PY'
import json,sys
path=sys.argv[1].split('.')
obj=json.load(sys.stdin)
for p in path:
  if isinstance(obj, list):
    try:
      i=int(p)
      obj=obj[i]
    except:
      print('')
      sys.exit(0)
  else:
    obj=obj.get(p, '')
print(obj if obj is not None else '')
PY
}

say "\n🚀 Migration du domaine ${CF_DOMAIN} de Pages vers Workers (service: ${CF_WORKER_SERVICE}/${CF_ENVIRONMENT})\n"

# 1) Inspect Pages project and domains
say "1️⃣ Vérification du Pages project et des domaines attachés..."
PAGES_RESP=$(api_call GET "/accounts/${CF_ACCOUNT_ID}/pages/projects/${CF_PROJECT_NAME}" || true)
if [[ -z "$PAGES_RESP" ]]; then
  say "   ⚠️  Impossible de récupérer le projet Pages (peut ne plus exister). Continuité de la migration."
else
  say "   ✅ Projet Pages trouvé: ${CF_PROJECT_NAME}"
  # Try to list domains via domains endpoint (newer API)
  DOMAINS_LIST=$(api_call GET "/accounts/${CF_ACCOUNT_ID}/pages/projects/${CF_PROJECT_NAME}/domains" || echo '{}')
  if echo "$DOMAINS_LIST" | grep -q 'result'; then
    say "   🌐 Domaines Pages actuels:"
    echo "$DOMAINS_LIST" | python3 -m json.tool | sed 's/^/      /'
    if echo "$DOMAINS_LIST" | grep -q "\"hostname\": \"${CF_DOMAIN}\""; then
      say "   ⚠️  ${CF_DOMAIN} est actuellement attaché à Pages → suppression nécessaire"
    else
      say "   ℹ️  ${CF_DOMAIN} n'est pas listé sur Pages (peut déjà être libéré)"
    fi
  fi
fi

# 2) Remove custom domain from Pages project (idempotent)
say "\n2️⃣ Retrait du domaine de Pages (si présent)..."
if api_call DELETE "/accounts/${CF_ACCOUNT_ID}/pages/projects/${CF_PROJECT_NAME}/domains/${CF_DOMAIN}" >/dev/null 2>&1; then
  say "   ✅ Domaine retiré de Pages: ${CF_DOMAIN}"
else
  say "   ℹ️  Domaine introuvable côté Pages (ok)"
fi

# 3) Attach the domain to the Worker service (Custom Domain)
say "\n3️⃣ Attachement du domaine au Worker (Custom Domain)..."
# 3.1 Try Workers Domains API first (no zone_id required)
ADD_PAYLOAD=$(cat <<JSON
{
  "service": "${CF_WORKER_SERVICE}",
  "environment": "${CF_ENVIRONMENT}",
  "zone_name": "${CF_ZONE_NAME}"
}
JSON
)
RESP1=$(api_call PUT "/accounts/${CF_ACCOUNT_ID}/workers/domains/records/${CF_DOMAIN}" "$ADD_PAYLOAD" || true)
if echo "$RESP1" | grep -q '"success":\s*true'; then
  say "   ✅ Domaine ajouté via workers/domains API"
else
  say "   ⚠️  Échec via workers/domains. Détails:"
  echo "$RESP1" | python3 -m json.tool 2>/dev/null | sed 's/^/      /' || echo "      $RESP1"
  
  # 3.2 Resolve zone_id then try Services Custom Domains API
  ZONE_LOOKUP=$(api_call GET "/zones?name=${CF_ZONE_NAME}&account.id=${CF_ACCOUNT_ID}" || echo '{}')
  say "   🔎 Zones lookup (account-scoped) pour ${CF_ZONE_NAME}:"
  echo "$ZONE_LOOKUP" | python3 -m json.tool | sed 's/^/      /' || true
  ZONE_ID=$(echo "$ZONE_LOOKUP" | python3 - << 'PY'
import json,sys
try:
  data=json.load(sys.stdin)
  rid=data.get('result',[])
  if rid:
    print(rid[0].get('id',''))
  else:
    print('')
except:
  print('')
PY
)
  if [[ -z "$ZONE_ID" ]]; then
    ZONE_LOOKUP2=$(api_call GET "/zones?name=${CF_ZONE_NAME}" || echo '{}')
    say "   🔎 Zones lookup (global) pour ${CF_ZONE_NAME}:"
    echo "$ZONE_LOOKUP2" | python3 -m json.tool | sed 's/^/      /' || true
    ZONE_ID=$(echo "$ZONE_LOOKUP2" | python3 - << 'PY'
import json,sys
try:
  data=json.load(sys.stdin)
  rid=data.get('result',[])
  if rid:
    print(rid[0].get('id',''))
  else:
    print('')
except:
  print('')
PY
)
fi

  if [[ -z "$ZONE_ID" ]]; then
    say "   ❌ Impossible de déterminer le zone_id pour ${CF_ZONE_NAME}. Vérifiez que la zone existe et les permissions Zone:Read."
    exit 2
  fi

  CD_PAYLOAD=$(cat <<JSON
{
  "hostname": "${CF_DOMAIN}",
  "zone_id": "${ZONE_ID}"
}
JSON
)
  RESP2=$(api_call POST "/accounts/${CF_ACCOUNT_ID}/workers/services/${CF_WORKER_SERVICE}/environments/${CF_ENVIRONMENT}/domains" "$CD_PAYLOAD" || true)
  if echo "$RESP2" | grep -q '"success":\s*true'; then
    say "   ✅ Domaine ajouté via services/environments/domains"
  else
    say "   ⚠️  Échec via services/environments/domains. Détails:"
    echo "$RESP2" | python3 -m json.tool 2>/dev/null | sed 's/^/      /' || echo "      $RESP2"
    say "   ↪️  Tentative via routes (services routes)."
    ROUTE_PAYLOAD=$(cat <<JSON
{
  "pattern": "${CF_DOMAIN}/*",
  "zone_id": "${ZONE_ID}"
}
JSON
)
    RESP3=$(api_call POST "/accounts/${CF_ACCOUNT_ID}/workers/services/${CF_WORKER_SERVICE}/environments/${CF_ENVIRONMENT}/routes" "$ROUTE_PAYLOAD" || true)
    if echo "$RESP3" | grep -q '"success":\s*true'; then
      say "   ✅ Route ajoutée au Worker (services routes)"
    else
      say "   ❌ Impossible d'attacher le domaine au Worker. Détails:"
      echo "$RESP3" | python3 -m json.tool 2>/dev/null | sed 's/^/      /' || echo "      $RESP3"
      exit 2
    fi
  fi
fi

# 4) Poll status until custom domain becomes active (TLS provisioned)
say "\n4️⃣ Vérification de l'état du domaine (provisionnement TLS)..."
ATTEMPTS=20
SLEEP_SECS=6
for i in $(seq 1 $ATTEMPTS); do
  LIST=$(api_call GET "/accounts/${CF_ACCOUNT_ID}/workers/domains/records" || echo '{}')
  # Try to find our domain entry
  ENTRY=$(echo "$LIST" | python3 - "$CF_DOMAIN" << 'PY'
import json,sys
host=sys.argv[1]
try:
  data=json.load(sys.stdin).get('result', [])
  for r in data:
    if r.get('hostname')==host:
      print(json.dumps(r))
      sys.exit(0)
except: pass
sys.exit(1)
PY
)
  if [[ -n "$ENTRY" ]]; then
    STATUS=$(echo "$ENTRY" | json_get status)
    CERT=$(echo "$ENTRY" | json_get certificate_status)
    say "   • status=${STATUS:-?}  certificate=${CERT:-?} (tentative ${i}/${ATTEMPTS})"
    if [[ "$STATUS" == "active" || "$CERT" == "active" ]]; then
      say "   ✅ Domaine actif côté Workers"
      break
    fi
  else
    say "   • Domaine non encore listé (tentative ${i}/${ATTEMPTS})"
  fi
  sleep "$SLEEP_SECS"
done

# 5) Final check via HTTPS
say "\n5️⃣ Test d'accès HTTP(s) final:"
set +e
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://${CF_DOMAIN}/")
set -e
if [[ "$HTTP_CODE" =~ ^2|3 ]]; then
  say "   ✅ Réponse OK (${HTTP_CODE}) depuis https://${CF_DOMAIN}"
else
  say "   ⚠️ Réponse HTTP ${HTTP_CODE}. Il peut y avoir une propagation ou un problème d'app."
fi

say "\n✅ Migration terminée (côté Cloudflare)."
say "Prochaines actions recommandées:"
say "  - Mettre à jour NEXTAUTH_URL/AUTH_URL → https://${CF_DOMAIN} (env Worker ${CF_ENVIRONMENT})"
say "  - Mettre à jour les redirect URIs OAuth Google/GitHub → https://${CF_DOMAIN}/api/auth/callback/*"
say "  - Tester /, /login, /signup, OAuth"
