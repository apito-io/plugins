# Catalog signing (Ed25519, hex).

- `catalog.pub` — committed. Engine embeds the same value.
- `catalog.priv` — local only, gitignored. Put the hex in GitHub Actions secret `PLUGIN_REGISTRY_SIGNING_KEY` on `apito-io/plugins`. Never commit it.
