--- === hs_grid_hammer ===
---
--- High-performance modal menu system using native canvas rendering.
---
--- ```lua
--- local gh = hs.loadSpoon("hs_grid_hammer")
---
--- local grid = gh.Grid.new({"cmd", "ctrl"}, "t", {
---   {
---     gh.Action.new({key = "e", application = "Terminal"}),
---     gh.Action.new({key = "s", application = "Safari"}),
---   },
---   {
---     gh.Action.new({key = "f", file = "~/Documents"}),
---     gh.Action.new({key = "x", handler = function() hs.alert.show("Hi!") end, description = "Hi"}),
---   },
--- }, "My Grid")
--- ```
---
--- Configuration is an optional 5th argument to Grid.new(); pass a Configuration
--- (or any plain table) with `showDelay` and/or `theme` fields.

local function load(name) return dofile(hs.spoons.resourcePath(name)) end

local M = {
  name = "hs_grid_hammer",
  version = "0.2.0",
  author = "Daniel German <dmg@turingmachine.org> (based on GridCraft by Micah R Ledbetter)",
  license = "MIT",
  homepage = "https://github.com/dmg/hs_grid_hammer",
}

M.Grid = load("Grid.lua")
M.Action = load("Action.lua")
M.Configuration = load("Configuration.lua")
M.Theme = load("Theme.lua")
M.Icon = load("Icon.lua")

function M:init() return self end
function M:start() return self end
function M:stop() return self end

return M
