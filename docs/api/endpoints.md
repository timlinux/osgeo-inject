<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# API Endpoints

Reference documentation for OSGEO-Inject server endpoints.

## Base URL

```
https://affiliate.osgeo.org
```

## Static Assets

### GET /js/osgeo-inject.min.js

Minified JavaScript library.

**Response:**
- Content-Type: `application/javascript`
- Cache-Control: `public, max-age=3600, must-revalidate`
- CORS: Enabled for whitelisted origins

### GET /css/osgeo-inject.min.css

Minified CSS stylesheet.

**Response:**
- Content-Type: `text/css`
- Cache-Control: `public, max-age=3600, must-revalidate`
- CORS: Enabled for whitelisted origins

### GET /images/osgeo-logo.svg

OSGeo logo image.

**Response:**
- Content-Type: `image/svg+xml`
- Cache-Control: `public, max-age=604800, immutable`
- CORS: Enabled for whitelisted origins

## Content

### GET /content/announcement.json

Current announcement data.

**Response:**
```json
{
  "id": "2026-001",
  "message": "FOSS4G 2026 - Register now!",
  "link": "https://foss4g.osgeo.org/",
  "published": "2026-01-15T00:00:00Z",
  "expires": "2026-12-31T23:59:59Z"
}
```

**Headers:**
- Content-Type: `application/json`
- Cache-Control: `public, max-age=900, must-revalidate`
- CORS: Enabled for whitelisted origins

### GET /content/history.json

Announcement history.

**Response:**
```json
{
  "announcements": [
    {
      "id": "2026-001",
      "message": "FOSS4G 2026 - Register now!",
      "link": "https://foss4g.osgeo.org/",
      "published": "2026-01-15T00:00:00Z",
      "expires": "2026-12-31T23:59:59Z",
      "active": true
    }
  ],
  "lastUpdated": "2026-01-15T00:00:00Z"
}
```

## Utility

### GET /health

Health check endpoint.

**Response:**
- Status: `200 OK`
- Body: `OK`
- Content-Type: `text/plain`

### GET /demo

Demo page showing the badge in action.

### GET /history

HTML page showing announcement history.

## CORS

All content endpoints support CORS for whitelisted origins:

**Preflight Response:**
```
Access-Control-Allow-Origin: <origin>
Access-Control-Allow-Methods: GET, OPTIONS
Access-Control-Allow-Headers: Accept, Content-Type
Access-Control-Max-Age: 86400
```

## Rate Limits

| Endpoint | Rate | Burst |
|----------|------|-------|
| Static assets | 10/s | 20 |
| Content | 10/s | 20 |
| Matomo | 30/s | 50 |

## Error Responses

### 404 Not Found

Resource does not exist.

### 429 Too Many Requests

Rate limit exceeded.

### 500 Internal Server Error

Server error. Check logs.
