#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
# SPDX-License-Identifier: MIT

# OSGEO-Inject Site Onboarding Script
# Adds new OSGeo project sites to the CORS whitelist and redeploys

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NGINX_CONF="$PROJECT_ROOT/nginx/nginx.conf"
SITES_FILE="$PROJECT_ROOT/data/sites.json"
DEPLOY_HOST="${OSGEO_INJECT_DEPLOY_HOST:-affiliate.osgeo.org}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for gum
check_dependencies() {
  if ! command -v gum &>/dev/null; then
    echo -e "${RED}Error: 'gum' is required but not installed.${NC}"
    echo "Install it via: nix develop"
    exit 1
  fi

  if ! command -v jq &>/dev/null; then
    echo -e "${RED}Error: 'jq' is required but not installed.${NC}"
    exit 1
  fi
}

# Show header
show_header() {
  gum style \
    --foreground 212 \
    --border-foreground 212 \
    --border double \
    --align center \
    --width 60 \
    --margin "1 2" \
    --padding "1 2" \
    "🌍 OSGEO-Inject Site Onboarding" \
    "Add new OSGeo project sites to the CORS whitelist"
}

# Interactive mode
interactive_onboard() {
  show_header

  # Get domain
  DOMAIN=$(gum input \
    --placeholder "example.osgeo.org" \
    --header "Enter the domain to onboard:" \
    --width 50)

  if [[ -z "$DOMAIN" ]]; then
    gum style --foreground 196 "❌ Domain cannot be empty"
    exit 1
  fi

  # Validate domain format
  if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$ ]]; then
    gum style --foreground 196 "❌ Invalid domain format: $DOMAIN"
    exit 1
  fi

  # Get project name
  PROJECT_NAME=$(gum input \
    --placeholder "QGIS" \
    --header "Enter the project name:" \
    --width 50)

  # Get contact email
  CONTACT_EMAIL=$(gum input \
    --placeholder "admin@example.org" \
    --header "Enter contact email (optional):" \
    --width 50)

  # Include subdomains?
  INCLUDE_SUBDOMAINS=$(gum choose \
    --header "Include subdomains?" \
    "Yes (*.${DOMAIN})" \
    "No (${DOMAIN} only)")

  # Confirm
  echo ""
  gum style \
    --foreground 220 \
    --border normal \
    --padding "1" \
    "Configuration Summary:" \
    "  Domain: $DOMAIN" \
    "  Project: ${PROJECT_NAME:-N/A}" \
    "  Contact: ${CONTACT_EMAIL:-N/A}" \
    "  Subdomains: $INCLUDE_SUBDOMAINS"

  if ! gum confirm "Add this site to CORS whitelist?"; then
    gum style --foreground 196 "❌ Onboarding cancelled"
    exit 0
  fi

  # Add to CORS whitelist
  add_cors_entry "$DOMAIN" "$PROJECT_NAME" "$INCLUDE_SUBDOMAINS"

  # Ask about deployment
  if gum confirm "Deploy changes to $DEPLOY_HOST?"; then
    deploy_changes
  else
    gum style --foreground 220 "⚠️  Changes saved locally but not deployed"
    gum style "Run 'nix run .#deploy' to deploy later"
  fi
}

# Add CORS entry to nginx config
add_cors_entry() {
  local domain="$1"
  local project_name="${2:-Unknown}"
  local include_subdomains="$3"

  gum spin --spinner dot --title "Adding CORS entry..." -- sleep 1

  # Create CORS pattern
  local pattern
  if [[ "$include_subdomains" == *"Yes"* ]]; then
    pattern="        \"~^https?://.*\\.${domain//./\\.}\$\" \$http_origin;"
    pattern+="\n        \"~^https?://${domain//./\\.}\$\" \$http_origin;"
  else
    pattern="        \"~^https?://${domain//./\\.}\$\" \$http_origin;"
  fi

  # Add to nginx config (before END CUSTOM ORIGINS marker)
  if grep -q "# END CUSTOM ORIGINS" "$NGINX_CONF"; then
    # Add entry with comment
    local entry="\n        # ${project_name}\n${pattern}"
    sed -i "s|# END CUSTOM ORIGINS|${entry}\n\n        # END CUSTOM ORIGINS|" "$NGINX_CONF"
  else
    echo -e "${RED}Error: Could not find CORS marker in nginx config${NC}"
    exit 1
  fi

  # Add to sites.json
  mkdir -p "$(dirname "$SITES_FILE")"
  if [[ -f "$SITES_FILE" ]]; then
    local temp_file
    temp_file=$(mktemp)
    jq --arg domain "$domain" \
      --arg project "$project_name" \
      --arg contact "$CONTACT_EMAIL" \
      --arg date "$(date -Iseconds)" \
      '.sites += [{domain: $domain, project: $project, contact: $contact, added: $date}]' \
      "$SITES_FILE" >"$temp_file"
    mv "$temp_file" "$SITES_FILE"
  else
    cat >"$SITES_FILE" <<EOF
{
  "sites": [
    {
      "domain": "$domain",
      "project": "$project_name",
      "contact": "$CONTACT_EMAIL",
      "added": "$(date -Iseconds)"
    }
  ]
}
EOF
  fi

  gum style --foreground 82 "✅ Added $domain to CORS whitelist"
}

