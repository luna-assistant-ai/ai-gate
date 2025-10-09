# Configuration Secrets Store Cloudflare

## Objectif
Utiliser le Secrets Store Cloudflare pour centraliser tous les secrets au lieu de les dupliquer dans chaque Worker.

## Secrets Store ID
`e0cc9185036e40cebc8c4b86840a961f`

## Avantages du Secrets Store
- ✅ Centralisation : Un seul endroit pour gérer tous les secrets
- ✅ Rotation facile : Mettre à jour un secret une seule fois
- ✅ Sécurité : Moins de duplication = moins de risques
- ✅ Audit : Meilleure traçabilité des accès

## Configuration dans wrangler.toml

### API (luna-proxy-api)

Ajouter dans `wrangler.toml` :

```toml
# Secrets Store binding
[[unsafe.bindings]]
type = "secret_store"
binding = "SECRETS"
id = "e0cc9185036e40cebc8c4b86840a961f"

[env.production]
# ... existing config ...

# Secrets Store binding pour production
[[env.production.unsafe.bindings]]
type = "secret_store"
binding = "SECRETS"
id = "e0cc9185036e40cebc8c4b86840a961f"
```

### Web (luna-proxy-web)

Ajouter dans `wrangler.toml` :

```toml
# Secrets Store binding
[[unsafe.bindings]]
type = "secret_store"
binding = "SECRETS"
id = "e0cc9185036e40cebc8c4b86840a961f"

[env.production]
# ... existing config ...

# Secrets Store binding pour production
[[env.production.unsafe.bindings]]
type = "secret_store"
binding = "SECRETS"
id = "e0cc9185036e40cebc8c4b86840a961f"
```

## Utilisation dans le code

### Avant (secrets individuels)
```typescript
const stripeKey = env.STRIPE_SECRET_KEY;
const jwtSecret = env.JWT_SECRET;
```

### Après (Secrets Store)
```typescript
const stripeKey = await env.SECRETS.get("STRIPE_SECRET_KEY");
const jwtSecret = await env.SECRETS.get("JWT_SECRET");
```

## Migration des secrets vers le Secrets Store

### 1. Vérifier les secrets actuels dans le Secrets Store

Via le dashboard Cloudflare :
https://dash.cloudflare.com/602a3ee367f65632af4cab4ca55b46e7/secrets-store/e0cc9185036e40cebc8c4b86840a961f

### 2. Ajouter les secrets manquants

Pour chaque secret qui n'est pas encore dans le Secrets Store, l'ajouter via le dashboard ou l'API.

#### Secrets API (luna-proxy-api)
- `ADMIN_API_KEY`
- `CF_ACCOUNT_ID`
- `CF_AUTH_EMAIL`
- `CF_AUTH_KEY`
- `CF_TURN_API_TOKEN`
- `CF_TURN_KEY_API_TOKEN`
- `CF_TURN_KEY_ID`
- `JWT_SECRET`
- `KEK_V1`
- `STRIPE_PRICE_GROWTH`
- `STRIPE_PRICE_STARTER`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`

#### Secrets Web (luna-proxy-web)
- `ADMIN_API_KEY`
- `AUTH_SECRET`
- `GITHUB_CLIENT_SECRET`
- `GOOGLE_CLIENT_SECRET`
- `NEXTAUTH_SECRET`

### 3. Modifier le code pour utiliser le Secrets Store

#### API - src/utils/stripe.ts
```typescript
export function getStripeClient(env: Env): Stripe {
  const stripeKey = await env.SECRETS.get('STRIPE_SECRET_KEY');
  if (!stripeKey) {
    throw new Error('STRIPE_SECRET_KEY not configured');
  }

  return new Stripe(stripeKey, {
    httpClient: Stripe.createFetchHttpClient(),
  });
}
```

#### API - src/types.ts
```typescript
export interface Env {
  // ... existing bindings ...

  // Secrets Store
  SECRETS: {
    get(key: string): Promise<string | null>;
  };
}
```

### 4. Migration progressive (recommandé)

Pour éviter les interruptions, utiliser un fallback :

```typescript
async function getSecret(env: Env, key: string): Promise<string | null> {
  // Try Secrets Store first
  if (env.SECRETS) {
    const value = await env.SECRETS.get(key);
    if (value) return value;
  }

  // Fallback to individual secret
  return env[key] || null;
}

