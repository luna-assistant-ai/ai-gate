# Vault + Ephemeral Token Flow

**Status**: ✅ Production Ready
**Date**: 2025-10-03
**API**: https://luna-proxy-api.joffrey-vanasten.workers.dev

---

## 🎯 Objectif

Les apps clientes **n'exposent jamais** de clé OpenAI longue durée :
1. Client colle sa clé **une fois** (via admin)
2. AI-Gate la **chiffre** et la stocke (vault AES-256-GCM)
3. À chaque session, AI-Gate **mint** un token éphémère (~60s) côté OpenAI
4. Client **consomme** le token éphémère pour WebRTC

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  1. Admin enregistre clé OpenAI (une fois)                 │
│                                                              │
│  POST /projects/key                                         │
│  Headers: X-Admin-API-Key: <ADMIN_SECRET>                  │
│  Body: { project_id, openai_key }                          │
│  ─────────────────────────────────────────                 │
│  → Chiffrement AES-256-GCM (KEK + DEK)                     │
│  → Stockage D1 table: project_secrets                      │
│  → Audit log: vault_key_saved                              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Client demande session (à chaque utilisation)           │
│                                                              │
│  POST /session                                              │
│  Body: { project_id, model, voice }                        │
│  ─────────────────────────────────────────────             │
│  → Déchiffre clé OpenAI (en RAM uniquement)                │
│  → POST https://api.openai.com/v1/realtime/sessions        │
│  → Récupère client_secret éphémère (~60s TTL)              │
│  → Récupère TURN credentials (CF Calls API)                │
│  ─────────────────────────────────────────────             │
│  ← Response: { client_secret, turn_credentials, ... }      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Client initie WebRTC avec token éphémère               │
│                                                              │
│  → Utilise client_secret.value (jamais la vraie clé!)      │
│  → Configure ICE avec turn_credentials                      │
│  → Connexion WebRTC à wss://api.openai.com/v1/realtime     │
│  → Token expire après ~60s (must initiate before expiry)   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔐 Sécurité

### Vault (Envelope Encryption)

- **KEK** (Key Encryption Key): `KEK_V1` secret Cloudflare Worker
- **DEK** (Data Encryption Key): Généré par projet (32 bytes random)
- **Algorithme**: AES-256-GCM
- **AAD**: `${project_id}|${kek_version}` (authenticated data)
- **Storage**: D1 table `project_secrets`

**Structure D1:**
```sql
CREATE TABLE project_secrets (
  project_id TEXT PRIMARY KEY,
  key_ciphertext TEXT NOT NULL,  -- Base64url encrypted OpenAI key
  key_iv TEXT NOT NULL,           -- Base64url IV for key encryption
  dek_wrapped TEXT NOT NULL,      -- Base64url DEK encrypted with KEK
  dek_iv TEXT NOT NULL,           -- Base64url IV for DEK wrapping
  kek_version TEXT NOT NULL,      -- 'v1', 'v2', etc.
  alg TEXT NOT NULL,              -- 'A256GCM'
  created_at INTEGER NOT NULL,
  rotated_at INTEGER,
  key_hash_prefix TEXT            -- First 16 hex chars of SHA-256(key)
);
```

### Authentication

**Vault endpoints** (require `ADMIN_API_KEY`):
- `POST /projects/key` - Save/update OpenAI key
- `DELETE /projects/key` - Delete OpenAI key
- `POST /projects/key/rotate` - Rotate KEK version

**Public endpoints** (no auth required):
- `POST /session` - Create ephemeral session (uses `project_id`)
- `GET /turn-credentials` - Get TURN credentials

### Audit Logs

Tous les événements vault sont loggés dans D1 `audit_logs`:
- `vault_key_saved`
- `vault_key_deleted`
- `vault_key_rotated`

Format:
```json
{
  "timestamp": 1696348800000,
  "eventType": "vault_key_saved",
  "apiKeyHash": "hash...",
  "sessionId": "project_id",
  "status": "success",
  "ipAddress": "203.0.113.1"
}
```

---

## 🌐 TURN/STUN Credentials

### Configuration actuelle

- **Auth method**: Legacy (CF_AUTH_EMAIL + CF_AUTH_KEY)
- **Fallback**: Automatic si Bearer token échoue
- **TTL**: 600 seconds (configurable via `TURN_TTL_SECONDS`)
- **Cache**: 30s micro-cache (configurable via `TURN_MICRO_CACHE_MS`)

### ICE Servers fournis

✅ **2 STUN** (no auth):
1. `stun:stun.cloudflare.com:3478`
2. `stun:stun.l.google.com:19302`

✅ **4 TURN** (authenticated):
1. `turn:turn.cloudflare.com:3478?transport=udp` - Default, best performance
2. `turns:turn.cloudflare.com:5349?transport=tcp` - TLS, firewall-friendly
3. `turns:turn.cloudflare.com:443?transport=tcp` - HTTPS port, proxy-friendly
4. `turn:turn.cloudflare.com:80?transport=tcp` - HTTP port, strict firewall

