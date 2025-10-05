# ✅ Déploiement Complet : Session-Based Pricing

**Date** : 2025-10-05
**Status** : ✅ **PRODUCTION LIVE**
**Migration** : Ancien pricing (minutes) → Nouveau pricing (sessions)

---

## 🎯 Résumé Exécutif

Migration réussie vers un système de pricing basé sur les **sessions** plutôt que les minutes. Le nouveau système est **100% déployé en production** et fonctionnel.

### Nouveau Modèle

- **Unité de facturation** : Sessions (1 session = 1 connexion WebRTC)
- **Plans** : FREE (100), STARTER (5000), GROWTH (20000)
- **Prix** : $0, $29/mo, $99/mo
- **Minutes** : Trackées en interne uniquement pour monitoring des coûts

---

## 📊 Plans Disponibles

| Plan | Prix | Sessions/mois | Estimation min | Projets | Rate Limit | Support |
|------|------|---------------|----------------|---------|------------|---------|
| **FREE** | $0 | 100 | ~200 | 1 | 100 req/min | Community |
| **STARTER** | $29 | 5,000 | ~10,000 | 3 | 1,000 req/min | Email 48h |
| **GROWTH** | $99 | 20,000 | ~40,000 | 10 | 10,000 req/min | Email 24h + SLA 99.9% |

---

## ✅ Déploiements Réussis

### 🧪 Staging (Mode Test)

**URL** : `https://luna-proxy-api-staging.joffrey-vanasten.workers.dev`

**Produits Stripe (Test)** :
- ✅ STARTER : `price_1SEiMwD10JtvEUh4Zbpwm1eW` ($29/mo, 5000 sessions)
- ✅ GROWTH : `price_1SEiN8D10JtvEUh4kSmrbY2k` ($99/mo, 20000 sessions)

**Secrets Configurés** :
- ✅ `STRIPE_PRICE_STARTER`
- ✅ `STRIPE_PRICE_GROWTH`
- ✅ `STRIPE_SECRET_KEY` (test)
- ✅ `STRIPE_WEBHOOK_SECRET` (test)

**Tests Validés** :
- ✅ `/billing/usage` retourne les quotas sessions
- ✅ `/billing/checkout` génère des URLs valides
- ✅ Quota verification (95/100 sessions testée)
- ✅ Database tracking fonctionnel

**Fichier** : `scripts/stripe-ids-sessions.test.json`

---

### 🚀 Production (Mode LIVE)

**URL** : `https://api.ai-gate.dev`

**Produits Stripe (LIVE)** :
- ✅ STARTER : `price_1SEiYaDIQ5dZHYjB9UwRQTEU` ($29/mo, 5000 sessions)
- ✅ GROWTH : `price_1SEiYoDIQ5dZHYjBp5GaJgL4` ($99/mo, 20000 sessions)

**Secrets Configurés** :
- ✅ `STRIPE_PRICE_STARTER`
- ✅ `STRIPE_PRICE_GROWTH`
- ✅ `STRIPE_SECRET_KEY` (live)
- ✅ `STRIPE_WEBHOOK_SECRET` (live)

**Webhook Production** :
- ✅ URL : `https://api.ai-gate.dev/webhooks/stripe`
- ✅ Webhook ID : `we_1SEibHDIQ5dZHYjBJ3mB5EhE`
- ✅ Events : `checkout.session.completed`, `customer.subscription.*`, `invoice.payment.*`
- ✅ Status : **Enabled**

**Tests Production** :
- ✅ `/billing/usage` fonctionnel
- ✅ `/billing/checkout` (STARTER) génère URL LIVE
- ✅ `/billing/checkout` (GROWTH) génère URL LIVE
- ✅ Database migrée avec succès

**Fichier** : `scripts/stripe-ids-sessions.live.json`

---

## 🔧 Modifications Techniques

### 1. Database Schema

**Fichier** : `luna-proxy-api/schema-billing.sql`

```sql
-- Plans supportés : 'free', 'starter', 'growth'
-- Session tracking avec minutes estimées
-- total_sessions = unité de facturation
-- total_minutes_used = tracking interne uniquement
```

