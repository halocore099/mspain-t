#!/usr/bin/env bash
# Debug bundle with Rayfield UI mode: _G.DEBUG = true, _G.UI = "Rayfield".
# Linoria mode is the default (use build.sh or build-debug.sh for that).
# Output: Distribution/Script.luau, ~/Documents/Macsploit Workspace/mspain-t.luau
set -euo pipefail
cd "$(dirname "$0")/.."

ROKIT_BIN="${ROKIT_BIN:-$HOME/.rokit/bin}"
export PATH="$ROKIT_BIN:$PATH"

"$ROKIT_BIN/lune" run Build bundle \
    input='default.project.json' \
    minify=true \
    output='Distribution/Script.luau' \
    env-name="Script" \
    darklua-config-path="Build/DarkLua.rayfield.json" \
    temp-dir-base="Distribution" \
    verbose=true

MACSPLOIT_WS="$HOME/Documents/Macsploit Workspace"
if [[ -d "$MACSPLOIT_WS" ]]; then
    cp Distribution/Script.luau "$MACSPLOIT_WS/mspain-t.luau"
    echo "Copied to $MACSPLOIT_WS/mspain-t.luau (Rayfield UI mode)"
fi
