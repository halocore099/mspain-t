#!/usr/bin/env bash
# Production bundle: minified, _G.DEBUG = false, debug branches stripped.
# Output: Distribution/Script.luau
set -euo pipefail
cd "$(dirname "$0")/.."

ROKIT_BIN="${ROKIT_BIN:-$HOME/.rokit/bin}"
export PATH="$ROKIT_BIN:$PATH"

"$ROKIT_BIN/lune" run Build bundle \
    input='default.project.json' \
    minify=true \
    output='Distribution/Script.luau' \
    env-name="Script" \
    darklua-config-path="Build/DarkLua.json" \
    temp-dir-base="Distribution" \
    verbose=true
