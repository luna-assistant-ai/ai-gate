# Instructions pour Claude - AI Gate Project

> **Last Updated**: 2025-10-04
> **Project**: AI Gate - Your AI Integration Platform
> **Monorepo**: https://github.com/luna-assistant-ai/ai-gate

---

## 🎯 Contexte du projet

**AI Gate** est une plateforme d'intégration pour l'API OpenAI Realtime, déployée sur Cloudflare Workers.

### Architecture Monorepo (Git Submodules)

```
ai-gate/
├── luna-proxy-api/          # Backend API (submodule)
├── luna-proxy-web/          # Frontend Next.js (submodule)
├── luna-proxy-dashboard/    # Dashboard (submodule)
├── docs/                    # Documentation centralisée
│   ├── deployment/
│   ├── setup/
│   ├── architecture/
│   └── migration/
└── scripts/                 # Scripts partagés (Stripe, Cloudflare)
```

**Tech Stack:**
- **Backend**: Cloudflare Workers, D1, Hono.js, TypeScript
- **Frontend**: Next.js 15, NextAuth v5, Cloudflare Pages, Tailwind CSS
- **Infrastructure**: Cloudflare (DNS, Email, Storage), Stripe, Resend

---

## 👤 Préférences de Travail de Joffrey

### Communication
- ✅ **Direct et concis** - Pas de verbiage inutile
- ✅ **"ok fais le"** = lance-toi sans demander confirmation
- ✅ **Proactif** - Anticipe les besoins et propose des solutions
- ✅ **Architecte** - Pense structure, organisation, best practices
- ❌ **Pas de longues explications** avant d'agir

### Workflow Préféré
1. **Analyse rapide** → Recommandation claire → Action
2. **TodoWrite systématique** pour tracker le progrès
3. **Commits avec messages détaillés** (conventional commits)
4. **Organisation professionnelle** - Clean code, docs, structure

### Style de Décision
- Propose des options avec **ta recommandation** (⭐)
- Si tu es sûr → **fais-le directement**
- Si incertain → **demande confirmation rapide**

---

## 🚨 Pièges Critiques à Éviter

### 1. Worker-to-Worker Communication
**TOUJOURS** utiliser `INTERNAL_API_URL` (workers.dev) pour les appels entre workers.

```typescript
// ❌ MAUVAIS - timeout 522
const API_URL = "https://api.ai-gate.dev";

// ✅ BON - utilise workers.dev en interne
const INTERNAL_API_URL = "https://luna-proxy-api.joffrey-vanasten.workers.dev";
```

### 2. Accès aux Variables Cloudflare
Dans les API routes Next.js :

```typescript
// ✅ BON
import { getCloudflareContext } from '@opennextjs/cloudflare';
const { env } = getCloudflareContext();
const db = env.DB;

// ❌ MAUVAIS
const db = context?.env?.DB; // undefined!
```

### 3. Secrets vs Variables
- **Secrets**: `process.env.SECRET_NAME` (NOT in getCloudflareContext().env)
- **Variables**: Définies dans `wrangler.toml` [vars]
- **Les variables ne sont PAS héritées** - Redéfinir par environnement

```toml
# ❌ MAUVAIS - Variables manquantes en production
[vars]
INTERNAL_API_URL = "https://luna-proxy-api.workers.dev"

[env.production.vars]
NEXT_PUBLIC_API_URL = "https://api.ai-gate.dev"
# INTERNAL_API_URL manquante !

# ✅ BON - Toutes les variables redéfinies
[vars]
INTERNAL_API_URL = "https://luna-proxy-api.workers.dev"

[env.production.vars]
NEXT_PUBLIC_API_URL = "https://api.ai-gate.dev"
INTERNAL_API_URL = "https://luna-proxy-api.workers.dev"  # Redéfinie !
```

### 4. Base de Données D1
- **Local**: Pas de `--remote`
- **Production**: **TOUJOURS** `--remote`

```bash
# ✅ Production
wrangler d1 execute luna-proxy-users --file=schema.sql --remote

# ✅ Local
wrangler d1 execute luna-proxy-users --file=schema.sql
```

### 5. Git Submodules
Les changements dans `luna-proxy-api/`, `luna-proxy-web/`, `luna-proxy-dashboard/` doivent être committés **dans le submodule**, puis la référence mise à jour dans le monorepo parent.

```bash
# ✅ BON - Commit dans le submodule
cd luna-proxy-api
git add .
git commit -m "feat: new feature"
git push

# Puis update la référence dans le parent
cd ..
git add luna-proxy-api
git commit -m "chore: update API submodule"
git push

# ❌ MAUVAIS - Commit direct dans le parent
git add luna-proxy-api/src/file.ts  # Ne marche pas !
```

