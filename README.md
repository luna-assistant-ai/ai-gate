<div align="center">
  <h1>🚀 AI Gate</h1>
  <p><strong>Your AI Integration Platform</strong></p>
  <p>Integrate OpenAI Realtime API into your apps with just your API key. No infrastructure setup required.</p>

  [![Production](https://img.shields.io/badge/Production-Live-success)](https://www.ai-gate.dev)
  [![API Status](https://img.shields.io/badge/API-Online-success)](https://api.ai-gate.dev/health)
  [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
</div>

---

## 📁 Monorepo Structure

This is the main monorepo for **AI Gate**, containing all packages, documentation, and shared scripts.

```
ai-gate/
├── luna-proxy-api/          # API backend (submodule)
├── luna-proxy-web/          # Web frontend (submodule)
├── docs/                    # Centralized documentation
│   ├── deployment/          # Deployment guides
│   ├── setup/               # Setup guides (Stripe, Email, OAuth)
│   ├── architecture/        # Architecture documentation
│   └── migration/           # Migration guides
├── scripts/                 # Shared utility scripts
│   ├── stripe/              # Stripe setup scripts
│   └── cloudflare/          # Cloudflare utilities
└── .github/workflows/       # CI/CD pipelines
```

---

## 🎯 What is AI Gate?

**AI Gate is your integration platform for voice AI.** We handle the complexity of OpenAI Realtime API integration so you can focus on building amazing experiences.

### Key Features

- 🔐 **Secure by Design** - Your OpenAI key, your control
- 🚀 **Zero Configuration** - Start integrating in 5 minutes
- 💻 **Simple API** - One endpoint, clear responses
- 🌍 **Global Edge** - Deployed on Cloudflare Workers
- 🎙️ **WebRTC Included** - TURN credentials provided automatically
- 💳 **Stripe Billing** - Metered usage with multiple tiers

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
# Clone with submodules
git clone --recursive https://github.com/luna-assistant-ai/ai-gate.git
cd ai-gate

# Or update existing clone
git submodule update --init --recursive
```

### 2. Setup Individual Packages

#### API Backend
```bash
cd luna-proxy-api
npm install
cp .dev.vars.example .dev.vars
# Configure your .dev.vars
npm run dev
```

See [luna-proxy-api/README.md](luna-proxy-api/README.md) for full setup.

#### Web Frontend
```bash
cd luna-proxy-web
npm install
cp .env.example .env.local
# Configure your .env.local
npm run dev
```

See [luna-proxy-web/README.md](luna-proxy-web/README.md) for full setup.

---

## 📚 Documentation

### 🚢 Deployment
- [Deployment Guide](docs/deployment/DEPLOYMENT.md) - Complete deployment guide for staging and production

### ⚙️ Setup Guides
- [Stripe Setup](docs/setup/STRIPE-SETUP.md) - Stripe integration (5 min)
- [Email Setup](docs/setup/EMAIL-SETUP.md) - Email routing with Cloudflare (5 min)
- [Pricing Strategy](docs/setup/PRICING-STRATEGY.md) - Pricing tiers and strategy

### 🏗️ Architecture
- [Vault Architecture](docs/architecture/VAULT-ARCHITECTURE.md) - Key encryption and vault design

### 📦 Migration
- [Vault Migration](docs/migration/VAULT-MIGRATION.md) - Migrate to vault-only architecture

---

## 🛠️ Shared Scripts

### Stripe Setup

```bash
# Bootstrap Stripe products and prices
./scripts/stripe/bootstrap.sh test   # Test mode
./scripts/stripe/bootstrap.sh live   # Live mode

# Export Stripe IDs for wrangler secrets
./scripts/stripe/export-ids.sh test

# Setup webhooks
./scripts/stripe/webhook-setup.sh test
```

### Cloudflare Utilities

```bash
# Domain migration helper
./scripts/cloudflare/migrate-domain.sh
```

See [scripts/README.md](scripts/README.md) for complete documentation.

---

## 🏗️ Packages

### [API Backend](https://github.com/luna-assistant-ai/luna-proxy-api)
**OpenAI Realtime API Proxy** - Cloudflare Workers backend

- WebSocket proxy to OpenAI Realtime API
- D1 database for users and projects
- Stripe billing integration
- JWT authentication
- Vault-based key encryption (AES-256-GCM)

**Tech Stack**: Cloudflare Workers, D1, Hono.js, TypeScript

### [Web Frontend](https://github.com/luna-assistant-ai/luna-proxy-web)
**AI Gate Dashboard** - Next.js web application

- User authentication (OAuth + Email/Password)
- Project management dashboard
- OpenAI Realtime API playground
- Stripe billing integration

**Tech Stack**: Next.js 15, NextAuth v5, Cloudflare Pages, Tailwind CSS

---

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
git commit -m "chore: update API to latest"
git push
```

### Commit changes in a submodule
```bash
# Work in the submodule
cd luna-proxy-api
git checkout -b feature/new-feature
# Make changes
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature

# Create PR for the submodule
# Once merged, update parent repo
cd ..
git add luna-proxy-api
git commit -m "chore: update API submodule"
git push
```

---

## 🌐 Production Deployments

- **Website**: https://www.ai-gate.dev
- **API**: https://api.ai-gate.dev
- **API Health**: https://api.ai-gate.dev/health
- **Status**: ✅ Live on Cloudflare Workers

### Staging

- **API**: https://staging.ai-gate.dev
- **Web**: https://luna-proxy-web-frontend-staging.joffrey-vanasten.workers.dev

---

## 💻 Tech Stack

### Backend (API)
- **Runtime**: Cloudflare Workers
- **Database**: D1 (SQLite)
- **Framework**: Hono.js
- **Language**: TypeScript
- **Billing**: Stripe
- **Encryption**: AES-256-GCM envelope encryption

### Frontend (Web)
- **Runtime**: Cloudflare Pages
- **Framework**: Next.js 15 (App Router)
- **Authentication**: NextAuth v5
- **Styling**: Tailwind CSS v4
- **Language**: TypeScript
- **UI**: React 19 (Server Components)

### Infrastructure
- **DNS**: Cloudflare
- **Email**: Cloudflare Email Routing + Resend
- **Storage**: Cloudflare D1, KV
- **CDN**: Cloudflare Global Network

---

## 🔐 Security

- **Key Encryption**: AES-256-GCM envelope encryption
- **Key Storage**: Never stored in plaintext
- **Session Tokens**: JWT with short expiration
- **Rate Limiting**: Per API key and IP
- **CORS**: Configurable per environment
- **Secrets Management**: Wrangler secrets (never committed)

---

## 📊 Pricing Plans

- **Free**: 200 minutes/month (app enforced)
- **Starter**: $9/mo, 1500 min included, $0.012/min overage
- **Build**: $19/mo, 3000 min included, $0.011/min overage
- **Pro**: $39/mo, 8000 min included, $0.009/min overage
- **Agency**: $99/mo, 25000 min included, $0.008/min overage
- **Enterprise**: Custom pricing

See [Pricing Strategy](docs/setup/PRICING-STRATEGY.md) for details.

---

## 🤝 Contributing

### For Contributors
1. Fork the repository
2. Clone with submodules: `git clone --recursive`
3. Create a feature branch
4. Make your changes in the appropriate package
5. Test locally
6. Submit a pull request

### Development Workflow
1. Work in the appropriate submodule (`luna-proxy-api` or `luna-proxy-web`)
2. Create a PR in that repository
3. Once merged, update the parent monorepo to reference the new commit

### Code Standards
- TypeScript strict mode
- ESLint + Prettier
- Conventional commits
- Tests required for new features

---

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🔗 Links

- **Production**: https://www.ai-gate.dev
- **API Docs**: https://api.ai-gate.dev
- **GitHub Org**: https://github.com/luna-assistant-ai
- **Support**: https://github.com/luna-assistant-ai/ai-gate/issues

---

<div align="center">
  <p><strong>Built with ❤️ for developers building the future of AI</strong></p>
  <p>AI Gate - Your gateway to AI APIs</p>
</div>
