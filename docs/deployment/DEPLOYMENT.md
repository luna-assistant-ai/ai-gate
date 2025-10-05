# Guide de Déploiement AI Gate

> **Note**: Ce projet utilise un monorepo avec des sous-modules Git.
> Voir [README.md](../README.md) pour la structure complète.

## 🚀 Déploiement rapide

### Prérequis
```bash
# Clone with submodules
git clone --recursive https://github.com/luna-assistant-ai/ai-gate.git
cd ai-gate

# Or update existing submodules
git submodule update --init --recursive
```

### Staging
```bash
# API
cd luna-proxy-api
wrangler deploy --env staging

# Web
cd ../luna-proxy-web
npm run build:cf
wrangler deploy --env staging
```

### Production
```bash
# API
cd luna-proxy-api
wrangler deploy

# Web
cd ../luna-proxy-web
npm run build:cf
wrangler deploy --env production
```

## ⚠️ Problèmes connus et solutions

### 1. Erreur 522 - Worker-to-Worker timeout
**Symptôme** : `error code: 522` lors d'appels entre workers via custom domain

**Solution** : Utiliser l'URL `.workers.dev` pour les appels internes
```typescript
// ❌ MAUVAIS - timeout
const API_URL = "https://api.ai-gate.dev";

// ✅ BON - utilise workers.dev en interne
const INTERNAL_API_URL = "https://luna-proxy-api.joffrey-vanasten.workers.dev";
```

### 2. Base de données D1 vide en production
**Symptôme** : Tables manquantes, erreurs lors des requêtes

**Solution** : Exécuter le schema sur la base REMOTE
```bash
cd luna-proxy-web
wrangler d1 execute luna-proxy-users --file=schema.sql --remote
```

### 3. Secrets non accessibles
**Symptôme** : `process.env.SECRET` est `undefined`

**Solution** : Les secrets sont accessibles via `process.env`, PAS via `getCloudflareContext()`
```typescript
// ✅ BON
const secret = process.env.ADMIN_API_KEY;

// ❌ MAUVAIS
const { env } = getCloudflareContext();
const secret = env.ADMIN_API_KEY; // undefined!
```

### 4. "No deploy targets" warning
**Symptôme** : Déploiement réussi mais changements non visibles

**Cause** : Aucune route configurée dans wrangler.toml

**Solution** : Les routes sont gérées via Cloudflare Dashboard pour le domaine principal

### 5. Context/env non accessible dans API routes
**Symptôme** : `context?.env?.DB` est `undefined`

**Solution** : Utiliser `getCloudflareContext()` pour OpenNext
```typescript
import { getCloudflareContext } from '@opennextjs/cloudflare';

const { env } = getCloudflareContext();
const db = env.DB;
```

### 6. Variables d'environnement manquantes en production
**Symptôme** : `process.env.INTERNAL_API_URL` est `undefined` en production, erreur 522

**Cause** : Les variables définies dans `[vars]` ne sont PAS héritées par `[env.production.vars]`

**Solution** : Redéfinir TOUTES les variables dans `[env.production.vars]`
```toml
# ❌ MAUVAIS - Variables manquantes en production
[vars]
INTERNAL_API_URL = "https://luna-proxy-api.joffrey-vanasten.workers.dev"

[env.production.vars]
NEXT_PUBLIC_API_URL = "https://api.ai-gate.dev"
# INTERNAL_API_URL manquante !

# ✅ BON - Variables redéfinies
[vars]
INTERNAL_API_URL = "https://luna-proxy-api.joffrey-vanasten.workers.dev"

[env.production.vars]
NEXT_PUBLIC_API_URL = "https://api.ai-gate.dev"
INTERNAL_API_URL = "https://luna-proxy-api.joffrey-vanasten.workers.dev"  # Redéfinie !
```

**Note** : Même chose pour KV namespaces et D1 databases - tout doit être redéfini par environnement.

### 7. OAuth user ID mismatch avec D1
**Symptôme** : `D1_ERROR: FOREIGN KEY constraint failed` lors de la création de projet

**Cause** : L'ID utilisateur dans le JWT NextAuth diffère de l'ID en base D1

**Solution** : Vérifier l'utilisateur par email et utiliser l'ID existant
```typescript
// Check by email first to handle ID mismatches
let userExists = await db
  .prepare('SELECT id FROM users WHERE email = ?')
  .bind(session.user.email)
  .first();

let actualUserId = session.user.id;

if (userExists && userExists.id !== session.user.id) {
  // User exists with different ID - use existing ID
  actualUserId = userExists.id;
}

// Use actualUserId for foreign key
await db.prepare('INSERT INTO user_projects (...) VALUES (?, ...)')
  .bind(projectId, actualUserId, ...)
  .run();
```

## 📋 Checklist pré-déploiement

### Avant chaque déploiement staging
- [ ] Variables d'environnement correctes dans `wrangler.toml`
- [ ] Secrets configurés : `wrangler secret list --env staging`
- [ ] Tests locaux passent
- [ ] Build réussit : `npm run build:cf`

