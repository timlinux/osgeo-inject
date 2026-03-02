<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Deployment

This guide covers deploying OSGEO-Inject to production.

## NixOS Anywhere Deployment

### Prerequisites

- Target server accessible via SSH
- Root SSH access configured
- Domain DNS pointing to server

### Deployment Steps

1. **Prepare Configuration**

```bash
# Edit your target configuration
vim nixos/vm-configuration.nix
```

2. **Deploy**

```bash
nixos-anywhere --flake .#osgeo-inject-vm root@your-server-ip
```

3. **Verify**

```bash
curl https://affiliate.osgeo.org/health
```

## Manual Deployment

### 1. Build Assets

```bash
nix develop
npm ci
npm run build
```

### 2. Copy Files

```bash
rsync -avz src/ root@server:/var/www/osgeo-inject/
rsync -avz nginx/nginx.conf root@server:/etc/nginx/
```

### 3. Configure SSL

Using Let's Encrypt:

```bash
certbot certonly --nginx -d affiliate.osgeo.org
```

### 4. Start Services

```bash
ssh root@server "systemctl restart nginx"
```

## Updating

### Update Announcements

```bash
./scripts/update-announcement.sh --deploy
```

### Update Static Assets

```bash
npm run build
rsync -avz src/ root@server:/var/www/osgeo-inject/
```

### Full System Update

```bash
nixos-rebuild switch --flake .#osgeo-inject --target-host root@server
```

## Rollback

NixOS supports instant rollbacks:

```bash
ssh root@server "nixos-rebuild switch --rollback"
```

## Monitoring

### Health Check

```bash
curl -f https://affiliate.osgeo.org/health || alert
```

### Nginx Logs

```bash
ssh root@server "tail -f /var/log/nginx/access.log"
```

### System Status

```bash
ssh root@server "systemctl status nginx matomo php-fpm"
```
