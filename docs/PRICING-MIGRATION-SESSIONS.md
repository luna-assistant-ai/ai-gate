# Migration vers le Pricing Basé Sessions

**Date**: 2025-10-05
**Status**: Ready for Implementation

---

## 📊 Vue d'ensemble

### Ancien modèle (Minutes)
- **Unité de facturation**: Minutes (estimées)
- **Plans**: Free (200 min), Starter (1500 min), Build (3000 min), Pro (8000 min), Agency (25000 min)
- **Prix**: $9, $19, $39, $99/mois

### Nouveau modèle (Sessions)
- **Unité de facturation**: Sessions (1 session = 1 connexion WebRTC)
- **Plans**: FREE (100 sessions), STARTER (5000 sessions), GROWTH (20000 sessions)
- **Prix**: $0, $29, $99/mois
- **Minutes**: Trackées en interne uniquement (estimation)

---

## 🎯 Pourquoi ce changement ?

### ✅ Avantages

1. **Transparence**: Une session = une connexion = facile à comprendre
2. **Simplicité**: Plus besoin d'estimer la durée à l'avance
3. **Équité**: Paiement basé sur l'usage réel, pas sur des estimations
4. **Scalabilité**: Plus facile de prévoir et d'optimiser les coûts

### 🔍 Comparaison

| Plan | Ancien (Minutes) | Nouveau (Sessions) | Estimation Minutes | Prix |
|------|------------------|--------------------|--------------------|------|
| FREE | 200 min | 100 sessions | ~200 min | $0 |
| STARTER | 1500 min | 5000 sessions | ~10000 min | $29 (+$20) |
| GROWTH | - | 20000 sessions | ~40000 min | $99 |

**Note**: En moyenne, 1 session ≈ 2 minutes (basé sur nos données)

---

## 🛠️ Modifications Techniques

### 1. Database Schema

**Fichier**: `luna-proxy-api/schema-billing.sql`

#### Changements:
```sql
-- stripe_customers.plan
-- Avant: 'free', 'starter', 'build', 'pro', 'agency'
-- Après:  'free', 'starter', 'growth'

-- session_usage
-- minutes_used: Reste pour tracking interne seulement
-- Nouveau commentaire: "Internal tracking only (estimated)"

-- monthly_usage
-- total_sessions: Nombre total de sessions (unité de facturation)
-- successful_sessions: Sessions qui comptent dans le quota
-- total_minutes_used: Tracking interne uniquement
```

### 2. Plan Configuration

**Fichier**: `luna-proxy-api/src/utils/stripe.ts`

```typescript
const PLAN_CONFIG = {
  free: {
    sessions: 100,              // ← Unité de facturation
    estimatedMinutes: 200,      // ← Estimation affichée
    price: 0,
    rateLimit: {
      requestsPerMinute: 100,   // ← Protection infrastructure
      concurrent: 1
    },
    features: {
      projects: 1,
      badge: true,              // "Powered by AI-Gate"
      support: 'community',
    },
  },
  starter: {
    sessions: 5000,
    estimatedMinutes: 10000,
    price: 2900,                // $29
    rateLimit: {
      requestsPerMinute: 1000,
      concurrent: 10
    },
    features: {
      projects: 3,
      badge: false,
      support: 'email-48h',
    },
  },
  growth: {
    sessions: 20000,
    estimatedMinutes: 40000,
    price: 9900,                // $99
    rateLimit: {
      requestsPerMinute: 10000,
      concurrent: 50
    },
    features: {
      projects: 10,
      badge: false,
      support: 'email-24h',
      sla: '99.9%',
    },
  },
}
```

### 3. Quota Verification

**Fichier**: `luna-proxy-api/src/index.ts`

```typescript
// Avant (ligne 511)
const usage = await getCurrentUsage(env, clientId);
// Retourne: minutesIncluded, minutesUsed, minutesRemaining

// Après
const usage = await getCurrentUsage(env, clientId);
// Retourne: sessionsIncluded, sessionsUsed, sessionsRemaining,
//           estimatedMinutes, minutesUsed (internal)
```

### 4. Session Tracking

**Nouveau**: Appel à `trackSession()` à chaque création de session

