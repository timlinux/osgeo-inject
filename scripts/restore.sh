#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
# SPDX-License-Identifier: MIT

# OSGEO-Inject Restore Script
# Restores Matomo database and configuration from backup

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${OSGEO_INJECT_BACKUP_DIR:-$PROJECT_ROOT/backups}"
DEPLOY_HOST="${OSGEO_INJECT_DEPLOY_HOST:-affiliate.osgeo.org}"

# Database configuration
DB_NAME="${MATOMO_DB_NAME:-matomo}"
DB_USER="${MATOMO_DB_USER:-matomo}"
DB_HOST="${MATOMO_DB_HOST:-localhost}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check dependencies
check_dependencies() {
  for cmd in gum mysql gunzip tar; do
    if ! command -v "$cmd" &>/dev/null; then
      echo -e "${RED}Error: '$cmd' is required but not installed.${NC}"
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
    "🔄 OSGEO-Inject Restore Manager" \
    "Restore from backup"
}

# Interactive mode
interactive_restore() {
  show_header

  # List available backups
  if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR"/*.tar.gz 2>/dev/null)" ]]; then
    gum style --foreground 196 "No backups found in $BACKUP_DIR"
    exit 1
  fi

  gum style --foreground 220 "⚠️  Warning: Restore will overwrite current data!"
  echo ""

  # Select backup
  local backups
  backups=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -exec basename {} \; | sort -r)

  BACKUP_FILE=$(echo "$backups" | gum choose --header "Select backup to restore:")

  if [[ -z "$BACKUP_FILE" ]]; then
    gum style --foreground 196 "No backup selected"
    exit 1
  fi

  # Show backup details
  show_backup_details "$BACKUP_DIR/$BACKUP_FILE"

  # Verify checksum
  verify_backup_checksum "$BACKUP_FILE"

  # Choose what to restore
  RESTORE_TYPE=$(gum choose \
    --header "What do you want to restore?" \
    "Full (Database + Config + Content)" \
    "Database only" \
    "Config only" \
    "Content only")

  # Confirm
  gum style --foreground 196 "⚠️  This will overwrite existing data!"

  if ! gum confirm --affirmative "Restore" --negative "Cancel" "Proceed with restore?"; then
    gum style "Restore cancelled"
    exit 0
  fi

  # Perform restore
  perform_restore "$BACKUP_DIR/$BACKUP_FILE" "$RESTORE_TYPE"
}

# Show backup details
show_backup_details() {
  local backup_file="$1"
  local temp_dir
  temp_dir=$(mktemp -d)

  # Extract manifest only
  tar -xzf "$backup_file" -C "$temp_dir" --wildcards '*/manifest.json' 2>/dev/null || true

  local manifest
  manifest=$(find "$temp_dir" -name "manifest.json" -type f | head -1)

  if [[ -f "$manifest" ]]; then
    gum style --foreground 212 "📦 Backup Details:"
    jq -r '"  Type: \(.type)\n  Created: \(.created)\n  Host: \(.host)\n  Version: \(.version)"' "$manifest"
    echo ""
  fi

  rm -rf "$temp_dir"
}

# Verify backup checksum
verify_backup_checksum() {
  local backup_file="$1"

  if [[ ! -f "$BACKUP_DIR/checksums.txt" ]]; then
    gum style --foreground 220 "⚠️  No checksum file found, skipping verification"
    return
  fi

  local expected_checksum
  expected_checksum=$(grep "$backup_file" "$BACKUP_DIR/checksums.txt" | cut -d' ' -f1 || echo "")

  if [[ -z "$expected_checksum" ]]; then
    gum style --foreground 220 "⚠️  No checksum found for this backup"
    return
  fi

  gum spin --spinner dots --title "Verifying checksum..." -- sleep 1

  local actual_checksum
  actual_checksum=$(sha256sum "$BACKUP_DIR/$backup_file" | cut -d' ' -f1)

  if [[ "$expected_checksum" == "$actual_checksum" ]]; then
    gum style --foreground 82 "✅ Checksum verified"
  else
    gum style --foreground 196 "❌ Checksum mismatch!"
    if ! gum confirm "Backup may be corrupted. Continue anyway?"; then
      exit 1
    fi
  fi
}

# Perform restore
perform_restore() {
  local backup_file="$1"
  local restore_type="$2"
  local temp_dir
  temp_dir=$(mktemp -d)

  gum spin --spinner dots --title "Extracting backup..." -- \
    tar -xzf "$backup_file" -C "$temp_dir"

  local backup_name
  backup_name=$(ls "$temp_dir")
  local backup_path="$temp_dir/$backup_name"

  case "$restore_type" in
  "Full"*)
    restore_database "$backup_path"
    restore_config "$backup_path"
    restore_content "$backup_path"
    ;;
  "Database only")
    restore_database "$backup_path"
    ;;
  "Config only")
    restore_config "$backup_path"
    ;;
  "Content only")
    restore_content "$backup_path"
    ;;
  esac

  rm -rf "$temp_dir"

  gum style --foreground 82 "✅ Restore completed successfully"

  # Offer to restart services
  if gum confirm "Restart services to apply changes?"; then
    restart_services
  fi
}

