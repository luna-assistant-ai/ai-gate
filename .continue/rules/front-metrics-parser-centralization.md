---
globs: luna-proxy-web/src/**/*.tsx
description: Prevents divergent logic between Dashboard and SessionMetrics,
  keeps tests aligned with API changes.
---

Centralize metrics parsing in src/lib/metrics.ts and import parseMetrics in UI components. Do not duplicate Prometheus parsing logic inside components.