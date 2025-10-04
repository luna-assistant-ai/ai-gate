# Email Setup Guide - AI Gate

## 🎯 Configuration Cloudflare Email Routing (5 minutes)

### Étape 1 : Activer Email Routing

1. **Aller sur Cloudflare Dashboard**
   - https://dash.cloudflare.com
   - Sélectionner le domaine `ai-gate.dev`

2. **Naviguer vers Email Routing**
   ```
   Sidebar → Email → Email Routing
   ```

3. **Activer Email Routing**
   - Cliquer sur "Get started" (si pas déjà activé)
   - Cloudflare va automatiquement ajouter les DNS records nécessaires

---

### Étape 2 : Créer les adresses email

#### A. billing@ai-gate.dev

1. **Email Routing → Routing Rules → Create address**
   ```
   Destination address: billing@ai-gate.dev
   Action: Send to an email
   Destination: [VOTRE-EMAIL-PERSONNEL]
   ```

2. **Vérifier votre email personnel**
   - Cloudflare envoie un email de confirmation
   - Cliquer sur le lien de vérification

#### B. support@ai-gate.dev

```
Destination address: support@ai-gate.dev
Action: Send to an email
Destination: [VOTRE-EMAIL-PERSONNEL]
```

#### C. noreply@ai-gate.dev

```
Destination address: noreply@ai-gate.dev
Action: Drop (ou Send to email si vous voulez recevoir)
```

**Note** : `noreply@` sera utilisé uniquement pour **envoyer** des emails, pas en recevoir.

---

### Étape 3 : Vérifier les DNS Records

Cloudflare Email Routing ajoute automatiquement :

```dns
ai-gate.dev.    MX    10    route1.mx.cloudflare.net
ai-gate.dev.    MX    10    route2.mx.cloudflare.net
ai-gate.dev.    MX    10    route3.mx.cloudflare.net
ai-gate.dev.    TXT   "v=spf1 include:_spf.mx.cloudflare.net ~all"
```

**Vérification** :
```bash
# Vérifier MX records
dig ai-gate.dev MX

# Vérifier SPF
dig ai-gate.dev TXT | grep spf1
```

---

### Étape 4 : Configurer Stripe

1. **Aller sur Stripe Dashboard**
   - https://dashboard.stripe.com

2. **Settings → Account details**
   ```
   Business email: billing@ai-gate.dev
   ```

3. **Settings → Email settings**
   ```
   ✅ Successful payments
   ✅ Failed payments
   ✅ Disputes
   ✅ Weekly summary

   Send to: billing@ai-gate.dev
   ```

---

### Étape 5 : Configurer l'envoi d'emails (Resend - Gratuit)

Pour **envoyer** des emails depuis AI Gate (confirmations, notifications) :

#### A. Créer compte Resend

1. **Aller sur https://resend.com**
2. **Sign up** (gratuit, 3000 emails/mois)
3. **Verify email**

#### B. Ajouter le domaine

1. **Dashboard → Domains → Add Domain**
   ```
   Domain: ai-gate.dev
   Region: Global
   ```

2. **Copier les DNS records**
   Resend va afficher 3 records à ajouter :
   ```
   resend._domainkey.ai-gate.dev    CNAME    ...
   resend.ai-gate.dev               TXT      ...
   ai-gate.dev                      TXT      v=spf1 include:spf.resend.com ~all
   ```

3. **Ajouter à Cloudflare DNS**
   ```
   Cloudflare Dashboard → DNS → Records → Add record
   ```

   **Important** : Pour le SPF, **merger** avec l'existant :
   ```
   v=spf1 include:_spf.mx.cloudflare.net include:spf.resend.com ~all
   ```

4. **Vérifier le domaine dans Resend**
   - Cliquer sur "Verify"
   - Attendre 2-3 minutes pour la propagation DNS

#### C. Créer API Key

1. **Resend Dashboard → API Keys → Create API Key**
   ```
   Name: AI Gate Production
   Permission: Sending access
   Domain: ai-gate.dev
   ```

2. **Copier la clé** (commence par `re_...`)

3. **Stocker dans Wrangler secrets**
   ```bash
   cd luna-proxy-api
   wrangler secret put RESEND_API_KEY
   # Coller: re_...
   ```

---

### Étape 6 : Tester l'envoi d'email

#### Test avec cURL (Resend API)

