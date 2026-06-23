--- === hs_grid_hammer.Action ===
---
--- Action definitions for grid cells.

local Util = dofile(hs.spoons.resourcePath("Util.lua"))
local Icon = dofile(hs.spoons.resourcePath("Icon.lua"))

local M = {}

local function handleEmpty(action, arg)
  action.empty = true
  action.handler = function() end
  action.description = arg.description  -- nil = not rendered
end

local function handleApplication(action, arg)
  local appPath = Util.findApplicationPath(arg.application)
  local appDesc = arg.description or arg.application

  if not appPath then
    print(string.format("[hs_grid_hammer] No application found for %s", arg.application))
    action.description = string.format("(%s)", appDesc)
    action.notFound = true
    return
  end

  action.applicationPath = appPath
  action.description = appDesc
  action.icon = action.icon or Icon.fromPath(appPath)
  action.handler = function()
    hs.application.launchOrFocus(arg.application)
  end
end

local function handleFile(action, arg)
  if hs.fs.attributes(arg.file) == nil then
    print(string.format("[hs_grid_hammer] No file found for %s", arg.file))
    action.description = string.format("(%s)", Util.getBasename(arg.file))
    action.notFound = true
    return
  end

  action.file = arg.file
  action.description = arg.description or Util.getBasename(arg.file)
  action.icon = action.icon or Icon.fromPath(arg.file)
  action.handler = function()
    hs.execute(string.format("open '%s'", action.file))
  end
end

local function handleSubmenu(action, arg)
  if arg.submenu.modal then
    action.submenu = arg.submenu
  else
    action.submenuTable = arg.submenu
  end
end

--- hs_grid_hammer.Action.new(arg) -> table
--- Constructor: build an action for a grid cell.
---
--- arg fields:
---  * key (string), mods (table), description (string), icon (hs.image)
---  * handler (function) — custom code to run
---  * empty (bool) — placeholder slot
---  * application (string) — app name to launch
---  * file (string) — path to open
---  * submenu (table or Grid) — nested menu
---
--- Keys with no `key` field render as invisible spacers.
function M.new(arg)
  local action = {
    mods = arg.mods or {},
    key = arg.key,
    handler = arg.handler or function() end,
    description = arg.description or "",
    icon = arg.icon,
  }

  if arg.empty then
    handleEmpty(action, arg)
  elseif arg.application then
    handleApplication(action, arg)
  elseif arg.file then
    handleFile(action, arg)
  elseif arg.submenu then
    handleSubmenu(action, arg)
  end

  return action
end

return M
