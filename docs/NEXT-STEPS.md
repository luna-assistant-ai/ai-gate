# 🎯 Prochaines Étapes - AI Gate

**Dernière mise à jour** : 2025-10-05
**Contexte** : Migration session-based pricing complétée ✅

---

## ✅ Déjà Fait

- [x] Migration du pricing : minutes → sessions
- [x] Produits Stripe créés (test + live)
- [x] Code déployé (staging + production)
- [x] Database migrée
- [x] Webhooks configurés
- [x] Tests validés

**📄 Voir** : [DEPLOYMENT-SUMMARY-SESSION-PRICING.md](DEPLOYMENT-SUMMARY-SESSION-PRICING.md)

---

## 🔥 Priorité Haute (Cette Semaine)

### 1. Tester un Vrai Paiement

**Pourquoi** : Valider le flux complet end-to-end

**Actions** :
```bash
# 1. Créer un checkout
curl -X POST 'https://api.ai-gate.dev/billing/checkout' \
  -H 'Content-Type: application/json' \
  -d '{
    "plan": "starter",
    "user_id": "real_test_user",
    "email": "ton-email@gmail.com"
  }'

# 2. Ouvrir l'URL retournée dans le navigateur
# 3. Utiliser une vraie carte de test Stripe : 4242 4242 4242 4242
# 4. Vérifier que le webhook est reçu
wrangler tail --env staging

# 5. Vérifier le plan en DB
wrangler d1 execute luna-proxy-audit --remote \
  --command "SELECT * FROM stripe_customers WHERE user_id='real_test_user';"
```

**Résultat attendu** :
- Paiement réussi
- Webhook `checkout.session.completed` reçu
- Plan mis à jour en DB : `free` → `starter`
- User peut créer des sessions

---

### 2. Mettre à Jour le Dashboard

**Fichiers à modifier** : `luna-proxy-dashboard/`

**Modifications** :

#### Affichage du Quota
```tsx
// components/usage/QuotaDisplay.tsx
<div className="quota-card">
  <h3>Session Usage</h3>
  <div className="usage-stats">
    <span className="big">{usage.sessionsUsed} / {usage.sessionsIncluded}</span>
    <span className="unit">sessions</span>
  </div>
  <div className="estimated">
    ≈ {usage.estimatedMinutes} minutes estimated
  </div>
  <ProgressBar
    value={usage.percentUsed}
    alert={usage.percentUsed >= 80}
  />
</div>
```

#### Page Pricing
```tsx
// pages/pricing.tsx
const plans = [
  {
    name: "Free",
    price: "$0",
    features: [
      "100 sessions/month",
      "≈ 200 minutes estimated",
      "1 project",
      "Community support",
      "Badge required: Powered by AI-Gate"
    ]
  },
  {
    name: "Starter",
    price: "$29",
    features: [
      "5,000 sessions/month",
      "≈ 10,000 minutes estimated",
      "3 projects",
      "Email support (48h)",
      "No badge required"
    ]
  },
  {
    name: "Growth",
    price: "$99",
    features: [
      "20,000 sessions/month",
      "≈ 40,000 minutes estimated",
      "10 projects",
      "Priority support (24h)",
      "SLA 99.9%"
    ],
    popular: true
  }
]
```

---

## 📊 Priorité Moyenne (2 Semaines)

### 3. Email Notifications

**Utiliser** : Resend, SendGrid, ou Cloudflare Email Workers

**Templates** :

#### Alerte 80% Quota
```
Subject: ⚠️ You've used 80% of your AI-Gate sessions

Hi {user_name},

You've used {sessions_used} out of {sessions_included} sessions this month ({percent_used}%).

To avoid service interruption, consider upgrading:
- STARTER: 5,000 sessions/month ($29)
- GROWTH: 20,000 sessions/month ($99)

Upgrade now: https://www.ai-gate.dev/dashboard?upgrade=true
```

#### Alerte 100% Quota
```
Subject: ⛔ Your AI-Gate quota is exhausted

Hi {user_name},

You've reached your monthly limit of {sessions_included} sessions.

Upgrade to continue using AI-Gate:
https://www.ai-gate.dev/dashboard?upgrade=urgent
```

#### Welcome Email
```
Subject: 🎉 Welcome to AI-Gate {plan_name}!

Thanks for subscribing to AI-Gate {plan_name}!

Your benefits:
- {sessions_quota} sessions per month
- {projects} projects
- {support} support

Get started: https://www.ai-gate.dev/docs/quickstart
```

