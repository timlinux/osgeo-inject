#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
# SPDX-License-Identifier: MIT

# OSGEO-Inject Backup Script
# Backs up Matomo database and configuration

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${OSGEO_INJECT_BACKUP_DIR:-$PROJECT_ROOT/backups}"
DEPLOY_HOST="${OSGEO_INJECT_DEPLOY_HOST:-affiliate.osgeo.org}"
RETENTION_DAYS="${OSGEO_INJECT_BACKUP_RETENTION:-30}"

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
  for cmd in gum mysqldump gzip; do
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
    "💾 OSGEO-Inject Backup Manager" \
    "Backup Matomo database and configuration"
}

# Interactive mode
interactive_backup() {
  show_header

  # Show current backups
  list_backups

  # Choose action
  ACTION=$(gum choose \
    --header "What would you like to do?" \
    "Create new backup" \
    "List backups" \
    "Download backup from server" \
    "Clean old backups" \
    "Verify backup integrity" \
    "Exit")

  case "$ACTION" in
  "Create new backup")
    create_backup
    ;;
  "List backups")
    list_backups_detailed
    ;;
  "Download backup from server")
    download_backup
    ;;
  "Clean old backups")
    clean_old_backups
    ;;
  "Verify backup integrity")
    verify_backup
    ;;
  "Exit")
    exit 0
    ;;
  esac
}

# Create backup
create_backup() {
  local backup_type
  backup_type=$(gum choose \
    --header "What to backup?" \
    "Full (Database + Config + Content)" \
    "Database only" \
    "Config only" \
    "Content only")

  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_name="osgeo-inject_${timestamp}"

  mkdir -p "$BACKUP_DIR"

  gum spin --spinner dots --title "Creating backup..." -- sleep 1

  case "$backup_type" in
  "Full"*)
    backup_database "$backup_name"
    backup_config "$backup_name"
    backup_content "$backup_name"
    create_manifest "$backup_name" "full"
    ;;
  "Database only")
    backup_database "$backup_name"
    create_manifest "$backup_name" "database"
    ;;
  "Config only")
    backup_config "$backup_name"
    create_manifest "$backup_name" "config"
    ;;
  "Content only")
    backup_content "$backup_name"
    create_manifest "$backup_name" "content"
    ;;
  esac

  # Create archive
  gum spin --spinner dots --title "Compressing backup..." -- \
    tar -czf "$BACKUP_DIR/${backup_name}.tar.gz" -C "$BACKUP_DIR" "$backup_name"

  # Cleanup temp directory
  rm -rf "${BACKUP_DIR:?}/${backup_name:?}"

  # Calculate size and checksum
  local size
  size=$(du -h "$BACKUP_DIR/${backup_name}.tar.gz" | cut -f1)
  local checksum
  checksum=$(sha256sum "$BACKUP_DIR/${backup_name}.tar.gz" | cut -d' ' -f1)

  echo "$checksum  ${backup_name}.tar.gz" >>"$BACKUP_DIR/checksums.txt"

  gum style --foreground 82 "✅ Backup created successfully"
  echo ""
  gum style \
    --foreground 220 \
    --border normal \
    --padding "1" \
    "Backup Details:" \
    "  File: ${backup_name}.tar.gz" \
    "  Size: $size" \
    "  Location: $BACKUP_DIR" \
    "  Checksum: ${checksum:0:16}..."
}

# Backup database
backup_database() {
  local backup_name="$1"
  local backup_path="$BACKUP_DIR/$backup_name"
  mkdir -p "$backup_path/database"

  # Check if running locally or need to SSH
  if [[ "$DEPLOY_HOST" != "localhost" ]]; then
    ssh "root@$DEPLOY_HOST" \
      "mysqldump -h $DB_HOST -u $DB_USER $DB_NAME" \
      >"$backup_path/database/matomo.sql"
  else
    mysqldump -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" \
      >"$backup_path/database/matomo.sql"
  fi

  gzip "$backup_path/database/matomo.sql"
}

