# Guide : Créer les Produits Stripe Manuellement (Mode LIVE)

**Date** : 2025-10-05
**Pour** : AI Gate - Session-based Pricing
**Raison** : Le Stripe CLI n'a pas les permissions pour créer des produits en mode live

---

## 🎯 Objectif

Créer 2 produits Stripe en mode LIVE pour le nouveau pricing basé sur les sessions.

---

## 📝 Étapes à Suivre

### 1. Accéder au Dashboard Stripe

1. Va sur [Stripe Dashboard](https://dashboard.stripe.com)
2. Assure-toi d'être en **mode LIVE** (toggle en haut à droite)
3. Va dans **Products** → [Product Catalog](https://dashboard.stripe.com/products)

---

### 2. Créer le Produit STARTER

#### Configuration du Produit

Clique sur **"+ Add product"** et remplis :

**Informations générales**
- **Name** : `AI Gate - Starter`
- **Description** : `5,000 sessions per month (~10,000 minutes estimated)`
- **Image** (optionnel) : Logo AI Gate si disponible

**Pricing**
- **Pricing model** : `Standard pricing`
- **Price** : `29.00` USD
- **Billing period** : `Monthly` (Recurring)
- **Payment type** : `Recurring`

**Advanced options** (optionnel mais recommandé)
Ajouter des metadata pour tracking :
```
plan = starter
sessions_quota = 5000
estimated_minutes = 10000
projects = 3
rate_limit_rpm = 1000
concurrent = 10
```

Clique sur **"Save product"**

#### ✅ Copier le Price ID

Après création, tu verras un **Price ID** qui ressemble à : `price_1XXXXXxxxxxx`

**📋 IMPORTANT : COPIE CE PRICE ID** → `price_________________` (Starter)

---

### 3. Créer le Produit GROWTH

Répète les mêmes étapes avec :

**Informations générales**
- **Name** : `AI Gate - Growth`
- **Description** : `20,000 sessions per month (~40,000 minutes estimated)`

**Pricing**
- **Price** : `99.00` USD
- **Billing period** : `Monthly` (Recurring)

**Metadata** (optionnel)
```
plan = growth
sessions_quota = 20000
estimated_minutes = 40000
projects = 10
rate_limit_rpm = 10000
concurrent = 50
sla = 99.9
```

Clique sur **"Save product"**

#### ✅ Copier le Price ID

**📋 IMPORTANT : COPIE CE PRICE ID** → `price_________________` (Growth)

---

## 4. Configurer les Secrets Wrangler

Une fois les 2 produits créés, configure les secrets dans ton Worker :

```bash
cd /Users/joffreyvanasten/luna-proxy-projects/luna-proxy-api

# Configurer STARTER
echo "price_XXXXXXXXXXXXX" | wrangler secret put STRIPE_PRICE_STARTER

# Configurer GROWTH
echo "price_YYYYYYYYYYY" | wrangler secret put STRIPE_PRICE_GROWTH
```

**Remplace `price_XXXXXXXXXXXXX` et `price_YYYYYYYYYYY` par les vrais IDs copiés !**

---

## 5. Vérifier la Configuration

Teste que tout fonctionne :

```bash
# Test du checkout STARTER
curl -X POST 'https://api.ai-gate.dev/billing/checkout' \
  -H 'Content-Type: application/json' \
  -d '{
    "plan": "starter",
    "user_id": "test_live_user",
    "email": "test@ai-gate.dev"
  }' | jq .

# Test du checkout GROWTH
curl -X POST 'https://api.ai-gate.dev/billing/checkout' \
  -H 'Content-Type: application/json' \
  -d '{
    "plan": "growth",
    "user_id": "test_live_user",
    "email": "test@ai-gate.dev"
  }' | jq .
```

Si tu reçois une URL Stripe Checkout, c'est bon ! ✅

---

## 6. Configurer le Webhook (Production)

1. Va sur [Stripe Webhooks](https://dashboard.stripe.com/webhooks)
2. Clique sur **"+ Add endpoint"**
3. Configure :
   - **Endpoint URL** : `https://api.ai-gate.dev/webhooks/stripe`
   - **Events to send** :
     - `checkout.session.completed`
     - `customer.subscription.created`
     - `customer.subscription.updated`
     - `customer.subscription.deleted`
     - `invoice.payment_succeeded`
     - `invoice.payment_failed`
4. Clique sur **"Add endpoint"**
5. Copie le **Signing secret** (`whsec_...`)
6. Configure-le :

```bash
cd luna-proxy-api
echo "whsec_ZZZZZZZZZZZZZ" | wrangler secret put STRIPE_WEBHOOK_SECRET
```

---

## ✅ Checklist Finale

- [ ] Produit "AI Gate - Starter" créé ($29/mo)
- [ ] Produit "AI Gate - Growth" créé ($99/mo)
- [ ] Price ID Starter copié et configuré
- [ ] Price ID Growth copié et configuré
- [ ] Secrets Wrangler configurés
- [ ] Tests checkout réussis
- [ ] Webhook configuré en production
- [ ] Webhook secret configuré

---

## 📊 Récapitulatif des Plans

| Plan | Prix | Sessions/mois | Estimation min | Price ID à copier |
|------|------|---------------|----------------|-------------------|
| FREE | $0 | 100 | ~200 | N/A (backend only) |
| STARTER | $29 | 5,000 | ~10,000 | `price_____________` |
| GROWTH | $99 | 20,000 | ~40,000 | `price_____________` |

---

## 🆘 Besoin d'Aide ?

Si tu rencontres un problème :

1. Vérifie que tu es bien en mode LIVE dans Stripe
2. Vérifie que les Price IDs sont corrects (commencent par `price_`)
3. Vérifie que les secrets sont bien configurés : `wrangler secret list`
4. Consulte les logs : `wrangler tail`

---

**Prêt à facturer en production !** 🚀
