# apito-plugins — Architecture

## Overview
`registry/*.json` → `tools/catalog` generates `dist/catalog.json` → Ed25519 sign → GitHub Release `catalog-v1`. Engine fetches that release, never clones plugin source.

## Key components
- `registry/` — one JSON file per plugin
- `schema/plugin-catalog.schema.json`
- `tools/catalog/main.go` — generate + optional sign
- `.github/workflows/registry.yml`

Last Updated: 2026-09-03

