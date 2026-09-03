# Contributing to the Apito plugin registry

This repository is a **signed catalog**, not plugin source. Each plugin lives in its own public GitHub repository.

## Author

1. Scaffold a plugin (`hc-<name>-plugin`) with `config.yml`, tests, Apache-2.0 license, and a release workflow.
2. Tag `vX.Y.Z`. CI must build `linux`/`darwin`/`windows` × `amd64`/`arm64`.
3. Each zip is named `hc-<name>-plugin-vX.Y.Z-<os>-<arch>.zip` and contains **root-level** binary + `config.yml`.
4. Publish checksums (`*-checksums.txt`).
5. Add `registry/<plugin-id>.json` in this repo. Point `releases[]` at immutable GitHub Release asset URLs (never `latest`). Include SHA-256 and byte size.
6. Open a pull request. Automated checks validate schema, unique IDs, capability allowlist, and (when enabled) fetch+hash every asset.
7. Official version bumps: label the PR `official`. Auto-merge runs after Registry CI is green.
8. After merge, CI signs `dist/catalog.json` with Apito's Ed25519 key and publishes the `catalog-v1` release.

## Reviewer

- Confirm the repository is public, license is OSI-approved, and `config.yml` matches the registry `runtime` snapshot.
- Confirm handshake is `APITO_PLUGIN` / `apito_plugin_magic_cookie_v1`.
- Reject path traversal, symlinks, `catalog-stub` installs, and mutable URLs.

## Super-admin (Engine)

Browse Administrator → Plugins, then Install / Update / Uninstall. Engine verifies the catalog signature before download.

## Project admin

Activate and set `env_vars` only for plugins already installed on the Engine.

## Trust boundary

A plugin binary is **host subprocess code** (HashiCorp go-plugin). Registry approval is review + checksum pinning, **not** sandboxing.
