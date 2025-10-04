# Cloudflare Calls API Token Setup

**Date**: 2025-10-03
**Status**: Legacy auth fonctionne (CF_AUTH_EMAIL + CF_AUTH_KEY)
**Recommandé**: Migrer vers Bearer token (meilleures pratiques de sécurité)

---

## 🎯 Pourquoi migrer vers Bearer token ?

**Actuellement** : On utilise **Global API Key** (legacy)
- ✅ Fonctionne bien
- ⚠️ Accès complet à tout le compte Cloudflare
- ⚠️ Rotation difficile

**Recommandé** : Utiliser **API Token** (scoped)
- ✅ Permissions limitées (Cloudflare Calls seulement)
- ✅ Rotation facile
- ✅ Meilleure sécurité (principe du moindre privilège)

---

## 📝 Créer un token Cloudflare Calls

### Étape 1: Accéder au dashboard

1. Aller sur https://dash.cloudflare.com/profile/api-tokens
2. Cliquer **"Create Token"**

### Étape 2: Configurer les permissions

**Option A - Template personnalisé** (recommandé):
```
Template: Start with a blank template

Permissions:
  Account → Cloudflare Calls → Edit

Account Resources:
  Include → <Votre compte> (CF_ACCOUNT_ID)

Client IP Address Filtering (optionnel):
  Is in → <IPs de vos Workers si statiques>

TTL:
  Expire le → <Jamais> ou définir une date de rotation
```

**Option B - API Token rapide**:
1. Chercher "Calls" dans les templates
2. Si pas de template: utiliser "Custom Token"
3. Sélectionner:
   - **Permission**: `Account` → `Cloudflare Calls` → `Edit`
   - **Account**: Votre compte (celui avec `CF_ACCOUNT_ID`)

### Étape 3: Créer et copier le token

1. Cliquer **"Continue to summary"**
2. Vérifier les permissions
3. Cliquer **"Create Token"**
4. **COPIER LE TOKEN** (vous ne le reverrez pas !)

Le token ressemble à :
```
wABCDEF1234567890abcdefGHIJKLMNOPQRSTUVWXYZ_01234567890abcdefghij
```

### Étape 4: Tester le token

```bash
# Remplacer YOUR_TOKEN et YOUR_ACCOUNT_ID
export CF_TURN_API_TOKEN="wABCDEF..."
export CF_ACCOUNT_ID="your-account-id-here"

# Test de vérification du token
curl -s "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CF_TURN_API_TOKEN" | jq .

# Expected output:
# {
#   "success": true,
#   "result": {
#     "id": "...",
#     "status": "active"
#   }
# }

# Test de création TURN credentials
curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/calls/turn_keys" \
  -H "Authorization: Bearer $CF_TURN_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ttl": 600}' | jq .

# Expected output:
# {
#   "success": true,
#   "result": {
#     "uid": "4d2e1ff...",
#     "secret": "c42e53a...",
#     "ttl": 600,
#     "expires_at": "2025-10-03T12:10:00Z"
#   }
# }
```

---

## 🚀 Déployer le token dans Workers

### Configurer le secret

```bash
cd luna-proxy-api

# Ajouter le token comme secret
wrangler secret put CF_TURN_API_TOKEN
# Paste: wABCDEF1234567890...

# Vérifier les secrets
wrangler secret list

# Expected output:
# [
#   { "name": "CF_TURN_API_TOKEN", "type": "secret_text" },
#   { "name": "CF_AUTH_EMAIL", "type": "secret_text" },
#   { "name": "CF_AUTH_KEY", "type": "secret_text" },
#   ...
# ]
```

### Vérifier le fonctionnement

