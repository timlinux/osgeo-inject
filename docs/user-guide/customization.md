<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Customization

Learn how to customize the appearance of the OSGEO-Inject badge.

## CSS Variables

Override these CSS custom properties to customize the badge:

```css
/* In your site's stylesheet */
.osgeo-inject {
  /* Background colors */
  --osgeo-bg: #ffffff;

  /* Text colors */
  --osgeo-text: #333333;
  --osgeo-text-secondary: #666666;

  /* Border and shadow */
  --osgeo-border: #e0e0e0;
  --osgeo-shadow: rgba(0, 0, 0, 0.15);

  /* Accent color (green by default) */
  --osgeo-accent: #4caf50;

  /* Link colors */
  --osgeo-link: #1a73e8;
  --osgeo-link-hover: #0d47a1;
}
```

## Dark Mode Customization

For dark mode, target the `.osgeo-inject--dark` class:

```css
.osgeo-inject--dark {
  --osgeo-bg: #2d2d2d;
  --osgeo-text: #e0e0e0;
  --osgeo-border: #444444;
}
```

## Positioning Adjustments

Adjust the badge position offset:

```css
/* Move the badge further from the corner */
.osgeo-inject--top-right {
  top: 32px;
  right: 32px;
}
```

## Z-Index Conflicts

If the badge is hidden behind other elements:

```css
.osgeo-inject {
  z-index: 9999999;
}
```

## Hide on Specific Pages

Use CSS to hide the badge on certain pages:

```css
/* Hide on documentation pages */
.docs-page .osgeo-inject {
  display: none;
}
```

## Animation Customization

Disable or customize animations:

```css
/* Disable all animations */
.osgeo-inject,
.osgeo-inject * {
  transition: none !important;
}

/* Custom animation timing */
.osgeo-inject__content {
  transition: max-height 0.5s ease-in-out;
}
```

## Accessibility

The badge respects `prefers-reduced-motion`:

```css
@media (prefers-reduced-motion: reduce) {
  .osgeo-inject,
  .osgeo-inject * {
    transition: none !important;
  }
}
```
