--- === hs_grid_hammer.Action ===
---
--- Action definitions for grid cells.
--- Compatible with GridCraft API but uses hs.image for icons instead of HTML.

local Util = dofile(hs.spoons.resourcePath("Util.lua"))

local M = {}

--------------------------------------------------------------------------------
-- Private action type handlers
--------------------------------------------------------------------------------

--- Handle no-key action (invisible spacer)
--- @param action table Action being built
--- @param arg table Original arguments
local function handleNoKey(action, arg)
  table.insert(action.classes, "no-key")
  action.handler = function() end
  action.description = arg.description or ""
end

--- Handle empty slot action
--- @param action table Action being built
--- @param arg table Original arguments
local function handleEmpty(action, arg)
  action.empty = true
  action.handler = function() end
  action.description = arg.description  -- nil = not rendered
  table.insert(action.classes, "empty")
end

--- Handle application launcher action
--- @param action table Action being built
--- @param arg table Original arguments
local function handleApplication(action, arg)
  local appPath = Util.findApplicationPath(arg.application)
  local appDesc = arg.description or arg.application
  table.insert(action.classes, "application")

  if not appPath then
    print(string.format("[hs_grid_hammer] No application found for %s", arg.application))
    action.description = string.format("(%s)", appDesc)
    action.notFound = true
    table.insert(action.classes, "not-found")
    return
  end

  action.application = arg.application
  action.applicationPath = appPath
  action.description = appDesc
  action.handler = function()
    hs.application.launchOrFocus(arg.application)
  end

  if not arg.icon then
    action.iconPath = appPath
  end
end

--- Handle file/folder opener action
--- @param action table Action being built
--- @param arg table Original arguments
local function handleFile(action, arg)
  table.insert(action.classes, "file")

  if hs.fs.attributes(arg.file) == nil then
    print(string.format("[hs_grid_hammer] No file found for %s", arg.file))
    action.description = string.format("(%s)", Util.getBasename(arg.file))
    action.notFound = true
    table.insert(action.classes, "not-found")
    return
  end

  action.file = arg.file
  action.description = arg.description or Util.getBasename(arg.file)
  action.handler = function()
    hs.execute(string.format("open '%s'", action.file))
  end

  if not arg.icon then
    action.iconPath = arg.file
  end
end

--- Handle submenu action
--- @param action table Action being built
--- @param arg table Original arguments
local function handleSubmenu(action, arg)
  table.insert(action.classes, "submenu")

  if arg.submenu.modal then
    -- Already a Grid object
    action.submenu = arg.submenu
  else
    -- Action table - store for Grid.lua to convert
    action.submenuTable = arg.submenu
  end
end

--- Handle custom handler action
--- @param action table Action being built
--- @param arg table Original arguments
local function handleCustom(action, arg)
  table.insert(action.classes, "custom-handler")
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- hs_grid_hammer.Action.new(table) -> table
--- Constructor
--- Create a new action for a grid
---
--- Parameters:
---  * arg - A table containing the parameters for the action.
---    * Basic parameters:
---      * mods: (table) Modifier keys like `{"cmd", "ctrl"}`
---      * key: (string) A key to trigger the action
---      * handler: (function) Code to run when the key is pressed
---      * description: (string) A description for the action
---      * icon: (hs.image) An hs.image object to display
---      * classes: (table) A list of classes for styling hints
---    * Convenience parameters:
---      * empty: (boolean) If true, creates a placeholder slot
---      * application: (string) Application name to launch
---      * file: (string) Path to a file or folder to open
---      * submenu: (table) A Grid object or action table for submenu
---
--- Returns:
---  * An action table ready to use in a grid's actionTable
function M.new(arg)
  local action = {
    mods = arg.mods or {},
    key = arg.key,
    handler = arg.handler or function() end,
    description = arg.description or "",
    icon = arg.icon,
    classes = arg.classes or {},
  }

  -- Dispatch to appropriate handler based on action type
  if arg.empty then
    handleEmpty(action, arg)
  elseif not action.key then
    handleNoKey(action, arg)
  elseif arg.application then
    handleApplication(action, arg)
  elseif arg.file then
    handleFile(action, arg)
  elseif arg.submenu then
    handleSubmenu(action, arg)
  elseif arg.handler then
    handleCustom(action, arg)
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
function M.applicationAction(appName, key, mods, description)
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
function M.fileAction(filePath, key, mods, description)
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
function M.emptyAction(key)
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
function M.spacer()
  return M.new({})
end

return M