**Note**: L'agent ICE choisit automatiquement (préfère STUN si possible, TURN si nécessaire).

---

## 📡 API Endpoints

### 1. Save Project Key (Admin)

**Request:**
```bash
curl -X POST https://luna-proxy-api.joffrey-vanasten.workers.dev/projects/key \
  -H "X-Admin-API-Key: $ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "my-app",
    "openai_key": "sk-proj-...",
    "validate": true,
    "kek_version": "v1"
  }'
```

**Response:**
```json
{
  "success": true,
  "project_id": "my-app",
  "kek_version": "v1",
  "created_at": 1696348800000
}
```

**Errors:**
- `401 Unauthorized` - Missing/invalid admin key
- `400 Bad Request` - Invalid OpenAI key (if `validate: true`)
- `500 Vault Error` - Encryption failure

---

### 2. Create Session (Public)

**Request:**
```bash
curl -X POST https://luna-proxy-api.joffrey-vanasten.workers.dev/session \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "my-app",
    "model": "gpt-4o-realtime-preview-2024-10-01",
    "voice": "echo"
  }'
```

**Response:**
```json
{
  "id": "sess_...",
  "model": "gpt-4o-realtime-preview-2024-10-01",
  "modalities": ["text", "audio"],
  "instructions": "...",
  "voice": "echo",
  "input_audio_format": "pcm16",
  "output_audio_format": "pcm16",
  "input_audio_transcription": null,
  "turn_detection": {
    "type": "server_vad",
    "threshold": 0.5,
    "prefix_padding_ms": 300,
    "silence_duration_ms": 200
  },
  "tools": [],
  "tool_choice": "auto",
  "temperature": 0.8,
  "max_response_output_tokens": "inf",

  "client_secret": {
    "value": "eph_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnop...",
    "expires_at": 1696348860
  },

  "turn_credentials": {
    "iceServers": [
      { "urls": "stun:stun.cloudflare.com:3478" },
      { "urls": "stun:stun.l.google.com:19302" },
      {
        "urls": "turn:turn.cloudflare.com:3478?transport=udp",
        "username": "...",
        "credential": "..."
      },
      {
        "urls": "turns:turn.cloudflare.com:5349?transport=tcp",
        "username": "...",
        "credential": "..."
      },
      {
        "urls": "turns:turn.cloudflare.com:443?transport=tcp",
        "username": "...",
        "credential": "..."
      },
      {
        "urls": "turn:turn.cloudflare.com:80?transport=tcp",
        "username": "...",
        "credential": "..."
      }
    ]
  },

  "session_id": "local_session_...",
  "metadata": {
    "model": "gpt-4o-realtime-preview-2024-10-01",
    "voice": "echo",
    "turn_server": "turn:turn.cloudflare.com:3478?transport=udp",
    "created_at": "2025-10-03T12:00:00.000Z"
  }
}
```

**Errors:**
- `401 Authentication Required` - No `project_id` ou clé introuvable
- `429 Rate Limit Exceeded` - 100 req/15min dépassé
- `400 Bad Request` - Paramètres invalides
- `500 Internal Error` - OpenAI API error

---

### 3. Delete Project Key (Admin)

**Request:**
```bash
curl -X DELETE https://luna-proxy-api.joffrey-vanasten.workers.dev/projects/key \
  -H "X-Admin-API-Key: $ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"project_id": "my-app"}'
```

**Response:**
```json
{
  "success": true,
  "project_id": "my-app"
}
```

---

### 4. Rotate KEK (Admin)

**Request:**
```bash
curl -X POST https://luna-proxy-api.joffrey-vanasten.workers.dev/projects/key/rotate \
  -H "X-Admin-API-Key: $ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "my-app",
    "kek_version": "v2"
  }'
```

**Response:**
```json
{
  "success": true,
  "project_id": "my-app",
  "kek_version": "v2",
  "rotated_at": 1696348900000
}
```

---

### 5. Get TURN Credentials (Public)

**Request:**
```bash
curl https://luna-proxy-api.joffrey-vanasten.workers.dev/turn-credentials
```

**Response:** (same as `turn_credentials` in `/session`)

---

## 🧪 Testing

### Test complet du flux

```bash
# 1. Enregistrer clé (admin)
curl -X POST https://luna-proxy-api.joffrey-vanasten.workers.dev/projects/key \
  -H "X-Admin-API-Key: your-admin-key" \
  -H "Content-Type: application/json" \
  -d '{"project_id":"test-001","openai_key":"sk-proj-real-key","validate":false}'

# 2. Créer session (public)
curl -X POST https://luna-proxy-api.joffrey-vanasten.workers.dev/session \
  -H "Content-Type: application/json" \
  -d '{"project_id":"test-001","model":"gpt-4o-realtime-preview-2024-10-01"}' \
  | jq '.client_secret.value'

# 3. Vérifier TURN
curl https://luna-proxy-api.joffrey-vanasten.workers.dev/turn-credentials \
  | jq '.iceServers | length'
# Expected: 6 (2 STUN + 4 TURN)
```

