<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Security

This guide covers security considerations for OSGEO-Inject.

## Design Principles

1. **Minimal Surface Area**: Only serve static files
2. **Defense in Depth**: Multiple security layers
3. **Least Privilege**: Restrict access to whitelisted origins
4. **Fail Secure**: Default to denying access

## Security Layers

### HTTPS Only

All traffic must use HTTPS:

```nginx
server {
    listen 80;
    return 301 https://$server_name$request_uri;
}
```

### CORS Whitelist

Only approved domains can load resources:

```nginx
map $http_origin $cors_origin {
    default "";  # Deny by default
    "~^https?://.*\.osgeo\.org$" $http_origin;
}
```

### Content Security Policy

```
Content-Security-Policy: default-src 'self';
                         script-src 'self';
                         style-src 'self' 'unsafe-inline';
                         img-src 'self' data:;
                         connect-src 'self'
```

### Rate Limiting

Prevent abuse:

```nginx
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req zone=general burst=20 nodelay;
```

## Input Sanitization

The JavaScript sanitizes all user-controlled content:

```javascript
function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str;
  return div.innerHTML;
}
```

## Secrets Management

- Never commit secrets to git
- Use environment variables for sensitive config
- Rotate credentials regularly

## Security Checklist

- [ ] HTTPS enabled with valid certificate
- [ ] Security headers configured
- [ ] CORS whitelist current
- [ ] Rate limiting enabled
- [ ] Logs monitored
- [ ] Backups encrypted
- [ ] Dependencies updated

## Vulnerability Reporting

Report security issues to: tim@kartoza.com

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact

We aim to respond within 48 hours.
