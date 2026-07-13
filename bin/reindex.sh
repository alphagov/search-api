#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$CACHE_DIR"
}

trap cleanup EXIT

export npm_config_cache="$CACHE_DIR"

npx --yes elasticdump@6.124.1 "$@"