---

## 🔑 Secrets Requis

### luna-proxy-api
- `ADMIN_API_KEY` - Admin endpoints
- `JWT_SECRET` - JWT signing
- `KEK_V1` - Vault encryption key
- `CF_TURN_API_TOKEN` - TURN credentials
- `CF_ACCOUNT_ID` - Cloudflare account
- `STRIPE_SECRET_KEY` - Stripe API key
- `STRIPE_WEBHOOK_SECRET` - Stripe webhooks

### luna-proxy-web
- `ADMIN_API_KEY` - Doit matcher l'API
- `AUTH_SECRET` - NextAuth
- `GOOGLE_CLIENT_SECRET` - OAuth Google
- `GITHUB_CLIENT_SECRET` - OAuth GitHub

---

## 🛠️ Commandes Fréquentes

### Monorepo Git

```bash
# Clone avec submodules
git clone --recursive https://github.com/luna-assistant-ai/ai-gate.git

# Update submodules
git submodule update --remote

# Update un submodule spécifique
cd luna-proxy-api
git pull origin main
cd ..
git add luna-proxy-api
git commit -m "chore: update API submodule"
```

### Build & Deploy

```bash
# Web (Production)
cd luna-proxy-web
npm run build:cf
wrangler deploy --env production

# API (Production)
cd luna-proxy-api
wrangler deploy

# Staging
wrangler deploy --env staging
```

### Debug

```bash
# Logs temps réel
wrangler tail luna-proxy-web-frontend --format pretty
wrangler tail luna-proxy-api --format pretty

# Vérifier déploiement
wrangler deployments list --name worker-name

# Lister secrets
wrangler secret list
wrangler secret list --env staging
```

### Base de Données

```bash
# Init DB production
cd luna-proxy-web
wrangler d1 execute luna-proxy-users --file=schema.sql --remote

# Vérifier tables
wrangler d1 execute luna-proxy-users --remote --command "SELECT name FROM sqlite_master WHERE type='table';"

# Lister bases
wrangler d1 list
```

### Scripts Partagés

```bash
# Stripe setup
./scripts/stripe/bootstrap.sh test      # Create products
./scripts/stripe/webhook-setup.sh test  # Setup webhooks
./scripts/stripe/export-ids.sh test     # Export IDs

# Deploy
./scripts/deploy.sh
```

---

## ⚡ Workflow de Déploiement

### 1. Développement Local
- Tester en local
- Commit dans le submodule approprié
- Push le submodule

### 2. Deploy Staging
```bash
wrangler deploy --env staging
```
- Tester sur staging
- Valider fonctionnalités

### 3. Deploy Production
```bash
# Vérifications
wrangler secret list
wrangler d1 list

# Build
npm run build:cf

# Deploy
wrangler deploy --env production

# Wait & Test
sleep 30
curl https://api.ai-gate.dev/health
```

### 4. Update Monorepo
```bash
cd /path/to/ai-gate
git add luna-proxy-api luna-proxy-web
git commit -m "chore: update submodules"
git push
```

---

## 🐛 Debugging Checklist

### Signup Ne Marche Pas
- [ ] DB initialisée ? `wrangler d1 list`
- [ ] Tables créées ? Execute schema
- [ ] `getCloudflareContext()` utilisé ?
- [ ] Logs : `wrangler tail`

### Création Projet Ne Marche Pas
- [ ] `INTERNAL_API_URL` dans wrangler.toml ?
- [ ] `ADMIN_API_KEY` dans secrets web ET api ?
- [ ] API répond ? `curl <workers.dev>/health`
- [ ] Erreur 522 ? → Check INTERNAL_API_URL

### Erreur 522
→ Appel worker-to-worker via custom domain
→ **Solution**: Utiliser INTERNAL_API_URL (.workers.dev)

---

## 📝 Conventions

### Commits (Conventional Commits)
```
feat: nouvelle fonctionnalité
fix: correction de bug
docs: documentation
chore: maintenance
refactor: refactoring
perf: performance
test: tests
ci: CI/CD
```

**Format:**
```
type(scope): subject

body

footer
```

