#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
# SPDX-License-Identifier: MIT

# Check image file sizes for pre-commit

set -euo pipefail

MAX_SIZE=51200 # 50KB in bytes
FAILED=0

for file in "$@"; do
  if [[ -f "$file" ]]; then
    size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)

    if [[ $size -gt $MAX_SIZE ]]; then
      echo "❌ $file: ${size} bytes (max: ${MAX_SIZE})"
      FAILED=1
    else
      echo "✓ $file: ${size} bytes"
    fi
  fi
done

if [[ $FAILED -eq 1 ]]; then
  echo ""
  echo "Image files must be under 50KB for optimal performance."
  echo "Consider using optipng or jpegoptim to compress images."
  exit 1
fi
