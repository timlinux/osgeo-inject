<!--
SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
SPDX-License-Identifier: MIT
-->

# Contributing

Thank you for your interest in contributing to OSGEO-Inject!

## Getting Started

### Prerequisites

- Nix (for development environment)
- Git

### Setup

1. Clone the repository:

```bash
git clone https://github.com/timlinux/osgeo-inject.git
cd osgeo-inject
```

2. Enter the development environment:

```bash
nix develop
```

3. Install npm dependencies:

```bash
npm ci
```

4. Install pre-commit hooks:

```bash
pre-commit install
```

## Development Workflow

### Running the Test Server

```bash
npm run serve
# or
nix run .#test-server
```

Visit http://localhost:8080/test/demo.html

### Building Assets

```bash
npm run build
```

### Linting

```bash
npm run lint
npm run format
```

### Documentation

```bash
npm run docs:serve
```

## Code Style

### JavaScript

- Use `"use strict";` in all files
- Prefer `const` over `let`, never use `var`
- Use template literals for string interpolation
- Add JSDoc comments for public functions

### CSS

- Follow BEM naming convention
- Use CSS custom properties for theming
- Keep selectors shallow (max 3 levels)

### Commits

Follow conventional commits:

```
feat: add new position option
fix: correct CORS header handling
docs: update installation guide
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes
4. Run tests and linting
5. Commit with clear messages
6. Push and open a PR

### PR Checklist

- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] Documentation updated
- [ ] REUSE compliance checked
- [ ] No secrets in code

## Testing

### Manual Testing

1. Start test server
2. Open demo page
3. Test all positions and themes
4. Test on mobile viewport
5. Test with screen reader

### Automated Testing

```bash
npm test
```

## Release Process

1. Update version in `package.json`
2. Update CHANGELOG.md
3. Create git tag: `git tag v0.1.0`
4. Push: `git push --tags`
5. GitHub Action creates release

## Getting Help

- Open an issue for bugs
- Start a discussion for questions
- Join OSGeo community channels

---

Made with 💗 by [Kartoza](https://kartoza.com)
