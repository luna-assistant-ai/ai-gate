---
globs: .github/workflows/web-ci.yml
description: Uncouples frontend from Drone infra, mirroring API pipelines but
  fit for Vercel hosting.
---

For luna-proxy-web, use GitHub Actions workflow at .github/workflows/web-ci.yml to lint, test, and deploy to Vercel on main. Keep Drone focused on API container deploys.