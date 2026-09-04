package main

import (
	"crypto/ed25519"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

type catalog struct {
	SchemaVersion int               `json:"schema_version"`
	GeneratedAt   string            `json:"generated_at"`
	Plugins       []json.RawMessage `json:"plugins"`
}

func main() {
	args := os.Args[1:]
	cmd := ""
	if len(args) > 0 && strings.HasPrefix(args[0], "-") {
		cmd = args[0]
		args = args[1:]
	}
	root := "."
	if len(args) > 0 {
		root = args[0]
	}
	switch cmd {
	case "-verify":
		verifyCatalog(root)
		return
	case "-genkey":
		genKey(root)
		return
	}
	regDir := filepath.Join(root, "registry")
	entries, err := os.ReadDir(regDir)
	if err != nil {
		fatal(err)
	}
	var names []string
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".json") {
			continue
		}
		names = append(names, e.Name())
	}
	sort.Strings(names)

	ids := map[string]string{}
	var plugins []json.RawMessage
	for _, name := range names {
		raw, err := os.ReadFile(filepath.Join(regDir, name))
		if err != nil {
			fatal(err)
		}
		var obj map[string]any
		if err := json.Unmarshal(raw, &obj); err != nil {
			fatal(fmt.Errorf("%s: %w", name, err))
		}
		id, _ := obj["id"].(string)
		if id == "" {
			fatal(fmt.Errorf("%s missing id", name))
		}
		if prev, ok := ids[id]; ok {
			fatal(fmt.Errorf("duplicate id %s in %s and %s", id, prev, name))
		}
		ids[id] = name
		status, _ := obj["status"].(string)
		if status == "catalog-stub" {
			if releases, ok := obj["releases"].([]any); ok && len(releases) > 0 {
				fatal(fmt.Errorf("%s: catalog-stub must not declare installable releases", name))
			}
		}
		if repo, _ := obj["repository"].(string); strings.Contains(strings.ToLower(repo), "/latest") {
			fatal(fmt.Errorf("%s: mutable latest URL rejected", name))
		}
		compact, err := json.Marshal(obj)
		if err != nil {
			fatal(err)
		}
		plugins = append(plugins, compact)
	}

	cat := catalog{
		SchemaVersion: 1,
		GeneratedAt:   time.Now().UTC().Format(time.RFC3339),
		Plugins:       plugins,
	}
	out, err := json.MarshalIndent(cat, "", "  ")
	out = append(out, '\n')
	if err != nil {
		fatal(err)
	}
	dist := filepath.Join(root, "dist")
	if err := os.MkdirAll(dist, 0o755); err != nil {
		fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dist, "catalog.json"), out, 0o644); err != nil {
		fatal(err)
	}

	legacy := map[string]any{"plugins": []any{}}
	var legacyPlugins []any
	for _, p := range plugins {
		var obj map[string]any
		_ = json.Unmarshal(p, &obj)
		legacyPlugins = append(legacyPlugins, map[string]any{
			"id":           obj["id"],
			"name":         obj["name"],
			"github_url":   obj["repository"],
			"description":  obj["description"],
			"status":       obj["status"],
			"is_official":  obj["trust"] == "official",
			"version":      obj["plugin_version"],
			"capabilities": obj["capabilities"],
		})
	}
	legacy["plugins"] = legacyPlugins
	legacyBytes, _ := json.MarshalIndent(legacy, "", "  ")
	legacyBytes = append(legacyBytes, '\n')
	_ = os.WriteFile(filepath.Join(root, "plugins.json"), legacyBytes, 0o644)

	keyHex := strings.TrimSpace(os.Getenv("PLUGIN_REGISTRY_SIGNING_KEY"))
	if keyHex == "" {
		fmt.Println("catalog written (unsigned; set PLUGIN_REGISTRY_SIGNING_KEY to sign)")
		return
	}
	raw, err := hex.DecodeString(keyHex)
	if err != nil {
		fatal(fmt.Errorf("PLUGIN_REGISTRY_SIGNING_KEY: %w", err))
	}
	if len(raw) != ed25519.PrivateKeySize {
		fatal(fmt.Errorf("PLUGIN_REGISTRY_SIGNING_KEY must be %d bytes hex", ed25519.PrivateKeySize))
	}
	sig := ed25519.Sign(ed25519.PrivateKey(raw), out)
	if err := os.WriteFile(filepath.Join(dist, "catalog.sig"), []byte(hex.EncodeToString(sig)+"\n"), 0o644); err != nil {
		fatal(err)
	}
	fmt.Println("catalog written and signed")
}

func verifyCatalog(root string) {
	pubHex, err := os.ReadFile(filepath.Join(root, "keys", "catalog.pub"))
	if err != nil {
		fatal(err)
	}
	pubRaw, err := hex.DecodeString(strings.TrimSpace(string(pubHex)))
	if err != nil || len(pubRaw) != ed25519.PublicKeySize {
		fatal(fmt.Errorf("keys/catalog.pub must be %d-byte hex", ed25519.PublicKeySize))
	}
	body, err := os.ReadFile(filepath.Join(root, "dist", "catalog.json"))
	if err != nil {
		fatal(err)
	}
	sigHex, err := os.ReadFile(filepath.Join(root, "dist", "catalog.sig"))
	if err != nil {
		fatal(err)
	}
	sig, err := hex.DecodeString(strings.TrimSpace(string(sigHex)))
	if err != nil || len(sig) != ed25519.SignatureSize {
		fatal(fmt.Errorf("dist/catalog.sig is not a 64-byte hex signature"))
	}
	if !ed25519.Verify(ed25519.PublicKey(pubRaw), body, sig) {
		fatal(fmt.Errorf("catalog.sig does not match keys/catalog.pub — PLUGIN_REGISTRY_SIGNING_KEY is the wrong private key or catalog.json was rewritten after signing"))
	}
	fmt.Println("catalog signature ok")
}

func genKey(root string) {
	dir := filepath.Join(root, "keys")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		fatal(err)
	}
	privPath := filepath.Join(dir, "catalog.priv")
	if _, err := os.Stat(privPath); err == nil && os.Getenv("FORCE_CATALOG_KEY") != "1" {
		fatal(fmt.Errorf("%s already exists; set FORCE_CATALOG_KEY=1 to overwrite", privPath))
	}
	pub, priv, err := ed25519.GenerateKey(nil)
	if err != nil {
		fatal(err)
	}
	if err := os.WriteFile(privPath, []byte(hex.EncodeToString(priv)+"\n"), 0o600); err != nil {
		fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "catalog.pub"), []byte(hex.EncodeToString(pub)+"\n"), 0o644); err != nil {
		fatal(err)
	}
	fmt.Println("wrote keys/catalog.pub and keys/catalog.priv (never commit the private key)")
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}
