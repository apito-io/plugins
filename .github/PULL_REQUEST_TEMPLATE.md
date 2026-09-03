## Registry PR

- [ ] Plugin source lives in its own public GitHub repository (`hc-*-plugin`)
- [ ] GitHub Release exists for the declared version (all OS/arch zips + checksums)
- [ ] `registry/<id>.json` is the only catalog change
- [ ] `runtime` matches repository `config.yml` (id, version, binary_path, capabilities, handshake)
- [ ] Release URLs are HTTPS GitHub `releases/download` (no `latest`)
- [ ] SHA-256 and size filled for every asset
- [ ] I understand Engine runs this binary as host code (not a sandbox)

### Notes

<!-- what this plugin does, who maintains it -->
