# mspain`t

A working fork of [mspaint](https://github.com/notpoiu/mspaint) — the open-source Roblox script hub originally by upio, deividcomsono, mstudio45, and bacalhauz. The original project went unmaintained and its public releases / dependency repos went offline; this fork brings the v2 codebase back to a buildable, testable state against current games.

Maintained by [halocore099](https://github.com/halocore099). Not affiliated with the original mspaint or its authors.

## Supported games

Per [`Src/Mappings.luau`](Src/Mappings.luau):

- **DOORS** (Lobby + in-game)
- **3008** (regular + 100-player)
- **R&D**
- **Build A Boat For Treasure**
- Universal fallback for anything else

As of the latest sweep on DOORS in-game, 66 of 72 testable features pass the self-test without errors. The 6 skipped toggles are event-driven (teleport, jumpscare, etc.) — they exercise correctly during real play, not via a brief toggle flip.

## Building

You need [rokit](https://github.com/rojo-rbx/rokit) installed. The vanity domain `rojo.to` referenced in some older docs no longer resolves — install rokit directly from [its GitHub releases](https://github.com/rojo-rbx/rokit/releases/latest) and run `./rokit self-install`.

Then in the repo root:

```sh
rokit install              # one-time — installs rojo + darklua + lune at pinned versions
scripts/build.sh           # production bundle -> Distribution/Script.luau
scripts/build-debug.sh     # debug bundle, also copies into ~/Documents/Macsploit Workspace/
```

The debug build preserves source line numbers and turns on the `_G.DEBUG` global, which enables the in-script **Self-Test** tab for triaging feature regressions.

## Running

In Macsploit (or any executor exposing `readfile` + `loadstring`):

```lua
loadstring(readfile("mspain-t.luau"))()
```

If a previous load was interrupted and left the loader guard set, reset it before re-injecting:

```lua
getgenv().mspain_t_loading = false
getgenv().mspain_t_loaded = false
```

## Tooling

- **`scripts/dump-doors.luau`** — A standalone Macsploit-runnable Lua snippet that dumps current DOORS structural state (`ReplicatedStorage`, `PlayerGui.MainUI`, `Workspace.CurrentRooms`, …) into `mspain-t-dumps/` in your executor workspace. Useful when DOORS gets patched and a feature breaks against the new instance layout — diff the dump against what the source code expects.
- **Self-Test tab** *(debug builds only)* — Iterates every Linoria toggle, briefly enables each, captures any errors / warnings on `LogService.MessageOut`, and writes a labeled report to `mspain-t-selftest-<timestamp>.txt`. Catches regressions across the ~70 features in one click.

## Credits

Original mspaint authors: **upio**, **deividcomsono**, **mstudio45**, **bacalhauz**. UI library: **mstudio45/LinoriaLib**. ESP library (vendored): **mstudio45's MS-ESP**.
