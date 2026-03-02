<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Configuration

This guide covers all configuration options for the OSGEO-Inject badge.

## Data Attributes

Configuration is done via `data-*` attributes on the script tag:

```html
<script
  src="https://affiliate.osgeo.org/js/osgeo-inject.min.js"
  defer
  data-position="top-right"
  data-theme="auto"
  data-collapsed="false"
></script>
```

## Options Reference

### data-position

Controls where the badge appears on the page.

| Value | Description |
|-------|-------------|
| `top-right` | Top right corner (default) |
| `top-left` | Top left corner |
| `bottom-right` | Bottom right corner |
| `bottom-left` | Bottom left corner |

### data-theme

Controls the color theme of the badge.

| Value | Description |
|-------|-------------|
| `auto` | Follow system preference (default) |
| `light` | Always use light theme |
| `dark` | Always use dark theme |

### data-collapsed

Controls whether the badge starts in collapsed state.

| Value | Description |
|-------|-------------|
| `false` | Start expanded (default) |
| `true` | Start collapsed |

## JavaScript API

You can also control the badge programmatically:

```javascript
// Access the badge API
window.OSGeoInject.init();

// Get version
console.log(window.OSGeoInject.version);

// Access configuration
console.log(window.OSGeoInject.config);
```

## CSS Customization

The badge uses CSS custom properties that you can override:

```css
.osgeo-inject {
  --osgeo-bg: #ffffff;
  --osgeo-text: #333333;
  --osgeo-text-secondary: #666666;
  --osgeo-border: #e0e0e0;
  --osgeo-shadow: rgba(0, 0, 0, 0.15);
  --osgeo-accent: #4caf50;
  --osgeo-link: #1a73e8;
  --osgeo-link-hover: #0d47a1;
}
```

## Caching

The badge caches announcement data for 1 hour in localStorage:

- `osgeo-inject-announcement`: Cached announcement JSON
- `osgeo-inject-announcement-time`: Cache timestamp

To force a refresh, clear these localStorage keys.
