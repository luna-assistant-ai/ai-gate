# Améliorations Staging pour AI Gate

## Objectif
Rendre l'environnement staging le plus proche possible de la production pour détecter les bugs avant le déploiement.

## Problèmes actuels

### 🔴 Critiques (risque de corruption de données prod)
1. **Web staging partage la DB production** (`luna-proxy-users`)
   - Risque : Tests staging pourraient corrompre les users prod
   - Fix : Créer `luna-proxy-users-staging`

### 🟡 Importants (différences avec prod)
2. **OAuth désactivé en staging**
   - Fix : Créer des OAuth apps séparées Google/GitHub pour staging

3. **Pas de custom domain pour staging**
   - Fix : Configurer `staging.ai-gate.dev` → API staging
   - Fix : Configurer `staging-app.ai-gate.dev` → Web staging

4. **Pas de KV RATE_LIMIT en staging web**
   - Fix : Créer un KV namespace dédié

5. **INTERNAL_API_URL non défini en staging web**
   - Fix : Pointer vers l'API staging

6. **Secrets Stripe non configurés en staging**
   - Fix : Utiliser Stripe test mode avec clés séparées

### 🟢 Nice to have
7. **Monitoring/logging différent**
   - Fix : Configurer des webhooks/alertes séparés

## Plan d'amélioration

### Phase 1 : Isolation des données (URGENT)
```bash
# 1. Créer DB D1 staging séparée pour le web
wrangler d1 create luna-proxy-users-staging

# 2. Copier le schéma (sans les données)
wrangler d1 execute luna-proxy-users-staging --remote --file=luna-proxy-web/schema.sql

# 3. Créer KV namespace staging pour rate limiting
wrangler kv namespace create "RATE_LIMIT_STAGING"
```

### Phase 2 : Configuration OAuth staging
```bash
# 1. Créer OAuth apps staging
# Google Cloud Console: Créer nouveau OAuth 2.0 Client ID
#   - Authorized redirect URIs: https://staging-app.ai-gate.dev/api/auth/callback/google
# GitHub Developer Settings: New OAuth App
#   - Callback URL: https://staging-app.ai-gate.dev/api/auth/callback/github

# 2. Configurer les secrets
cd luna-proxy-web
wrangler secret put GOOGLE_CLIENT_SECRET --env staging
wrangler secret put GITHUB_CLIENT_SECRET --env staging
wrangler secret put AUTH_SECRET --env staging
```

### Phase 3 : Custom domains
```bash
# Via Cloudflare Dashboard ou wrangler
# 1. API staging: staging.ai-gate.dev → luna-proxy-api-staging
# 2. Web staging: staging-app.ai-gate.dev → luna-proxy-web-frontend-staging
```

### Phase 4 : Stripe test mode
```bash
# 1. Récupérer les clés Stripe test mode
# 2. Créer les produits Stripe en test mode
cd luna-proxy-api
wrangler secret put STRIPE_SECRET_KEY --env staging  # sk_test_...
wrangler secret put STRIPE_WEBHOOK_SECRET --env staging
wrangler secret put STRIPE_PRICE_STARTER --env staging
wrangler secret put STRIPE_PRICE_GROWTH --env staging
```

## Configuration mise à jour

### luna-proxy-api/wrangler.toml
```toml
[env.staging]
name = "luna-proxy-api-staging"
routes = [
  { pattern = "staging.ai-gate.dev", custom_domain = true }
]

[[env.staging.kv_namespaces]]
binding = "CLIENTS"
id = "1dbece59b9a54790a103ab9b162185e0"

[[env.staging.kv_namespaces]]
binding = "METRICS"
id = "ceb80499836347a3a5d436d0522c7f03"

[[env.staging.kv_namespaces]]
binding = "RATE_LIMITER"
id = "d590f25f9b3642d1ae5e9bc3ebb1ba78"

[[env.staging.d1_databases]]
binding = "AUDIT_DB"
database_name = "luna-proxy-audit-staging"
database_id = "fe91c742-20b1-4780-82d9-8cb145f395a5"

[env.staging.vars]
ENVIRONMENT = "staging"
LOG_LEVEL = "debug"
CORS_MODE = "public"
ALLOWED_ORIGINS = "https://staging.ai-gate.dev,https://staging-app.ai-gate.dev,http://localhost:3000,http://localhost:3002"
```

