# apito-plugins — Knowledge

Part of the **apito** ecosystem. See `/.knowledge/projects/apito.md`.

## Read order
1. This file. 2. `ARCHITECTURE.md`. 3. `DECISIONS.md`. 4. `CONTRIBUTING.md`.

## Purpose
Signed public registry for reviewed HashiCorp plugins. Plugin source lives in one public repo per plugin. This repo publishes `dist/catalog.json` + `dist/catalog.sig`.

## Responsibilities
- Per-plugin `registry/<id>.json` review
- Schema + CI validation
- Ed25519-signed catalog release `catalog-v1`

## Consumers / blast radius
Engine installer, Console marketplace, apito.io/plugins, CLI `apito plugin add`.

Last Updated: 2026-09-03