**Migration** :
- ✅ Staging : Exécutée avec succès
- ✅ Production : Exécutée + `ALTER TABLE` pour compatibilité

### 2. Code Backend

**Fichiers modifiés** :
- `luna-proxy-api/src/utils/stripe.ts` - Configuration plans et quotas
- `luna-proxy-api/src/types.ts` - Types mis à jour
- `luna-proxy-api/src/handlers/billing.ts` - Plans 'starter' et 'growth'
- `luna-proxy-api/src/index.ts` - Tracking sessions + quota verification

**Nouvelles fonctionnalités** :
```typescript
// Quota basé sessions
getCurrentUsage(env, userId) → {
  sessionsIncluded: 100,
  sessionsUsed: 0,
  sessionsRemaining: 100,
  estimatedMinutes: 200,
  minutesUsed: 0,
  percentUsed: 0,
  rateLimit: { requestsPerMinute: 100, concurrent: 1 }
}

// Tracking automatique
trackSession(env, sessionId, projectId, userId)
```

### 3. Scripts Créés

- ✅ `scripts/stripe-setup-sessions.sh` - Création produits Stripe
- ✅ `scripts/stripe-export-secrets-sessions.sh` - Export secrets
- ✅ `scripts/stripe-ids-sessions.test.json` - IDs staging
- ✅ `scripts/stripe-ids-sessions.live.json` - IDs production

### 4. Documentation

- ✅ `docs/PRICING-MIGRATION-SESSIONS.md` - Guide de migration complet
- ✅ `docs/STRIPE-PRODUCTS-MANUAL-SETUP.md` - Guide création manuelle
- ✅ `docs/DEPLOYMENT-SUMMARY-SESSION-PRICING.md` - Ce document

---

## 🧪 Tests Effectués

### Staging

| Test | Résultat | Détails |
|------|----------|---------|
| Checkout STARTER | ✅ Pass | URL générée valide |
| Checkout GROWTH | ✅ Pass | URL générée valide |
| Usage API | ✅ Pass | Retourne quotas sessions |
| Quota 95/100 | ✅ Pass | `sessionsRemaining: 5` |
| Quota dépassé | ✅ Pass | `sessionsRemaining: 0` |
| Webhook config | ✅ Pass | Secret configuré |

### Production

| Test | Résultat | Détails |
|------|----------|---------|
| Checkout STARTER | ✅ Pass | URL LIVE générée |
| Checkout GROWTH | ✅ Pass | URL LIVE générée |
| Usage API | ✅ Pass | Retourne quotas sessions |
| Database migration | ✅ Pass | Schema updated |
| Webhook endpoint | ✅ Pass | Active et configuré |

---

## 📈 Endpoints Disponibles

### GET `/billing/usage`

**Query Params** : `user_id`

**Response** :
```json
{
  "plan": "free",
  "sessionsIncluded": 100,
  "sessionsUsed": 0,
  "sessionsRemaining": 100,
  "estimatedMinutes": 200,
  "minutesUsed": 0,
  "percentUsed": 0,
  "rateLimit": {
    "requestsPerMinute": 100,
    "concurrent": 1
  }
}
```

### POST `/billing/checkout`

**Body** :
```json
{
  "plan": "starter",  // ou "growth"
  "user_id": "user_123",
  "email": "user@example.com"
}
```

**Response** :
```json
{
  "url": "https://checkout.stripe.com/..."
}
```

### POST `/billing/portal`

**Body** :
```json
{
  "user_id": "user_123"
}
```

### POST `/webhooks/stripe`

**Events supportés** :
- `checkout.session.completed` - Après paiement réussi
- `customer.subscription.created` - Nouvelle souscription
- `customer.subscription.updated` - Modification plan
- `customer.subscription.deleted` - Annulation
- `invoice.payment_succeeded` - Paiement mensuel réussi
- `invoice.payment_failed` - Échec de paiement

---

## 🔐 Secrets Wrangler

### Production

```bash
wrangler secret list
```