**Implémentation** :
```typescript
// luna-proxy-api/src/utils/notifications.ts
export async function sendQuotaAlert(userId: string, usage: UsageData) {
  if (usage.percentUsed >= 80 && usage.percentUsed < 100) {
    await sendEmail({
      to: user.email,
      template: 'quota-warning-80',
      data: usage
    });
  }

  if (usage.percentUsed >= 100) {
    await sendEmail({
      to: user.email,
      template: 'quota-exceeded',
      data: usage
    });
  }
}
```

---

### 4. Analytics Dashboard

**Métriques à tracker** :

- **MRR** (Monthly Recurring Revenue)
- **Churn Rate** (% users qui cancel)
- **Conversion Rate** (free → paid)
- **ARPU** (Average Revenue Per User)
- **Sessions par plan** (usage moyen)

**Endpoint admin** :
```typescript
// GET /admin/analytics
{
  mrr: 1450, // $14.50 USD
  active_users: 150,
  paid_users: 50,
  free_users: 100,
  conversion_rate: 33.3, // %
  churn_rate: 5.2, // %
  sessions_by_plan: {
    free: { avg: 45, total: 4500 },
    starter: { avg: 2340, total: 70200 },
    growth: { avg: 8900, total: 89000 }
  }
}
```

---

## 🔮 Priorité Basse (1-3 Mois)

### 5. Features Avancées

#### Badge "Powered by AI-Gate"
```tsx
// Pour free tier uniquement
{plan === 'free' && (
  <a href="https://ai-gate.dev" className="powered-by-badge">
    ⚡ Powered by AI-Gate
  </a>
)}
```

#### Support Ticket System
- Intégrer Crisp, Intercom, ou custom
- Auto-assign selon le plan (community vs email)

#### Factures PDF
```typescript
// Générer PDF avec puppeteer ou jsPDF
async function generateInvoice(invoiceId: string) {
  const invoice = await getStripeInvoice(invoiceId);
  const pdf = await createPDF(invoice);
  await uploadToR2(pdf);
  return pdf_url;
}
```

#### Volume Discounts
```
Pour les entreprises (>100k sessions/mois)
Contact sales: enterprise@ai-gate.dev
Custom pricing available
```

---

### 6. Migration Utilisateurs Existants

**Si tu as déjà des users avec ancien pricing** :

#### Script de migration
```typescript
// scripts/migrate-users-to-sessions.ts
async function migrateUsers() {
  const oldUsers = await db.query(`
    SELECT * FROM stripe_customers
    WHERE plan IN ('build', 'pro', 'agency')
  `);

  for (const user of oldUsers) {
    const newPlan = mapOldToNew(user.plan);
    await updateUserPlan(user.user_id, newPlan);
    await sendMigrationEmail(user.email, newPlan);
  }
}

function mapOldToNew(oldPlan: string): string {
  const mapping = {
    'build': 'starter',  // Upgrade
    'pro': 'growth',     // Upgrade
    'agency': 'growth'   // Downgrade légèrement
  };
  return mapping[oldPlan] || 'free';
}
```

#### Email template
```
Subject: 📢 AI-Gate Pricing Update - You're Getting More!

Hi {user_name},

Great news! We've updated our pricing to give you MORE value.

Your old plan: {old_plan} ({old_minutes} minutes)
Your new plan: {new_plan} ({new_sessions} sessions ≈ {estimated_minutes} min)

→ You're getting {increase}% more usage! 🎉

No action needed. Your next invoice will reflect this change.

Questions? Reply to this email.
```

---

## 🎨 Nice to Have

- [ ] Dark mode pour le dashboard
- [ ] Export usage CSV
- [ ] Webhooks pour les users (notifs custom)
- [ ] API rate limiting par IP
- [ ] Géolocalisation des sessions
- [ ] Comparaison plans (tableau interactif)
- [ ] Testimonials / case studies
- [ ] Blog avec guides techniques
- [ ] Affiliate program (15% commission)

---

## 📚 Documentation à Créer

1. **User Guide** - Comment utiliser AI-Gate
2. **API Reference** - Tous les endpoints
3. **Billing FAQ** - Questions fréquentes
4. **Migration Guide** (pour les anciens users)
5. **Troubleshooting** - Erreurs communes

---

## 🔐 Sécurité

- [ ] Rate limiting global (anti-DDoS)
- [ ] Captcha sur signup
- [ ] 2FA pour comptes admin
- [ ] Audit logs (qui a fait quoi)
- [ ] IP whitelist option (pour enterprise)

---

## 📞 Support

Pour toute question :
- Voir [DEPLOYMENT-SUMMARY-SESSION-PRICING.md](DEPLOYMENT-SUMMARY-SESSION-PRICING.md)
- Voir [PRICING-MIGRATION-SESSIONS.md](PRICING-MIGRATION-SESSIONS.md)
- Consulter les logs : `wrangler tail`
- Stripe Dashboard : https://dashboard.stripe.com

---

**Bon courage ! 🚀**