# Backup config
backup_config() {
  local backup_name="$1"
  local backup_path="$BACKUP_DIR/$backup_name"
  mkdir -p "$backup_path/config"

  if [[ "$DEPLOY_HOST" != "localhost" ]]; then
    # Download configs from server
    rsync -avz "root@$DEPLOY_HOST:/etc/nginx/nginx.conf" "$backup_path/config/"
    rsync -avz "root@$DEPLOY_HOST:/var/www/matomo/config/" "$backup_path/config/matomo/" 2>/dev/null || true
  else
    cp -r "$PROJECT_ROOT/nginx/" "$backup_path/config/"
  fi
}

# Backup content
backup_content() {
  local backup_name="$1"
  local backup_path="$BACKUP_DIR/$backup_name"
  mkdir -p "$backup_path/content"

  if [[ "$DEPLOY_HOST" != "localhost" ]]; then
    rsync -avz "root@$DEPLOY_HOST:/var/www/osgeo-inject/content/" "$backup_path/content/"
  else
    cp -r "$PROJECT_ROOT/src/content/"* "$backup_path/content/"
  fi

  # Also backup sites.json if exists
  if [[ -f "$PROJECT_ROOT/data/sites.json" ]]; then
    cp "$PROJECT_ROOT/data/sites.json" "$backup_path/content/"
  fi
}

# Create manifest
create_manifest() {
  local backup_name="$1"
  local backup_type="$2"
  local backup_path="$BACKUP_DIR/$backup_name"

  cat >"$backup_path/manifest.json" <<EOF
{
  "name": "$backup_name",
  "type": "$backup_type",
  "created": "$(date -Iseconds)",
  "host": "$DEPLOY_HOST",
  "version": "0.1.0"
}
EOF
}

# List backups
list_backups() {
  if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
    gum style --foreground 220 "No backups found"
    return
  fi

  gum style --foreground 212 "📦 Recent Backups:"
  echo ""

  find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime -30 -exec ls -lh {} \; |
    awk '{print "  " $NF " (" $5 ")"}' |
    head -10
}

