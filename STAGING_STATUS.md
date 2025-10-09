# Statut Staging - AI Gate

## ✅ Améliorations appliquées aujourd'hui

### 1. **Isolation des données (CRITIQUE)**
- ✅ **DB D1 staging créée** : `luna-proxy-users-staging` (5ecb0455-e99a-4fa7-ba4d-e286574968e0)
  - Plus de risque de corruption des données prod
  - Tests staging isolés de la prod

- ✅ **KV Rate Limit staging créé** : `RATE_LIMIT_STAGING` (cce8062a722b46a2ba1570073c073d3d)
  - Rate limiting indépendant pour staging

### 2. **Configuration mise à jour**
- ✅ `luna-proxy-web/wrangler.toml` env.staging mis à jour avec :
  - Nouvelle DB D1 staging
  - Nouveau KV namespace
  - INTERNAL_API_URL pointant vers staging.ai-gate.dev

### 3. **Infrastructure actuelle**
- ✅ API staging: `staging.ai-gate.dev` → `luna-proxy-api-staging` (déjà configuré)
- ✅ Web staging: `luna-proxy-web-frontend-staging.joffrey-vanasten.workers.dev`
- ✅ DB D1 API staging: `luna-proxy-audit-staging` (déjà créée)

## 🟡 Prochaines étapes recommandées (optionnel)

### Phase 2 : OAuth staging (non-bloquant)
Si tu veux tester OAuth en staging :
1. Créer une OAuth app Google staging
2. Créer une OAuth app GitHub staging
3. Configurer les secrets :
   ```bash
   cd luna-proxy-web
   wrangler secret put GOOGLE_CLIENT_SECRET --env staging
   wrangler secret put GITHUB_CLIENT_SECRET --env staging
   wrangler secret put AUTH_SECRET --env staging
   wrangler secret put NEXTAUTH_SECRET --env staging
   ```

### Phase 3 : Stripe test mode (non-bloquant)
Pour tester les paiements en staging :
1. Récupérer les clés Stripe test mode (sk_test_...)
2. Créer les produits Stripe en test mode
3. Configurer les secrets :
   ```bash
   cd luna-proxy-api
   wrangler secret put STRIPE_SECRET_KEY --env staging
   wrangler secret put STRIPE_WEBHOOK_SECRET --env staging
   wrangler secret put STRIPE_PRICE_STARTER --env staging
   wrangler secret put STRIPE_PRICE_GROWTH --env staging
   ```

### Phase 4 : Custom domain web staging (nice-to-have)
Configurer un custom domain pour le web staging :
- Créer `staging-app.ai-gate.dev` → `luna-proxy-web-frontend-staging`
- Mettre à jour AUTH_URL et NEXTAUTH_URL dans wrangler.toml

## 📊 Comparaison Prod vs Staging

| Ressource | Production | Staging | Isolé ? |
|-----------|-----------|---------|---------|
| **API Worker** | luna-proxy-api | luna-proxy-api-staging | ✅ |
| **API Domain** | api.ai-gate.dev | staging.ai-gate.dev | ✅ |
| **API DB D1** | luna-proxy-audit | luna-proxy-audit-staging | ✅ |
| **API KV** | 3 namespaces prod | 3 namespaces staging | ✅ |
| **Web Worker** | luna-proxy-web-frontend | luna-proxy-web-frontend-staging | ✅ |
| **Web Domain** | www.ai-gate.dev | workers.dev URL | ⚠️ (OK) |
| **Web DB D1** | luna-proxy-users | luna-proxy-users-staging | ✅ |
| **Web KV** | RATE_LIMIT prod | RATE_LIMIT staging | ✅ |
| **OAuth** | Google + GitHub prod | Désactivé | ⚠️ (OK) |
| **Stripe** | Live mode | Non configuré | ⚠️ (OK) |

## 🎯 État actuel : SÉCURISÉ

**Avant aujourd'hui :**
- 🔴 **RISQUE CRITIQUE** : Staging partageait la DB prod → risque de corruption

**Maintenant :**
- ✅ **SÉCURISÉ** : Toutes les données staging sont isolées
- ✅ **PRÊT** : Staging peut être utilisé pour tester sans risque
- ⚠️ **LIMITÉ** : OAuth et Stripe non configurés (mais non bloquant)

## 🚀 Comment utiliser staging

### Tester l'API staging
```bash
# Health check
curl https://staging.ai-gate.dev/health

# Metrics
curl https://staging.ai-gate.dev/metrics
```

### Tester le web staging
```bash
# Ouvrir dans le navigateur
open https://luna-proxy-web-frontend-staging.joffrey-vanasten.workers.dev
```

### Déployer en staging
```bash
# API
cd luna-proxy-api
wrangler deploy --env staging

# Web
cd luna-proxy-web
npm run build:cf
npx wrangler deploy --env staging
```

### Voir les logs staging
```bash
# API
cd luna-proxy-api
wrangler tail --env staging

# Web
cd luna-proxy-web
wrangler tail --env staging
```

## 📝 Notes importantes

1. **OAuth désactivé en staging** : Pour l'instant, tu ne peux pas te connecter avec Google/GitHub en staging. Il faut créer des OAuth apps dédiées staging si besoin.

2. **Stripe non configuré en staging** : Les paiements ne fonctionneront pas en staging. Il faut configurer Stripe test mode si besoin.

3. **Custom domain web** : Le web staging utilise l'URL workers.dev. Si tu veux un custom domain (staging-app.ai-gate.dev), il faut le configurer dans Cloudflare.

4. **Tous les autres secrets** : Il faut aussi copier les secrets de prod vers staging (ADMIN_API_KEY, JWT_SECRET, etc.) si tu veux tester les fonctionnalités complètes.

## ✅ Conclusion

**L'environnement staging est maintenant sécurisé et isolé de la production !** 🎉

Tu peux l'utiliser pour tester sans risque de corrompre les données prod. Les fonctionnalités OAuth et Stripe peuvent être ajoutées plus tard si besoin.

Pour plus de détails sur les améliorations futures, voir [STAGING_IMPROVEMENTS.md](STAGING_IMPROVEMENTS.md).
