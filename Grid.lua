--- === hs_grid_hammer.Grid ===
---
--- Modal grid manager using hs.hotkey.modal for instant key handling.
--- Replaces GridCraft's EventTap-based validation with direct key bindings.
---
--- @module hs_grid_hammer.Grid

local Theme = dofile(hs.spoons.resourcePath("Theme.lua"))
local KeyMap = dofile(hs.spoons.resourcePath("KeyMap.lua"))
local CanvasRenderer = dofile(hs.spoons.resourcePath("CanvasRenderer.lua"))

-- Lazy-loaded modules
local IconLoader = nil

local M = {}
local Grid = {}
Grid.__index = Grid

--------------------------------------------------------------------------------
-- Private helper functions
--------------------------------------------------------------------------------

--- Load IconLoader module lazily (once per session)
local function getIconLoader()
  if IconLoader == nil then
    local ok, loader = pcall(function()
      return dofile(hs.spoons.resourcePath("IconLoader.lua"))
    end)
    IconLoader = ok and loader or false
  end
  return IconLoader or nil
end

--- Assign keyIds to all actions and populate keyMap
--- @param actionTable table 2D array of actions
--- @param keyMap table KeyMap instance to populate
local function initializeActions(actionTable, keyMap)
  for rowIdx, row in ipairs(actionTable) do
    for colIdx, action in ipairs(row) do
      action.keyId = action.keyId or string.format("%dx%d", rowIdx, colIdx)
      if action.key then
        keyMap:add(action.mods or {}, action.key, action)
      end
    end
  end
end

--- Create the modal hotkey
--- @param mods table|nil Modifier keys
--- @param key string|nil Trigger key
--- @return hs.hotkey.modal Modal instance
local function createModal(mods, key)
  if mods and key then
    return hs.hotkey.modal.new(mods, key)
  else
    return hs.hotkey.modal.new()
  end
end

--- Convert submenuTable to Grid object if needed
--- @param action table Action with potential submenuTable
--- @param parentGrid table Parent grid instance
local function ensureSubmenuGrid(action, parentGrid)
  if action.submenuTable and not action.submenu then
    action.submenu = M.new(
      nil,  -- No global trigger for submenus
      nil,
      action.submenuTable,
      action.description or "Submenu",
      parentGrid.config,
      parentGrid.chooserKey
    )
    -- Bind parent's trigger key to close submenu
    if parentGrid.triggerKey then
      action.submenu.modal:bind(
        parentGrid.triggerMods or {},
        parentGrid.triggerKey,
        function() action.submenu:stop() end
      )
    end
  end
end

--- Bind all action keys to the modal
--- @param grid table Grid instance
local function bindActionKeys(grid)
  for _, row in ipairs(grid.actionTable) do
    for _, action in ipairs(row) do
      if action.key then
        ensureSubmenuGrid(action, grid)

        local hasAction = action.handler or action.submenu
        if hasAction then
          grid.modal:bind(action.mods or {}, action.key, function()
            if action.submenu then
              grid:stop()
              hs.timer.doAfter(grid.theme.fadeTime, function()
                action.submenu:start()
              end)
            else
              local keyId = action.keyId
              grid:stop(keyId)
              hs.timer.doAfter(grid.theme.fadeTime, function()
                action.handler()
              end)
            end
          end)
        end
      end
    end
  end
end

--- Bind system keys (escape, trigger toggle, chooser)
--- @param grid table Grid instance
local function bindSystemKeys(grid)
  -- Escape to close
  grid.modal:bind({}, "escape", function()
    grid:stop()
  end)

  -- Trigger key toggles modal off
  if grid.triggerKey then
    grid.modal:bind(grid.triggerMods or {}, grid.triggerKey, function()
      grid:stop()
    end)
  end

  -- Chooser key
  if grid.chooserKey then
    grid.modal:bind({}, grid.chooserKey, function()
      grid:showChooser()
    end)
  end
end

