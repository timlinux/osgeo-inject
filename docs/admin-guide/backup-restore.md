<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Backup & Restore

This guide covers backup and restore procedures for OSGEO-Inject.

## Overview

The system backs up:
- **Database**: Matomo analytics data
- **Configuration**: Nginx config, Matomo config
- **Content**: Announcements, history, site list

## Backup Script

### Interactive Mode

```bash
./scripts/backup.sh
```

This launches a TUI with options to:
- Create full backup
- Create partial backup (database/config/content only)
- List existing backups
- Verify backup integrity
- Clean old backups

### CLI Mode

```bash
# Full backup
./scripts/backup.sh -t full

# Database only
./scripts/backup.sh -t database

# List backups
./scripts/backup.sh --list

# Verify checksums
./scripts/backup.sh --verify
```

## Automated Backups

NixOS configures daily automated backups:

```nix
services.osgeo-inject = {
  enableBackups = true;
  backupSchedule = "daily";  # or "weekly", or systemd calendar format
  backupDir = "/var/backups/osgeo-inject";
};
```

Check backup status:

```bash
systemctl status osgeo-inject-backup.timer
journalctl -u osgeo-inject-backup
```

## Restore Script

### Interactive Mode

```bash
./scripts/restore.sh
```

This allows you to:
- Select a backup to restore
- Choose what to restore (full/database/config/content)
- Verify backup integrity before restoring

### CLI Mode

```bash
# Restore from specific backup
./scripts/restore.sh -f backups/osgeo-inject_20260302.tar.gz -t full

# Database only
./scripts/restore.sh -f backup.tar.gz -t database

# Skip confirmation (automated restores)
./scripts/restore.sh -f backup.tar.gz --force
```

## Backup Structure

```
osgeo-inject_20260302_120000/
├── manifest.json      # Backup metadata
├── database/
│   └── matomo.sql.gz  # Database dump
├── config/
│   ├── nginx.conf     # Nginx configuration
│   └── matomo/        # Matomo config files
└── content/
    ├── announcement.json
    ├── history.json
    └── sites.json
```

## Verification

Backups include SHA-256 checksums:

```bash
# View checksums
cat backups/checksums.txt

# Verify a specific backup
sha256sum -c backups/checksums.txt
```

## Retention Policy

By default, backups are retained for 30 days. Configure via:

```bash
export OSGEO_INJECT_BACKUP_RETENTION=60  # days
```

## Recovery Procedures

### Full System Recovery

1. Deploy fresh NixOS installation
2. Copy latest backup to server
3. Run restore script with `--force`
4. Restart services

### Database Recovery Only

```bash
gunzip -c matomo.sql.gz | mysql matomo
```

### Configuration Recovery

```bash
rsync -avz config/ /etc/nginx/
nginx -t && systemctl reload nginx
```

## Best Practices

1. **Test restores regularly**: Don't wait for a disaster
2. **Off-site backups**: Copy backups to remote storage
3. **Monitor backup jobs**: Check systemd timer status
4. **Encrypt sensitive backups**: Use GPG for database dumps
