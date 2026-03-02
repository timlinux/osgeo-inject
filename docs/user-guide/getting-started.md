<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Getting Started

This guide will help you integrate the OSGEO-Inject badge into your OSGeo community project website.

## Prerequisites

Before integrating, ensure your project:

1. Is an official OSGeo community project or incubating project
2. Has been onboarded to the CORS whitelist (contact the administrators)
3. Has HTTPS enabled on your website

## Integration Steps

### Step 1: Add the CSS

Add the stylesheet to your HTML `<head>`:

```html
<link
  rel="stylesheet"
  href="https://affiliate.osgeo.org/css/osgeo-inject.min.css"
/>
```

### Step 2: Add the JavaScript

Add the script before your closing `</body>` tag or in the `<head>` with `defer`:

```html
<script
  src="https://affiliate.osgeo.org/js/osgeo-inject.min.js"
  defer
></script>
```

### Step 3: Configure Position (Optional)

Specify where the badge should appear:

```html
<script
  src="https://affiliate.osgeo.org/js/osgeo-inject.min.js"
  defer
  data-position="top-right"
></script>
```

## Configuration Options

| Attribute | Values | Default | Description |
|-----------|--------|---------|-------------|
| `data-position` | `top-right`, `top-left`, `bottom-right`, `bottom-left` | `top-right` | Badge position |
| `data-collapsed` | `true`, `false` | `false` | Start collapsed |
| `data-theme` | `light`, `dark`, `auto` | `auto` | Color theme |

## Example Integration

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>My OSGeo Project</title>
  <!-- OSGEO-Inject CSS -->
  <link
    rel="stylesheet"
    href="https://affiliate.osgeo.org/css/osgeo-inject.min.css"
  />
</head>
<body>
  <h1>Welcome to My Project</h1>
  <p>Your content here...</p>

  <!-- OSGEO-Inject JavaScript -->
  <script
    src="https://affiliate.osgeo.org/js/osgeo-inject.min.js"
    defer
    data-position="top-right"
    data-theme="auto"
  ></script>
</body>
</html>
```

## Verification

After adding the code:

1. Refresh your page
2. Look for the OSGeo badge in the specified corner
3. Click on it to verify the links work
4. Check the browser console for any errors

## Troubleshooting

### Badge not appearing

1. **Check CORS**: Your domain must be whitelisted. Contact administrators.
2. **Check Console**: Look for errors in browser developer tools.
3. **Check HTTPS**: The badge only works on HTTPS sites.

### Badge appears but no announcement

The announcement may have expired or not yet been set. Contact administrators.

### Styling conflicts

The badge uses a high z-index (999999) and fixed positioning. If you have other fixed elements, adjust your CSS accordingly.

## Next Steps

- [Configuration](configuration.md) - Detailed configuration options
- [Customization](customization.md) - Styling and theming
- [FAQ](faq.md) - Common questions
