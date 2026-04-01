#!/bin/bash
set -euo pipefail
INPUT_VERSION="${1:-}"
VERSION="${INPUT_VERSION:-1.6.3}"
[ -z "$VERSION" ] && { echo "Failed to resolve version" >&2; exit 1; }
echo "VERSION=$VERSION"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
