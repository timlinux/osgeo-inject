<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Architecture

This document describes the system architecture of OSGEO-Inject.

## System Overview

```mermaid
graph TB
    subgraph "Client Browser"
        A[OSGeo Project Page]
        B[osgeo-inject.js]
        C[Badge UI]
    end

    subgraph "OSGEO-Inject Server"
        D[Nginx]
        E[Static Assets]
        F[Content JSON]
    end

    subgraph "Analytics"
        G[Matomo]
    end

    A -->|loads| B
    B -->|fetches| D
    D -->|serves| E
    D -->|serves| F
    B -->|renders| C
    B -->|tracks| G
```

## Component Architecture

### Client Components

```mermaid
classDiagram
    class OSGeoInject {
        +init()
        +config: Config
        +version: string
    }

    class Config {
        +baseUrl: string
        +matomoUrl: string
        +matomoSiteId: number
        +announcementEndpoint: string
        +cacheDuration: number
    }

    class Badge {
        +render()
        +toggle()
        +updateTheme()
    }

    class Analytics {
        +trackPageView()
    }

    OSGeoInject --> Config
    OSGeoInject --> Badge
    OSGeoInject --> Analytics
```

### Server Components

```mermaid
C4Container
    title OSGEO-Inject Server Architecture

    Container(nginx, "Nginx", "Web Server", "Serves static assets with CORS")
    Container(matomo, "Matomo", "Analytics", "Tracks page views")
    ContainerDb(content, "Content", "JSON Files", "Announcements and history")
    ContainerDb(mariadb, "MariaDB", "Database", "Matomo data")

    Rel(nginx, content, "Reads")
    Rel(matomo, mariadb, "Stores data")
```

## Data Flow

### Page Load Sequence

```mermaid
sequenceDiagram
    participant Browser
    participant Page as OSGeo Project
    participant Inject as OSGEO-Inject Server
    participant Matomo

    Browser->>Page: Request page
    Page->>Browser: HTML response
    Browser->>Inject: Load osgeo-inject.js
    Inject->>Browser: JavaScript file
    Browser->>Inject: Load osgeo-inject.css
    Inject->>Browser: CSS file
    Browser->>Browser: Initialize badge
    Browser->>Inject: Fetch announcement.json
    Inject->>Browser: JSON response
    Browser->>Browser: Render badge
    Browser->>Matomo: Track page view (pixel)
```

### Announcement Update Flow

```mermaid
sequenceDiagram
    participant Admin
    participant Script as update-announcement.sh
    participant Server as OSGEO-Inject Server
    participant Clients

    Admin->>Script: Create announcement
    Script->>Script: Archive current
    Script->>Script: Generate new JSON
    Script->>Server: Deploy via rsync
    Server->>Server: Update content files
    Note over Clients: Cache expires (1 hour)
    Clients->>Server: Fetch new announcement
    Server->>Clients: Updated JSON
```

## File Structure

```
osgeo-inject/
├── src/
│   ├── js/
│   │   └── osgeo-inject.js      # Main JavaScript
│   ├── css/
│   │   └── osgeo-inject.css     # Styles
│   ├── content/
│   │   ├── announcement.json    # Current announcement
│   │   └── history.json         # Announcement history
│   └── images/
│       └── osgeo-logo.svg       # OSGeo logo
├── nginx/
│   └── nginx.conf               # Server configuration
├── nixos/
│   ├── module.nix               # NixOS module
│   └── vm-configuration.nix     # VM testbed
├── scripts/
│   ├── onboard-site.sh          # Site onboarding
│   ├── update-announcement.sh   # Announcement management
│   ├── backup.sh                # Backup workflow
│   └── restore.sh               # Restore workflow
├── docs/                        # MkDocs documentation
└── test/                        # Test files
```

## Security Model

```mermaid
graph TB
    subgraph "Security Layers"
        A[HTTPS Only]
        B[CORS Whitelist]
        C[CSP Headers]
        D[Rate Limiting]
        E[Input Sanitization]
    end

    F[Request] --> A
    A --> B
    B --> C
    C --> D
    D --> E
    E --> G[Response]
```

### CORS Strategy

Only whitelisted OSGeo project domains can load the resources:

```nginx
map $http_origin $cors_origin {
    default "";
    "~^https?://.*\.osgeo\.org$" $http_origin;
    "~^https?://.*\.qgis\.org$" $http_origin;
    # ... other OSGeo projects
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

## Performance Optimizations

### Caching Strategy

| Resource | Cache Duration | Strategy |
|----------|----------------|----------|
| JavaScript | 1 hour | `must-revalidate` |
| CSS | 1 hour | `must-revalidate` |
| Images | 7 days | `immutable` |
| Announcements | 15 minutes | `must-revalidate` |

### Asset Size Budget

| Asset | Budget | Minified |
|-------|--------|----------|
| JavaScript | < 10KB | ✓ |
| CSS | < 5KB | ✓ |
| Images | < 50KB each | Optimized |
| **Total** | **< 15KB** | |

### Client-Side Caching

```javascript
// localStorage caching
const cacheKey = "osgeo-inject-announcement";
const cacheTimeKey = "osgeo-inject-announcement-time";
const cacheDuration = 3600000; // 1 hour
```

## Monitoring & Analytics

```mermaid
graph LR
    A[Page View] -->|pixel| B[Matomo]
    B --> C[Dashboard]
    C --> D[Reports]

    subgraph "Tracked Data"
        E[Hostname]
        F[Path]
        G[Timestamp]
    end
```

## Deployment Architecture

```mermaid
graph TB
    subgraph "Development"
        A[Local Dev]
        B[Nix Flake]
    end

    subgraph "CI/CD"
        C[GitHub Actions]
        D[Pre-commit Hooks]
    end

    subgraph "Production"
        E[NixOS Server]
        F[Let's Encrypt]
        G[Matomo Instance]
    end

    A --> B
    B --> C
    C --> E
    D --> C
    E --> F
    E --> G
```
