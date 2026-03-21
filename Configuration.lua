--- === hs_grid_hammer.Configuration ===
---
--- Configuration parameters for a hs_grid_hammer grid.
---
--- Includes settings for:
--- * Show delay (showDelay)
--- * Theme overrides (theme)

local M = {}


--- hs_grid_hammer.Configuration.new() -> table
--- Constructor
--- Create a new configuration object for a grid.
---
--- Returns:
--- * A Configuration object with default values
M.new = function()
  local config = {}

  --- hs_grid_hammer.Configuration.showDelay
  --- Field
  --- Delay in seconds before view is shown (0 = instant)
  config.showDelay = 0

  --- hs_grid_hammer.Configuration.theme
  --- Field
  --- Theme overrides table (merged with Theme.default)
  --- See Theme.lua for available options
  config.theme = nil

  return config
end


return M
