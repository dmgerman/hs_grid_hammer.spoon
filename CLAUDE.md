# hs_grid_hammer.spoon

Modal menu system for Hammerspoon using native canvas rendering. Originally a reimplementation of GridCraft by Micah R Ledbetter.

## Architecture

```
init.lua          → Public API (exports Grid, Action, Configuration, Theme, Icon)
Grid.lua          → Modal manager (hs.hotkey.modal)
CanvasRenderer.lua → Native hs.canvas rendering (canvas reused across show/hide)
Action.lua        → Action factory (app, file, submenu, custom handler). Eager icon load.
Icon.lua          → Icon generation. Canvas-generated icons (symbol, fromText) memoized by input.
Theme.lua         → Visual constants (single source of truth)
Color.lua         → Color utilities — internal only
Chooser.lua       → Action-table flattener for hs.chooser — internal only
Configuration.lua → Optional config factory (showDelay, theme overrides)
Util.lua          → App-path lookup, basename — internal only
```

### Data flow

1. `Grid.new()` creates CanvasRenderer + `hs.hotkey.modal`. `Action.new` resolves icons synchronously and stores them in `action.icon`.
2. Modal entered → CanvasRenderer builds canvas once (first show) and reuses it on every subsequent show.
3. Key press → `hs.hotkey.modal` dispatch → action handler → `grid:stop()`.

### Icon loading

Icons are resolved **synchronously at setup time**, never at show time. Every action ends up with `action.icon` populated (or nil if the resource is missing). `Icon.symbol(name)` and `Icon.fromText(label)` memoize their results per session, so duplicate calls return the same image. Menus are treated as fully static — if you ever need dynamic icons, add a flag and re-evaluate in `modal:entered`.

### Module loading

Each file loads its dependencies directly via `dofile(hs.spoons.resourcePath("X.lua"))`. No memoization layer — Lua modules are small and the redundant loads happen only at startup.

### Conventions

- **Key IDs**: `"rowIdx×colIdx"` format (e.g., `"1x1"`, `"2x3"`) — used across CanvasRenderer and Grid.
- **Canvas element IDs**: `"keyId_bg"`, `"keyId_icon"`, `"keyId_hotkey"`, `"keyId_desc"`.
- **Color tables**: `{red=, green=, blue=, alpha=}` or `{white=, alpha=}` (auto-converted).
- **Submenu lazy init**: `submenuTable` (raw 2D array) is converted to a Grid on first bind.

## Testing

```lua
-- Run automated tests in Hammerspoon console:
dofile(hs.spoons.resourcePath("tests/run_all_tests.lua"))

-- Visual tests:
dofile(hs.spoons.resourcePath("tests/test_phase1.lua"))
dofile(hs.spoons.resourcePath("tests/test_phase4.lua"))
```

- Phase 1: Theme, CanvasRenderer
- Phase 2: Grid modal lifecycle and key binding
- Phase 4: Integration (spoon loading, module exports, icon memoization)

## Development notes

- `Grid.cleanup()` must be called before Hammerspoon reload to prevent orphaned instances.
- Hammerspoon reload hangs IPC — run `hs -c "hs.reload()"` in background (see parent CLAUDE.md).
- Empty cells: `action.empty = true`, rendered at 0.5 alpha with dashed border.
- Actions with no `key` field are skipped during rendering (invisible layout slots).
- Canvas is reused across show/hide cycles; `destroy()` frees it for reload/reconfiguration.

## Design principles (learned the hard way)

1. **Don't port concepts that don't apply.** When reimplementing, question every field and method — does it serve a purpose in the *new* architecture, or is it a vestige of the old one?
2. **Check what already exists before writing new code.** Search the codebase for existing utilities before adding helpers. Duplicates rot.
3. **Reuse expensive objects.** If something can be created once and shown/hidden, don't destroy and rebuild it every time.
4. **Don't leave diagnostic code in production paths.** Timing prints and `collectgarbage()` calls on the hot path are overhead, not observability.
5. **If a framework already does it, don't also do it.** `hs.hotkey.modal` handles key dispatch — building a parallel lookup table that never gets consulted is pure waste.
6. **Cache only what's expensive.** macOS-loaded icons are cheap once stored in `action.icon`; an LRU on top adds GC pressure for no win. Canvas-generated icons (symbol, fromText) *are* expensive — memoize those by input.
