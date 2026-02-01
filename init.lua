--- === hs_grid_hammer ===
---
--- High-performance modal menu system using native canvas rendering.
--- A faster alternative to GridCraft, replacing WebView with hs.canvas
--- and EventTap validation with O(1) key lookup.
---
--- Download: [https://github.com/your-repo/hs_grid_hammer](https://github.com/your-repo/hs_grid_hammer)

local M = {}

M.name = "hs_grid_hammer"
M.version = "0.1.0"
M.author = "Your Name"
M.license = "MIT"
M.homepage = "https://github.com/your-repo/hs_grid_hammer"

--- hs_grid_hammer.Grid
--- Variable
--- Grid modal manager - create grids with Grid.new()
M.Grid = dofile(hs.spoons.resourcePath("Grid.lua"))

--- hs_grid_hammer.Action
--- Variable
--- Action factory - create actions with Action.new()
M.Action = dofile(hs.spoons.resourcePath("Action.lua"))

--- hs_grid_hammer.Configuration
--- Variable
--- Configuration factory - create configs with Configuration.new()
M.Configuration = dofile(hs.spoons.resourcePath("Configuration.lua"))

--- hs_grid_hammer.Theme
--- Variable
--- Theme definitions - access Theme.default or create with Theme.new()
M.Theme = dofile(hs.spoons.resourcePath("Theme.lua"))

--- hs_grid_hammer.Icon
--- Variable
--- Icon utilities - create icons from files, bundle IDs, text, or symbols
M.Icon = dofile(hs.spoons.resourcePath("Icon.lua"))

--- hs_grid_hammer.IconLoader
--- Variable
--- Async icon loading with caching
M.IconLoader = dofile(hs.spoons.resourcePath("IconLoader.lua"))

--- hs_grid_hammer.Chooser
--- Variable
--- Chooser interface utilities
M.Chooser = dofile(hs.spoons.resourcePath("Chooser.lua"))

--- hs_grid_hammer.Util
--- Variable
--- Utility functions
M.Util = dofile(hs.spoons.resourcePath("Util.lua"))


--- hs_grid_hammer:init()
--- Method
--- Initialize the spoon
---
--- Returns:
---  * The spoon object
function M:init()
  return self
end


--- hs_grid_hammer:start()
--- Method
--- Start the spoon (currently a no-op, grids are started individually)
---
--- Returns:
---  * The spoon object
function M:start()
  return self
end


--- hs_grid_hammer:stop()
--- Method
--- Stop the spoon (currently a no-op)
---
--- Returns:
---  * The spoon object
function M:stop()
  return self
end


return M
