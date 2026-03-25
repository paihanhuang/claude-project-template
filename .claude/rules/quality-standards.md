---
description: Quality standards applied to all code produced by agents
---

# Quality Standards

- **Minimalism** — Write only what is necessary. No speculative features, no drive-by refactors, no dead code.
- **Correctness** — Verify before declaring done. If uncertain, test it. Prefer failing explicitly over silent corruption.
- **Clarity** — Code should be readable without comments where possible. Intent over cleverness. Explicit over implicit.
- **Safety** — No destructive actions without explicit user permission. No security vulnerabilities (OWASP top 10).
- **Maintainability** — Flat over nested. Small functions over large. Clear naming over documentation.
- **Efficiency** — Consider time complexity and memory usage. Don't optimize prematurely, but don't ignore O(n^2) traps.
