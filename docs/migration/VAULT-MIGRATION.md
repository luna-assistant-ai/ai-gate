# Migration Vault-Only (2025-10-04)

## 🎯 Objectif

Forcer le mode **vault-only** pour renforcer la sécurité : les clés OpenAI ne peuvent plus être envoyées directement via headers. Tous les clients doivent utiliser soit :
1. **JWT tokens** (commercial flow)
2. **project_id** (vault flow)

## ✅ Changements effectués

### API (`luna-proxy-api`)

#### 1. `/session` endpoint ([src/index.ts:412-441](luna-proxy-api/src/index.ts:412-441))
- ❌ **SUPPRIMÉ** : `X-OpenAI-API-Key` header pass-through
- ❌ **SUPPRIMÉ** : Bearer token non-JWT (direct API key)
- ✅ **CONSERVÉ** : JWT token validation
- ✅ **CONSERVÉ** : `project_id` vault flow
- ✅ **AMÉLIORÉ** : Message d'erreur explicite mentionnant "vault-only"

**Avant** :
```typescript
// Acceptait X-OpenAI-API-Key header
apiKey = request.headers.get('X-OpenAI-API-Key');

// Acceptait Bearer token non-JWT
if (!jwtPayload) {
  apiKey = token; // Direct API key
}
```

**Après** :
```typescript
// Seulement JWT ou project_id
if (jwtPayload) {
  apiKey = client.openaiApiKey; // From managed client
}

if (!apiKey) {
  // Try project_id vault flow
  const k = await loadProjectKey(env, projectId);
  if (k) apiKey = k;
}
```

#### 2. Nettoyage du code
- ❌ **SUPPRIMÉ** : Anciennes routes Express (`src/routes/`)
- ❌ **SUPPRIMÉ** : Fichiers backup (`index-old.ts`, `index.ts.backup`)

### Web (`luna-proxy-web`)

#### 1. Playground ([src/app/playground/page.tsx](luna-proxy-web/src/app/playground/page.tsx:11-14))
- ❌ **SUPPRIMÉ** : Input `apiKey` (BYOK fallback)
- ✅ **UNIQUEMENT** : Input `project_id` (vault-only)
- ✅ **AJOUTÉ** : Security notice expliquant le vault-only
- ✅ **MIS À JOUR** : Code snippet montrant le vault flow complet
- ✅ **MIS À JOUR** : Instructions AI assistant (zero-trust messaging)

#### 2. Landing Page ([src/app/page.tsx](luna-proxy-web/src/app/page.tsx:311-335))
- ❌ **SUPPRIMÉ** : Exemple avec `X-OpenAI-API-Key` header
- ✅ **REMPLACÉ** : Exemple avec `project_id` (vault-only)
- ✅ **MIS À JOUR** : Bullet points sécurité (vault-encrypted, ephemeral tokens)

#### 3. Helpers ([src/lib/api.ts](luna-proxy-web/src/lib/api.ts:1-4))
- ❌ **SUPPRIMÉ** : Fonction `fetchSession(body, apiKey)`
- ✅ **AJOUTÉ** : Commentaire redirigeant vers playground/page.tsx

#### 4. Tests ([src/__tests__/api.test.ts](luna-proxy-web/src/__tests__/api.test.ts:13-14))
- ❌ **SUPPRIMÉ** : Tests `fetchSession` (obsolète)
- ✅ **CONSERVÉ** : Tests `fetchMetricsText` et `fetchMetricsJson`

## 🧪 Tests

### Script de test créé : [test-vault-only.sh](test-vault-only.sh:1)

Vérifie que :
1. ❌ `X-OpenAI-API-Key` header est rejeté (401)
2. ❌ Bearer token non-JWT est rejeté (401)
3. ❌ Requête sans auth est rejetée (401) avec message "vault-only"

### Validation locale
```bash
# Type-check
cd luna-proxy-web
npm run type-check  # ✅ PASS

# API build
cd luna-proxy-api
wrangler deploy --dry-run  # ✅ PASS
```

## 📝 Documentation mise à jour

### Messaging sécurité

**Avant** : "BYOK (Bring Your Own Key) - We never store your key"

**Après** : "Vault-only security - API keys encrypted in vault, never exposed to clients"

### Exemples de code

**Avant** :
```javascript
headers: {
  'X-OpenAI-API-Key': YOUR_KEY
}
```

**Après** :
```javascript
body: JSON.stringify({
  project_id: 'proj_123' // Secure vault-only!
})
```

## 🚀 Déploiement

### Pré-requis
1. Clés OpenAI déjà déposées dans vault via `/projects/key`
2. Users avec `project_id` valides

### Commandes
```bash
# 1. API
cd luna-proxy-api
wrangler deploy

# 2. Web
cd luna-proxy-web
npm run build:cf
wrangler deploy --env production

# 3. Tester
./test-vault-only.sh
```

## ⚠️ Breaking Changes

### Pour les clients existants

**SI** votre code utilisait `X-OpenAI-API-Key` header :
```javascript
// ❌ NE MARCHE PLUS
headers: { 'X-OpenAI-API-Key': 'sk-...' }
```

**MIGRATION** :
1. Déposer votre clé une fois via `/projects/key` (admin only)
2. Utiliser `project_id` dans `/session`

```javascript
// ✅ NOUVEAU CODE
body: JSON.stringify({
  project_id: 'proj_your_id',
  model: 'gpt-4o-realtime-preview',
  voice: 'echo'
})
```

## 🔒 Bénéfices sécurité

1. **Zero-trust** : Clés OpenAI jamais exposées côté client
2. **Audit trail** : Tous les accès vault sont loggés
3. **Rotation facile** : Clés peuvent être changées sans toucher au code client
4. **Tokens éphémères** : client_secret expire en ~60s
5. **Rate limiting** : Max 5 sessions concurrentes par projet

## 📊 Métriques attendues

Après déploiement, vérifier :
- `error_rate` : Peut augmenter temporairement (clients non migrés)
- `vault_hits` : Doit être 100% des sessions
- `audit_logs` : `vault_key_loaded` pour chaque session

## 🆘 Rollback

Si problème critique :

```bash
# API
cd luna-proxy-api
git revert HEAD
wrangler deploy

# Web
cd luna-proxy-web
git revert HEAD
npm run build:cf
wrangler deploy --env production
```

## ✅ Checklist déploiement

- [x] Code modifié (API + Web)
- [x] Type-check validé
- [x] Build validé (dry-run)
- [x] Script de test créé
- [ ] Tests exécutés sur staging
- [ ] Déployé en production
- [ ] Tests exécutés sur production
- [ ] Monitoring vérifié (error rate stable)
- [ ] Documentation mise à jour

---

**Date** : 2025-10-04
**Auteur** : Claude + Joffrey
**Status** : ✅ Ready to deploy
