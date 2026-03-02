#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
# SPDX-License-Identifier: MIT

# OSGEO-Inject Announcement Update Script
# Updates the announcement message and archives old ones

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANNOUNCEMENT_FILE="$PROJECT_ROOT/src/content/announcement.json"
HISTORY_FILE="$PROJECT_ROOT/src/content/history.json"
DEPLOY_HOST="${OSGEO_INJECT_DEPLOY_HOST:-affiliate.osgeo.org}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check dependencies
check_dependencies() {
  for cmd in gum jq; do
    if ! command -v "$cmd" &>/dev/null; then
      echo -e "${RED}Error: '$cmd' is required but not installed.${NC}"
      echo "Install dependencies via: nix develop"
      exit 1
    fi
  done
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
    "📢 OSGEO-Inject Announcement Manager" \
    "Update announcements for OSGeo project sites"
}

# Show current announcement
show_current() {
  if [[ -f "$ANNOUNCEMENT_FILE" ]]; then
    gum style --foreground 220 "Current Announcement:"
    echo ""
    jq -r '"  ID: \(.id)\n  Message: \(.message)\n  Link: \(.link)\n  Published: \(.published)\n  Expires: \(.expires)"' "$ANNOUNCEMENT_FILE"
    echo ""
  else
    gum style --foreground 196 "No current announcement set"
  fi
}

# Generate announcement ID
generate_id() {
  local year
  year=$(date +%Y)
  local count=1

  if [[ -f "$HISTORY_FILE" ]]; then
    local last_id
    last_id=$(jq -r ".announcements[-1].id // \"\"" "$HISTORY_FILE")
    if [[ "$last_id" =~ ^${year}-([0-9]+)$ ]]; then
      count=$((BASH_REMATCH[1] + 1))
    fi
  fi

  printf "%s-%03d" "$year" "$count"
}

# Interactive mode
interactive_update() {
  show_header
  show_current

  # Choose action
  ACTION=$(gum choose \
    --header "What would you like to do?" \
    "Create new announcement" \
    "Edit current announcement" \
    "View announcement history" \
    "Expire current announcement" \
    "Exit")

  case "$ACTION" in
  "Create new announcement")
    create_announcement
    ;;
  "Edit current announcement")
    edit_announcement
    ;;
  "View announcement history")
    view_history
    ;;
  "Expire current announcement")
    expire_announcement
    ;;
  "Exit")
    exit 0
    ;;
  esac
}

# Create new announcement
create_announcement() {
  local id
  id=$(generate_id)

  gum style --foreground 212 "Creating new announcement (ID: $id)"
  echo ""

  # Get message
  MESSAGE=$(gum input \
    --placeholder "FOSS4G 2026 - Early bird registration open!" \
    --header "Enter announcement message (max 100 chars):" \
    --width 80 \
    --char-limit 100)

  if [[ -z "$MESSAGE" ]]; then
    gum style --foreground 196 "❌ Message cannot be empty"
    exit 1
  fi

  # Get link
  LINK=$(gum input \
    --placeholder "https://foss4g.osgeo.org/" \
    --header "Enter announcement link:" \
    --width 80)

  # Validate URL
  if [[ -n "$LINK" ]] && ! [[ "$LINK" =~ ^https?:// ]]; then
    gum style --foreground 196 "❌ Invalid URL format"
    exit 1
  fi

  # Get expiry duration
  EXPIRY=$(gum choose \
    --header "When should this announcement expire?" \
    "1 week" \
    "2 weeks" \
    "1 month" \
    "3 months" \
    "6 months" \
    "1 year" \
    "Custom date")

  local expires_date
  case "$EXPIRY" in
  "1 week")
    expires_date=$(date -d "+1 week" -Iseconds)
    ;;
  "2 weeks")
    expires_date=$(date -d "+2 weeks" -Iseconds)
    ;;
  "1 month")
    expires_date=$(date -d "+1 month" -Iseconds)
    ;;
  "3 months")
    expires_date=$(date -d "+3 months" -Iseconds)
    ;;
  "6 months")
    expires_date=$(date -d "+6 months" -Iseconds)
    ;;
  "1 year")
    expires_date=$(date -d "+1 year" -Iseconds)
    ;;
  "Custom date")
    CUSTOM_DATE=$(gum input \
      --placeholder "2026-12-31" \
      --header "Enter expiry date (YYYY-MM-DD):")
    expires_date="${CUSTOM_DATE}T23:59:59Z"
    ;;
  esac

  # Confirm
  echo ""
  gum style \
    --foreground 220 \
    --border normal \
    --padding "1" \
    "New Announcement:" \
    "  ID: $id" \
    "  Message: $MESSAGE" \
    "  Link: $LINK" \
    "  Expires: $expires_date"

  if ! gum confirm "Create this announcement?"; then
    gum style --foreground 196 "❌ Cancelled"
    exit 0
  fi

  # Archive current announcement if exists
  if [[ -f "$ANNOUNCEMENT_FILE" ]]; then
    archive_current
  fi

  # Create new announcement
  local published_date
  published_date=$(date -Iseconds)

  cat >"$ANNOUNCEMENT_FILE" <<EOF
{
  "id": "$id",
  "message": "$MESSAGE",
  "link": "$LINK",
  "published": "$published_date",
  "expires": "$expires_date"
}
EOF

  # Add to history
  update_history "$id" "$MESSAGE" "$LINK" "$published_date" "$expires_date" "true"

  gum style --foreground 82 "✅ Announcement created successfully"

  # Offer to deploy
  if gum confirm "Deploy to $DEPLOY_HOST?"; then
    deploy_changes
  fi
}

