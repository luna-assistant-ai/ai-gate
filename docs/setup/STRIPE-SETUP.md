# Stripe Setup Guide – Session-Based Pricing

AI Gate utilise désormais des abonnements basés sur le **nombre de sessions** (1 session = 1 connexion WebRTC). Cette page décrit comment déployer ou répliquer la configuration Stripe pour les environnements **test** et **live**.

---

## ⚙️ Prérequis

- [Stripe CLI](https://stripe.com/docs/stripe-cli) installée (`brew install stripe/stripe-cli/stripe`)
- Connexion `stripe login` effectuée pour chaque mode (test et live)
- `jq` disponible (`brew install jq`)
- Accès à `wrangler` (`npm install -g wrangler`)

> ℹ️ Les scripts utilisent la variable `STRIPE` (par défaut `~/bin/stripe`). Vous pouvez la surcharger à l’exécution :
> ```bash
> STRIPE="stripe" ./scripts/stripe-setup-sessions.sh           # test (mode par défaut)
> STRIPE="stripe --live" ./scripts/stripe-setup-sessions.sh    # live
> ```

---

## 🚀 Étape 1 – Créer les produits & prix

Exécuter le script CLI qui crée les plans **Starter** et **Growth** et génère un fichier d’inventaire.

```bash
# Mode test (par défaut)
./scripts/stripe-setup-sessions.sh

# Mode live (assurez-vous d’être connecté avec `stripe login --live`)
STRIPE="stripe --live" ./scripts/stripe-setup-sessions.sh
```

Le script affiche les IDs créés et les enregistre dans :

- `scripts/stripe-ids-sessions.test.json`
- `scripts/stripe-ids-sessions.live.json` (si vous lancez la version live)

| Plan    | Prix | Sessions/mois | Minutes estimées | Projets | Rate limit | Support |
|---------|------|---------------|------------------|---------|------------|---------|
| FREE    | $0   | 100           | ~200              | 1       | 100 req/min | Community |
| STARTER | $29  | 5 000         | ~10 000           | 3       | 1 000 req/min | E-mail 48h |
| GROWTH  | $99  | 20 000        | ~40 000           | 10      | 10 000 req/min | E-mail 24h + SLA 99.9 % |

> Besoin d’une mise en place manuelle (UI Stripe) ? Consultez [STRIPE-PRODUCTS-MANUAL-SETUP.md](../STRIPE-PRODUCTS-MANUAL-SETUP.md).

---

## 🔐 Étape 2 – Exporter les secrets Wrangler

Utilisez l’helper pour générer les commandes `wrangler secret put` adaptées :

```bash
# Environnement staging (mode test)
./scripts/stripe-export-secrets-sessions.sh test

# Production (mode live)
./scripts/stripe-export-secrets-sessions.sh live
```

La sortie ressemble à :

```bash
cd luna-proxy-api
wrangler secret put STRIPE_PRICE_STARTER       # price_...
wrangler secret put STRIPE_PRICE_GROWTH        # price_...
wrangler secret put STRIPE_SECRET_KEY          # sk_test_... / sk_live_...
wrangler secret put STRIPE_WEBHOOK_SECRET      # whsec_...
```

Copiez-collez chaque valeur lorsque `wrangler` la demande. Pour l’environnement staging, ajoutez `--env staging` aux commandes.

---

## 🪝 Étape 3 – Configurer les webhooks

Les webhooks restent identiques : `checkout.session.completed`, `customer.subscription.*`, `invoice.*`. Vous pouvez :

- Utiliser le helper CLI historique :
  ```bash
  ./scripts/stripe/webhook-setup.sh test
  ./scripts/stripe/webhook-setup.sh live
  ```
- Ou créer l’endpoint manuellement via le dashboard Stripe (cf. section “Webhooks” de [STRIPE-PRODUCTS-MANUAL-SETUP.md](../STRIPE-PRODUCTS-MANUAL-SETUP.md)).

Notez l’ID et le secret retournés (`whsec_...`) puis ajoutez-les avec `wrangler secret put STRIPE_WEBHOOK_SECRET`.

---

## ✅ Étape 4 – Vérifier la configuration

1. **Checkout**
   ```bash
   curl -X POST https://api.ai-gate.dev/billing/checkout \
     -H "Content-Type: application/json" \
     -d '{
       "plan": "starter",
       "user_id": "test_user_123",
       "email": "test@example.com"
     }'
   ```
   → Une URL Stripe Checkout doit être retournée.

2. **Webhook**
   ```bash
   stripe listen --forward-to https://api.ai-gate.dev/webhooks/stripe
   stripe trigger checkout.session.completed
   ```
   → Vérifiez la réception du webhook (`wrangler tail`).

3. **Usage**
   ```bash
   wrangler d1 execute luna-proxy-audit --remote \
     --command "SELECT plan FROM stripe_customers WHERE user_id='test_user_123';"
   ```
   → Le plan doit passer à `starter`.

---

## 🧭 Référence rapide

- Script CLI principal : `./scripts/stripe-setup-sessions.sh`
- Export Wrangler : `./scripts/stripe-export-secrets-sessions.sh [test|live]`
- Fichiers d’IDs générés : `scripts/stripe-ids-sessions.<mode>.json`
- Webhooks : `./scripts/stripe/webhook-setup.sh [test|live]`
- Documentation complémentaire :
  - [STRIPE-PRODUCTS-MANUAL-SETUP.md](../STRIPE-PRODUCTS-MANUAL-SETUP.md)
  - [DEPLOYMENT-SUMMARY-SESSION-PRICING.md](../DEPLOYMENT-SUMMARY-SESSION-PRICING.md)
  - [NEXT-STEPS.md](../NEXT-STEPS.md)

---

**Temps total :** ~10 minutes (hors validation live).
