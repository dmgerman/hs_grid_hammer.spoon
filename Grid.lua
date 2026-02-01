--- === hs_grid_hammer.Grid ===
---
--- Modal grid manager using hs.hotkey.modal for instant key handling.
--- Replaces GridCraft's EventTap-based validation with direct key bindings.

local Theme = dofile(hs.spoons.resourcePath("Theme.lua"))
local KeyMap = dofile(hs.spoons.resourcePath("KeyMap.lua"))
local CanvasRenderer = dofile(hs.spoons.resourcePath("CanvasRenderer.lua"))

local M = {}

--- Create a new grid modal
---
--- @param mods table Modifier keys for trigger hotkey (e.g., {"cmd", "ctrl"})
--- @param key string Key to trigger the modal (e.g., "t")
--- @param actionTable table 2D array of actions (rows of columns)
--- @param title string Optional title for the grid
--- @param config table Optional configuration
--- @param chooserKey string Optional key to open chooser interface
--- @return table Grid instance
function M.new(mods, key, actionTable, title, config, chooserKey)
  local grid = {}

  grid.title = title or "hs_grid_hammer"
  grid.config = config or {}
  grid.theme = Theme.new(grid.config.theme)
  grid.actionTable = actionTable
  grid.triggerMods = mods
  grid.triggerKey = key
  grid.chooserKey = chooserKey

  -- Build KeyMap for O(1) lookup
  grid.keyMap = KeyMap.new()

  -- Assign keyId to each action and populate keyMap
  for rowIdx, row in ipairs(actionTable) do
    for colIdx, action in ipairs(row) do
      action.keyId = action.keyId or string.format("%dx%d", rowIdx, colIdx)
      if action.key then
        grid.keyMap:add(action.mods or {}, action.key, action)
      end
    end
  end

  -- Create the modal hotkey
  if mods and key then
    grid.modal = hs.hotkey.modal.new(mods, key)
  else
    -- No global trigger - modal must be started manually
    grid.modal = hs.hotkey.modal.new()
  end

  -- Create renderer (but don't show yet)
  grid.renderer = CanvasRenderer.new(actionTable, grid.theme)

  -- Track if we're currently showing
  grid.isShowing = false

  -- Timer for delayed show (cancelled if user acts before delay)
  grid.showTimer = nil

  --- Start the grid (enter modal and show canvas)
  function grid:start()
    self.modal:enter()
  end

  --- Stop the grid (exit modal and hide canvas)
  --- @param selectedKeyId string Optional keyId that was selected
  function grid:stop(selectedKeyId)
    -- Cancel pending show timer if exists
    if self.showTimer then
      self.showTimer:stop()
      self.showTimer = nil
    end
    if selectedKeyId then
      self.renderer:highlightCell(selectedKeyId)
    end
    self.modal:exit()
  end

  --- Modal entered callback - show the canvas (with optional delay)
  function grid.modal:entered()
    grid.isShowing = true

    local showDelay = grid.config.showDelay or 0
    if showDelay > 0 then
      -- Delayed show - user can act before menu appears
      grid.showTimer = hs.timer.doAfter(showDelay, function()
        grid.showTimer = nil
        if grid.isShowing then
          grid.renderer:show()
          -- Load icons after show
          local ok, IconLoader = pcall(function()
            return dofile(hs.spoons.resourcePath("IconLoader.lua"))
          end)
          if ok and IconLoader then
            grid:loadIconsAsync(IconLoader)
          end
        end
      end)
    else
      -- Immediate show
      grid.renderer:show()

      -- Load icons asynchronously if IconLoader is available
      local ok, IconLoader = pcall(function()
        return dofile(hs.spoons.resourcePath("IconLoader.lua"))
      end)
      if ok and IconLoader then
        grid:loadIconsAsync(IconLoader)
      end
    end
  end

  --- Modal exited callback - hide the canvas
  function grid.modal:exited()
    grid.isShowing = false
    -- Small delay to allow any selection highlight to show
    local delay = grid.config.animationDelay or 0.05
    hs.timer.doAfter(delay, function()
      if not grid.isShowing then
        grid.renderer:hide()
      end
    end)
  end

  -- Bind escape to close
  grid.modal:bind({}, "escape", function()
    grid:stop()
  end)

  -- Bind trigger key to close (if provided)
  if key then
    grid.modal:bind(mods or {}, key, function()
      grid:stop()
    end)
  end

  -- Bind chooser key (if provided)
  if chooserKey then
    grid.modal:bind({}, chooserKey, function()
      grid:showChooser()
    end)
  end

  -- Bind all action keys
  for _, row in ipairs(actionTable) do
    for _, action in ipairs(row) do
      if action.key then
        -- Convert submenuTable to Grid object if needed
        if action.submenuTable and not action.submenu then
          action.submenu = M.new(
            nil,  -- No global trigger for submenus
            nil,
            action.submenuTable,
            action.description or "Submenu",
            grid.config,
            grid.chooserKey
          )
          -- Bind parent's trigger key to close submenu (if parent has trigger)
          if grid.triggerKey then
            action.submenu.modal:bind(grid.triggerMods or {}, grid.triggerKey, function()
              action.submenu:stop()
            end)
          end
        end

        -- Bind the key
        local hasAction = action.handler or action.submenu
        if hasAction then
          grid.modal:bind(action.mods or {}, action.key, function()
            -- Handle submenu
            if action.submenu then
              grid:stop()
              hs.timer.doAfter(grid.theme.fadeTime, function()
                action.submenu:start()
              end)
            else
              -- Execute handler and close
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

  --- Load icons asynchronously after grid is shown
  --- @param IconLoader table The IconLoader module
  function grid:loadIconsAsync(IconLoader)
    for _, row in ipairs(self.actionTable) do
      for _, action in ipairs(row) do
        if action.key and not action.icon then
          -- Determine what icon to load
          local iconPath = nil
          if action.application then
            iconPath = action.applicationPath
          elseif action.file then
            iconPath = action.file
          end

          if iconPath then
            local keyId = action.keyId
            IconLoader.loadAsync(iconPath, function(image)
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
  function grid:showChooser()
    self:stop()

    -- Lazy load Chooser module
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
  function grid:setConfiguration(newConfig)
    for k, v in pairs(newConfig) do
      self.config[k] = v
    end
    self.theme = Theme.new(self.config.theme)
    self.renderer = CanvasRenderer.new(self.actionTable, self.theme)
  end

  return grid
end

return M
