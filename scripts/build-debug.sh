#!/usr/bin/env bash
# Debug bundle: readable, _G.DEBUG = true, source line numbers preserved.
# Also copies the bundle into the Macsploit Workspace for fast iteration.
# Output: Distribution/Script.luau, ~/Documents/Macsploit Workspace/mspaint-t.luau
set -euo pipefail
cd "$(dirname "$0")/.."

ROKIT_BIN="${ROKIT_BIN:-$HOME/.rokit/bin}"
export PATH="$ROKIT_BIN:$PATH"

"$ROKIT_BIN/lune" run Build bundle \
    input='default.project.json' \
    minify=false \
    output='Distribution/Script.luau' \
    env-name="Script" \
    darklua-config-path="Build/DarkLua.debug.json" \
    temp-dir-base="Distribution" \
    verbose=true

MACSPLOIT_WS="$HOME/Documents/Macsploit Workspace"
if [[ -d "$MACSPLOIT_WS" ]]; then
    cp Distribution/Script.luau "$MACSPLOIT_WS/mspaint-t.luau"
    echo "Copied to $MACSPLOIT_WS/mspaint-t.luau"
fi
