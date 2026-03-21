# hs_grid_hammer.spoon

High-performance modal menu system for Hammerspoon using native canvas rendering and O(1) key lookup. Reimplementation of GridCraft by Micah R Ledbetter.

## Architecture

```
init.lua          → Public API, exports all modules (with _require cache)
Grid.lua          → Core modal manager (hs.hotkey.modal)
CanvasRenderer.lua → Native hs.canvas rendering engine (canvas reuse, in-place icon updates)
Action.lua        → Action factory (app launch, file open, submenu, custom handler)
KeyMap.lua        → O(1) key lookup hash table (available for external use, not used by Grid)
Theme.lua         → All visual constants (single source of truth)
Icon.lua          → All icon generation (single source of truth)
IconLoader.lua    → Async icon loading + LRU cache (max 100, evicts 20)
Color.lua         → Color utilities (HSL, hex parsing, string→color)
Chooser.lua       → Searchable action selection (flattens action tables)
Configuration.lua → Grid config factory (showDelay, theme overrides)
Util.lua          → App finding, path helpers
```

### Data Flow

1. `Grid.new()` creates CanvasRenderer + hs.hotkey.modal
2. Modal entered → CanvasRenderer builds canvas once (first show), reuses on subsequent shows
3. Placeholder icons render immediately; real icons load async via IconLoader
4. Key press → hs.hotkey.modal dispatch → action handler → grid:stop()

### Module Loading

All modules use `_require()` with a global cache (`_hs_grid_hammer_modules`). Each module is loaded exactly once per Hammerspoon session. Cache is naturally cleared on hs.reload().

### Key Conventions

- **Key IDs**: `"rowIdx×colIdx"` format (e.g., `"1x1"`, `"2x3"`) — used across KeyMap, CanvasRenderer, and Grid
- **Canvas element IDs**: `"keyId_bg"`, `"keyId_icon"`, `"keyId_hotkey"`, `"keyId_desc"`
- **Modifier order**: cmd → ctrl → alt → shift → fn (normalized in KeyMap)
- **Color tables**: `{red=, green=, blue=, alpha=}` or `{white=, alpha=}` (auto-converted)
- **Submenu lazy init**: `submenuTable` (raw 2D array) converted to Grid on first bind

## Testing

```lua
-- Run all tests in Hammerspoon console:
dofile(hs.spoons.resourcePath("tests/run_all_tests.lua"))

-- Run specific phase:
dofile(hs.spoons.resourcePath("tests/test_phase1.lua"))
```

- Phase 1: Theme, KeyMap, CanvasRenderer, Color
- Phase 2: Grid modal lifecycle and key binding
- Phase 3: IconLoader cache behavior
- Phase 4: Integration (spoon loading, module exports)

## Development Notes

- `Grid.cleanup()` must be called before Hammerspoon reload to prevent orphaned instances
- Hammerspoon reload hangs IPC — run `hs -c "hs.reload()"` in background (see parent CLAUDE.md)
- Empty cells: `action.empty = true`, rendered at 0.5 alpha with dashed border
- Spacers: `Action.spacer()` — no key, not rendered, invisible layout placeholder
- Canvas is reused across show/hide cycles; `destroy()` frees it for reload/reconfiguration
- `updateIcon()` replaces elements in-place (no remove/insert) using stored indexes

## Design Principles (learned the hard way)

1. **Don't port concepts that don't apply.** When reimplementing, question every field and method — does it serve a purpose in the *new* architecture, or is it a vestige of the old one?
2. **Check what already exists before writing new code.** Search the codebase for existing utilities before adding helpers. Duplicates rot.
3. **Reuse expensive objects.** If something can be created once and shown/hidden, don't destroy and rebuild it every time. Prefer `show()/hide()` over `delete()/new()`.
4. **Don't leave diagnostic code in production paths.** Timing prints and `collectgarbage()` calls on the hot path are overhead, not observability. Add them to debug, remove them when done.
5. **If a framework already does it, don't also do it.** `hs.hotkey.modal` handles key dispatch — building a parallel KeyMap that's never consulted is pure waste.