# List backups with details
list_backups_detailed() {
  if [[ ! -d "$BACKUP_DIR" ]]; then
    gum style --foreground 220 "No backups found"
    return
  fi

  gum style --foreground 212 "📦 All Backups:"
  echo ""

  for backup in "$BACKUP_DIR"/*.tar.gz; do
    [[ -f "$backup" ]] || continue

    local filename
    filename=$(basename "$backup")
    local size
    size=$(du -h "$backup" | cut -f1)
    local date
    date=$(stat -c %y "$backup" 2>/dev/null || stat -f %Sm "$backup" 2>/dev/null)

    echo "  📁 $filename"
    echo "     Size: $size | Date: ${date%% *}"
    echo ""
  done
}

# Download backup from server
download_backup() {
  gum spin --spinner globe --title "Fetching backup list from $DEPLOY_HOST..." -- sleep 1

  # Get list of backups on server
  local remote_backups
  remote_backups=$(ssh "root@$DEPLOY_HOST" "ls -1 /var/backups/osgeo-inject/*.tar.gz 2>/dev/null" || echo "")

  if [[ -z "$remote_backups" ]]; then
    gum style --foreground 220 "No backups found on server"
    return
  fi

  # Select backup to download
  BACKUP_FILE=$(echo "$remote_backups" | gum choose --header "Select backup to download:")

  if [[ -z "$BACKUP_FILE" ]]; then
    return
  fi

  gum spin --spinner globe --title "Downloading..." -- \
    rsync -avz "root@$DEPLOY_HOST:$BACKUP_FILE" "$BACKUP_DIR/"

  gum style --foreground 82 "✅ Downloaded: $(basename "$BACKUP_FILE")"
}

# Clean old backups
clean_old_backups() {
  gum style --foreground 220 "Backups older than $RETENTION_DAYS days will be removed"

  local old_backups
  old_backups=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +"$RETENTION_DAYS" 2>/dev/null)

  if [[ -z "$old_backups" ]]; then
    gum style --foreground 82 "No old backups to clean"
    return
  fi

  echo "Found old backups:"
  echo "$old_backups" | while read -r f; do
    echo "  - $(basename "$f")"
  done

  if gum confirm "Delete these backups?"; then
    echo "$old_backups" | xargs rm -f
    gum style --foreground 82 "✅ Old backups removed"
  fi
}

# Verify backup integrity
verify_backup() {
  if [[ ! -f "$BACKUP_DIR/checksums.txt" ]]; then
    gum style --foreground 220 "No checksum file found"
    return
  fi

  gum spin --spinner dots --title "Verifying checksums..." -- sleep 1

  local failed=0
  while IFS= read -r line; do
    local checksum file
    checksum=$(echo "$line" | cut -d' ' -f1)
    file=$(echo "$line" | cut -d' ' -f3)

    if [[ -f "$BACKUP_DIR/$file" ]]; then
      local current_checksum
      current_checksum=$(sha256sum "$BACKUP_DIR/$file" | cut -d' ' -f1)
      if [[ "$checksum" == "$current_checksum" ]]; then
        echo "  ✅ $file"
      else
        echo "  ❌ $file (checksum mismatch)"
        ((failed++))
      fi
    fi
  done <"$BACKUP_DIR/checksums.txt"

  if [[ $failed -eq 0 ]]; then
    gum style --foreground 82 "✅ All backups verified"
  else
    gum style --foreground 196 "❌ $failed backup(s) failed verification"
  fi
}

# CLI mode
cli_backup() {
  local backup_type="full"
  local remote="no"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -t | --type)
      backup_type="$2"
      shift 2
      ;;
    -r | --remote)
      remote="yes"
      shift
      ;;
    --list)
      list_backups_detailed
      exit 0
      ;;
    --clean)
      clean_old_backups
      exit 0
      ;;
    --verify)
      verify_backup
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

  # Create backup in CLI mode
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_name="osgeo-inject_${timestamp}"

  mkdir -p "$BACKUP_DIR"

  case "$backup_type" in
  full)
    backup_database "$backup_name"
    backup_config "$backup_name"
    backup_content "$backup_name"
    create_manifest "$backup_name" "full"
    ;;
  database)
    backup_database "$backup_name"
    create_manifest "$backup_name" "database"
    ;;
  config)
    backup_config "$backup_name"
    create_manifest "$backup_name" "config"
    ;;
  content)
    backup_content "$backup_name"
    create_manifest "$backup_name" "content"
    ;;
  *)
    echo "Unknown backup type: $backup_type"
    exit 1
    ;;
  esac

  # Compress
  tar -czf "$BACKUP_DIR/${backup_name}.tar.gz" -C "$BACKUP_DIR" "$backup_name"
  rm -rf "${BACKUP_DIR:?}/${backup_name:?}"

  # Checksum
  sha256sum "$BACKUP_DIR/${backup_name}.tar.gz" >>"$BACKUP_DIR/checksums.txt"

  echo "✅ Backup created: $BACKUP_DIR/${backup_name}.tar.gz"
}

# Show help
show_help() {
  cat <<EOF
OSGEO-Inject Backup Manager

Usage:
  $(basename "$0")                    Interactive mode
  $(basename "$0") [options]          CLI mode

Options:
  -t, --type TYPE         Backup type: full, database, config, content
  -r, --remote            Backup from remote server
  --list                  List all backups
  --clean                 Remove old backups
  --verify                Verify backup checksums
  -h, --help              Show this help

Environment:
  OSGEO_INJECT_BACKUP_DIR       Backup directory (default: ./backups)
  OSGEO_INJECT_DEPLOY_HOST      Remote host (default: affiliate.osgeo.org)
  OSGEO_INJECT_BACKUP_RETENTION Days to keep backups (default: 30)
  MATOMO_DB_NAME                Database name (default: matomo)
  MATOMO_DB_USER                Database user (default: matomo)
  MATOMO_DB_HOST                Database host (default: localhost)

Examples:
  $(basename "$0")                          # Interactive
  $(basename "$0") -t database              # Database only
  $(basename "$0") -t full -r               # Full backup from remote
  $(basename "$0") --list                   # List backups
  $(basename "$0") --clean                  # Clean old backups
EOF
}

# Main
main() {
  check_dependencies

  case "${1:-}" in
  --help | -h)
    show_help
    ;;
  --list)
    list_backups_detailed
    ;;
  --clean)
    clean_old_backups
    ;;
  --verify)
    verify_backup
    ;;
  "")
    interactive_backup
    ;;
  *)
    cli_backup "$@"
    ;;
  esac
}

main "$@"