// Usage
const stripeKey = await getSecret(env, 'STRIPE_SECRET_KEY');
```

## ⚠️ Limitations et considérations

### 1. API asynchrone
Les secrets du Secrets Store sont récupérés de manière **asynchrone** :
```typescript
// ❌ Ne marche pas
const key = env.SECRETS.STRIPE_SECRET_KEY;

// ✅ Correct
const key = await env.SECRETS.get('STRIPE_SECRET_KEY');
```

### 2. Performance
- Premier appel : ~10-20ms (fetch depuis le store)
- Appels suivants : Potentiellement cachés
- Impact : Négligeable pour la plupart des use cases

### 3. Code synchrone
Si ton code actuel est synchrone, il faudra le rendre asynchrone :
```typescript
// Avant (synchrone)
function initStripe(env: Env) {
  return new Stripe(env.STRIPE_SECRET_KEY);
}

// Après (asynchrone)
async function initStripe(env: Env) {
  const key = await env.SECRETS.get('STRIPE_SECRET_KEY');
  return new Stripe(key);
}
```

## Plan de migration

### Phase 1 : Configuration (non-bloquant)
1. ✅ Ajouter les bindings Secrets Store dans wrangler.toml
2. ✅ Déployer (le binding sera disponible mais non utilisé)

### Phase 2 : Helpers (non-bloquant)
1. ✅ Créer une fonction helper `getSecret(env, key)`
2. ✅ Implémenter le fallback (Secrets Store → secret individuel)

### Phase 3 : Migration du code (progressif)
1. ✅ Migrer une route à la fois (ex: /billing/checkout)
2. ✅ Tester en staging
3. ✅ Déployer en production
4. ✅ Répéter pour chaque route

### Phase 4 : Nettoyage (optionnel)
1. ⚠️ Supprimer les secrets individuels
2. ⚠️ Supprimer le code fallback

## Alternative simple : Garder les secrets individuels

Si la migration vers Secrets Store est trop complexe, tu peux continuer à utiliser les secrets individuels actuels. Ils fonctionnent très bien et sont déjà configurés.

**Avantages des secrets individuels :**
- ✅ Plus simple (pas de code async)
- ✅ Déjà configurés et fonctionnels
- ✅ Pas de migration nécessaire

**Inconvénients :**
- ⚠️ Duplication des secrets entre Workers
- ⚠️ Rotation plus complexe (N Workers × M secrets)

## Recommandation

**Pour l'instant : GARDER les secrets individuels**

Raisons :
1. Ils fonctionnent parfaitement
2. Pas de complexité ajoutée
3. Pas de risque de casser la production
4. Migration vers Secrets Store peut se faire plus tard si besoin

**Si tu veux vraiment utiliser Secrets Store :**
1. Commence par staging uniquement
2. Teste bien le code asynchrone
3. Migre une route à la fois
4. Garde le fallback pendant plusieurs semaines

## Commandes utiles

### Ajouter un secret au Secrets Store (via dashboard uniquement)
Il n'y a pas de commande wrangler pour ça actuellement, il faut passer par le dashboard Cloudflare.

### Lister les bindings d'un Worker
```bash
wrangler deployments list --env production | head -20
```

### Tester un secret
```bash
# API
curl -H "Authorization: Bearer <ADMIN_API_KEY>" https://api.ai-gate.dev/admin/health

# Test Stripe
curl -X POST https://api.ai-gate.dev/billing/checkout \
  -H "Content-Type: application/json" \
  -d '{"plan":"starter","user_id":"test","email":"test@example.com"}'
```

## Conclusion

**Status actuel : ✅ Tous les secrets sont configurés et fonctionnels**

Tu n'as **pas besoin** de migrer vers Secrets Store maintenant. Les secrets individuels fonctionnent parfaitement.

Si tu veux quand même utiliser Secrets Store, je te recommande de :
1. Commencer par staging
2. Créer un helper avec fallback
3. Migrer progressivement
4. Garder les secrets individuels en fallback pendant au moins 1 mois