Secrets configurés :
- `STRIPE_SECRET_KEY` - Clé API Stripe live
- `STRIPE_PRICE_STARTER` - Price ID Starter plan
- `STRIPE_PRICE_GROWTH` - Price ID Growth plan
- `STRIPE_WEBHOOK_SECRET` - Secret webhook production

### Staging

```bash
wrangler secret list --env staging
```

Secrets configurés (mode test) :
- `STRIPE_SECRET_KEY` - Clé API Stripe test
- `STRIPE_PRICE_STARTER` - Price ID test Starter
- `STRIPE_PRICE_GROWTH` - Price ID test Growth
- `STRIPE_WEBHOOK_SECRET` - Secret webhook staging

---

## 📝 Prochaines Étapes Recommandées

### Court Terme (cette semaine)

1. **Mettre à jour le Dashboard** (luna-proxy-dashboard)
   - Afficher sessions utilisées/quota
   - Afficher estimation minutes en petit texte
   - Ajouter progress bar avec alerte à 80%

2. **Créer la page Pricing**
   - Plans : FREE, STARTER, GROWTH
   - Mettre sessions en avant
   - Mentionner OpenAI billing séparé

3. **Tester un vrai paiement**
   - Acheter un plan STARTER avec une vraie carte
   - Vérifier webhook reçu
   - Vérifier plan mis à jour en DB

### Moyen Terme (2-4 semaines)

4. **Email notifications**
   - Alerte à 80% du quota
   - Alerte à 100% du quota
   - Email de bienvenue après souscription

5. **Analytics**
   - Dashboard admin pour voir tous les users
   - Métriques : conversion rate, churn, MRR
   - Tracking sessions par plan

6. **Migration utilisateurs existants**
   - Identifier users avec ancien pricing
   - Email de notification du changement
   - Script de migration automatique

### Long Terme (1-3 mois)

7. **Features avancées**
   - Badge "Powered by AI-Gate" pour free tier
   - Support ticket system
   - Factures PDF automatiques
   - Volume discounts (sur demande)

---

## 🆘 Troubleshooting

### Erreur "STRIPE_SECRET_KEY not configured"

```bash
cd luna-proxy-api
echo "sk_live_..." | wrangler secret put STRIPE_SECRET_KEY
```

### Erreur "D1_ERROR: no such column"

La table existe avec l'ancien schema. Exécuter :

```bash
wrangler d1 execute luna-proxy-audit --remote \
  --command "ALTER TABLE monthly_usage ADD COLUMN total_minutes_used INTEGER DEFAULT 0;"
```

### Webhook non reçu

Vérifier dans Stripe Dashboard > Webhooks que l'endpoint est actif et que les events sont bien configurés.

### Test checkout ne fonctionne pas

Vérifier les secrets :
```bash
wrangler secret list
```

Tester manuellement :
```bash
curl -X POST 'https://api.ai-gate.dev/billing/checkout' \
  -H 'Content-Type: application/json' \
  -d '{"plan":"starter","user_id":"test","email":"test@test.com"}'
```

---

## 📞 Liens Utiles

- [Stripe Dashboard](https://dashboard.stripe.com)
- [Stripe Products](https://dashboard.stripe.com/products)
- [Stripe Webhooks](https://dashboard.stripe.com/webhooks)
- [Cloudflare D1 Dashboard](https://dash.cloudflare.com/?to=/:account/workers/d1)
- [Wrangler Docs](https://developers.cloudflare.com/workers/wrangler/)

---

## ✅ Statut Final

| Composant | Staging | Production |
|-----------|---------|------------|
| Database Schema | ✅ Migré | ✅ Migré |
| Stripe Products | ✅ Créés (test) | ✅ Créés (live) |
| Code Déployé | ✅ v1.0.0 | ✅ v1.0.0 |
| Secrets Configurés | ✅ Complet | ✅ Complet |
| Webhooks | ✅ Configuré | ✅ Configuré |
| Tests | ✅ Passed | ✅ Passed |

---

**🎉 PRODUCTION READY - Session-based pricing est LIVE !**

*Dernière mise à jour : 2025-10-05 03:30 UTC*
