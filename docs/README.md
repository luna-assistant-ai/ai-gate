# AI Gate Documentation

> **Complete documentation for AI Gate - Your AI Integration Platform**

This directory contains all documentation for the AI Gate project.

---

## 📁 Documentation Structure

```
docs/
├── deployment/          # Deployment and infrastructure
├── setup/              # Setup and configuration guides
├── architecture/       # System architecture and design
├── migration/          # Migration guides
└── internal/           # Internal documentation
```

---

## 🚀 Getting Started

### For Developers

1. **[Quick Start](../README.md#quick-start)** - Clone and setup the project
2. **[Contributing Guide](../CONTRIBUTING.md)** - How to contribute
3. **[API Documentation](../luna-proxy-api/README.md)** - API backend docs
4. **[Web Documentation](../luna-proxy-web/README.md)** - Web frontend docs

### For Deployers

1. **[Deployment Guide](deployment/DEPLOYMENT.md)** - Complete deployment instructions
2. **[Stripe Setup](setup/STRIPE-SETUP.md)** - Configure billing
3. **[Email Setup](setup/EMAIL-SETUP.md)** - Configure email routing

---

## 📚 Documentation Index

### 🚢 Deployment

| Document | Description |
|----------|-------------|
| [DEPLOYMENT.md](deployment/DEPLOYMENT.md) | Complete deployment guide for staging and production |

**Covers:**
- Cloudflare Workers deployment
- Environment configuration
- Common issues and solutions
- Monitoring and debugging

---

### ⚙️ Setup Guides

| Document | Description | Time |
|----------|-------------|------|
| [STRIPE-SETUP.md](setup/STRIPE-SETUP.md) | Stripe integration guide | 5-10 min |
| [EMAIL-SETUP.md](setup/EMAIL-SETUP.md) | Email routing with Cloudflare + Resend | 5-10 min |
| [PRICING-STRATEGY.md](setup/PRICING-STRATEGY.md) | Pricing tiers and strategy | - |

#### Stripe Setup
- Create products and prices
- Configure webhooks
- Set up secrets
- Test billing flow

**Quick Start:**
```bash
# Bootstrap Stripe
./scripts/stripe/bootstrap.sh test

# Setup webhooks
./scripts/stripe/webhook-setup.sh test

# Export secrets
./scripts/stripe/export-ids.sh test
```

#### Email Setup
- Cloudflare Email Routing (receiving)
- Resend (sending)
- Domain verification
- Email templates

**Addresses:**
- `billing@ai-gate.dev` - Billing notifications
- `support@ai-gate.dev` - Customer support
- `noreply@ai-gate.dev` - Transactional emails (send-only)

---

### 🏗️ Architecture

| Document | Description |
|----------|-------------|
| [VAULT-ARCHITECTURE.md](architecture/VAULT-ARCHITECTURE.md) | Key encryption and vault design |

**Covers:**
- AES-256-GCM envelope encryption
- Key Encryption Key (KEK) management
- Data Encryption Key (DEK) generation
- Security best practices

**Key Concepts:**
- **Vault**: Encrypted key storage in D1
- **KEK**: Master encryption key (stored in Wrangler secrets)
- **DEK**: Per-project encryption keys
- **Ciphertext**: Encrypted OpenAI keys

---

### 📦 Migration

| Document | Description |
|----------|-------------|
| [VAULT-MIGRATION.md](migration/VAULT-MIGRATION.md) | Migrate to vault-only architecture |

**Covers:**
- Migration from direct API keys to vault
- Database schema updates
- API endpoint changes
- Backwards compatibility

---

### 🔒 Internal Documentation

| Document | Description |
|----------|-------------|
| [CLOUDFLARE-CALLS-TOKEN.md](internal/CLOUDFLARE-CALLS-TOKEN.md) | Cloudflare Calls TURN token setup |
| [IMPROVEMENTS-2025-10-03.md](internal/IMPROVEMENTS-2025-10-03.md) | Project improvements log |

---

## 🎯 Common Tasks

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone --recursive https://github.com/luna-assistant-ai/ai-gate.git
   cd ai-gate
   ```

2. **Setup Stripe**
   - Follow [STRIPE-SETUP.md](setup/STRIPE-SETUP.md)
   - Run bootstrap scripts
   - Configure secrets

3. **Setup Email**
   - Follow [EMAIL-SETUP.md](setup/EMAIL-SETUP.md)
   - Configure Cloudflare Email Routing
   - Setup Resend for sending

4. **Deploy**
   - Follow [DEPLOYMENT.md](deployment/DEPLOYMENT.md)
   - Deploy to staging first
   - Test thoroughly
   - Deploy to production

### Deployment

```bash
# Deploy API (staging)
cd luna-proxy-api
wrangler deploy --env staging

# Deploy Web (staging)
cd ../luna-proxy-web
npm run build:cf
wrangler deploy --env staging

# Production (remove --env flag)
```

### Troubleshooting

See [DEPLOYMENT.md](deployment/DEPLOYMENT.md) for:
- Common errors and fixes
- 522 timeouts (Worker-to-Worker)
- D1 database issues
- Environment variable problems
- OAuth user ID mismatches

---

## 🛠️ Scripts

All shared scripts are documented in [scripts/README.md](../scripts/README.md).

### Stripe Scripts

- `scripts/stripe/bootstrap.sh` - Create products and prices
- `scripts/stripe/export-ids.sh` - Export IDs for secrets
- `scripts/stripe/webhook-setup.sh` - Configure webhooks

### Cloudflare Scripts

- `scripts/cloudflare/migrate-domain.sh` - Domain migration helper
- `scripts/deploy.sh` - Deployment script

---

## 📊 Architecture Overview

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
       ↓
┌─────────────────────────────────────────┐
│  Cloudflare Pages (luna-proxy-web)      │
│  - Next.js 15                           │
│  - NextAuth v5                          │
│  - D1 (users, projects metadata)        │
└──────┬──────────────────────────────────┘
       │ INTERNAL_API_URL
       │ (workers.dev)
       ↓
┌─────────────────────────────────────────┐
│  Cloudflare Workers (luna-proxy-api)    │
│  - Hono.js API                          │
│  - D1 (vault, audit logs)               │
│  - Stripe billing                       │
│  - Key encryption (AES-256-GCM)         │
└──────┬──────────────────────────────────┘
       │
       ↓
┌─────────────────────────────────────────┐
│  OpenAI Realtime API                    │
│  - WebSocket proxy                      │
│  - Voice AI conversations               │
└─────────────────────────────────────────┘
```

---

## 🔐 Security

### Key Principles

1. **Encryption at Rest**: All OpenAI API keys encrypted in D1
2. **Encryption in Transit**: HTTPS/WSS only
3. **Key Isolation**: Each project has unique DEK
4. **KEK Protection**: Master key stored as Wrangler secret
5. **No Plaintext**: Keys never stored unencrypted

### Security Docs

- [Vault Architecture](architecture/VAULT-ARCHITECTURE.md)
- [Deployment Security](deployment/DEPLOYMENT.md#security)

---

## 💡 Best Practices

### Development

1. Always work in feature branches
2. Test locally before deploying
3. Use conventional commits
4. Update documentation with code changes
5. Add tests for new features

### Deployment

1. Deploy to staging first
2. Test thoroughly before production
3. Monitor logs after deployment
4. Keep secrets secure (never commit)
5. Use environment-specific configs

### Documentation

1. Keep docs up to date
2. Include code examples
3. Document breaking changes
4. Add troubleshooting sections
5. Link related docs

---

## 📝 Contributing to Docs

Found an error or want to improve documentation?

1. Edit the relevant `.md` file
2. Follow [Markdown best practices](https://www.markdownguide.org/basic-syntax/)
3. Submit a PR with clear description
4. Reference related issues if applicable

---

## 🔗 External Resources

- **OpenAI Realtime API**: https://platform.openai.com/docs/guides/realtime
- **Cloudflare Workers**: https://developers.cloudflare.com/workers/
- **Cloudflare D1**: https://developers.cloudflare.com/d1/
- **Next.js**: https://nextjs.org/docs
- **Stripe**: https://stripe.com/docs

---

## ❓ Need Help?

- 💬 [GitHub Discussions](https://github.com/luna-assistant-ai/ai-gate/discussions)
- 🐛 [Report Issues](https://github.com/luna-assistant-ai/ai-gate/issues)
- 📧 Email: support@ai-gate.dev

---

<div align="center">
  <p><strong>AI Gate - Your gateway to AI APIs</strong></p>
  <p>Built with ❤️ for developers</p>
</div>
