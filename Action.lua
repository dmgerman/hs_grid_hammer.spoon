--- === hs_grid_hammer.Action ===
---
--- Action definitions for grid cells.
--- Compatible with GridCraft API but uses hs.image for icons instead of HTML.

local Util = dofile(hs.spoons.resourcePath("Util.lua"))

local M = {}

--- hs_grid_hammer.Action.new(table) -> table
--- Constructor
--- Create a new action for a grid
---
--- Parameters:
---  * arg - A table containing the parameters for the action.
---    * Basic parameters:
---      * mods: (table) Modifier keys like `{"cmd", "ctrl"}` to trigger the action along with the key. Use `{}` for no modifiers
---      * key: (string) A key to trigger the action along with the modifiers, like "x" or "F11".
---      * handler: (function) Code to run when the key is pressed
---      * description: (string) A description for the action
---      * icon: (hs.image) An hs.image object to display as the icon (optional)
---      * classes: (table) A list of classes for styling hints (optional)
---    * Convenience parameters:
---      * empty: (boolean) If true, the handler is set to a no-op function.
---      * application: (string) The name of an application to switch to.
---      * file: (string) Path to a file or folder to open.
---      * submenu: (table) A Grid object for a submenu.
---
--- Returns:
---  * An action table ready to use in a grid's actionTable
M.new = function(arg)
  local action = {}

  action.mods = arg.mods or {}
  action.key = arg.key
  action.handler = arg.handler or function() end
  action.description = arg.description or ""
  action.icon = arg.icon  -- hs.image object, or nil for placeholder
  action.classes = arg.classes or {}

  if not action.key then
    -- No key - this is an invisible spacer
    table.insert(action.classes, "no-key")
    action.handler = function() end
    action.description = arg.description or ""
    return action
  elseif arg.empty then
    -- Empty slot placeholder
    action.empty = true
    action.handler = function() end
    action.description = arg.description or "No action"
    table.insert(action.classes, "empty")
    return action
  elseif arg.application then
    -- Application launcher
    local appPath = Util.findApplicationPath(arg.application)
    local appDesc = arg.description or arg.application
    table.insert(action.classes, "application")

    if not appPath then
      print(string.format("[hs_grid_hammer] No application found for %s", arg.application))
      action.description = string.format("(%s)", appDesc)
      action.notFound = true
      table.insert(action.classes, "not-found")
    else
      action.application = arg.application
      action.applicationPath = appPath
      action.handler = function()
        hs.application.launchOrFocus(arg.application)
      end
      action.description = appDesc

      -- Load icon if not provided (will be loaded async by IconLoader)
      if not arg.icon then
        -- Store path for async loading; actual icon loaded by Grid
        action.iconPath = appPath
      end
    end
  elseif arg.file then
    -- File/folder opener
    table.insert(action.classes, "file")

    if hs.fs.attributes(arg.file) == nil then
      print(string.format("[hs_grid_hammer] No file found for %s", arg.file))
      action.description = string.format("(%s)", Util.getBasename(arg.file))
      action.notFound = true
      table.insert(action.classes, "not-found")
    else
      action.file = arg.file
      action.handler = function()
        hs.execute(string.format("open '%s'", action.file))
      end
      if not arg.description then
        action.description = Util.getBasename(action.file)
      end

      -- Store path for async icon loading
      if not arg.icon then
        action.iconPath = arg.file
      end
    end
  elseif arg.submenu then
    -- Submenu container
    table.insert(action.classes, "submenu")
    -- Accept either a Grid object or an action table
    if arg.submenu.modal then
      -- Already a Grid object
      action.submenu = arg.submenu
    else
      -- Action table - store for Grid.lua to create Grid object
      action.submenuTable = arg.submenu
    end
    -- Handler is set by Grid.lua when binding keys
  elseif arg.handler then
    -- Custom handler
    table.insert(action.classes, "custom-handler")
  end

  return action
end


--- hs_grid_hammer.Action.applicationAction(appName, key, mods, description) -> table
--- Function
--- Convenience function to create an application launcher action
---
--- Parameters:
---  * appName - Application name
---  * key - Trigger key
---  * mods - Optional modifier keys
---  * description - Optional description (defaults to appName)
---
--- Returns:
---  * An action table
M.applicationAction = function(appName, key, mods, description)
  return M.new({
    application = appName,
    key = key,
    mods = mods,
    description = description,
  })
end


--- hs_grid_hammer.Action.fileAction(filePath, key, mods, description) -> table
--- Function
--- Convenience function to create a file opener action
---
--- Parameters:
---  * filePath - Path to file or folder
---  * key - Trigger key
---  * mods - Optional modifier keys
---  * description - Optional description (defaults to basename)
---
--- Returns:
---  * An action table
M.fileAction = function(filePath, key, mods, description)
  return M.new({
    file = filePath,
    key = key,
    mods = mods,
    description = description,
  })
end


--- hs_grid_hammer.Action.emptyAction(key) -> table
--- Function
--- Convenience function to create an empty placeholder action
---
--- Parameters:
---  * key - Trigger key (required but does nothing)
---
--- Returns:
---  * An action table
M.emptyAction = function(key)
  return M.new({
    key = key,
    empty = true,
  })
end


--- hs_grid_hammer.Action.spacer() -> table
--- Function
--- Create an invisible spacer (no key, not rendered)
---
--- Returns:
---  * An action table
M.spacer = function()
  return M.new({})
end


return M