```bash
curl -X POST https://api.resend.com/emails \
  -H "Authorization: Bearer re_YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "from": "AI Gate <noreply@ai-gate.dev>",
    "to": "votre-email@exemple.com",
    "subject": "Test Email - AI Gate",
    "html": "<h1>Hello from AI Gate!</h1><p>Email routing works! 🎉</p>"
  }'
```

**Réponse attendue** :
```json
{
  "id": "49a3999c-0ce1-4ea6-ab68-afcd6dc2e794",
  "from": "noreply@ai-gate.dev",
  "to": "votre-email@exemple.com",
  "created_at": "2025-10-04T04:30:00.000Z"
}
```

---

## ✅ Checklist de vérification

### Email Routing (Cloudflare)
- [ ] billing@ai-gate.dev configuré
- [ ] support@ai-gate.dev configuré
- [ ] noreply@ai-gate.dev configuré
- [ ] Email personnel vérifié
- [ ] MX records visibles dans DNS

### Stripe
- [ ] Business email = billing@ai-gate.dev
- [ ] Email notifications activées

### Resend (Envoi)
- [ ] Domaine ai-gate.dev ajouté
- [ ] DNS records ajoutés à Cloudflare
- [ ] Domaine vérifié (statut "Verified")
- [ ] API key créée
- [ ] Secret RESEND_API_KEY configuré
- [ ] Test email envoyé avec succès

---

## 🎨 Templates d'emails à créer (Plus tard)

### 1. Welcome Email
```
Subject: Welcome to AI Gate! 🎉
From: AI Gate <noreply@ai-gate.dev>

Hi {name},

Welcome to AI Gate! Your account is ready.

Quick start:
1. Deposit your OpenAI key → /projects/key
2. Get your project_id
3. Start creating sessions

Need help? Reply to support@ai-gate.dev

Best,
The AI Gate Team
```

### 2. Quota Warning (80%)
```
Subject: 80% of your free quota used
From: AI Gate <noreply@ai-gate.dev>

Hi {name},

You've used 80/100 sessions this month.

Upgrade to Pay-as-you-go to keep going:
→ Only $0.10 per successful session
→ Unlimited sessions

[Upgrade Now]

Questions? support@ai-gate.dev
```

### 3. Payment Success
```
Subject: Payment received - Thank you! 💳
From: AI Gate <billing@ai-gate.dev>

Hi {name},

Your payment of ${amount} was successful.

Plan: Pay-as-you-go
Sessions this month: {count}
Next invoice: {date}

[View Invoice] [Manage Billing]

Thanks for using AI Gate!
```

---

## 🔧 Commandes utiles

### Vérifier DNS
```bash
# MX records
dig ai-gate.dev MX +short

# SPF
dig ai-gate.dev TXT +short | grep spf

# DKIM (Resend)
dig resend._domainkey.ai-gate.dev CNAME +short
```

### Tester réception email
```bash
# Envoyer un email test à billing@ai-gate.dev
echo "Test email" | mail -s "Test Subject" billing@ai-gate.dev
```

### Logs Resend
```bash
# Voir les emails envoyés
curl https://api.resend.com/emails \
  -H "Authorization: Bearer re_YOUR_API_KEY"
```

---

## 📊 Monitoring

### Cloudflare Email Routing
```
Dashboard → Email → Email Routing → Analytics
```
- Emails reçus
- Emails forwarded
- Emails rejected (spam)

### Resend
```
Dashboard → Emails
```
- Envoyés
- Delivered
- Bounced
- Spam complaints

---

## 🚨 Troubleshooting

### "Email not received"
1. Vérifier MX records : `dig ai-gate.dev MX`
2. Vérifier spam folder
3. Cloudflare Dashboard → Email Routing → Logs

### "Domain not verified" (Resend)
1. Vérifier DNS records dans Cloudflare
2. Attendre 5-10 min pour propagation
3. Re-cliquer "Verify"

### "SPF fail"
Vérifier que le TXT record contient bien :
```
v=spf1 include:_spf.mx.cloudflare.net include:spf.resend.com ~all
```

---

## 💰 Coûts

- **Cloudflare Email Routing** : Gratuit (illimité)
- **Resend** : Gratuit jusqu'à 3000 emails/mois, puis $20/mois (100k emails)

---

**Setup Time** : 10 minutes
**Status** : Production-ready
**Next** : Créer templates emails + intégrer dans l'app
