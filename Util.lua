--- === hs_grid_hammer.Util ===
---
--- Generic utility functions

local M = {}


--- hs_grid_hammer.Util.findApplicationPath(string) -> string or nil
--- Function
--- Find an application path by its name
---
--- Parameters:
---  * appName - The name of the application to find
---
--- Returns:
---  * The full path to the application, or nil if not found
M.findApplicationPath = function(appName)
  -- If the app name is a fully qualified path, return it directly
  if appName:lower():match("^/") then
    return appName
  end

  -- If the app name doesn't end with ".app", append it
  if not appName:lower():match("%.app$") then
    appName = appName .. ".app"
  end

  -- Check if the app name is a special case
  local specials = {
    ["Finder.app"] = "/System/Library/CoreServices/Finder.app",
  }
  if specials[appName] then
    return specials[appName]
  end

  -- Find the app in common application directories
  local appDirs = {
    "/Applications",
    "/Applications/Utilities",
    "/System/Applications",
    "/System/Applications/Utilities",
    "/System/Library/CoreServices",
    os.getenv("HOME") .. "/Applications",
    os.getenv("HOME") .. "/Applications/Chrome Apps.localized",
  }
  for _, dir in ipairs(appDirs) do
    local appPath = dir .. "/" .. appName
    if hs.fs.attributes(appPath) then
      return appPath
    end
  end

  -- If the app is not found, return nil
  return nil
end


--- hs_grid_hammer.Util.getBasename(string) -> string
--- Function
--- Get the last component of a file path, or "/" if the path is the root directory
---
--- Parameters:
---  * path - The file path to get the basename from
---
--- Returns:
---  * The basename of the path
M.getBasename = function(path)
  if not path or path == "" then
    return ""
  elseif path == "/" then
    return "/"
  end
  -- Remove trailing slashes
  path = path:gsub("[/\\]+$", "")
  return path:match("([^/\\]+)$") or "/"
end


--- hs_grid_hammer.Util.formatModifiers(table, string) -> string
--- Function
--- Formats modifier keys for display
---
--- Parameters:
---  * mods - A table of modifier keys like {"ctrl", "shift"}
---  * format - (optional) "abbreviated" for "c-s-" format, "full" for "Ctrl+Shift+" format,
---             "symbols" for "⌃⇧" format. Defaults to "abbreviated"
---
--- Returns:
---  * A string with formatted modifiers, or an empty string if no modifiers
---
--- Notes:
---  * Modifiers are ordered in macOS standard: Cmd, Ctrl, Alt, Shift, Fn
M.formatModifiers = function(mods, format)
  format = format or "abbreviated"

  if not mods or (type(mods) == "string" and mods == "") or (type(mods) == "table" and #mods == 0) then
    return ""
  end

  -- Define the modifier maps
  local abbreviatedMap = {
    cmd = "m",
    ctrl = "c",
    alt = "a",
    shift = "s",
    fn = "f"
  }

  local fullMap = {
    cmd = "Cmd",
    ctrl = "Ctrl",
    alt = "Alt",
    shift = "Shift",
    fn = "Fn"
  }

  local symbolMap = {
    cmd = "⌘",
    ctrl = "⌃",
    alt = "⌥",
    shift = "⇧",
    fn = "fn"
  }

  local modMap, separator
  if format == "full" then
    modMap = fullMap
    separator = "+"
  elseif format == "symbols" then
    modMap = symbolMap
    separator = ""
  else
    modMap = abbreviatedMap
    separator = "-"
  end

  -- Define the desired order of modifiers (macOS standard)
  local modOrder = { "cmd", "ctrl", "alt", "shift", "fn" }

  -- Normalize mods to a table if it's a string
  local modList = {}
  if type(mods) == "string" then
    for mod in string.gmatch(mods, "%S+") do
      table.insert(modList, string.lower(mod))
    end
  elseif type(mods) == "table" then
    for _, mod in ipairs(mods) do
      table.insert(modList, string.lower(mod))
    end
  end

  -- Create a set of modifiers for quick lookup
  local modSet = {}
  for _, mod in ipairs(modList) do
    modSet[mod] = true
  end

  -- Build the modifier string in the correct order
  local result = ""
  for _, mod in ipairs(modOrder) do
    if modSet[mod] then
      result = result .. modMap[mod] .. separator
    end
  end

  return result
end


--- hs_grid_hammer.Util.fileContents(string) -> string or nil
--- Function
--- Get the contents of a file at a given path
---
--- Parameters:
---  * fullPath - The full path to the file
---
--- Returns:
---  * The file contents as a string, or nil if the file cannot be read
M.fileContents = function(fullPath)
  local file = io.open(fullPath, "r")
  if file then
    local contents = file:read("*a")
    file:close()
    return contents
  else
    return nil
  end
end


return M