### Avant chaque déploiement production
- [ ] Staging testé et validé
- [ ] Base D1 initialisée : `wrangler d1 execute --remote --file=schema.sql`
- [ ] Secrets en production : `wrangler secret list`
- [ ] Variables d'environnement vérifiées dans `[env.production.vars]`
  - [ ] `INTERNAL_API_URL` présente
  - [ ] `NEXT_PUBLIC_API_URL` présente
  - [ ] KV namespace `RATE_LIMIT` configuré
  - [ ] D1 database `DB` configurée
- [ ] Routes configurées (via Dashboard si nécessaire)
- [ ] Commit & push du code

### Après déploiement
- [ ] Tester signup/login
- [ ] Tester création de projet
- [ ] Lancer le smoke test staging (`OPENAI_TEST_KEY=… ./scripts/smoke-staging.sh`)
- [ ] Révoquer la clé OpenAI de test utilisée pour le smoke test
- [ ] Vérifier logs : `wrangler tail [worker-name]`
- [ ] Tester les routes principales

## 🔧 Scripts utiles

### Vérifier le déploiement
```bash
# Check API health
curl https://api.ai-gate.dev/health

# Check Web
curl -I https://www.ai-gate.dev

# Voir les logs en temps réel
wrangler tail luna-proxy-web-frontend --format pretty
wrangler tail luna-proxy-api --format pretty
```

### Smoke test staging
```bash
cd ~/ai-gate   # ou le chemin vers votre clone du monorepo
export OPENAI_TEST_KEY="sk-proj-..."   # clé OpenAI dédiée aux tests
./scripts/smoke-staging.sh

# Le script crée un utilisateur jetable, se connecte, crée puis supprime un projet.
# À la fin, révoque immédiatement la clé OpenAI utilisée.
```

### Debugging
```bash
# Liste des déploiements
wrangler deployments list --name [worker-name]

# Liste des secrets
wrangler secret list
wrangler secret list --env staging

# Liste des bases D1
wrangler d1 list

# Vérifier les tables
wrangler d1 execute luna-proxy-users --remote --command "SELECT name FROM sqlite_master WHERE type='table';"
```

## 🏗️ Architecture des URLs

### Production
- **Public API** : `https://api.ai-gate.dev` (pour clients externes)
- **Internal API** : `https://luna-proxy-api.joffrey-vanasten.workers.dev` (appels worker-to-worker)
- **Web** : `https://www.ai-gate.dev`

### Staging
- **API** : `https://staging.ai-gate.dev`
- **Web** : `https://luna-proxy-web-frontend-staging.joffrey-vanasten.workers.dev`

## 📦 Variables d'environnement requises

### luna-proxy-api (Production)
```toml
[vars]
ENVIRONMENT = "production"
LOG_LEVEL = "info"
CORS_MODE = "enterprise"
ALLOWED_ORIGINS = "https://ai-gate.dev,https://www.ai-gate.dev,..."
```

**Secrets requis** :
- `ADMIN_API_KEY`
- `JWT_SECRET`
- `KEK_V1`
- `CF_TURN_API_TOKEN`
- `CF_ACCOUNT_ID`

### luna-proxy-web (Production)
```toml
[vars]
NEXT_PUBLIC_API_BASE = "https://api.ai-gate.dev"
NEXT_PUBLIC_API_URL = "https://api.ai-gate.dev"
INTERNAL_API_URL = "https://luna-proxy-api.joffrey-vanasten.workers.dev"  # IMPORTANT!
AUTH_URL = "https://www.ai-gate.dev"
GOOGLE_CLIENT_ID = "..."
GITHUB_CLIENT_ID = "..."
```

**Secrets requis** :
- `ADMIN_API_KEY`
- `AUTH_SECRET`
- `GOOGLE_CLIENT_SECRET`
- `GITHUB_CLIENT_SECRET`

## 🔐 Gestion des secrets

### Ajouter un secret
```bash
wrangler secret put SECRET_NAME
wrangler secret put SECRET_NAME --env staging
```

### Lister les secrets
```bash
wrangler secret list
wrangler secret list --env staging
```

### ⚠️ Important
- Les secrets sont par environnement (production vs staging)
- Les secrets ne sont PAS versionnés dans git
- Toujours vérifier que les secrets existent avant de déployer

## 🐛 Debugging en production

### Si la création de compte ne marche pas
1. Vérifier que la DB est initialisée : `wrangler d1 list`
2. Vérifier les tables : voir commande ci-dessus
3. Check logs : `wrangler tail luna-proxy-web-frontend --format pretty`

### Si la création de projet ne marche pas
1. Vérifier `INTERNAL_API_URL` dans wrangler.toml
2. Vérifier `ADMIN_API_KEY` dans les secrets web ET api
3. Tester l'API directement : `curl https://api.ai-gate.dev/health`
4. Check les logs des deux workers simultanément

### Hard refresh
Toujours faire un hard refresh après déploiement :
- Mac : `Cmd + Shift + R`
- Windows/Linux : `Ctrl + Shift + R`

## 📞 Support

En cas de problème persistant :
1. Vérifier les logs cloudflare
2. Vérifier le status Cloudflare : https://www.cloudflarestatus.com/
3. Rollback si nécessaire : `wrangler rollback [version-id]`