--- Set up modal entered/exited callbacks
--- @param grid table Grid instance
local function setupModalCallbacks(grid)
  function grid.modal:entered()
    grid.isShowing = true

    local showDelay = grid.config.showDelay or 0
    if showDelay > 0 then
      grid.showTimer = hs.timer.doAfter(showDelay, function()
        grid.showTimer = nil
        if grid.isShowing then
          grid:showAndLoadIcons()
        end
      end)
    else
      grid:showAndLoadIcons()
    end
  end

  function grid.modal:exited()
    grid.isShowing = false
    local delay = grid.config.animationDelay or 0.05
    hs.timer.doAfter(delay, function()
      if not grid.isShowing then
        grid.renderer:hide()
      end
    end)
  end
end

--------------------------------------------------------------------------------
-- Grid instance methods
--------------------------------------------------------------------------------

--- Start the grid (enter modal and show canvas)
function Grid:start()
  self.modal:enter()
end

--- Stop the grid (exit modal and hide canvas)
--- @param selectedKeyId string|nil Optional keyId that was selected
function Grid:stop(selectedKeyId)
  if self.showTimer then
    self.showTimer:stop()
    self.showTimer = nil
  end
  if selectedKeyId then
    self.renderer:highlightCell(selectedKeyId)
  end
  self.modal:exit()
end

--- Show renderer and load icons asynchronously
function Grid:showAndLoadIcons()
  self.renderer:show()

  local loader = getIconLoader()
  if loader then
    self:loadIconsAsync(loader)
  end
end

--- Load icons asynchronously after grid is shown
--- @param loader table The IconLoader module
function Grid:loadIconsAsync(loader)
  for _, row in ipairs(self.actionTable) do
    for _, action in ipairs(row) do
      if action.key and not action.icon then
        local iconPath = action.applicationPath or action.file
        if iconPath then
          local keyId = action.keyId
          loader.loadAsync(iconPath, function(image)
            if image and self.isShowing then
              self.renderer:updateIcon(keyId, image)
            end
          end)
        end
      end
    end
  end
end

--- Show the chooser interface
function Grid:showChooser()
  self:stop()

  local ok, Chooser = pcall(function()
    return dofile(hs.spoons.resourcePath("Chooser.lua"))
  end)

  if not ok then
    hs.alert.show("Chooser module not available")
    return
  end

  local choices, actions = Chooser.fromActionTable(self.actionTable)

  if #choices == 0 then
    hs.alert.show("No actions available")
    return
  end

  local chooser = hs.chooser.new(function(choice)
    if choice then
      local action = actions[choice.uuid]
      if action and action.handler then
        action.handler()
      end
    end
  end)

  chooser:choices(choices)
  chooser:width(30)
  chooser:show()
end

--- Set configuration and rebuild renderer
--- @param newConfig table New configuration to merge
function Grid:setConfiguration(newConfig)
  for k, v in pairs(newConfig) do
    self.config[k] = v
  end
  self.theme = Theme.new(self.config.theme)
  self.renderer = CanvasRenderer.new(self.actionTable, self.theme)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Create a new grid modal.
---
--- @param mods table|nil Modifier keys for trigger hotkey (e.g., {"cmd", "ctrl"})
--- @param key string|nil Key to trigger the modal (e.g., "t")
--- @param actionTable table 2D array of actions (rows of columns)
--- @param title string|nil Optional title for the grid
--- @param config table|nil Optional configuration
--- @param chooserKey string|nil Optional key to open chooser interface
--- @return table Grid instance
function M.new(mods, key, actionTable, title, config, chooserKey)
  local grid = setmetatable({}, Grid)

  -- Core properties
  grid.title = title or "hs_grid_hammer"
  grid.config = config or {}
  grid.theme = Theme.new(grid.config.theme)
  grid.actionTable = actionTable
  grid.triggerMods = mods
  grid.triggerKey = key
  grid.chooserKey = chooserKey

  -- State
  grid.isShowing = false
  grid.showTimer = nil

  -- Build components
  grid.keyMap = KeyMap.new()
  initializeActions(actionTable, grid.keyMap)
  grid.modal = createModal(mods, key)
  grid.renderer = CanvasRenderer.new(actionTable, grid.theme)

  -- Bind keys and callbacks
  bindSystemKeys(grid)
  bindActionKeys(grid)
  setupModalCallbacks(grid)

  return grid
end

return M
