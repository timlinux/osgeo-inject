<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Testing

This guide covers testing procedures for OSGEO-Inject.

## Test Server

Start the local test server:

```bash
npm run serve
# or
nix run .#test-server
```

Visit http://localhost:8080/test/demo.html

## Manual Testing

### Badge Display

1. Open demo page
2. Verify badge appears in correct position
3. Check logo loads correctly
4. Verify announcement text displays

### Position Testing

Test all four positions:

```html
data-position="top-right"
data-position="top-left"
data-position="bottom-right"
data-position="bottom-left"
```

### Theme Testing

1. **Auto**: Change system theme, verify badge updates
2. **Light**: Force light mode
3. **Dark**: Force dark mode

### Collapsed State

```html
data-collapsed="true"
```

Verify badge starts collapsed and can be expanded.

### Mobile Testing

1. Open demo in mobile viewport
2. Verify responsive layout
3. Check touch interactions

### Accessibility Testing

1. **Keyboard**: Tab through badge, verify focus states
2. **Screen Reader**: Test with VoiceOver/NVDA
3. **Reduced Motion**: Enable preference, verify no animations

## Automated Testing

### Linting

```bash
npm run lint
```

### Format Check

```bash
npm run format:check
```

### Pre-commit Hooks

```bash
pre-commit run --all-files
```

## CORS Testing

Test CORS from different origins:

```bash
# Should succeed (whitelisted)
curl -H "Origin: https://qgis.org" \
     -I https://affiliate.osgeo.org/js/osgeo-inject.min.js

# Should fail (not whitelisted)
curl -H "Origin: https://evil.com" \
     -I https://affiliate.osgeo.org/js/osgeo-inject.min.js
```

## Performance Testing

### Asset Size

```bash
npm run build
ls -la src/js/osgeo-inject.min.js  # Should be < 10KB
ls -la src/css/osgeo-inject.min.css  # Should be < 5KB
```

### Network

Use browser DevTools:
1. Open Network tab
2. Load demo page
3. Verify all requests complete quickly
4. Check for caching headers

## Browser Compatibility

Test in:
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile Safari
- Chrome Android

## Test Checklist

- [ ] Badge displays correctly
- [ ] All positions work
- [ ] Theme switching works
- [ ] Collapsed state works
- [ ] Links are correct
- [ ] Announcement displays
- [ ] Mobile responsive
- [ ] Keyboard accessible
- [ ] Screen reader compatible
- [ ] Assets under size budget
- [ ] CORS working
- [ ] Caching working