```typescript
// luna-proxy-api/src/index.ts (ligne 757)
if (clientId) {
  await trackClientUsage(env, clientId, true);
  // ← NOUVEAU: Track session for billing
  await trackSession(env, sessionId, usedProjectId || 'default', clientId);
}
```

### 5. Environment Variables

**Fichier**: `luna-proxy-api/src/types.ts`

```typescript
// Avant
STRIPE_PRICE_PAYG: string;
STRIPE_PRICE_PRO: string;

// Après
STRIPE_PRICE_STARTER: string;  // $29/mo - 5000 sessions
STRIPE_PRICE_GROWTH: string;   // $99/mo - 20000 sessions
```

---

## 🚀 Plan de Déploiement

### Étape 1: Créer les produits Stripe

```bash
cd /path/to/ai-gate

# Mode test (recommandé d'abord)
./scripts/stripe-setup-sessions.sh

# Vérifier le fichier créé
cat scripts/stripe-ids-sessions.test.json
```

**Résultat attendu**:
- ✅ Produit "AI Gate - Starter" créé ($29/mo)
- ✅ Produit "AI Gate - Growth" créé ($99/mo)
- ✅ IDs sauvegardés dans `stripe-ids-sessions.test.json`

### Étape 2: Configurer les secrets

```bash
# Export des IDs
./scripts/stripe-export-secrets-sessions.sh test

# Copier les commandes affichées et les exécuter dans luna-proxy-api/
cd luna-proxy-api

# Exemple (remplacer par vos vrais IDs):
wrangler secret put STRIPE_PRICE_STARTER --env staging
# Paste: price_xxxxxxxxxxxxx

wrangler secret put STRIPE_PRICE_GROWTH --env staging
# Paste: price_yyyyyyyyyyyyyyy

wrangler secret put STRIPE_SECRET_KEY --env staging
# Paste: sk_test_xxxxxxxxxxxxx

wrangler secret put STRIPE_WEBHOOK_SECRET --env staging
# Paste: whsec_xxxxxxxxxxxxx
```

### Étape 3: Mettre à jour la base de données

```bash
cd luna-proxy-api

# Staging
wrangler d1 execute luna-proxy-audit-staging --file=../schema-billing.sql --env staging

# Production (après tests)
wrangler d1 execute luna-proxy-audit --file=../schema-billing.sql
```

### Étape 4: Déployer le code

```bash
cd luna-proxy-api

# Staging d'abord
wrangler deploy --env staging

# Tester le endpoint /billing/usage
curl https://luna-proxy-api-staging.joffrey-vanasten.workers.dev/billing/usage?user_id=test

# Production (après validation)
wrangler deploy
```

### Étape 5: Configurer le webhook Stripe

