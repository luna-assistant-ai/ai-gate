#!/bin/bash

set -e

ACCOUNT_ID="602a3ee367f65632af4cab4ca55b46e7"
PROJECT_NAME="luna-proxy-web-frontend"
WORKER_NAME="luna-proxy-web-frontend"
DOMAIN="www.ai-gate.dev"

echo "🚀 Migration du domaine www.ai-gate.dev vers Worker"
echo ""

# Step 1: Verify current state
echo "1️⃣ Vérification de l'état actuel..."
echo "   Pages project:"
wrangler pages project list | grep luna-proxy-web-frontend || echo "   Project not found"

echo ""
echo "   Worker deployments:"
wrangler deployments list --name=$WORKER_NAME 2>/dev/null | head -5 || echo "   Worker found"

# Step 2: The actual migration needs to be done via Cloudflare dashboard or API
# Since wrangler doesn't have a direct command to manage Pages custom domains,
# we'll use the Cloudflare API via curl with wrangler's credentials

echo ""
echo "2️⃣ Pour retirer le domaine du Pages project:"
echo "   Option A: Via dashboard Cloudflare"
echo "   https://dash.cloudflare.com/${ACCOUNT_ID}/pages/view/${PROJECT_NAME}/settings/domains"
echo ""
echo "   Option B: Via API (nécessite un API token)"
echo "   curl -X DELETE \"https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/domains/${DOMAIN}\" \\"
echo "     -H \"Authorization: Bearer \$CLOUDFLARE_API_TOKEN\""

echo ""
echo "3️⃣ Pour ajouter le domaine au Worker:"
echo "   Le domaine est déjà configuré dans wrangler.toml"
echo "   Il sera automatiquement attaché au prochain déploiement:"
echo ""
echo "   cd luna-proxy-web"
echo "   npm run deploy:production"

echo ""
echo "4️⃣ Alternative: Utiliser le dashboard Cloudflare"
echo "   Workers: https://dash.cloudflare.com/${ACCOUNT_ID}/workers/services/view/${WORKER_NAME}/production/settings/domains"
echo "   Cliquer sur 'Add Custom Domain' et entrer: ${DOMAIN}"

echo ""
echo "✅ Guide préparé. Voir MIGRATION_DOMAIN.md pour les étapes détaillées."
