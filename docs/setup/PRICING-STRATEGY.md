# Session-Based Pricing Strategy

## 🎯 Vision

> **"Pay for the sessions you actually run."**
>
> 1 session = 1 connexion WebRTC complète via AI Gate (création d'un token éphémère + usage TURN si nécessaire).

Le modèle est désormais **100 % orienté sessions**, avec suivi des minutes en interne uniquement pour l'analyse des coûts.

---

## 💰 Plans

| Plan    | Prix mensuel | Sessions/mois | Minutes estimées | Projets | Rate limit | Support |
|---------|--------------|---------------|------------------|---------|------------|---------|
| Free    | $0           | 100           | ~200             | 1       | 100 req/min | Communauté, badge requis |
| Starter | $29          | 5 000         | ~10 000          | 3       | 1 000 req/min | Email (48h) |
| Growth  | $99          | 20 000        | ~40 000          | 10      | 10 000 req/min | Email (24h) + SLA 99.9 % |

**Caractéristiques communes**
- Sessions comptabilisées uniquement quand la connexion réussit (>5 s).
- Minutes agrégées côté D1 (`minutes_used`) pour surveiller les coûts OpenAI/TURN.
- Possibilité d'upgrade/downgrade self-service via Stripe Customer Portal.

---

## 🔄 Parcours client

1. **Free** : onboarding sans CB, badge obligatoire.
2. **Starter / Growth** : abonnement mensuel via Checkout Stripe.
3. **Quota** : vérification `sessionsRemaining` côté API avant chaque `/session`.
4. **Portail** : `/billing/portal` permet la gestion autonome de l'abonnement.
5. **Alertes** (à implémenter) : e-mails 80 % / 100 % usage, suspension lorsqu'on dépasse le quota.

---

## 🧱 Implémentation (statut)

| Domaine | Action | Statut |
|---------|--------|--------|
| Stripe  | Produits & prix Starter/Growth | ✅ `stripe-setup-sessions.sh` |
| API     | Nouvelle config `PLAN_CONFIG` | ✅ `src/utils/stripe.ts` |
| API     | Tracking sessions (`trackSession`) | ✅ `src/index.ts` |
| API     | Quota check (`checkQuotaRemaining`) | ✅ `src/index.ts` |
| API     | Schemas D1 (minutes_used) | ✅ `schema-billing.sql` |
| Dashboard | Affichage quotas sessions | 🔄 À mettre à jour (`luna-proxy-dashboard`) |
| Dashboard | Page Pricing | 🔄 À rafraîchir |
| Notifications | Emails 80 % / 100 % | 🔜 backlog |

---

## 🗄️ Schéma de données

```sql
CREATE TABLE IF NOT EXISTS stripe_customers (
  user_id TEXT PRIMARY KEY,
  stripe_customer_id TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  plan TEXT DEFAULT 'free', -- free, starter, growth
  stripe_subscription_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

```sql
CREATE TABLE IF NOT EXISTS session_usage (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  project_id TEXT NOT NULL,
  session_id TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL,
  duration_ms INTEGER DEFAULT 0,
  minutes_used INTEGER DEFAULT 0, -- internal tracking only
  charged BOOLEAN DEFAULT 0,
  stripe_invoice_id TEXT,
  error_reason TEXT,
  created_at INTEGER NOT NULL,
  completed_at INTEGER
);
```

```sql
CREATE TABLE IF NOT EXISTS monthly_usage (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  total_sessions INTEGER DEFAULT 0,
  successful_sessions INTEGER DEFAULT 0,
  failed_sessions INTEGER DEFAULT 0,
  total_minutes_used INTEGER DEFAULT 0,
  stripe_invoice_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

---

## 🧩 API & Backend

### Checkout
```typescript
POST /billing/checkout
Body: { plan: 'starter' | 'growth', user_id, email }
Response: { url: 'https://checkout.stripe.com/...' }
```

### Portal
```typescript
POST /billing/portal
Body: { user_id }
Response: { url: 'https://billing.stripe.com/...' }
```

### Usage
```typescript
GET /billing/usage?user_id=...
// Renvoie plan, sessionsIncluded, sessionsUsed, sessionsRemaining,
// percentUsed, minutesUsed (estimation), rate limits
```

### Session
```typescript
POST /session
Headers: Authorization: Bearer <JWT> (clé gérée) ou X-OpenAI-API-Key
Comportement:
  - Vérifie quota via checkQuotaRemaining
  - Crée session OpenAI
  - Enregistre session_usage + monthly_usage
  - Retourne turn_credentials + client_secret
```

---

## 📈 Roadmap complémentaires

- **Usage-based add-on** – Pack sessions additionnels (ex : +1 000 sessions pour $10).
- **Overage soft-cap** – Option d'activer un dépassement facturé automatiquement.
- **Enterprise** – Négociation custom (contrats, invoicing manuel, usage illimité).
- **Analytics** – Dashboard quotas + consommation minute vs sessions.
- **Notifications** – Emails et webhooks quand `percentUsed` > 80/100.

---

## 🔗 Ressources

- CLI : `./scripts/stripe-setup-sessions.sh`
- Secrets : `./scripts/stripe-export-secrets-sessions.sh`
- Documentation :
  - [DEPLOYMENT-SUMMARY-SESSION-PRICING.md](../DEPLOYMENT-SUMMARY-SESSION-PRICING.md)
  - [NEXT-STEPS.md](../NEXT-STEPS.md)
  - [STRIPE-PRODUCTS-MANUAL-SETUP.md](../STRIPE-PRODUCTS-MANUAL-SETUP.md)

---

**Dernière mise à jour :** 2025-10-06
