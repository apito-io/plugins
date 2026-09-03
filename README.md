# Apito Plugin Registry

Signed public catalog of reviewed HashiCorp plugins. **Plugin source does not live here.** Each plugin has its own repository. Engine installs only GitHub Release zips pinned by OS/arch, URL, size, and SHA-256.

- Browse: [apito.io/plugins](https://apito.io/plugins/)
- Signed catalog: GitHub Release `catalog-v1` (`catalog.json` + `catalog.sig`)
- Per-plugin entries: [`registry/`](./registry/)
- Schema: [`schema/plugin-catalog.schema.json`](./schema/plugin-catalog.schema.json)
- Contribute: [`CONTRIBUTING.md`](./CONTRIBUTING.md)

## Naming

```
hc-{name}-plugin
```

## What Engine installs

Reviewed release zips only. Engine never clones or compiles arbitrary source.

```
hc-<name>-plugin-v1.0.0-<os>-<arch>.zip   # binary + config.yml at zip root
hc-<name>-plugin-v1.0.0-checksums.txt
```

Platforms: linux, darwin, windows × amd64, arm64.

## Roles

| Who | Can |
| --- | --- |
| Anyone | Browse this registry and apito.io/plugins |
| Super-admin | Install / update / uninstall on an Engine (`plugins.deploy`) |
| Project admin | Activate / configure plugins already installed on that Engine |

Plugin binary = host subprocess. Registry approval is not a sandbox.