# Restore database
restore_database() {
  local backup_path="$1"
  local db_backup="$backup_path/database/matomo.sql.gz"

  if [[ ! -f "$db_backup" ]]; then
    gum style --foreground 220 "⚠️  No database backup found"
    return
  fi

  gum spin --spinner dots --title "Restoring database..." -- sleep 1

  if [[ "$DEPLOY_HOST" != "localhost" ]]; then
    # Restore to remote
    gunzip -c "$db_backup" | ssh "root@$DEPLOY_HOST" "mysql -h $DB_HOST -u $DB_USER $DB_NAME"
  else
    gunzip -c "$db_backup" | mysql -h "$DB_HOST" -u "$DB_USER" "$DB_NAME"
  fi

  gum style --foreground 82 "  ✓ Database restored"
}

# Restore config
restore_config() {
  local backup_path="$1"
  local config_dir="$backup_path/config"

  if [[ ! -d "$config_dir" ]]; then
    gum style --foreground 220 "⚠️  No config backup found"
    return
  fi

  gum spin --spinner dots --title "Restoring configuration..." -- sleep 1

  if [[ "$DEPLOY_HOST" != "localhost" ]]; then
    # Restore to remote
    if [[ -f "$config_dir/nginx.conf" ]]; then
      rsync -avz "$config_dir/nginx.conf" "root@$DEPLOY_HOST:/etc/nginx/nginx.conf"
    fi
    if [[ -d "$config_dir/matomo" ]]; then
      rsync -avz "$config_dir/matomo/" "root@$DEPLOY_HOST:/var/www/matomo/config/"
    fi
  else
    if [[ -f "$config_dir/nginx.conf" ]]; then
      cp "$config_dir/nginx.conf" "$PROJECT_ROOT/nginx/nginx.conf"
    fi
  fi

  gum style --foreground 82 "  ✓ Configuration restored"
}

# Restore content
restore_content() {
  local backup_path="$1"
  local content_dir="$backup_path/content"

  if [[ ! -d "$content_dir" ]]; then
    gum style --foreground 220 "⚠️  No content backup found"
    return
  fi

  gum spin --spinner dots --title "Restoring content..." -- sleep 1

  if [[ "$DEPLOY_HOST" != "localhost" ]]; then
    rsync -avz "$content_dir/" "root@$DEPLOY_HOST:/var/www/osgeo-inject/content/"
  else
    cp -r "$content_dir/"* "$PROJECT_ROOT/src/content/"
  fi

  # Restore sites.json if present
  if [[ -f "$content_dir/sites.json" ]]; then
    mkdir -p "$PROJECT_ROOT/data"
    cp "$content_dir/sites.json" "$PROJECT_ROOT/data/"
  fi

  gum style --foreground 82 "  ✓ Content restored"
}

# Restart services
restart_services() {
  gum spin --spinner globe --title "Restarting services..." -- sleep 1

  if [[ "$DEPLOY_HOST" != "localhost" ]]; then
    ssh "root@$DEPLOY_HOST" "systemctl restart nginx && systemctl restart php-fpm" || true
  else
    sudo systemctl restart nginx 2>/dev/null || true
  fi

  gum style --foreground 82 "✅ Services restarted"
}

# CLI mode
cli_restore() {
  local backup_file=""
  local restore_type="full"
  local force="no"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -f | --file)
      backup_file="$2"
      shift 2
      ;;
    -t | --type)
      restore_type="$2"
      shift 2
      ;;
    --force)
      force="yes"
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

  if [[ -z "$backup_file" ]]; then
    echo "Error: --file is required"
    show_help
    exit 1
  fi

  if [[ ! -f "$backup_file" ]]; then
    echo "Error: Backup file not found: $backup_file"
    exit 1
  fi

  # Verify
  local filename
  filename=$(basename "$backup_file")
  verify_backup_checksum "$filename" 2>/dev/null || true

  # Confirm unless forced
  if [[ "$force" != "yes" ]]; then
    echo "⚠️  This will overwrite existing data!"
    read -rp "Continue? [y/N] " confirm
    if [[ "$confirm" != [yY] ]]; then
      echo "Cancelled"
      exit 0
    fi
  fi

  # Map type
  local type_map="Full"
  case "$restore_type" in
  full) type_map="Full" ;;
  database) type_map="Database only" ;;
  config) type_map="Config only" ;;
  content) type_map="Content only" ;;
  esac

  perform_restore "$backup_file" "$type_map"
}

# Show help
show_help() {
  cat <<EOF
OSGEO-Inject Restore Manager

Usage:
  $(basename "$0")                    Interactive mode
  $(basename "$0") [options]          CLI mode

Options:
  -f, --file FILE         Backup file to restore (required)
  -t, --type TYPE         Restore type: full, database, config, content
  --force                 Skip confirmation prompt
  -h, --help              Show this help

Examples:
  $(basename "$0")                                  # Interactive
  $(basename "$0") -f backup.tar.gz -t full        # Restore full backup
  $(basename "$0") -f backup.tar.gz -t database    # Database only
  $(basename "$0") -f backup.tar.gz --force        # Skip confirmation

Environment:
  OSGEO_INJECT_BACKUP_DIR       Backup directory
  OSGEO_INJECT_DEPLOY_HOST      Target host for restore
  MATOMO_DB_NAME                Database name
  MATOMO_DB_USER                Database user
  MATOMO_DB_HOST                Database host
EOF
}

# Main
main() {
  check_dependencies

  case "${1:-}" in
  --help | -h)
    show_help
    ;;
  "")
    interactive_restore
    ;;
  *)
    cli_restore "$@"
    ;;
  esac
}

main "$@"
