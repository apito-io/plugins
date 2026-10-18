# apito-plugins — AI Changelog

Not git history — the *reasoning* behind changes. Newest on top.
Format per entry: date, **Changed**, **Why**, **Affected**.

---
## 2026-10-18 — full Apache LICENSE text

- **Changed:** Replaced short LICENSE notices with the full Apache-2.0 text and added a repo-root LICENSE.
- **Why:** GitHub license detection needs the full license, not a 3-line pointer.
- **Affected:** `LICENSE` and the short `hc-*/LICENSE` files. Already-full licenses were not rewritten. Uncommitted.

## 2026-09-03 — Discord, Stripe, Cloudinary official plugins

- **Changed:** Real plugins (not catalog-stub): Discord notifications,
  Stripe Checkout+webhook, Cloudinary media library. `config.yml`
  capabilities + empty env_var keys.
- **Why:** User-facing “I can do this via plugin” examples.
- **Affected:** `hc-discord-plugin/`, `hc-stripe-plugin/`,
  `hc-cloudinary-plugin/`, `plugins.json`, `.gitignore`.

---
## 2026-09-03 — plugins.json capability catalog

- **Changed:** Registry entries use `capabilities` instead of
  system/project `type`. Docs URLs → `/docs/platform/plugins/`. Stubs
  labeled `catalog-stub`.
- **Why:** Public registry matched dual plugin types that no longer exist.
- **Affected:** `plugins.json`. Hello-world `plugin.proto` reserved enums.

---
## 2026-07-06
- **Changed:** Bootstrapped knowledge system for this repo.
- **Why:** Cross-LLM durable knowledge + working memory.
- **Affected:** this repo only.

Last Updated: 2026-07-06