Le code dans [src/utils/turn.ts](luna-proxy-api/src/utils/turn.ts#L54-71) essaie automatiquement :

1. **Bearer token** (`CF_TURN_API_TOKEN`) en premier
2. **Legacy auth** (`CF_AUTH_EMAIL` + `CF_AUTH_KEY`) en fallback si Bearer échoue
3. **STUN-only** si tout échoue

```bash
# Test l'endpoint TURN en production
curl -s https://luna-proxy-api.joffrey-vanasten.workers.dev/turn-credentials | jq .

# Vérifier les logs pour voir quelle auth a été utilisée
wrangler tail --format pretty

# Expected log:
# "Attempting Cloudflare Calls auth via Bearer token"
# "Bearer response status: 200"
# "Generated robust credentials with 6 ICE servers (2 STUN + 4 TURN) { auth_method: 'bearer' }"
```

---

## 📊 Observabilité

### Vérifier quelle méthode d'auth est utilisée

```bash
# Créer une session et vérifier les audit logs
curl -s https://luna-proxy-api.joffrey-vanasten.workers.dev/audit-logs?limit=1 \
  -H "X-Admin-API-Key: $ADMIN_API_KEY" | jq '.'

# Chercher dans metadata:
# {
#   "turn_auth_method": "bearer",  // ou "legacy" ou "stun_only"
#   "turn_enabled": true,
#   "project_id": "..."
# }
```

### Logs Cloudflare Workers

```bash
wrangler tail --format pretty

# Logs attendus lors d'une session:
# - "Attempting Cloudflare Calls auth via Bearer token"
# - "Bearer response status: 200"
# - "Generated robust credentials with 6 ICE servers { auth_method: 'bearer' }"
```

---

## 🔄 Rotation du token

### Quand rotater ?

- **Compromis de sécurité** : Immédiatement
- **Rotation planifiée** : Tous les 90 jours (bonne pratique)
- **Changement de permissions** : Si besoin d'ajuster les scopes

### Procédure de rotation

1. **Créer nouveau token** (comme ci-dessus)
2. **Tester le nouveau token** (curl test)
3. **Mettre à jour le secret Worker**:
   ```bash
   wrangler secret put CF_TURN_API_TOKEN
   # Paste: <nouveau token>
   ```
4. **Vérifier en prod** (créer une session de test)
5. **Révoquer l'ancien token** (Cloudflare dashboard)

**Note**: Grâce au fallback legacy, pas de downtime si le nouveau token échoue.

---

## ⚠️ Troubleshooting

### Token invalide (401/403)

**Symptôme**: Logs montrent "Bearer auth failed, falling back to legacy"

**Solutions**:
1. Vérifier le token avec `curl .../user/tokens/verify`
2. Vérifier les permissions : `Account → Cloudflare Calls → Edit`
3. Vérifier l'Account ID (doit matcher `CF_ACCOUNT_ID`)
4. Le token peut avoir expiré (vérifier TTL)

### Pas de TURN (seulement STUN)

**Symptôme**: Seulement 2 ICE servers au lieu de 6

**Solutions**:
1. Vérifier les logs : `auth_method: 'stun_only'`
2. Vérifier que `CF_TURN_API_TOKEN` OU `CF_AUTH_EMAIL+KEY` sont configurés
3. Tester manuellement l'API Cloudflare Calls (curl)
4. Vérifier le compte a Cloudflare Calls activé

### Rate limit Cloudflare API

**Symptôme**: HTTP 429 de l'API Cloudflare

**Solutions**:
1. Augmenter `TURN_MICRO_CACHE_MS` (défaut 30s)
2. Vérifier pas de boucle infinie dans le code
3. Le cache devrait limiter les appels API

---

## ✅ Checklist de migration

- [ ] Créer token Bearer avec permission "Cloudflare Calls: Edit"
- [ ] Tester token avec `curl .../user/tokens/verify`
- [ ] Tester TURN avec `curl .../calls/turn_keys`
- [ ] Déployer avec `wrangler secret put CF_TURN_API_TOKEN`
- [ ] Vérifier prod avec `/turn-credentials`
- [ ] Vérifier logs montrent `auth_method: 'bearer'`
- [ ] Créer session test et vérifier 6 ICE servers
- [ ] Documenter date de rotation (90 jours)
- [ ] (Optionnel) Révoquer CF_AUTH_KEY legacy

---

## 📚 Ressources

- [Cloudflare Calls Docs](https://developers.cloudflare.com/calls/)
- [Cloudflare API Tokens](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)
- [TURN Protocol (RFC 8656)](https://datatracker.ietf.org/doc/html/rfc8656)
- [WebRTC ICE](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Protocols#ice)

---

## 🔐 Sécurité

**À FAIRE** :
- ✅ Utiliser API Token (scoped) plutôt que Global API Key
- ✅ Configurer TTL sur les tokens (rotation automatique)
- ✅ Limiter IP addresses si Workers ont IPs statiques
- ✅ Monitorer usage via audit logs

**À NE PAS FAIRE** :
- ❌ Committer le token dans git
- ❌ Partager le token en clair (Slack, email, etc.)
- ❌ Donner plus de permissions que nécessaire
- ❌ Ignorer les logs de sécurité Cloudflare
