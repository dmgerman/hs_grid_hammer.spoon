--- === hs_grid_hammer.Grid ===
---
--- Modal grid manager using hs.hotkey.modal for instant key handling.
--- Replaces GridCraft's EventTap-based validation with direct key bindings.
---
--- @module hs_grid_hammer.Grid

local Theme = dofile(hs.spoons.resourcePath("Theme.lua"))
local CanvasRenderer = dofile(hs.spoons.resourcePath("CanvasRenderer.lua"))

local M = {}
local Grid = {}
Grid.__index = Grid

-- Instance registry for cleanup on reload
local instances = {}

--------------------------------------------------------------------------------
-- Private helper functions
--------------------------------------------------------------------------------

--- Assign keyIds to all actions
--- @param actionTable table 2D array of actions
local function initializeActions(actionTable)
  for rowIdx, row in ipairs(actionTable) do
    for colIdx, action in ipairs(row) do
      action.keyId = action.keyId or string.format("%dx%d", rowIdx, colIdx)
    end
  end
end

--- Create the modal hotkey
--- @param mods table|nil Modifier keys
--- @param key string|nil Trigger key
--- @param description string|nil Description for the hotkey
--- @return hs.hotkey.modal Modal instance
local function createModal(mods, key, description)
  if mods and key then
    local desc = description and (description .. " [Grid]") or nil
    return hs.hotkey.modal.new(mods, key, desc)
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
    grid:stop()

    if action.submenu then
      action.submenu:start()
    else
      action.handler()
    end
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

    local description = (action.description or "Unknown") .. " [Grid]"

    grid.modal:bind(
      action.mods or {},
      action.key,
      description,
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
      grid.renderer:show()
      return
    end

    grid.showTimer = hs.timer.doAfter(showDelay, function()
      grid.showTimer = nil
      if grid.isShowing then
        grid.renderer:show()
      end
    end)
  end

  function grid.modal:exited()
    grid.isShowing = false
    grid.renderer:hide()
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
function Grid:stop()
  if self.showTimer then
    self.showTimer:stop()
    self.showTimer = nil
  end
  self.modal:exit()
end

--- Show the chooser interface
function Grid:showChooser()
  self:stop()

  local Chooser = dofile(hs.spoons.resourcePath("Chooser.lua"))
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

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Clean up all grid instances (call before reload or re-creation).
--- Stops all modals and force-hides all renderers.
function M.cleanup()
  print(string.format("[hs_grid_hammer] cleanup: destroying %d grid instances", #instances))
  for _, grid in ipairs(instances) do
    pcall(function()
      if grid.showTimer then
        grid.showTimer:stop()
        grid.showTimer = nil
      end
      grid.isShowing = false
      grid.modal:exit()
      grid.renderer:destroy()
    end)
  end
  instances = {}
end

--- Return all registered grid instances (for debugging).
--- @return table Array of Grid instances
function M.instances()
  return instances
end

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
  initializeActions(actionTable)
  grid.modal = createModal(mods, key, title)
  grid.renderer = CanvasRenderer.new(actionTable, grid.theme)

  -- Bind keys and callbacks
  bindSystemKeys(grid)
  bindActionKeys(grid)
  setupModalCallbacks(grid)

  -- Register for cleanup
  table.insert(instances, grid)

  return grid
end

return M
