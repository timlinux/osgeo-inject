<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# OSGEO-Inject

**Lightweight affiliate badge system for OSGeo community projects**

[![CI Status](https://github.com/timlinux/OSGEO-Inject/actions/workflows/ci.yml/badge.svg)](https://github.com/timlinux/OSGEO-Inject/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

OSGEO-Inject is a minimal, high-performance JavaScript widget that displays OSGeo affiliation badges and announcements on participating project websites. Designed with security and performance as the highest priorities, the entire payload is under 15KB and loads asynchronously to never impact host page performance.

```mermaid
graph LR
    A[OSGeo Project Site] -->|loads| B[osgeo-inject.js]
    B -->|fetches| C[announcement.json]
    B -->|tracks| D[Matomo Analytics]
    B -->|displays| E[OSGeo Badge]
```

## Key Features

- **Tiny Footprint**: Under 15KB total (JS + CSS + images)
- **Zero Dependencies**: Pure JavaScript and CSS, no external libraries
- **Security First**: Strict CORS policies, CSP compliant
- **Performance Optimized**: Async loading, aggressive caching
- **Accessible**: WCAG 2.1 AA compliant
- **Themeable**: Light/dark mode support with auto-detection
- **Analytics**: Matomo integration for usage tracking

## Quick Start

Add these two lines to your HTML:

```html
<script
  src="https://affiliate.osgeo.org/js/osgeo-inject.min.js"
  defer
  data-position="top-right"
></script>
<link
  rel="stylesheet"
  href="https://affiliate.osgeo.org/css/osgeo-inject.min.css"
/>
```

That's it! The OSGeo badge will appear in the specified position on your page.

## Architecture

```mermaid
C4Context
    title OSGEO-Inject System Context

    Person(user, "Website Visitor", "Visits an OSGeo project website")
    System(osgeo_project, "OSGeo Project Site", "Community project website")
    System(inject_server, "OSGEO-Inject Server", "affiliate.osgeo.org")
    System(matomo, "Matomo Analytics", "Usage tracking")

    Rel(user, osgeo_project, "Visits")
    Rel(osgeo_project, inject_server, "Loads JS/CSS/Images")
    Rel(inject_server, matomo, "Tracks views")
```

## How It Works

1. **Loading**: The script loads asynchronously, never blocking page render
2. **Configuration**: Reads options from `data-*` attributes
3. **Fetching**: Retrieves current announcement from the server (cached for 1 hour)
4. **Rendering**: Creates a minimal DOM structure for the badge
5. **Tracking**: Sends a single pixel request to Matomo for analytics

## Support This Project

This project is maintained by volunteers in the OSGeo community. If you find it useful, please consider supporting its development:

- [GitHub Sponsors](https://github.com/sponsors/timlinux)
- [Ko-fi](https://ko-fi.com/kartoza)

---

Made with 💗 by [Kartoza](https://kartoza.com) | [Donate!](https://github.com/sponsors/timlinux) | [GitHub](https://github.com/timlinux/OSGEO-Inject)
