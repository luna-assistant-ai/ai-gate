# Custom Domain Staging - Configuré ✅

## ✅ Ce qui a été fait

### 1. Configuration du custom domain
- ✅ **Web staging** : `staging-app.ai-gate.dev` → `luna-proxy-web-frontend-staging`
- ✅ **API staging** : `staging.ai-gate.dev` → `luna-proxy-api-staging` (déjà existant)

### 2. Mise à jour des configs

#### luna-proxy-web/wrangler.toml
```toml
[env.staging]
name = "luna-proxy-web-frontend-staging"
workers_dev = false  # ✅ Désactivé workers.dev
routes = [
  { pattern = "staging-app.ai-gate.dev", custom_domain = true }
]

[env.staging.vars]
AUTH_URL = "https://staging-app.ai-gate.dev"
NEXTAUTH_URL = "https://staging-app.ai-gate.dev"
ALLOWED_CORS_ORIGINS = "https://staging-app.ai-gate.dev,https://staging.ai-gate.dev"
AUTH_COOKIE_DOMAIN = ".ai-gate.dev"  # ✅ Cookies partagés sur *.ai-gate.dev
```

#### luna-proxy-api/wrangler.toml
```toml
[env.staging.vars]
ALLOWED_ORIGINS = "https://staging.ai-gate.dev,https://staging-app.ai-gate.dev,http://localhost:3000,http://localhost:3002"
```

### 3. Déploiements
```bash
# Web staging
cd luna-proxy-web
npm run build:cf
npx wrangler deploy --env staging
# ✅ Deployed: staging-app.ai-gate.dev

# API staging
cd luna-proxy-api
wrangler deploy --env staging
# ✅ Deployed: staging.ai-gate.dev
```

### 4. Tests de validation
```bash
# Web staging
curl -I https://staging-app.ai-gate.dev
# ✅ HTTP/2 200

# API staging health
curl https://staging.ai-gate.dev/health
# ✅ {"status":"healthy"}

# API staging metrics
curl https://staging.ai-gate.dev/metrics
# ✅ {"uptime_seconds":...}
```

## 🎯 URLs Staging

| Service | URL | Status |
|---------|-----|--------|
| **Web** | https://staging-app.ai-gate.dev | ✅ Actif |
| **API** | https://staging.ai-gate.dev | ✅ Actif |
| **API Health** | https://staging.ai-gate.dev/health | ✅ Actif |
| **API Metrics** | https://staging.ai-gate.dev/metrics | ✅ Actif |

## 🔐 Sécurité

### Isolation des données
- ✅ **DB D1 séparée** : `luna-proxy-users-staging` (5ecb0455-e99a-4fa7-ba4d-e286574968e0)
- ✅ **KV séparé** : `RATE_LIMIT_STAGING` (cce8062a722b46a2ba1570073c073d3d)
- ✅ **DB API séparée** : `luna-proxy-audit-staging` (fe91c742-20b1-4780-82d9-8cb145f395a5)

### CORS
- ✅ API accepte les requêtes de `staging-app.ai-gate.dev`
- ✅ Cookies partagés sur `.ai-gate.dev` (permet NextAuth)

## 📖 Utilisation

### Accéder au staging
```bash
# Ouvrir dans le navigateur
open https://staging-app.ai-gate.dev
```

### Voir les logs
```bash
# Web staging
cd luna-proxy-web
wrangler tail --env staging

# API staging
cd luna-proxy-api
wrangler tail --env staging
```

### Déployer en staging
```bash
# Web
cd luna-proxy-web
npm run build:cf
npx wrangler deploy --env staging

# API
cd luna-proxy-api
wrangler deploy --env staging
```

## ⚠️ Limitations actuelles

1. **OAuth désactivé** : Pas de connexion Google/GitHub en staging
   - Solution : Créer des OAuth apps staging dédiées

2. **Stripe non configuré** : Pas de paiements en staging
   - Solution : Configurer Stripe test mode

3. **Secrets non copiés** : Certains secrets manquent en staging
   - Solution : Copier les secrets de prod vers staging (voir ci-dessous)

## 🔧 Prochaines étapes (optionnel)

### Copier les secrets essentiels en staging
```bash
cd luna-proxy-web
wrangler secret put AUTH_SECRET --env staging
wrangler secret put NEXTAUTH_SECRET --env staging
wrangler secret put ADMIN_API_KEY --env staging

cd luna-proxy-api
wrangler secret put ADMIN_API_KEY --env staging
wrangler secret put JWT_SECRET --env staging
wrangler secret put KEK_V1 --env staging
```

### Configurer OAuth staging (optionnel)
1. Google Cloud Console → Créer OAuth 2.0 Client ID
   - Authorized redirect URIs: `https://staging-app.ai-gate.dev/api/auth/callback/google`
2. GitHub Developer Settings → New OAuth App
   - Callback URL: `https://staging-app.ai-gate.dev/api/auth/callback/github`
3. Mettre à jour `wrangler.toml` :
   ```toml
   GOOGLE_CLIENT_ID = "<staging_client_id>"
   GITHUB_CLIENT_ID = "<staging_client_id>"
   ```
4. Configurer les secrets :
   ```bash
   wrangler secret put GOOGLE_CLIENT_SECRET --env staging
   wrangler secret put GITHUB_CLIENT_SECRET --env staging
   ```

### Configurer Stripe test mode (optionnel)
```bash
cd luna-proxy-api
wrangler secret put STRIPE_SECRET_KEY --env staging  # sk_test_...
wrangler secret put STRIPE_WEBHOOK_SECRET --env staging
wrangler secret put STRIPE_PRICE_STARTER --env staging
wrangler secret put STRIPE_PRICE_GROWTH --env staging
```

## ✅ Résultat final

**L'environnement staging est maintenant :**
- ✅ **Isolé** : Données séparées de la production
- ✅ **Accessible** : Custom domain `staging-app.ai-gate.dev`
- ✅ **Sécurisé** : CORS et cookies configurés
- ✅ **Fonctionnel** : Peut être utilisé pour tester sans risque
- ⚠️ **Limité** : OAuth et Stripe non configurés (optionnel)

**Tu peux maintenant tester toutes les fonctionnalités en staging avant de déployer en prod !** 🚀