### Vérifier l'auth admin

```bash
# Sans auth → 401
curl -X POST https://luna-proxy-api.joffrey-vanasten.workers.dev/projects/key \
  -H "Content-Type: application/json" \
  -d '{"project_id":"test","openai_key":"sk-test"}'

# Expected: {"error":"unauthorized","message":"Admin API key required to manage project keys"}
```

---

## ⚙️ Configuration

### Secrets Cloudflare Workers

```bash
# Vault
wrangler secret put KEK_V1              # Base64url 32 bytes
wrangler secret put ADMIN_API_KEY       # Random secure string

# TURN (legacy auth - fonctionne actuellement)
wrangler secret put CF_AUTH_EMAIL       # Cloudflare account email
wrangler secret put CF_AUTH_KEY         # Global API Key
wrangler secret put CF_ACCOUNT_ID       # Account ID

# TURN (Bearer token - optionnel, recommandé)
wrangler secret put CF_TURN_API_TOKEN   # Token avec permission "Calls: Edit"
```

### Environment Variables

Dans `wrangler.toml`:
```toml
[vars]
ENVIRONMENT = "production"
LOG_LEVEL = "info"
CORS_MODE = "public"

# TURN config (optionnel)
# TURN_TTL_SECONDS = "600"
# TURN_MICRO_CACHE_MS = "30000"
```

---

## 📊 Métriques & Monitoring

### Logs disponibles

1. **Audit logs** (D1 `audit_logs`):
   - `vault_key_saved`
   - `vault_key_deleted`
   - `vault_key_rotated`
   - `session_created`
   - `session_error`

2. **Metrics endpoint** (public):
   ```bash
   curl https://luna-proxy-api.joffrey-vanasten.workers.dev/metrics
   ```

3. **Audit logs endpoint** (admin):
   ```bash
   curl https://luna-proxy-api.joffrey-vanasten.workers.dev/audit-logs?limit=100 \
     -H "X-Admin-API-Key: $ADMIN_API_KEY"
   ```

### Rate Limits

- **Session creation**: 100 req / 15 min par `apiKeyHash` (hash du project_id)
- Headers de réponse:
  - `X-RateLimit-Limit: 100`
  - `X-RateLimit-Remaining: 95`
  - `X-RateLimit-Reset: 1696349400`

---

## 🔄 Prochaines étapes recommandées

### Court terme (optionnel)

1. **Token Cloudflare Calls Bearer** (meilleure pratique):
   - Aller sur https://dash.cloudflare.com/profile/api-tokens
   - Créer token avec permission: `Account → Cloudflare Calls → Edit`
   - `wrangler secret put CF_TURN_API_TOKEN`
   - Le fallback legacy continuera de fonctionner si Bearer échoue

2. **CORS restrictif** (si dashboard web):
   - Mettre `ACCESS_MODE=enterprise` dans vars
   - Configurer `ALLOWED_ORIGINS` strictement
   - Ou utiliser Cloudflare Access pour `/projects/key*`

### Long terme

1. **Rotation KEK_V2**:
   ```bash
   # Générer KEK_V2
   openssl rand -base64 32 | tr -d '\n' | tr '+/' '-_'

   # Configurer
   wrangler secret put KEK_V2

   # Rotater tous les projets
   curl -X POST .../projects/key/rotate \
     -H "X-Admin-API-Key: ..." \
     -d '{"project_id":"my-app","kek_version":"v2"}'
   ```

2. **Métriques TURN usage**:
   - Tracker combien de sessions utilisent TURN vs STUN-only
   - Ajouter à `/metrics/details`

3. **Quotas par project**:
   - Limiter sessions/jour par `project_id`
   - Stocker dans D1 ou KV

---

## ✅ État actuel (Production Ready)

| Feature | Status | Notes |
|---------|--------|-------|
| Vault encryption | ✅ | AES-256-GCM, KEK_V1 configuré |
| Admin auth | ✅ | X-Admin-API-Key requis |
| Audit logs | ✅ | D1 audit_logs table |
| Session éphémère | ✅ | project_id → client_secret |
| TURN credentials | ✅ | Legacy auth (2 STUN + 4 TURN) |
| Rate limiting | ✅ | 100/15min par project |
| CORS | ✅ | Public mode activé |
| Deployment | ✅ | https://luna-proxy-api.joffrey-vanasten.workers.dev |

**Conclusion**: Le flux complet est **opérationnel en production** ! 🚀
