---
globs: luna-proxy-web/src/**/*.{ts,tsx}
description: Ensures environments can override the API URL and keeps components clean.
---

Always use NEXT_PUBLIC_API_BASE_URL with default https://api.ai-gate.dev via a helper (src/lib/api.ts) instead of hardcoding URLs in components.