# Deploy changes using NixOS Anywhere
deploy_changes() {
  gum spin --spinner globe --title "Deploying to $DEPLOY_HOST..." -- sleep 2

  # Check if we can reach the host
  if ! ping -c 1 -W 2 "$DEPLOY_HOST" &>/dev/null; then
    gum style --foreground 196 "❌ Cannot reach $DEPLOY_HOST"
    gum style "Please check network connectivity"
    exit 1
  fi

  # Deploy using nixos-anywhere or rebuild
  if command -v nixos-anywhere &>/dev/null; then
    nixos-anywhere --flake ".#osgeo-inject" "root@$DEPLOY_HOST" || {
      gum style --foreground 196 "❌ Deployment failed"
      exit 1
    }
  else
    # Fallback: just copy config and reload nginx
    gum style --foreground 220 "⚠️  nixos-anywhere not available, using rsync"
    rsync -avz "$NGINX_CONF" "root@$DEPLOY_HOST:/etc/nginx/nginx.conf"
    ssh "root@$DEPLOY_HOST" "nginx -t && systemctl reload nginx"
  fi

  gum style --foreground 82 "✅ Deployed successfully to $DEPLOY_HOST"
}

# CLI mode (non-interactive)
cli_onboard() {
  local domain=""
  local project_name=""
  local include_subdomains="no"
  local deploy="no"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -d | --domain)
      domain="$2"
      shift 2
      ;;
    -p | --project)
      project_name="$2"
      shift 2
      ;;
    -s | --subdomains)
      include_subdomains="yes"
      shift
      ;;
    --deploy)
      deploy="yes"
      shift
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
    esac
  done

  if [[ -z "$domain" ]]; then
    echo "Error: --domain is required"
    show_help
    exit 1
  fi

  # Validate domain
  if ! [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$ ]]; then
    echo "Error: Invalid domain format: $domain"
    exit 1
  fi

  local subdomain_choice="No"
  [[ "$include_subdomains" == "yes" ]] && subdomain_choice="Yes"

  add_cors_entry "$domain" "$project_name" "$subdomain_choice"

  if [[ "$deploy" == "yes" ]]; then
    deploy_changes
  fi
}

# Show help
show_help() {
  cat <<EOF
OSGEO-Inject Site Onboarding

Usage:
  $(basename "$0")                    Interactive mode
  $(basename "$0") [options]          CLI mode

Options:
  -d, --domain DOMAIN     Domain to onboard (required)
  -p, --project NAME      Project name
  -s, --subdomains        Include subdomains (*.domain)
  --deploy                Deploy changes after adding
  -h, --help              Show this help

Examples:
  # Interactive mode
  $(basename "$0")

  # CLI mode
  $(basename "$0") -d qgis.org -p QGIS -s --deploy
  $(basename "$0") --domain postgis.net --project PostGIS

Environment:
  OSGEO_INJECT_DEPLOY_HOST    Target host (default: affiliate.osgeo.org)
EOF
}

# List onboarded sites
list_sites() {
  if [[ -f "$SITES_FILE" ]]; then
    gum style --foreground 212 "📋 Onboarded Sites:"
    echo ""
    jq -r '.sites[] | "  • \(.project // "Unknown"): \(.domain) (added: \(.added | split("T")[0]))"' "$SITES_FILE"
  else
    gum style --foreground 220 "No sites onboarded yet"
  fi
}

# Main
main() {
  check_dependencies

  # Parse mode
  case "${1:-}" in
  --list | -l)
    list_sites
    ;;
  --help | -h)
    show_help
    ;;
  "")
    interactive_onboard
    ;;
  *)
    cli_onboard "$@"
    ;;
  esac
}

main "$@"
