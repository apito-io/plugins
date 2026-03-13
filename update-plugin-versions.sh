#!/usr/bin/env bash
#
# update-plugin-versions.sh
#
# Fetches the latest release tag for each plugin from GitHub and updates
# plugins.json with the new version. Run manually when releasing plugins.
#
# Requirements: curl, jq
# Optional: GITHUB_TOKEN env var for higher API rate limits
#
# Usage: ./update-plugin-versions.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_JSON="${SCRIPT_DIR}/plugins.json"
BACKUP_JSON="${SCRIPT_DIR}/plugins.json.bak"

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi

if [[ ! -f "$PLUGINS_JSON" ]]; then
  echo "Error: plugins.json not found at $PLUGINS_JSON"
  exit 1
fi

# GitHub API with optional token for rate limits
GH_HEADERS=(-H "Accept: application/vnd.github.v3+json")
[[ -n "${GITHUB_TOKEN:-}" ]] && GH_HEADERS+=(-H "Authorization: token $GITHUB_TOKEN")

echo "Fetching latest releases from GitHub..."
echo ""

# Build updated plugins array
UPDATED_PLUGINS="[]"
PLUGIN_COUNT=$(jq '.plugins | length' "$PLUGINS_JSON")
UPDATED_COUNT=0

for i in $(seq 0 $((PLUGIN_COUNT - 1))); do
  PLUGIN=$(jq -c ".plugins[$i]" "$PLUGINS_JSON")
  PLUGIN_ID=$(echo "$PLUGIN" | jq -r '.id')
  GITHUB_URL=$(echo "$PLUGIN" | jq -r '.github_url')
  CURRENT_VERSION=$(echo "$PLUGIN" | jq -r '.version')

  # Extract owner/repo from github_url (e.g. https://github.com/apito-io/hc-auth-plugin)
  if [[ "$GITHUB_URL" =~ https://github\.com/([^/]+)/([^/]+)/?$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
  else
    echo "  [SKIP] $PLUGIN_ID: Could not parse github_url"
    UPDATED_PLUGINS=$(echo "$UPDATED_PLUGINS" | jq --argjson p "$PLUGIN" '. + [$p]')
    continue
  fi

  # Fetch latest release from GitHub API
  RESPONSE=$(curl -s -w "\n%{http_code}" "${GH_HEADERS[@]}" \
    "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest")

  BODY=$(echo "$RESPONSE" | sed '$d')
  CODE=$(echo "$RESPONSE" | tail -n 1)
  LATEST_VERSION=""

  if [[ "$CODE" == "200" ]]; then
    TAG_NAME=$(echo "$BODY" | jq -r '.tag_name // empty')
    [[ -n "$TAG_NAME" ]] && LATEST_VERSION="${TAG_NAME#v}"
  fi

  # Fallback: fetch latest tag if no releases
  if [[ -z "$LATEST_VERSION" ]]; then
    TAGS_RESP=$(curl -s -w "\n%{http_code}" "${GH_HEADERS[@]}" \
      "https://api.github.com/repos/${OWNER}/${REPO}/tags?per_page=1")
    TAGS_BODY=$(echo "$TAGS_RESP" | sed '$d')
    TAGS_CODE=$(echo "$TAGS_RESP" | tail -n 1)
    if [[ "$TAGS_CODE" == "200" ]]; then
      TAG_NAME=$(echo "$TAGS_BODY" | jq -r '.[0].name // empty')
      [[ -n "$TAG_NAME" ]] && LATEST_VERSION="${TAG_NAME#v}"
    fi
  fi

  if [[ -n "$LATEST_VERSION" ]]; then
    if [[ "$LATEST_VERSION" != "$CURRENT_VERSION" ]]; then
      PLUGIN=$(echo "$PLUGIN" | jq --arg v "$LATEST_VERSION" '.version = $v')
      PLUGIN=$(echo "$PLUGIN" | jq --arg d "$(date +%Y-%m-%d)" '.updated_at = $d')
      ((UPDATED_COUNT++)) || true
      echo "  [UPDATE] $PLUGIN_ID: $CURRENT_VERSION -> $LATEST_VERSION"
    else
      echo "  [OK] $PLUGIN_ID: $CURRENT_VERSION (up to date)"
    fi
  else
    echo "  [SKIP] $PLUGIN_ID: No release/tag found (keeping $CURRENT_VERSION)"
  fi

  UPDATED_PLUGINS=$(echo "$UPDATED_PLUGINS" | jq --argjson p "$PLUGIN" '. + [$p]')
done

if [[ $UPDATED_COUNT -eq 0 ]]; then
  echo ""
  echo "No updates needed. All versions are current."
  exit 0
fi

echo ""
echo "Updating plugins.json ($UPDATED_COUNT plugin(s) updated)..."

cp "$PLUGINS_JSON" "$BACKUP_JSON"

jq --argjson new_plugins "$UPDATED_PLUGINS" '.plugins = $new_plugins' "$PLUGINS_JSON" > "${PLUGINS_JSON}.tmp"
mv "${PLUGINS_JSON}.tmp" "$PLUGINS_JSON"

echo "Done. Backup saved to plugins.json.bak"
echo ""
echo "To commit and push:"
echo "  cd $SCRIPT_DIR"
echo "  git add plugins.json"
echo "  git commit -m 'chore: update plugin versions from latest GitHub releases'"
echo "  git push"