1. Aller sur [Stripe Dashboard > Webhooks](https://dashboard.stripe.com/test/webhooks)
2. Créer un nouveau endpoint:
   - **URL**: `https://api.ai-gate.dev/webhooks/stripe` (staging: `https://luna-proxy-api-staging.joffrey-vanasten.workers.dev/webhooks/stripe`)
   - **Events**:
     - `checkout.session.completed`
     - `customer.subscription.created`
     - `customer.subscription.deleted`
     - `invoice.payment_succeeded`
     - `invoice.payment_failed`
3. Copier le **Signing secret** (`whsec_...`)
4. L'ajouter avec `wrangler secret put STRIPE_WEBHOOK_SECRET`

### Étape 6: Tester le flux complet

```bash
# 1. Créer une session test
curl -X POST https://luna-proxy-api-staging.joffrey-vanasten.workers.dev/billing/checkout \
  -H "Content-Type: application/json" \
  -d '{
    "plan": "starter",
    "user_id": "test_user_123",
    "email": "test@example.com"
  }'

# 2. Vérifier l'usage
curl https://luna-proxy-api-staging.joffrey-vanasten.workers.dev/billing/usage?user_id=test_user_123

# Résultat attendu:
# {
#   "plan": "free",
#   "sessionsIncluded": 100,
#   "sessionsUsed": 0,
#   "sessionsRemaining": 100,
#   "estimatedMinutes": 200,
#   "minutesUsed": 0,
#   "percentUsed": 0
# }
```

---

## 📈 Impact sur le Dashboard

### À mettre à jour dans `luna-proxy-dashboard`

1. **Affichage du quota**:
   ```tsx
   // Avant
   <div>{usage.minutesUsed} / {usage.minutesIncluded} minutes</div>

   // Après
   <div>
     <div className="text-2xl font-bold">
       {usage.sessionsUsed} / {usage.sessionsIncluded} sessions
     </div>
     <div className="text-sm text-gray-500">
       ≈ {usage.estimatedMinutes} minutes estimated
     </div>
   </div>
   ```

2. **Pricing Page**:
   ```tsx
   // Mettre en avant les sessions, ajouter les minutes en petit
   <PricingCard
     plan="Starter"
     price="$29/mo"
     features={[
       "✅ 5,000 sessions/month",
       "💡 ≈ 10,000 minutes estimated",
       "📊 3 projects included",
       "📧 Email support (48h)"
     ]}
   />
   ```

3. **Progress Bar**:
   ```tsx
   <ProgressBar
     value={usage.sessionsUsed}
     max={usage.sessionsIncluded}
     label={`${usage.percentUsed}% used`}
     alert={usage.percentUsed >= 80}
   />
   ```

---

## 🔄 Migration des utilisateurs existants

### Stratégie

1. **Grandfathering (recommandé)**:
   - Utilisateurs actuels gardent leurs plans pendant 3 mois
   - Email de notification avec les nouveaux quotas équivalents
   - Migration automatique après 3 mois

2. **Mapping des plans**:
   ```
   Ancien → Nouveau (équivalent)
   ─────────────────────────────
   FREE (200 min)        → FREE (100 sessions ≈ 200 min)
   STARTER (1500 min)    → STARTER (5000 sessions ≈ 10k min) ⬆️ UPGRADE
   BUILD (3000 min)      → STARTER (5000 sessions ≈ 10k min) ⬆️ UPGRADE
   PRO (8000 min)        → GROWTH (20k sessions ≈ 40k min) ⬆️ UPGRADE
   AGENCY (25k min)      → GROWTH (20k sessions ≈ 40k min) ≈ équivalent
   ```

3. **Script de migration DB**:
   ```sql
   -- Mettre à jour les plans existants
   UPDATE stripe_customers
   SET plan = CASE
     WHEN plan = 'build' THEN 'starter'
     WHEN plan IN ('pro', 'agency') THEN 'growth'
     ELSE plan
   END
   WHERE plan IN ('build', 'pro', 'agency');
   ```

---

## ✅ Checklist de Validation

### Avant déploiement Production

- [ ] Produits Stripe créés en mode test
- [ ] Secrets configurés en staging
- [ ] Base de données migrée (staging)
- [ ] Code déployé en staging
- [ ] Webhook Stripe configuré
- [ ] Tests du flux checkout réussis
- [ ] Tests du quota verification réussis
- [ ] Dashboard mis à jour
- [ ] Documentation mise à jour

### Déploiement Production

- [ ] Produits Stripe créés en mode live
- [ ] Secrets configurés en production
- [ ] Base de données migrée (production)
- [ ] Code déployé en production
- [ ] Webhook Stripe configuré (production)
- [ ] Email de notification envoyé aux utilisateurs
- [ ] Monitoring actif (sessions, quotas, erreurs)

---

## 📞 Support & Rollback

### En cas de problème

1. **Rollback code**:
   ```bash
   cd luna-proxy-api
   git revert HEAD
   wrangler deploy
   ```

2. **Rollback DB** (si nécessaire):
   ```sql
   -- Restaurer les anciens noms de plans
   UPDATE stripe_customers
   SET plan = CASE
     WHEN plan = 'starter' AND price = 900 THEN 'starter'
     WHEN plan = 'starter' AND price = 1900 THEN 'build'
     WHEN plan = 'growth' THEN 'pro'
     ELSE plan
   END;
   ```

3. **Contacter Stripe Support**: Pour archiver les nouveaux produits si besoin

---

## 📚 Ressources

- [Stripe Products API](https://stripe.com/docs/api/products)
- [Stripe Checkout Sessions](https://stripe.com/docs/payments/checkout)
- [Cloudflare D1 Documentation](https://developers.cloudflare.com/d1/)
- [AI-Gate Architecture](../luna-proxy-api/ARCHITECTURE.md)

---

**Prêt pour implémentation** ✅
Pour questions: voir `docs/RESUME-CONVERSATION.txt`
