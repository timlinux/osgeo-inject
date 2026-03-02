<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# OSGEO-Inject

**Lightweight affiliate badge system for OSGeo community projects**

![OSGEO-Inject Banner](docs/assets/screenshot.png)

A minimal, high-performance JavaScript widget that displays OSGeo affiliation
badges and announcements on participating project websites. Designed with
security and performance as the highest priorities, the entire payload is
under 15KB and loads asynchronously to never impact host page performance.

---

[![CI Status](https://github.com/timlinux/osgeo-inject/actions/workflows/ci.yml/badge.svg)](https://github.com/timlinux/osgeo-inject/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/timlinux/osgeo-inject)](https://github.com/timlinux/osgeo-inject/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![REUSE Compliant](https://img.shields.io/badge/reuse-compliant-green.svg)](https://reuse.software/)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?logo=javascript&logoColor=black)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?logo=css3&logoColor=white)
![Nix](https://img.shields.io/badge/Nix-5277C3?logo=nixos&logoColor=white)
![NixOS](https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white)

---

## Quick Start

Add these two lines to your project's HTML:

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

That's it! The OSGeo badge will appear in the top-right corner of your page.

### Configuration Options

| Attribute | Values | Default | Description |
|-----------|--------|---------|-------------|
| `data-position` | `top-right`, `top-left`, `bottom-right`, `bottom-left` | `top-right` | Badge position |
| `data-collapsed` | `true`, `false` | `false` | Start collapsed |
| `data-theme` | `light`, `dark`, `auto` | `auto` | Color theme |

---

## Key Links

- 📖 [**Documentation**](https://timlinux.github.io/osgeo-inject/)
- 🐛 [**Issue Tracker**](https://github.com/timlinux/osgeo-inject/issues)
- 📜 [**Code of Conduct**](CODE_OF_CONDUCT.md)
- 📄 [**License (MIT)**](LICENSES/MIT.txt)
- 👩‍💻 [**Developer Guide**](https://timlinux.github.io/osgeo-inject/developer-guide/)

---

## Support This Project

This project is maintained by volunteers in the OSGeo community. If you find
it useful, please consider supporting its development:

[![Sponsor](https://img.shields.io/badge/Sponsor-❤-red)](https://github.com/sponsors/timlinux)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Buy%20me%20a%20coffee-orange)](https://ko-fi.com/kartoza)

---

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START -->
| [<img src="https://avatars.githubusercontent.com/u/178003?v=4" width="100px;"/><br /><sub><b>Tim Sketcher</b></sub>](https://github.com/timlinux) |
|:---:|
<!-- ALL-CONTRIBUTORS-LIST:END -->

---

Made with 💗 by [Kartoza](https://kartoza.com) | [Donate!](https://github.com/sponsors/timlinux) | [GitHub](https://github.com/timlinux/osgeo-inject)
