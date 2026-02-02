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

-- Diagnostic counter
local showCount = 0

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
  end
  return hs.hotkey.modal.new()
end

--- Create a Grid object from an action's submenuTable if present.
--- Mutates action.submenu. No-op if submenu already exists or no submenuTable.
--- @param action table Action to process
--- @param parentGrid table Parent grid (for inheriting config)
local function createSubmenuFromTable(action, parentGrid)
  if not action.submenuTable then return end
  if action.submenu then return end

  action.submenu = M.new(
    nil, nil,  -- No global trigger for submenus
    action.submenuTable,
    action.description or "Submenu",
    parentGrid.config,
    parentGrid.chooserKey
  )

  -- Allow parent's trigger key to close submenu
  if parentGrid.triggerKey then
    action.submenu.modal:bind(
      parentGrid.triggerMods or {},
      parentGrid.triggerKey,
      function() action.submenu:stop() end
    )
  end
end

--- Create the key handler for an action
--- @param grid table Grid instance
--- @param action table Action being bound
--- @return function Handler function for modal:bind
local function createActionHandler(grid, action)
  return function()
    local selectedKeyId = action.submenu and nil or action.keyId
    grid:stop(selectedKeyId)

    hs.timer.doAfter(grid.theme.fadeTime, function()
      if action.submenu then
        action.submenu:start()
      else
        action.handler()
      end
    end)
  end
end

--- Iterate over all actions in actionTable, calling fn for each
--- @param actionTable table 2D array of actions
--- @param fn function Called with (action, rowIdx, colIdx)
local function forEachAction(actionTable, fn)
  for rowIdx, row in ipairs(actionTable) do
    for colIdx, action in ipairs(row) do
      fn(action, rowIdx, colIdx)
    end
  end
end

--- Bind all action keys to the modal
--- @param grid table Grid instance
local function bindActionKeys(grid)
  forEachAction(grid.actionTable, function(action)
    if not action.key then return end

    createSubmenuFromTable(action, grid)

    local hasAction = action.handler or action.submenu
    if not hasAction then return end

    grid.modal:bind(
      action.mods or {},
      action.key,
      createActionHandler(grid, action)
    )
  end)
end

--- Bind system keys (escape, trigger toggle, chooser)
--- @param grid table Grid instance
local function bindSystemKeys(grid)
  grid.modal:bind({}, "escape", function() grid:stop() end)

  if grid.triggerKey then
    grid.modal:bind(grid.triggerMods or {}, grid.triggerKey, function()
      grid:stop()
    end)
  end

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
    if showDelay <= 0 then
      grid:showAndLoadIcons()
      return
    end

    grid.showTimer = hs.timer.doAfter(showDelay, function()
      grid.showTimer = nil
      if grid.isShowing then
        grid:showAndLoadIcons()
      end
    end)
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
  showCount = showCount + 1
  local startTime = hs.timer.absoluteTime()

  self.renderer:show()

  local showTime = hs.timer.absoluteTime()
  local showMs = (showTime - startTime) / 1000000

  local loader = getIconLoader()
  if loader then
    self:loadIconsAsync(loader)
  end

  local totalMs = (hs.timer.absoluteTime() - startTime) / 1000000
  local memKB = collectgarbage("count")
  print(string.format("[hs_grid_hammer] #%d show=%.1fms total=%.1fms mem=%.0fKB", showCount, showMs, totalMs, memKB))

  -- Periodic GC to prevent memory growth
  if showCount % 10 == 0 then
    collectgarbage("collect")
  end
end

--- Load icons asynchronously after grid is shown
--- @param loader table The IconLoader module
function Grid:loadIconsAsync(loader)
  forEachAction(self.actionTable, function(action)
    if not action.key then return end
    if action.icon then return end
    if action.iconLoaded then return end  -- Already loaded in previous show

    local iconPath = action.applicationPath or action.file
    if not iconPath then return end

    local keyId = action.keyId
    local grid = self
    action.iconLoaded = true  -- Mark as loaded (even if loading fails)
    loader.loadAsync(iconPath, function(image)
      if image and grid.isShowing then
        action.icon = image  -- Store for future reference
        grid.renderer:updateIcon(keyId, image)
      end
    end)
  end)
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
    if not choice then return end
    local action = actions[choice.uuid]
    if action and action.handler then
      action.handler()
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
