<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Matomo Setup

This guide covers setting up Matomo analytics for OSGEO-Inject.

## Overview

Matomo tracks badge impressions across all participating sites, providing:

- Page view counts per site
- Geographic distribution
- Traffic patterns

## NixOS Configuration

```nix
services.osgeo-inject = {
  enableMatomo = true;
  matomoDomain = "matomo.affiliate.osgeo.org";
};
```

## Initial Setup

1. Access Matomo at `https://matomo.affiliate.osgeo.org`
2. Follow the installation wizard
3. Create a site with ID 1 for OSGEO-Inject
4. Note the tracking code (already integrated)

## Configuration

### Site Setup

Create a site in Matomo for OSGEO-Inject:

- **Name**: OSGEO-Inject
- **URLs**: All participating OSGeo project domains
- **Type**: Website

### Privacy Settings

Configure privacy-respecting settings:

- **IP Anonymization**: Enable (mask last 2 bytes)
- **Do Not Track**: Respect
- **Data Retention**: 180 days

## Tracking Implementation

The JavaScript uses pixel tracking:

```javascript
const params = new URLSearchParams({
  idsite: 1,
  rec: 1,
  url: window.location.href,
  action_name: document.title,
});

const img = new Image();
img.src = `${matomoUrl}/matomo.php?${params}`;
```

## Reports

### Useful Reports

- **Visitors > Overview**: Total impressions
- **Behavior > Pages**: Top pages
- **Visitors > Locations**: Geographic distribution

### Custom Segments

Create segments for specific projects:

- QGIS: `pageUrl=@qgis.org`
- PostGIS: `pageUrl=@postgis.net`

## Maintenance

### Database Optimization

```bash
mysql matomo -e "OPTIMIZE TABLE matomo_log_visit;"
```

### Archive Processing

```bash
php /var/www/matomo/console core:archive
```

## Backup

Matomo data is included in system backups:

```bash
./scripts/backup.sh -t database
```
