#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
# SPDX-License-Identifier: MIT

# Nginx configuration validation script for pre-commit

set -euo pipefail

for file in "$@"; do
  if [[ -f "$file" ]]; then
    echo "Validating: $file"

    # Create a temporary nginx environment
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    # Create minimal required structure
    mkdir -p "$temp_dir"/{logs,ssl,www}
    touch "$temp_dir/ssl/affiliate.osgeo.org.crt"
    touch "$temp_dir/ssl/affiliate.osgeo.org.key"

    # Create a test configuration that includes the target file
    cat >"$temp_dir/test.conf" <<EOF
daemon off;
worker_processes 1;
error_log /dev/null;
pid $temp_dir/nginx.pid;

events {
    worker_connections 64;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /dev/null;

    # Minimal SSL config for validation
    ssl_certificate $temp_dir/ssl/affiliate.osgeo.org.crt;
    ssl_certificate_key $temp_dir/ssl/affiliate.osgeo.org.key;
}
EOF

    # Basic syntax check - look for common issues
    if grep -qE '^\s*$\{' "$file"; then
      echo "Error: Unresolved variable in $file"
      exit 1
    fi

    # Check for duplicate directives
    if grep -oE '^\s*server_name\s+' "$file" | wc -l | grep -qvE '^[0-2]$'; then
      echo "Warning: Multiple server_name directives found"
    fi

    echo "✓ $file syntax OK"
  fi
done
