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


return M
