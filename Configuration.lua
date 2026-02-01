--- === hs_grid_hammer.Configuration ===
---
--- Configuration parameters for a hs_grid_hammer grid.
---
--- Includes settings for:
--- * Animation timing (animationMs)
--- * Animation delay before hide (animationDelay)
--- * Show delay (showDelay)
--- * Invalid key alert behavior (showInvalidKeyAlert)
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

  -- Valid keys for replace()
  local validKeys = {
    "animationMs",
    "animationDelay",
    "showDelay",
    "showInvalidKeyAlert",
    "theme",
  }

  --- hs_grid_hammer.Configuration.animationMs
  --- Field
  --- Time for fade animation in ms, default is 150ms.
  config.animationMs = 150

  --- hs_grid_hammer.Configuration:animationSeconds() -> number
  --- Method
  --- Time for animation in seconds (derived from animationMs)
  function config:animationSeconds()
    return self.animationMs / 1000
  end

  --- hs_grid_hammer.Configuration.animationDelay
  --- Field
  --- Delay in seconds before hiding canvas after action (allows visual feedback)
  config.animationDelay = 0.05

  --- hs_grid_hammer.Configuration.showDelay
  --- Field
  --- Delay in seconds before view is shown (0 = instant)
  config.showDelay = 0

  --- hs_grid_hammer.Configuration.showInvalidKeyAlert
  --- Field
  --- Show alerts when user presses keys not bound to actions, default is false
  --- Note: hs_grid_hammer uses direct key bindings, so invalid keys are simply ignored
  config.showInvalidKeyAlert = false

  --- hs_grid_hammer.Configuration.theme
  --- Field
  --- Theme overrides table (merged with Theme.default)
  --- See Theme.lua for available options
  config.theme = nil

  --- hs_grid_hammer.Configuration:toTable() -> table
  --- Method
  --- Return the configuration as a plain table
  function config:toTable()
    return {
      animationMs = self.animationMs,
      animationSeconds = self:animationSeconds(),
      animationDelay = self.animationDelay,
      showDelay = self.showDelay,
      showInvalidKeyAlert = self.showInvalidKeyAlert,
      theme = self.theme,
    }
  end

  --- hs_grid_hammer.Configuration:replace() -> Configuration
  --- Method
  --- Replace ALL values of the configuration with values from the update object
  ---
  --- Parameters:
  ---  * updateConfig - A table containing new configuration values.
  ---
  --- Returns:
  --- * The configuration object itself, for chaining.
  ---
  --- Notes:
  --- * If a key is missing in the updateConfig, the value in the existing configuration will be set to nil.
  function config:replace(updateConfig)
    for _, key in ipairs(validKeys) do
      config[key] = updateConfig[key]
    end
    return self
  end

  --- hs_grid_hammer.Configuration:merge() -> Configuration
  --- Method
  --- Merge values from the update object (only overwrites provided keys)
  ---
  --- Parameters:
  ---  * updateConfig - A table containing new configuration values.
  ---
  --- Returns:
  --- * The configuration object itself, for chaining.
  function config:merge(updateConfig)
    if not updateConfig then return self end
    for _, key in ipairs(validKeys) do
      if updateConfig[key] ~= nil then
        config[key] = updateConfig[key]
      end
    end
    return self
  end

  return config
end


return M
