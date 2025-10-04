# Instructions pour Claude - Luna Proxy Project

## 🎯 Contexte du projet

Luna Proxy est une plateforme de gestion de proxies AI déployée sur Cloudflare Workers avec :
- **luna-proxy-api** : API backend (TypeScript + Hono)
- **luna-proxy-web** : Frontend Next.js 15 avec OpenNext
- **luna-proxy-dashboard** : Dashboard de monitoring

## 🚨 Pièges critiques à éviter

### 1. Worker-to-Worker Communication
**TOUJOURS** utiliser `INTERNAL_API_URL` (workers.dev) pour les appels entre workers.
- ❌ `https://api.ai-gate.dev` → timeout 522
- ✅ `https://luna-proxy-api.joffrey-vanasten.workers.dev` → fonctionne

### 2. Accès aux variables Cloudflare
Dans les API routes Next.js :
```typescript
// ✅ BON
import { getCloudflareContext } from '@opennextjs/cloudflare';
const { env } = getCloudflareContext();
const db = env.DB;

// ❌ MAUVAIS
const db = context?.env?.DB; // undefined!
```

### 3. Secrets vs Variables
- **Secrets** : Accessibles via `process.env.SECRET_NAME`
- **Variables** : Définies dans `wrangler.toml` [vars]
- Les secrets ne sont PAS dans `getCloudflareContext().env`

### 4. Base de données D1
Toujours exécuter avec `--remote` pour la production :
```bash
wrangler d1 execute DB_NAME --file=schema.sql --remote
```

### 5. Déploiement
- Production : `wrangler deploy --name worker-name` (PAS `--env production`)
- Staging : `wrangler deploy --env staging`
- Toujours attendre 30s après deploy avant de tester

## 📁 Structure du projet

```
luna-proxy-projects/
├── luna-proxy-api/          # Backend API
│   ├── src/
│   ├── wrangler.toml
│   └── package.json
├── luna-proxy-web/          # Frontend Next.js
│   ├── src/app/
│   ├── wrangler.toml
│   ├── schema.sql          # DB schema
│   └── package.json
├── luna-proxy-dashboard/    # Dashboard
└── DEPLOYMENT.md           # Guide de déploiement
```

## 🔑 Secrets requis

### luna-proxy-api
- ADMIN_API_KEY
- JWT_SECRET
- KEK_V1
- CF_TURN_API_TOKEN
- CF_ACCOUNT_ID
- CF_AUTH_EMAIL (staging uniquement)
- CF_AUTH_KEY (staging uniquement)

### luna-proxy-web
- ADMIN_API_KEY (même que l'API)
- AUTH_SECRET
- GOOGLE_CLIENT_SECRET
- GITHUB_CLIENT_SECRET

## 🛠️ Commandes fréquentes

### Build & Deploy
```bash
# Web (Production)
cd luna-proxy-web
npm run build:cf
wrangler deploy --name luna-proxy-web-frontend

# API (Production)
cd luna-proxy-api
wrangler deploy

# Staging
wrangler deploy --env staging
```

### Debug
```bash
# Logs temps réel
wrangler tail luna-proxy-web-frontend --format pretty
wrangler tail luna-proxy-api --format pretty

# Vérifier déploiement
wrangler deployments list --name worker-name

# Lister secrets
wrangler secret list
wrangler secret list --env staging
```

### Base de données
```bash
# Init DB production
cd luna-proxy-web
wrangler d1 execute luna-proxy-users --file=schema.sql --remote

# Vérifier tables
wrangler d1 execute luna-proxy-users --remote --command "SELECT name FROM sqlite_master WHERE type='table';"

# Lister les bases
wrangler d1 list
```

## ⚡ Workflow de déploiement

1. **Développement local**
   - Tester en local
   - Commit changements

2. **Deploy en staging**
   - `wrangler deploy --env staging`
   - Tester sur staging
   - Valider fonctionnalités

3. **Deploy en production**
   - Vérifier secrets : `wrangler secret list`
   - Vérifier DB : `wrangler d1 list`
   - Build : `npm run build:cf`
   - Deploy : `wrangler deploy --name worker-name`
   - Attendre 30s
   - Hard refresh navigateur
   - Tester : signup, login, création projet

4. **Monitoring**
   - Tail logs : `wrangler tail worker-name`
   - Check health : `curl https://api.ai-gate.dev/health`

## 🐛 Debugging checklist

### Si signup ne marche pas
- [ ] DB initialisée ? `wrangler d1 list`
- [ ] Tables créées ? Voir commande ci-dessus
- [ ] `getCloudflareContext()` utilisé correctement ?
- [ ] Logs : `wrangler tail luna-proxy-web-frontend`

### Si création projet ne marche pas
- [ ] `INTERNAL_API_URL` configuré dans wrangler.toml ?
- [ ] `ADMIN_API_KEY` dans secrets web ET api ?
- [ ] API répond ? `curl https://luna-proxy-api.joffrey-vanasten.workers.dev/health`
- [ ] Erreur 522 ? → vérifier INTERNAL_API_URL
- [ ] Logs API : `wrangler tail luna-proxy-api`

### Si erreur 522
→ Appel worker-to-worker via custom domain
→ Solution : utiliser INTERNAL_API_URL (.workers.dev)

## 📝 Conventions de commit

Utiliser conventional commits :
- `feat:` nouvelle fonctionnalité
- `fix:` correction de bug
- `docs:` documentation
- `chore:` maintenance
- `refactor:` refactoring

## 🚀 URLs importantes

### Production
- Web : https://www.ai-gate.dev
- API publique : https://api.ai-gate.dev
- API interne : https://luna-proxy-api.joffrey-vanasten.workers.dev

### Staging
- Web : https://luna-proxy-web-frontend-staging.joffrey-vanasten.workers.dev
- API : https://staging.ai-gate.dev

## 💡 Tips pour Claude

1. Toujours vérifier que `INTERNAL_API_URL` est utilisé pour les appels serveur
2. Ne jamais déployer sans vérifier les secrets avant
3. Attendre 30s après deploy avant de dire "c'est déployé"
4. Utiliser `getCloudflareContext()` dans les API routes Next.js
5. Toujours commit les changements de wrangler.toml
6. Ne pas créer de nouveaux fichiers MD sans demander

## 🔄 Processus de résolution de problèmes

1. **Identifier** : Logs + error messages
2. **Vérifier** : Secrets, variables, DB
3. **Tester** : Appels directs API, curl
4. **Corriger** : Code changes
5. **Build** : `npm run build:cf`
6. **Deploy** : `wrangler deploy`
7. **Valider** : Tests manuels + logs
8. **Documenter** : Mettre à jour DEPLOYMENT.md si nouveau piège

## ⚠️ Ne JAMAIS faire

- ❌ Déployer sans build
- ❌ Utiliser custom domain pour worker-to-worker
- ❌ Oublier `--remote` pour D1 en production
- ❌ Créer des MD files sans demander
- ❌ Push des secrets dans git
- ❌ Utiliser `context?.env` au lieu de `getCloudflareContext()`

## ✅ Toujours faire

- ✅ Vérifier secrets avant deploy
- ✅ Attendre 30s après deploy
- ✅ Hard refresh navigateur
- ✅ Check logs après deploy
- ✅ Tester en staging d'abord
- ✅ Commit + push après deploy réussi
