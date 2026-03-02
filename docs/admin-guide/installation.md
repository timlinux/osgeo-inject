<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Installation

This guide covers how to deploy the OSGEO-Inject server.

## Prerequisites

- NixOS or a system with Nix installed
- A domain pointing to your server
- SSL certificate (or use Let's Encrypt)

## NixOS Deployment

### 1. Add the Module

Add the OSGEO-Inject flake to your system configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    osgeo-inject.url = "github:timlinux/OSGEO-Inject";
  };

  outputs = { self, nixpkgs, osgeo-inject }: {
    nixosConfigurations.myserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        osgeo-inject.nixosModules.default
      ];
    };
  };
}
```

### 2. Enable the Service

In your `configuration.nix`:

```nix
{
  services.osgeo-inject = {
    enable = true;
    domain = "affiliate.osgeo.org";
    enableACME = true;
    acmeEmail = "admin@example.org";
    enableMatomo = true;
  };
}
```

### 3. Deploy

```bash
sudo nixos-rebuild switch --flake .#myserver
```

## Docker Deployment

A Docker-based deployment is also available:

```yaml
# docker-compose.yml
version: '3.8'
services:
  osgeo-inject:
    image: ghcr.io/timlinux/OSGEO-Inject:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./content:/var/www/osgeo-inject/content
      - ./certs:/etc/ssl/certs
    environment:
      - DOMAIN=affiliate.osgeo.org
```

## Manual Installation

### 1. Clone Repository

```bash
git clone https://github.com/timlinux/OSGEO-Inject.git
cd osgeo-inject
```

### 2. Build Assets

```bash
nix develop
npm ci
npm run build
```

### 3. Configure Nginx

Copy `nginx/nginx.conf` to your nginx configuration directory and adjust paths.

### 4. Deploy Static Files

```bash
rsync -avz src/ /var/www/osgeo-inject/
```

## Verification

After deployment, verify the installation:

```bash
# Health check
curl https://affiliate.osgeo.org/health

# Test CORS
curl -H "Origin: https://qgis.org" \
     -I https://affiliate.osgeo.org/js/osgeo-inject.min.js
```

## Next Steps

- [Nginx Configuration](nginx.md)
- [Matomo Setup](matomo.md)
- [Security](security.md)
