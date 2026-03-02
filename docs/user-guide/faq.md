<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Frequently Asked Questions

## General

### What is OSGEO-Inject?

OSGEO-Inject is a lightweight JavaScript widget that displays OSGeo affiliation
badges and announcements on participating project websites.

### Is it free to use?

Yes, OSGEO-Inject is open source software licensed under the MIT license.

### Which projects can use it?

Any official OSGeo community project, incubating project, or affiliated project
can use OSGEO-Inject after being onboarded.

## Technical

### Why isn't the badge showing?

1. **Check CORS**: Your domain must be whitelisted
2. **Check HTTPS**: The badge only works on HTTPS sites
3. **Check Console**: Look for JavaScript errors
4. **Check Script Tag**: Ensure the script is loading

### Can I use it on localhost?

Yes, `localhost` is whitelisted for development purposes.

### Does it affect page performance?

No. The badge:
- Loads asynchronously (doesn't block rendering)
- Has a tiny footprint (< 15KB total)
- Caches aggressively (1 hour for announcements)

### Is it accessible?

Yes. The badge is WCAG 2.1 AA compliant with:
- Keyboard navigation support
- Screen reader compatibility
- High contrast support
- Reduced motion support

### Does it track users?

The badge sends a single, anonymous tracking request to Matomo containing:
- Page URL and title
- Hostname
- Timestamp

No personal information is collected.

## Troubleshooting

### Badge appears but no announcement

The announcement may have expired or not been set. Contact administrators.

### Badge is behind other elements

Add CSS to increase the z-index:

```css
.osgeo-inject { z-index: 9999999; }
```

### Badge conflicts with my site's CSS

Use more specific selectors or override CSS variables.

### How do I get my project onboarded?

Contact the OSGEO-Inject administrators with:
- Your project name
- Your domain(s)
- A brief description

## Support

### Where can I get help?

- [Documentation](https://timlinux.github.io/osgeo-inject/)
- [GitHub Issues](https://github.com/timlinux/osgeo-inject/issues)
- [OSGeo Mailing Lists](https://www.osgeo.org/community/)

### How can I contribute?

See our [Contributing Guide](../developer-guide/contributing.md).
