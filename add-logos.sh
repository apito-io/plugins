#!/usr/bin/env bash
# Add logos to all 15 plugin repos using simple-icons (SVG) + qlmanage (SVG->PNG)
# Run from apito-plugins directory

BASE="https://cdn.jsdelivr.net/npm/simple-icons@v11/icons"
SIZE=256

get_slug() {
  case "$1" in
    hc-auth-plugin) echo keycloak ;;
    hc-storage-plugin) echo amazonaws ;;
    hc-email-plugin) echo mailgun ;;
    hc-cache-plugin) echo redis ;;
    hc-realtime-plugin) echo socketdotio ;;
    hc-rate-limit-plugin) echo cloudflare ;;
    hc-search-plugin) echo elasticsearch ;;
    hc-webhook-plugin) echo zapier ;;
    hc-push-notification-plugin) echo firebase ;;
    hc-scheduler-plugin) echo vercel ;;
    hc-logging-plugin) echo datadog ;;
    hc-analytics-plugin) echo googleanalytics ;;
    hc-sms-plugin) echo twilio ;;
    hc-payment-plugin) echo stripe ;;
    hc-ai-plugin) echo openai ;;
    *) echo "" ;;
  esac
}

cd "$(dirname "$0")"
for dir in hc-auth-plugin hc-storage-plugin hc-email-plugin hc-cache-plugin hc-realtime-plugin hc-rate-limit-plugin hc-search-plugin hc-webhook-plugin hc-push-notification-plugin hc-scheduler-plugin hc-logging-plugin hc-analytics-plugin hc-sms-plugin hc-payment-plugin hc-ai-plugin; do
  slug=$(get_slug "$dir")
  [ -z "$slug" ] && continue
  url="$BASE/$slug.svg"
  svg="$dir/icon.svg"
  png="$dir/logo.png"
  if [ -d "$dir" ]; then
    echo "=== $dir ($slug) ==="
    curl -sL "$url" -o "$svg" 2>/dev/null || { echo "  Failed to fetch"; continue; }
    if [ -s "$svg" ]; then
      qlmanage -t -s $SIZE -o "$dir" "$svg" 2>/dev/null
      if [ -f "$dir/icon.svg.png" ]; then
        mv "$dir/icon.svg.png" "$png"
        echo "  OK: $png"
      fi
      rm -f "$svg"
    fi
  fi
done
echo "Done."
