# apito-plugins — Decisions

Format: Decision / Reason / Alternatives / Status. Newest on top.

---
Decision: Registry-only repo; one public GitHub repo per plugin.
Reason: Reviewable PRs, independent release matrices, Engine never builds source.
Status: accepted
---
Decision: Ed25519-signed catalog; install pinned GitHub Release zips only.
Reason: No clone/compile on Engine. Checksum + config.yml must match catalog.
Status: accepted
---
Decision: Super-admin installs; project admins only activate.
Reason: Plugin binary is host code.
Status: accepted

Last Updated: 2026-09-03

