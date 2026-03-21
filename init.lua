--- === hs_grid_hammer ===
---
--- High-performance modal menu system using native canvas rendering.
--- A faster alternative to GridCraft, replacing WebView with hs.canvas
--- and EventTap validation with O(1) key lookup.
---
--- ## Quick Start
---
--- ```lua
--- local gh = hs.loadSpoon("hs_grid_hammer")
---
--- local grid = gh.Grid.new({"cmd", "ctrl"}, "t", {
---   {
---     gh.Action.new({key = "e", application = "Terminal", description = "Terminal"}),
---     gh.Action.new({key = "s", application = "Safari", description = "Safari"}),
---   },
---   {
---     gh.Action.new({key = "f", file = "~/Documents", description = "Documents"}),
---     gh.Action.new({key = "x", handler = function() hs.alert.show("Hello!") end, description = "Custom"}),
---   },
--- }, "My Grid")
--- ```
---
--- ## Configuration
---
--- Pass a config table as the 5th argument to Grid.new():
---
--- ```lua
--- local config = gh.Configuration.new()
--- config.showDelay = 0.2  -- Delay before showing menu (seconds)
--- gh.Grid.new(mods, key, actions, title, config)
--- ```

--- Module cache to avoid re-executing dofile() multiple times
_hs_grid_hammer_modules = _hs_grid_hammer_modules or {}
local function _require(name)
  if not _hs_grid_hammer_modules[name] then
    _hs_grid_hammer_modules[name] = dofile(hs.spoons.resourcePath(name))
  end
  return _hs_grid_hammer_modules[name]
end

local M = {}

--- Metadata
--- @field name string Spoon name
--- @field version string Spoon version
--- @field author string Spoon author
--- @field license string Spoon license
--- @field homepage string Spoon homepage URL
M.name = "hs_grid_hammer"
M.version = "0.1.0"
M.author = "Daniel German <dmg@turingmachine.org> (based on GridCraft by Micah R Ledbetter)"
M.license = "MIT"
M.homepage = "https://github.com/dmg/hs_grid_hammer"

--------------------------------------------------------------------------------
-- Public Modules
--------------------------------------------------------------------------------

--- hs_grid_hammer.Grid
--- Variable
--- Grid modal manager for creating keyboard-driven modal menus.
---
--- Methods:
---  * `Grid.new(mods, key, actionTable, title, config, chooserKey)` - Create a new grid
---  * `grid:start()` - Show the grid and enter modal mode
---  * `grid:stop()` - Hide the grid and exit modal mode
---  * `grid:setConfiguration(config)` - Update configuration
---  * `grid:showChooser()` - Show searchable chooser interface
M.Grid = _require("Grid.lua")

--- hs_grid_hammer.Action
--- Variable
--- Action factory for creating grid cell actions.
---
--- Methods:
---  * `Action.new(opts)` - Create an action with options:
---    - `key` (string): Hotkey to trigger this action
---    - `mods` (table): Optional modifier keys
---    - `description` (string): Label shown in cell
---    - `application` (string): App name to launch
---    - `file` (string): File/folder path to open
---    - `handler` (function): Custom function to execute
---    - `icon` (hs.image): Custom icon image
---    - `submenuTable` (table): 2D array for nested submenu
---    - `empty` (boolean): Mark as placeholder cell
M.Action = _require("Action.lua")

--- hs_grid_hammer.Configuration
--- Variable
--- Configuration factory for grid options.
---
--- Methods:
---  * `Configuration.new(opts)` - Create config with options:
---    - `showDelay` (number): Seconds to wait before showing grid (default 0)
---    - `theme` (table): Theme overrides (see Theme module)
M.Configuration = _require("Configuration.lua")

--- hs_grid_hammer.Theme
--- Variable
--- Theme definitions for visual customization.
---
--- Properties:
---  * `Theme.default` - Default theme table with all values
---
--- Methods:
---  * `Theme.new(overrides)` - Create theme with custom overrides
---
--- Theme options include: backgroundColor, cellBackground, cellWidth,
--- cellHeight, iconSize, fadeTime, and more.
M.Theme = _require("Theme.lua")

--- hs_grid_hammer.Icon
--- Variable
--- Icon utilities for creating hs.image icons.
---
--- Methods:
---  * `Icon.fromFile(path)` - Load image from PNG/JPG file
---  * `Icon.fromPath(path)` - Get icon for app bundle or file
---  * `Icon.fromBundleID(bundleID)` - Get icon by bundle ID
---  * `Icon.fromText(label, opts)` - Create text-based icon
---  * `Icon.placeholder(text, symbol, bgColor)` - Create placeholder icon
---  * `Icon.symbol(name)` - Get predefined symbol icon (Phosphor replacement)
---  * `Icon.empty()` - Create transparent icon
---
--- Predefined symbols: app-window, monitor, chat, translate, speaker-high,
--- globe, folder, file, terminal, mail, calendar, search, settings, music,
--- video, microphone, keyboard
M.Icon = _require("Icon.lua")

--- hs_grid_hammer.IconLoader
--- Variable
--- Async icon loading with LRU caching.
---
--- Methods:
---  * `IconLoader.loadAsync(path, callback)` - Load icon asynchronously
---  * `IconLoader.loadAppIconAsync(appName, callback)` - Load app icon by name
---  * `IconLoader.placeholder(text, size)` - Generate placeholder icon
---  * `IconLoader.get(key)` - Get cached icon
---  * `IconLoader.put(key, image)` - Store icon in cache
---  * `IconLoader.clear()` - Clear the cache
---  * `IconLoader.getStats()` - Get cache statistics
---  * `IconLoader.printStats()` - Print cache statistics
M.IconLoader = _require("IconLoader.lua")

--- hs_grid_hammer.Chooser
--- Variable
--- Chooser interface utilities for searchable action selection.
---
--- Methods:
---  * `Chooser.fromActionTable(actionTable)` - Convert actions to chooser format
---    Returns: choices (table), actions (table keyed by uuid)
M.Chooser = _require("Chooser.lua")

--- hs_grid_hammer.Color
--- Variable
--- Color utilities for generating consistent colors.
---
--- Methods:
---  * `Color.hslToRgb(h, s, l)` - Convert HSL to RGB values
---  * `Color.hashToHue(str)` - Generate deterministic hue from string
---  * `Color.fromString(str, saturation, lightness)` - Generate color from string
---  * `Color.fromHex(hex)` - Parse hex color string
---  * `Color.withAlpha(color, alpha)` - Apply alpha to color
M.Color = _require("Color.lua")

--- hs_grid_hammer.Util
--- Variable
--- Utility functions.
---
--- Methods:
---  * Various helper functions ported from GridCraft
M.Util = _require("Util.lua")

--------------------------------------------------------------------------------
-- Spoon Lifecycle
--------------------------------------------------------------------------------

--- hs_grid_hammer:init()
--- Method
--- Initialize the spoon.
---
--- Returns:
---  * The spoon object
function M:init()
  return self
end

--- hs_grid_hammer:start()
--- Method
--- Start the spoon. Grids are started individually via grid:start().
---
--- Returns:
---  * The spoon object
function M:start()
  return self
end

--- hs_grid_hammer:stop()
--- Method
--- Stop the spoon.
---
--- Returns:
---  * The spoon object
function M:stop()
  return self
end

return M