**Example:**
```
feat(api): add email routing endpoints

- Add /admin/setup-emails endpoint
- Add Resend integration helpers
- Update documentation

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Documentation
- **Markdown** pour tous les docs
- **Code examples** avec syntax highlighting
- **Liens relatifs** pour navigation
- **Emojis** pour sections (🎯 🚀 ✅ ❌ ⚠️)

### Code Style
- **TypeScript strict mode**
- **ESLint + Prettier**
- **2 spaces indentation**
- **Single quotes**
- **Named exports** over default

---

## 🚀 URLs Importantes

### Production
- **Web**: https://www.ai-gate.dev
- **API (public)**: https://api.ai-gate.dev
- **API (internal)**: https://luna-proxy-api.joffrey-vanasten.workers.dev
- **GitHub**: https://github.com/luna-assistant-ai/ai-gate

### Staging
- **Web**: https://luna-proxy-web-frontend-staging.joffrey-vanasten.workers.dev
- **API**: https://staging.ai-gate.dev

---

## 💡 Tips pour Claude

### Proactivité
1. **Utilise TodoWrite** systématiquement pour tracker les tâches
2. **Propose des solutions** avec ta recommandation ⭐
3. **Agis directement** quand tu es sûr
4. **Commits détaillés** avec conventional commits

### Organisation
1. **Vérifie la cohérence** entre docs, code, structure
2. **Pense architecture** - Où ce fichier devrait-il être ?
3. **Clean code** - Pas de fichiers temporaires committés
4. **Documentation** - Update docs avec les changements

### Git Submodules
1. **Toujours commit dans le submodule d'abord**
2. Puis update la référence dans le parent
3. Ne jamais commit directement des fichiers dans `luna-proxy-*/`

### Sécurité
1. **Jamais commit de secrets**
2. **Vérifier .gitignore** avant d'ajouter de nouveaux fichiers
3. **Stripe IDs** dans scripts/stripe-ids.*.json → gitignored
4. **Setup scripts** avec clés hardcodées → gitignored

---

## ⚠️ Ne JAMAIS Faire

- ❌ Déployer sans build
- ❌ Utiliser custom domain pour worker-to-worker
- ❌ Oublier `--remote` pour D1 en production
- ❌ Créer des MD files sans raison (sauf si demandé)
- ❌ Push des secrets dans git
- ❌ Utiliser `context?.env` au lieu de `getCloudflareContext()`
- ❌ Commit dans le parent au lieu du submodule
- ❌ Oublier de redéfinir les variables par environnement

---

## ✅ Toujours Faire

- ✅ Vérifier secrets avant deploy
- ✅ Attendre 30s après deploy
- ✅ Hard refresh navigateur (Cmd+Shift+R)
- ✅ Check logs après deploy
- ✅ Tester en staging d'abord
- ✅ Commit + push après validation
- ✅ Update docs si nouveaux pièges découverts
- ✅ TodoWrite pour tracker les tâches complexes
- ✅ Commit dans le submodule, puis update référence parent

---

## 🔄 Processus de Résolution de Problèmes

1. **Identifier**: Logs + error messages
2. **Vérifier**: Secrets, variables, DB, submodules
3. **Tester**: Appels directs API, curl
4. **Corriger**: Code changes (dans le bon submodule!)
5. **Build**: `npm run build:cf`
6. **Deploy**: `wrangler deploy`
7. **Valider**: Tests manuels + logs
8. **Commit**: Submodule → Parent
9. **Documenter**: Update docs si nouveau piège

---

## 📚 Documentation Structure

```
docs/
├── README.md              # Index principal
├── deployment/
│   └── DEPLOYMENT.md      # Guide complet
├── setup/
│   ├── STRIPE-SETUP.md
│   ├── EMAIL-SETUP.md
│   └── PRICING-STRATEGY.md
├── architecture/
│   └── VAULT-ARCHITECTURE.md
├── migration/
│   └── VAULT-MIGRATION.md
└── internal/
    └── *.md               # Docs internes
```

**Liens importants:**
- [Main README](../README.md)
- [Documentation Index](../docs/README.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [Changelog](../CHANGELOG.md)

---

## 🎯 Objectifs du Projet

1. **Production-ready** - Déploiements stables et fiables
2. **Well-documented** - Docs claires et à jour
3. **Professional** - Code, structure, organisation
4. **Scalable** - Architecture monorepo avec submodules
5. **Secure** - Secrets protégés, encryption, best practices

---

## 🤝 Collaboration Efficace

### Quand Joffrey dit:
- **"ok"** → Fais-le directement
- **"que recommandes-tu"** → Donne 2-3 options avec ta recommandation ⭐
- **"verifie"** → Analyse détaillée + recommandations
- **"ameliore"** → Optimise sans demander

### Style de réponse:
- **Court et direct** - Pas de blabla
- **Actions concrètes** - Commandes, code, exemples
- **TodoWrite** - Pour tracker les tâches complexes
- **Badges de statut** - ✅ ❌ ⚠️ pour clarté visuelle

---

**Last sync**: 2025-10-04
**Version**: 2.0
**Status**: Production-ready monorepo avec 3 submodules

🚀 **AI Gate - Your gateway to AI APIs**
