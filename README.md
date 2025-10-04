# Luna Proxy Projects

**Monorepo for Luna Proxy - OpenAI Realtime API Gateway**

## 📁 Repository Structure

This monorepo contains documentation, shared scripts, and references to the main Luna Proxy projects:

```
luna-proxy-projects/
├── luna-proxy-api/          # API backend (submodule)
├── luna-proxy-web/          # Web frontend (submodule)
├── scripts/                 # Shared utility scripts
│   ├── stripe-bootstrap.sh
│   ├── stripe-export-ids.sh
│   └── stripe-webhook-setup.sh
├── DEPLOYMENT.md            # Deployment guide
├── STRIPE-SETUP-GUIDE.md    # Stripe integration guide
├── EMAIL-SETUP-GUIDE.md     # Email routing setup
└── STRIPE-PRICING-STRATEGY.md
```

## 🚀 Quick Start

### 1. Clone with Submodules

```bash
git clone --recursive https://github.com/luna-assistant-ai/luna-proxy-projects.git
cd luna-proxy-projects
```

Or if already cloned:

```bash
git submodule update --init --recursive
```

### 2. Setup Individual Projects

#### API Backend
```bash
cd luna-proxy-api
npm install
# See luna-proxy-api/README.md for configuration
```

#### Web Frontend
```bash
cd luna-proxy-web
npm install
# See luna-proxy-web/README.md for configuration
```

## 📚 Documentation

### Setup Guides
- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide
- [STRIPE-SETUP-GUIDE.md](STRIPE-SETUP-GUIDE.md) - Stripe integration (5 min)
- [EMAIL-SETUP-GUIDE.md](EMAIL-SETUP-GUIDE.md) - Email routing setup (5 min)
- [STRIPE-PRICING-STRATEGY.md](STRIPE-PRICING-STRATEGY.md) - Pricing tiers

### Migration Guides
- [VAULT-ONLY-MIGRATION.md](VAULT-ONLY-MIGRATION.md) - Vault-only migration

## 🛠️ Shared Scripts

### Stripe Setup
```bash
# Bootstrap Stripe products and prices
./scripts/stripe-bootstrap.sh test   # Test mode
./scripts/stripe-bootstrap.sh live   # Live mode

# Export Stripe IDs for wrangler secrets
./scripts/stripe-export-ids.sh test

# Setup webhooks
./scripts/stripe-webhook-setup.sh test
```

## 🏗️ Projects

### [luna-proxy-api](https://github.com/luna-assistant-ai/luna-proxy-api)
Cloudflare Workers API backend for OpenAI Realtime API proxying
- WebSocket proxy
- D1 database
- Stripe billing
- JWT authentication

### [luna-proxy-web](https://github.com/luna-assistant-ai/luna-proxy-web)
Next.js web frontend
- Dashboard
- Playground
- OAuth authentication
- Cloudflare Pages deployment

## 🔄 Working with Submodules

### Update all submodules to latest
```bash
git submodule update --remote
```

### Update a specific submodule
```bash
cd luna-proxy-api
git pull origin main
cd ..
git add luna-proxy-api
git commit -m "chore: update luna-proxy-api"
```

### Commit changes in submodules
```bash
# Work in the submodule
cd luna-proxy-api
git add .
git commit -m "feat: new feature"
git push

# Update parent repo to track new commit
cd ..
git add luna-proxy-api
git commit -m "chore: update luna-proxy-api to latest"
git push
```

## 🔐 Security

- All API keys and secrets are stored in Wrangler secrets
- Setup scripts with hardcoded credentials are gitignored
- See [.gitignore](.gitignore) for excluded files

## 🌐 Live Deployments

- **Production**: https://www.ai-gate.dev
- **API**: https://api.ai-gate.dev
- **Staging API**: https://luna-proxy-api-staging.joffrey-vanasten.workers.dev

## 📊 Tech Stack

### Backend (luna-proxy-api)
- Cloudflare Workers
- D1 (SQLite)
- Hono.js
- TypeScript

### Frontend (luna-proxy-web)
- Next.js 15
- NextAuth v5
- Cloudflare Pages
- Tailwind CSS

### Infrastructure
- Cloudflare DNS
- Cloudflare Email Routing
- Resend (transactional emails)
- Stripe (billing)

## 📝 Contributing

1. Make changes in the appropriate submodule
2. Commit and push the submodule changes
3. Update the parent repo to reference the new commit
4. Update documentation in this monorepo if needed

## 📄 License

MIT
