<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Nginx Configuration

This guide explains the OSGEO-Inject Nginx configuration.

## Overview

The Nginx configuration is optimized for:

- **Security**: Strict CORS, CSP headers, rate limiting
- **Performance**: Gzip compression, caching, HTTP/2

## CORS Configuration

The CORS whitelist uses an Nginx map:

```nginx
map $http_origin $cors_origin {
    default "";
    "~^https?://.*\.osgeo\.org$" $http_origin;
    "~^https?://.*\.qgis\.org$" $http_origin;
    # ... more origins
}
```

### Adding Origins

Edit the map block or use the onboarding script:

```bash
./scripts/onboard-site.sh -d newproject.org -s
```

## Caching Headers

| Resource | Cache Duration | Header |
|----------|----------------|--------|
| JavaScript | 1 hour | `max-age=3600, must-revalidate` |
| CSS | 1 hour | `max-age=3600, must-revalidate` |
| Images | 7 days | `max-age=604800, immutable` |
| Content | 15 minutes | `max-age=900, must-revalidate` |

## Security Headers

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
add_header X-Content-Type-Options "nosniff";
add_header X-Frame-Options "SAMEORIGIN";
add_header X-XSS-Protection "1; mode=block";
add_header Referrer-Policy "strict-origin-when-cross-origin";
```

## Rate Limiting

```nginx
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;
```

## SSL Configuration

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;
ssl_session_cache shared:SSL:10m;
ssl_stapling on;
ssl_stapling_verify on;
```

## Testing Configuration

```bash
# Syntax check
nginx -t

# Reload
systemctl reload nginx
```