### luna-proxy-web/wrangler.toml
```toml
[env.staging]
name = "luna-proxy-web-frontend-staging"
routes = [
  { pattern = "staging-app.ai-gate.dev", custom_domain = true }
]

[[env.staging.d1_databases]]
binding = "DB"
database_name = "luna-proxy-users-staging"
database_id = "5ecb0455-e99a-4fa7-ba4d-e286574968e0"  # ✅ CRÉÉ

[[env.staging.kv_namespaces]]
binding = "RATE_LIMIT"
id = "cce8062a722b46a2ba1570073c073d3d"  # ✅ CRÉÉ

[env.staging.vars]
NEXT_PUBLIC_API_BASE = "https://staging.ai-gate.dev"
NEXT_PUBLIC_API_URL = "https://staging.ai-gate.dev"
INTERNAL_API_URL = "https://staging.ai-gate.dev"
AUTH_URL = "https://luna-proxy-web-frontend-staging.joffrey-vanasten.workers.dev"
NEXTAUTH_URL = "https://luna-proxy-web-frontend-staging.joffrey-vanasten.workers.dev"
ALLOWED_CORS_ORIGINS = "https://luna-proxy-web-frontend-staging.joffrey-vanasten.workers.dev,https://staging.ai-gate.dev"
AUTH_COOKIE_DOMAIN = ""  # Vide pour workers.dev
AUTH_TRUST_HOST = "true"
GOOGLE_CLIENT_ID = ""  # À configurer si OAuth staging souhaité
GITHUB_CLIENT_ID = ""  # À configurer si OAuth staging souhaité
```

## Secrets à configurer

### API Staging
```bash
cd luna-proxy-api

# Stripe (test mode)
wrangler secret put STRIPE_SECRET_KEY --env staging
wrangler secret put STRIPE_WEBHOOK_SECRET --env staging
wrangler secret put STRIPE_PRICE_STARTER --env staging
wrangler secret put STRIPE_PRICE_GROWTH --env staging

# Cloudflare TURN (peut partager avec prod)
wrangler secret put CF_TURN_API_TOKEN --env staging
wrangler secret put CF_ACCOUNT_ID --env staging

# Admin API
wrangler secret put ADMIN_API_KEY --env staging
wrangler secret put JWT_SECRET --env staging
wrangler secret put KEK_V1 --env staging
```

### Web Staging
```bash
cd luna-proxy-web

# NextAuth
wrangler secret put AUTH_SECRET --env staging
wrangler secret put NEXTAUTH_SECRET --env staging

# OAuth (apps staging dédiées)
wrangler secret put GOOGLE_CLIENT_SECRET --env staging
wrangler secret put GITHUB_CLIENT_SECRET --env staging

# Admin
wrangler secret put ADMIN_API_KEY --env staging
```

## Workflow de déploiement

### Déploiement staging
```bash
# API
cd luna-proxy-api
wrangler deploy --env staging

# Web
cd ../luna-proxy-web
npm run build:cf
npx wrangler deploy --env staging
```

### Tests staging
```bash
# 1. Tester l'API
curl https://staging.ai-gate.dev/health

# 2. Tester le web
open https://staging-app.ai-gate.dev

# 3. Tester OAuth
# - Se connecter avec Google/GitHub
# - Vérifier que les users vont dans luna-proxy-users-staging

# 4. Tester Stripe (test mode)
# - Upgrade vers Starter
# - Utiliser carte test: 4242 4242 4242 4242
# - Vérifier le webhook
```

### Promotion vers production
```bash
# 1. Tester en staging
# 2. Merger dans main
# 3. Déployer en production
cd luna-proxy-api && wrangler deploy --env production
cd ../luna-proxy-web && npm run build:cf && npx wrangler deploy --env production
```

## Monitoring

### Logs staging
```bash
# API
wrangler tail --env staging

# Web
wrangler tail --env staging
```

### Métriques
- Configurer des webhooks Sentry/DataDog séparés pour staging
- Utiliser des prefixes pour différencier les logs

## Checklist avant mise en prod

- [ ] DB D1 staging séparée créée
- [ ] KV namespaces staging créés
- [ ] Custom domains configurés
- [ ] OAuth apps staging créées
- [ ] Secrets Stripe test mode configurés
- [ ] Tous les secrets copiés en staging
- [ ] Tests e2e passent en staging
- [ ] Webhooks Stripe test mode configurés
- [ ] Documentation mise à jour

## Coûts estimés

- Custom domains: Gratuit (dans le plan Cloudflare)
- DB D1 staging: ~$0 (dans les limites free tier)
- KV staging: ~$0 (dans les limites free tier)
- OAuth apps: Gratuit
- Stripe test mode: Gratuit
- **Total: ~$0** (si dans les limites free tier)

## Bénéfices

✅ **Sécurité**: Aucun risque de corruption des données prod
✅ **Fiabilité**: Tests complets avant prod (OAuth, Stripe, etc.)
✅ **Debug**: Logs détaillés (LOG_LEVEL=debug) sans impacter prod
✅ **Confiance**: Détection des bugs avant qu'ils atteignent les users
✅ **Rapidité**: Itération rapide sans risque
