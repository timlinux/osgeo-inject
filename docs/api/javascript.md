<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# JavaScript API

Reference documentation for the OSGEO-Inject JavaScript API.

## Global Object

The library exposes `window.OSGeoInject`:

```javascript
window.OSGeoInject = {
  init: Function,
  version: string,
  config: Object
};
```

## Methods

### init()

Manually initialize the badge. Called automatically on page load.

```javascript
window.OSGeoInject.init();
```

## Properties

### version

The library version string.

```javascript
console.log(window.OSGeoInject.version); // "0.1.0"
```

### config

The configuration object:

```javascript
{
  baseUrl: "https://affiliate.osgeo.org",
  matomoUrl: "https://affiliate.osgeo.org/matomo",
  matomoSiteId: 1,
  announcementEndpoint: "/content/announcement.json",
  osgeoUrl: "https://www.osgeo.org",
  osgeoProjectsUrl: "https://www.osgeo.org/projects/",
  logoPath: "/images/osgeo-logo.svg",
  cacheDuration: 3600000
}
```

## Data Attributes

Configure via script tag attributes:

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `data-position` | string | `"top-right"` | Badge position |
| `data-collapsed` | boolean | `false` | Start collapsed |
| `data-theme` | string | `"auto"` | Color theme |

## Events

The badge doesn't emit custom events, but you can observe DOM changes:

```javascript
const observer = new MutationObserver((mutations) => {
  // Badge was modified
});

observer.observe(
  document.getElementById('osgeo-inject-badge'),
  { attributes: true, childList: true }
);
```

## CSS Classes

| Class | Description |
|-------|-------------|
| `.osgeo-inject` | Main container |
| `.osgeo-inject--collapsed` | Collapsed state |
| `.osgeo-inject--light` | Light theme |
| `.osgeo-inject--dark` | Dark theme |
| `.osgeo-inject--top-right` | Position modifier |

## LocalStorage

The library uses localStorage for caching:

| Key | Description |
|-----|-------------|
| `osgeo-inject-announcement` | Cached announcement JSON |
| `osgeo-inject-announcement-time` | Cache timestamp |

Clear cache:

```javascript
localStorage.removeItem('osgeo-inject-announcement');
localStorage.removeItem('osgeo-inject-announcement-time');
```