# Archive current announcement
archive_current() {
  if [[ ! -f "$ANNOUNCEMENT_FILE" ]]; then
    return
  fi

  local current_id
  current_id=$(jq -r '.id' "$ANNOUNCEMENT_FILE")

  # Mark as inactive in history
  if [[ -f "$HISTORY_FILE" ]]; then
    local temp_file
    temp_file=$(mktemp)
    jq --arg id "$current_id" \
      '(.announcements[] | select(.id == $id)).active = false' \
      "$HISTORY_FILE" >"$temp_file"
    mv "$temp_file" "$HISTORY_FILE"
  fi
}

# Update history file
update_history() {
  local id="$1"
  local message="$2"
  local link="$3"
  local published="$4"
  local expires="$5"
  local active="$6"

  mkdir -p "$(dirname "$HISTORY_FILE")"

  if [[ -f "$HISTORY_FILE" ]]; then
    local temp_file
    temp_file=$(mktemp)
    jq --arg id "$id" \
      --arg message "$message" \
      --arg link "$link" \
      --arg published "$published" \
      --arg expires "$expires" \
      --argjson active "$active" \
      --arg updated "$(date -Iseconds)" \
      '.announcements += [{id: $id, message: $message, link: $link, published: $published, expires: $expires, active: $active}] | .lastUpdated = $updated' \
      "$HISTORY_FILE" >"$temp_file"
    mv "$temp_file" "$HISTORY_FILE"
  else
    cat >"$HISTORY_FILE" <<EOF
{
  "announcements": [
    {
      "id": "$id",
      "message": "$message",
      "link": "$link",
      "published": "$published",
      "expires": "$expires",
      "active": $active
    }
  ],
  "lastUpdated": "$(date -Iseconds)"
}
EOF
  fi
}

# View announcement history
view_history() {
  if [[ ! -f "$HISTORY_FILE" ]]; then
    gum style --foreground 220 "No announcement history"
    return
  fi

  gum style --foreground 212 "📜 Announcement History:"
  echo ""

  jq -r '.announcements | reverse | .[] |
    if .active then "🟢" else "⚪" end +
    " [\(.id)] \(.message)\n   Link: \(.link)\n   Published: \(.published | split("T")[0]) | Expires: \(.expires | split("T")[0])\n"' \
    "$HISTORY_FILE"

  echo ""
  gum style --foreground 245 "🟢 = Active  ⚪ = Archived"
}

# Edit current announcement
edit_announcement() {
  if [[ ! -f "$ANNOUNCEMENT_FILE" ]]; then
    gum style --foreground 196 "No current announcement to edit"
    exit 1
  fi

  local current_message current_link current_expires
  current_message=$(jq -r '.message' "$ANNOUNCEMENT_FILE")
  current_link=$(jq -r '.link' "$ANNOUNCEMENT_FILE")
  current_expires=$(jq -r '.expires' "$ANNOUNCEMENT_FILE")

  MESSAGE=$(gum input \
    --value "$current_message" \
    --header "Edit message:" \
    --width 80)

  LINK=$(gum input \
    --value "$current_link" \
    --header "Edit link:" \
    --width 80)

  if gum confirm "Update announcement?"; then
    local temp_file
    temp_file=$(mktemp)
    jq --arg message "$MESSAGE" --arg link "$LINK" \
      '.message = $message | .link = $link' \
      "$ANNOUNCEMENT_FILE" >"$temp_file"
    mv "$temp_file" "$ANNOUNCEMENT_FILE"

    gum style --foreground 82 "✅ Announcement updated"

    if gum confirm "Deploy to $DEPLOY_HOST?"; then
      deploy_changes
    fi
  fi
}

# Expire current announcement
expire_announcement() {
  if [[ ! -f "$ANNOUNCEMENT_FILE" ]]; then
    gum style --foreground 196 "No current announcement to expire"
    exit 1
  fi

  show_current

  if gum confirm --affirmative "Expire" --negative "Cancel" "Expire current announcement?"; then
    archive_current
    rm "$ANNOUNCEMENT_FILE"
    gum style --foreground 82 "✅ Announcement expired and archived"

    if gum confirm "Deploy to $DEPLOY_HOST?"; then
      deploy_changes
    fi
  fi
}

