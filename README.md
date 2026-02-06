# Apito Plugin Registry

The official registry of Apito plugins. This repository contains the canonical list of plugins available for the Apito backend-as-a-service platform.

## Browse Plugins

- **Website**: [apito.io/plugins](https://apito.io/plugins)
- **Registry File**: [`plugins.json`](./plugins.json) – the single source of truth for all listed plugins

## Plugin Naming Convention

All plugins must follow the naming pattern:

```
hc-{name}-plugin
```

Examples: `hc-auth-plugin`, `hc-storage-plugin`, `hc-email-plugin`

## Required Files for Each Plugin

Your plugin repository must include:

| File | Description |
|------|-------------|
| `config.yml` | Plugin configuration (id, type, GraphQL/REST config, env vars) |
| `README.md` | Plugin documentation, installation, and API reference |
| `logo.png` | Plugin icon (recommended: 256x256px) |

See the [CDN Plugin Development Guide](./CDN-PLUGIN-DEVELOPMENT.md) for the full plugin structure and implementation details.

## How to Develop a Plugin

1. Read the [CDN Plugin Development Guide](./CDN-PLUGIN-DEVELOPMENT.md) – it covers architecture, storage provider integration, GraphQL/REST setup, and frontend integration
2. Use the `hc-apito-cdn-plugin` (Cloudflare R2) or `hc-media-s3-plugin` as reference implementations
3. Follow the HashiCorp plugin protocol and Apito handshake configuration
4. Implement `config.yml` with the required structure

## How to Submit Your Plugin

1. **Create your plugin repository** following the naming convention `hc-{name}-plugin`
2. **Ensure your repo contains**: `config.yml`, `README.md`, and `logo.png`
3. **Add your plugin** to `plugins.json` in this repository:
   - Fork this repo
   - Add your plugin entry to the `plugins` array in `plugins.json`
   - Follow the schema below
4. **Open a Pull Request** to `main`
5. **Upon approval**, your plugin will appear on the Apito website

### plugins.json Entry Schema

```json
{
  "id": "hc-your-plugin",
  "name": "Your Plugin Name",
  "description": "Short description (1 line)",
  "long_description": "Longer description (2-3 sentences)",
  "category": "authentication|storage|communication|data|security|performance|monitoring|analytics",
  "type": "system|project",
  "version": "1.0.0",
  "author": "Your Name or Team",
  "author_url": "https://your-website.com",
  "icon": "https://raw.githubusercontent.com/your-org/hc-your-plugin/main/logo.png",
  "tags": ["tag1", "tag2", "tag3"],
  "github_url": "https://github.com/your-org/hc-your-plugin",
  "documentation_url": "/docs/cli/plugin-management",
  "is_official": false,
  "language": "go",
  "license": "Apache-2.0",
  "created_at": "YYYY-MM-DD",
  "updated_at": "YYYY-MM-DD"
}
```

### Validation Rules for PR Acceptance

- `id` must match the repo name and follow `hc-{name}-plugin`
- `github_url` must be a valid public GitHub URL
- `icon` must be a valid URL (typically GitHub raw for `logo.png`)
- `category` must be one of the defined categories
- `type` must be `system` or `project`
- The plugin repo must contain `config.yml`, `README.md`, and `logo.png` at the root

## Documentation

- [CDN Plugin Development Guide](./CDN-PLUGIN-DEVELOPMENT.md) – Build storage/CDN plugins
- [Debug Guide](./DEBUG_GUIDE.md) – Debugging HashiCorp plugins
