<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# API Reference

Developer reference for the OSGEO-Inject codebase.

## Module Structure

```
src/js/osgeo-inject.js
├── CONFIG (object)          # Configuration constants
├── DEFAULTS (object)        # Default options
├── getOptions() → Object    # Read data attributes
├── detectTheme() → string   # Theme detection
├── fetchAnnouncement() → Promise<Object>  # Fetch announcement
├── trackPageView()          # Send analytics
├── createBadge() → Element  # Create DOM
├── escapeHtml() → string    # XSS prevention
└── init()                   # Main initialization
```

## Configuration

```javascript
const CONFIG = {
  baseUrl: "https://affiliate.osgeo.org",
  matomoUrl: "https://affiliate.osgeo.org/matomo",
  matomoSiteId: 1,
  announcementEndpoint: "/content/announcement.json",
  osgeoUrl: "https://www.osgeo.org",
  osgeoProjectsUrl: "https://www.osgeo.org/projects/",
  logoPath: "/images/osgeo-logo.svg",
  cacheDuration: 3600000
};
```

## Functions

### getOptions()

Reads configuration from script tag data attributes.

```javascript
function getOptions() {
  const script = document.currentScript ||
    document.querySelector('script[src*="osgeo-inject"]');
  // ...
}
```

### detectTheme(themeSetting)

Detects preferred color scheme.

```javascript
function detectTheme(themeSetting) {
  if (themeSetting === "light" || themeSetting === "dark") {
    return themeSetting;
  }
  // Auto-detect
  if (window.matchMedia?.("(prefers-color-scheme: dark)").matches) {
    return "dark";
  }
  return "light";
}
```

### fetchAnnouncement()

Fetches announcement with caching.

```javascript
async function fetchAnnouncement() {
  // Check localStorage cache
  // Fetch if expired
  // Cache result
  return data;
}
```

### createBadge(options, announcement)

Creates the badge DOM structure.

```javascript
function createBadge(options, announcement) {
  const container = document.createElement("div");
  container.id = "osgeo-inject-badge";
  // ...
  return container;
}
```

### escapeHtml(str)

Escapes HTML to prevent XSS.

```javascript
function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str;
  return div.innerHTML;
}
```

## CSS Architecture

### BEM Naming

```css
.osgeo-inject              /* Block */
.osgeo-inject__content     /* Element */
.osgeo-inject--collapsed   /* Modifier */
```

### Custom Properties

```css
.osgeo-inject {
  --osgeo-bg: #fff;
  --osgeo-text: #333;
  --osgeo-accent: #4caf50;
}
```

## Build Process

```bash
# Minify JavaScript
uglifyjs src/js/osgeo-inject.js \
  --compress --mangle \
  -o src/js/osgeo-inject.min.js

# Minify CSS
cleancss \
  -o src/css/osgeo-inject.min.css \
  src/css/osgeo-inject.css
```