# Deploy changes
deploy_changes() {
  gum spin --spinner globe --title "Deploying to $DEPLOY_HOST..." -- sleep 1

  # Sync content files
  rsync -avz "$PROJECT_ROOT/src/content/" "root@$DEPLOY_HOST:/var/www/osgeo-inject/content/"

  # Generate history HTML
  generate_history_html

  gum style --foreground 82 "✅ Deployed successfully"
}

# Generate history HTML page
generate_history_html() {
  local html_file="$PROJECT_ROOT/src/history.html"

  cat >"$html_file" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>OSGEO-Inject Announcement History</title>
  <style>
    :root {
      --bg: #f5f5f5;
      --card-bg: #fff;
      --text: #333;
      --text-secondary: #666;
      --border: #e0e0e0;
      --accent: #4caf50;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #1a1a1a;
        --card-bg: #2d2d2d;
        --text: #e0e0e0;
        --text-secondary: #a0a0a0;
        --border: #444;
      }
    }
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg);
      color: var(--text);
      max-width: 800px;
      margin: 0 auto;
      padding: 2rem;
    }
    h1 { color: var(--accent); }
    .announcement {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1rem;
      margin: 1rem 0;
    }
    .announcement.active { border-left: 4px solid var(--accent); }
    .announcement h3 { margin: 0 0 0.5rem; }
    .meta { color: var(--text-secondary); font-size: 0.9rem; }
    a { color: var(--accent); }
    .footer { margin-top: 2rem; text-align: center; color: var(--text-secondary); }
  </style>
</head>
<body>
  <h1>📢 Announcement History</h1>
  <div id="announcements"></div>
  <div class="footer">
    Made with 💗 by <a href="https://kartoza.com">Kartoza</a> |
    <a href="https://github.com/sponsors/timlinux">Donate!</a> |
    <a href="https://github.com/timlinux/OSGEO-Inject">GitHub</a>
  </div>
  <script>
    fetch('/content/history.json')
      .then(r => r.json())
      .then(data => {
        const container = document.getElementById('announcements');
        const sorted = data.announcements.slice().reverse();
        sorted.forEach(a => {
          const div = document.createElement('div');
          div.className = 'announcement' + (a.active ? ' active' : '');
          div.innerHTML = `
            <h3>${a.active ? '🟢' : '⚪'} ${a.message}</h3>
            <p><a href="${a.link}" target="_blank">${a.link}</a></p>
            <p class="meta">
              Published: ${new Date(a.published).toLocaleDateString()} |
              ${a.active ? 'Expires' : 'Expired'}: ${new Date(a.expires).toLocaleDateString()}
            </p>
          `;
          container.appendChild(div);
        });
      });
  </script>
</body>
</html>
EOF
}

# CLI mode
cli_update() {
  local message=""
  local link=""
  local expires=""
  local deploy="no"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -m | --message)
      message="$2"
      shift 2
      ;;
    -l | --link)
      link="$2"
      shift 2
      ;;
    -e | --expires)
      expires="$2"
      shift 2
      ;;
    --deploy)
      deploy="yes"
      shift
      ;;
    --history)
      view_history
      exit 0
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

  if [[ -z "$message" ]]; then
    echo "Error: --message is required"
    show_help
    exit 1
  fi

  # Generate ID and dates
  local id
  id=$(generate_id)
  local published_date
  published_date=$(date -Iseconds)
  local expires_date
  expires_date="${expires:-$(date -d "+1 month" -Iseconds)}"

  # Archive current
  if [[ -f "$ANNOUNCEMENT_FILE" ]]; then
    archive_current
  fi

  # Create announcement
  cat >"$ANNOUNCEMENT_FILE" <<EOF
{
  "id": "$id",
  "message": "$message",
  "link": "${link:-}",
  "published": "$published_date",
  "expires": "$expires_date"
}
EOF

  update_history "$id" "$message" "$link" "$published_date" "$expires_date" "true"

  echo "✅ Created announcement: $id"

  if [[ "$deploy" == "yes" ]]; then
    deploy_changes
  fi
}

# Show help
show_help() {
  cat <<EOF
OSGEO-Inject Announcement Manager

Usage:
  $(basename "$0")                    Interactive mode
  $(basename "$0") [options]          CLI mode

Options:
  -m, --message TEXT      Announcement message (required)
  -l, --link URL          Announcement link
  -e, --expires DATE      Expiry date (ISO format)
  --deploy                Deploy after creating
  --history               View announcement history
  -h, --help              Show this help

Examples:
  # Interactive mode
  $(basename "$0")

  # CLI mode
  $(basename "$0") -m "FOSS4G 2026!" -l "https://foss4g.osgeo.org" --deploy
  $(basename "$0") --history
EOF
}

# Main
main() {
  check_dependencies

  case "${1:-}" in
  --help | -h)
    show_help
    ;;
  --history)
    view_history
    ;;
  "")
    interactive_update
    ;;
  *)
    cli_update "$@"
    ;;
  esac
}

main "$@"
