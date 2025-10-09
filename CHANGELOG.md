# Changelog

All notable changes to AI Gate will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Comprehensive documentation structure in `docs/`
- `CONTRIBUTING.md` with contribution guidelines
- `docs/README.md` as documentation index
- Git submodule for `luna-proxy-dashboard`

### Changed
- **BREAKING**: Reorganized monorepo structure
- Rebranded from "Luna Proxy Projects" to "AI Gate"
- Moved all documentation to `docs/` subdirectories
- Reorganized scripts into `scripts/stripe/` and `scripts/cloudflare/`
- Updated all README files for consistency

### Removed
- Obsolete documentation files
- Temporary setup scripts moved to gitignore

---

## [1.1.0] - 2025-10-05

### Changed
- OpenNext packaging for Cloudflare Workers stabilized: `output: 'standalone'`, `prepare:standalone` script, and `build:cf` with `--skipNextBuild`.
- Build/deploy scripts (web): `build:staging`, `build:production`, `deploy:staging`, `deploy:production`.
- Cloudflare bindings alignment: explicit `INTERNAL_API_URL` (prod/staging) and dedicated KV RATE_LIMIT in staging.

### Fixed
- OpenNext bundling error (missing pages-manifest) resolved via standalone + preparation.

### Removed
- Removed `pages:deploy` script and `@cloudflare/next-on-pages` dependency (deployment via Workers only).

### Security
- `AUTH_SECRET` configured in production for NextAuth v5 (token signing recommended).

### Docs
- `luna-proxy-web/ARCHITECTURE.md`: "vault-only BYOK" workflow clarified (deposit → unwrap-on-session), audit logging, AES-GCM.
- `luna-proxy-api/README.md`: Quick Start "deposit key → request session with project_id", auth options (project_id or JWT), request example.

### Deployments
- Staging: web + API OK (workers.dev), no binding warnings.
- Production: web deployed, API healthy.

## [1.0.0] - 2025-10-04

### Added
- Initial monorepo structure with git submodules
- `luna-proxy-api` as submodule (API backend)
- `luna-proxy-web` as submodule (Web frontend)
- Shared scripts for Stripe and Cloudflare setup
- Documentation for deployment, Stripe, and email setup
- `.gitignore` with security protections

### Security
- Protected temporary scripts with secrets in `.gitignore`
- Stripe generated files excluded from git

---

## Release Notes

### Version 1.0.0 - Initial Release

**AI Gate** is now live! 🎉

**What's Included:**

#### API Backend (luna-proxy-api)
- OpenAI Realtime API proxy
- WebSocket support for voice conversations
- D1 database for users and projects
- Vault-based key encryption (AES-256-GCM)
- Stripe billing integration
- JWT authentication
- Rate limiting and concurrent session control

#### Web Frontend (luna-proxy-web)
- Next.js 15 with App Router
- NextAuth v5 (OAuth + Email/Password)
- Project management dashboard
- OpenAI Realtime API playground
- Stripe billing integration
- Deployed on Cloudflare Pages

#### Infrastructure
- Cloudflare Workers global deployment
- D1 (SQLite) for data persistence
- Cloudflare Email Routing
- Resend for transactional emails
- Stripe for metered billing

#### Pricing Plans
- Free: 200 min/month
- Starter: $9/mo, 1500 min included
- Build: $19/mo, 3000 min included
- Pro: $39/mo, 8000 min included
- Agency: $99/mo, 25000 min included
- Enterprise: Custom pricing

#### Documentation
- Complete deployment guide
- Stripe setup guide (5 min)
- Email setup guide (5 min)
- Architecture documentation
- Migration guides
- Shared utility scripts

---

## [0.1.0] - 2025-09-28

### Added
- Project initialization
- Basic monorepo structure
- Git submodules configuration

---

## Versioning Strategy

We use [Semantic Versioning](https://semver.org/):

- **MAJOR** version: Incompatible API changes
- **MINOR** version: Backwards-compatible functionality
- **PATCH** version: Backwards-compatible bug fixes

### What Triggers a Version Bump?

#### MAJOR (Breaking Changes)
- API endpoint changes that break existing clients
- Database schema changes requiring migration
- Authentication changes
- Response format changes

#### MINOR (New Features)
- New API endpoints
- New features in dashboard
- New billing plans
- Enhanced functionality (backwards compatible)

#### PATCH (Bug Fixes)
- Bug fixes
- Performance improvements
- Documentation updates
- Security patches (non-breaking)

---

## Migration Guides

### Upgrading Between Versions

See [docs/migration/](docs/migration/) for version-specific migration guides.

---

## Links

- **Production**: https://www.ai-gate.dev
- **API**: https://api.ai-gate.dev
- **GitHub**: https://github.com/luna-assistant-ai/ai-gate
- **Changelog**: https://github.com/luna-assistant-ai/ai-gate/blob/main/CHANGELOG.md

---

<div align="center">
  <p><strong>AI Gate - Your gateway to AI APIs</strong></p>
</div>
