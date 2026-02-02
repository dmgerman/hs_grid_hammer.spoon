--- === hs_grid_hammer.CanvasRenderer ===
---
--- Native canvas rendering for the grid.
--- Replaces GridCraft's WebView with hs.canvas for 10-100x faster rendering.

local Theme = dofile(hs.spoons.resourcePath("Theme.lua"))
local Color = dofile(hs.spoons.resourcePath("Color.lua"))

local M = {}
M.__index = M

-- Track pending canvas deletions for cleanup
local pendingDeletes = {}

--------------------------------------------------------------------------------
-- Private helper functions
--------------------------------------------------------------------------------

--- Apply alpha multiplier to a color
--- @param color table Color with red/green/blue or white
--- @param alpha number Alpha multiplier (0-1)
--- @return table New color with adjusted alpha
local function colorWithAlpha(color, alpha)
  return {
    red = color.red or color.white,
    green = color.green or color.white,
    blue = color.blue or color.white,
    alpha = (color.alpha or 1.0) * alpha,
  }
end

--- Calculate cell position from row/column indices
--- @param theme table Theme settings
--- @param rowIdx number 1-based row index
--- @param colIdx number 1-based column index
--- @return number cellX, number cellY
local function cellPosition(theme, rowIdx, colIdx)
  local cellX = theme.cellSpacing + (colIdx - 1) * (theme.cellWidth + theme.cellSpacing)
  local cellY = theme.cellSpacing + (rowIdx - 1) * (theme.cellHeight + theme.cellSpacing)
  return cellX, cellY
end

--- Calculate icon position within a cell
--- @param theme table Theme settings
--- @param cellX number Cell X position
--- @param cellY number Cell Y position
--- @return number iconX, number iconY
local function iconPosition(theme, cellX, cellY)
  local iconX = cellX + (theme.cellWidth - theme.iconSize) / 2
  local iconY = cellY + theme.iconTopMargin
  return iconX, iconY
end

--- Create cell background element
--- @param keyId string Cell identifier
--- @param theme table Theme settings
--- @param cellX number Cell X position
--- @param cellY number Cell Y position
--- @param alpha number Alpha multiplier
--- @return table Canvas element
local function createCellBackground(keyId, theme, cellX, cellY, alpha)
  return {
    id = keyId .. "_bg",
    type = "rectangle",
    action = "fill",
    frame = {x = cellX, y = cellY, w = theme.cellWidth, h = theme.cellHeight},
    fillColor = colorWithAlpha(theme.cellBackground, alpha),
    roundedRectRadii = {xRadius = theme.cellCornerRadius, yRadius = theme.cellCornerRadius},
  }
end

--- Create cell border element
--- @param keyId string Cell identifier
--- @param theme table Theme settings
--- @param cellX number Cell X position
--- @param cellY number Cell Y position
--- @param alpha number Alpha multiplier
--- @param isDashed boolean Whether to use dashed stroke
--- @return table Canvas element
local function createCellBorder(keyId, theme, cellX, cellY, alpha, isDashed)
  return {
    id = keyId .. "_border",
    type = "rectangle",
    action = "stroke",
    frame = {x = cellX, y = cellY, w = theme.cellWidth, h = theme.cellHeight},
    strokeColor = colorWithAlpha(theme.cellBorder, alpha),
    strokeWidth = theme.cellBorderWidth,
    strokeDashPattern = isDashed and {6, 4} or nil,
    roundedRectRadii = {xRadius = theme.cellCornerRadius, yRadius = theme.cellCornerRadius},
  }
end

--- Create icon image element
--- @param keyId string Cell identifier
--- @param theme table Theme settings
--- @param iconX number Icon X position
--- @param iconY number Icon Y position
--- @param image hs.image Icon image
--- @param alpha number Alpha multiplier
--- @return table Canvas element
local function createIconImage(keyId, theme, iconX, iconY, image, alpha)
  return {
    id = keyId .. "_icon",
    type = "image",
    frame = {x = iconX, y = iconY, w = theme.iconSize, h = theme.iconSize},
    image = image,
    imageAlpha = alpha,
  }
end

--- Create placeholder icon elements (colored rect + letter)
--- @param keyId string Cell identifier
--- @param theme table Theme settings
--- @param iconX number Icon X position
--- @param iconY number Icon Y position
--- @param text string Text for color/letter derivation
--- @param alpha number Alpha multiplier
--- @return table, table Background element, letter element
local function createPlaceholderIcon(keyId, theme, iconX, iconY, text, alpha)
  local size = theme.iconSize
  local offsetY = size * theme.placeholderTextOffsetRatio

  local bgElement = {
    id = keyId .. "_icon_bg",
    type = "rectangle",
    action = "fill",
    frame = {x = iconX, y = iconY, w = size, h = size},
    fillColor = Color.fromString(text),
    roundedRectRadii = {xRadius = theme.iconCornerRadius, yRadius = theme.iconCornerRadius},
    imageAlpha = alpha,
  }

  local letter = string.upper(string.sub(text or "?", 1, 1))
  local letterElement = {
    id = keyId .. "_icon_letter",
    type = "text",
    frame = {x = iconX, y = iconY + offsetY, w = size, h = size - offsetY},
    text = letter,
    textAlignment = "center",
    textColor = {white = 1.0, alpha = alpha},
    textFont = theme.placeholderFont,
    textSize = size * theme.placeholderTextRatio,
  }

  return bgElement, letterElement
end

--- Create hotkey label element
--- @param keyId string Cell identifier
--- @param theme table Theme settings
--- @param cellX number Cell X position
--- @param cellY number Cell Y position
--- @param mods table Modifier keys
--- @param key string Key character
--- @param textColor table Text color
--- @return table Canvas element
local function createHotkeyLabel(keyId, theme, cellX, cellY, mods, key, textColor)
  -- Format hotkey text
  local hotkeyText = ""
  if mods and #mods > 0 then
    local modMap = {cmd = "⌘", ctrl = "⌃", alt = "⌥", shift = "⇧", fn = "fn"}
    for _, mod in ipairs(mods) do
      hotkeyText = hotkeyText .. (modMap[string.lower(mod)] or mod)
    end
  end
  hotkeyText = hotkeyText .. string.upper(key)

  return {
    id = keyId .. "_hotkey",
    type = "text",
    frame = {
      x = cellX + theme.hotkeyInsetX,
      y = cellY + theme.cellHeight - theme.hotkeyFontSize - theme.hotkeyInsetY - 4,
      w = theme.cellWidth / 2,
      h = theme.hotkeyFontSize + 4,
    },
    text = hotkeyText,
    textAlignment = "left",
    textColor = textColor,
    textFont = theme.hotkeyFont,
    textSize = theme.hotkeyFontSize,
  }
end

--- Create description label element
--- @param keyId string Cell identifier
--- @param theme table Theme settings
--- @param cellX number Cell X position
--- @param cellY number Cell Y position
--- @param description string Description text
--- @param textColor table Text color
--- @return table Canvas element
local function createDescriptionLabel(keyId, theme, cellX, cellY, description, textColor)
  return {
    id = keyId .. "_desc",
    type = "text",
    frame = {
      x = cellX + theme.cellWidth / 2,
      y = cellY + theme.cellHeight - theme.descriptionFontSize - theme.descriptionInsetY - 4,
      w = theme.cellWidth / 2 - theme.descriptionInsetX,
      h = theme.descriptionFontSize + 4,
    },
    text = description,
    textAlignment = "right",
    textColor = textColor,
    textFont = theme.descriptionFont,
    textSize = theme.descriptionFontSize,
  }
end

--------------------------------------------------------------------------------
-- CanvasRenderer methods
--------------------------------------------------------------------------------

--- Create a new CanvasRenderer
---
--- @param actionTable table 2D array of actions (rows of columns)
--- @param theme table Optional theme overrides
--- @return table CanvasRenderer instance
function M.new(actionTable, theme)
  local self = setmetatable({}, M)
  self.actionTable = actionTable
  self.theme = theme or Theme.default
  self.canvas = nil
  self.cellElements = {}
  return self
end

--- Calculate grid dimensions from action table
--- @return number rows, number maxCols
function M:gridDimensions()
  local rows = #self.actionTable
  local maxCols = 0
  for _, row in ipairs(self.actionTable) do
    maxCols = math.max(maxCols, #row)
  end
  return rows, maxCols
end

--- Calculate canvas size based on grid dimensions
--- @return number width, number height
function M:canvasSize()
  local rows, cols = self:gridDimensions()
  local t = self.theme
  local width = (cols * t.cellWidth) + ((cols + 1) * t.cellSpacing)
  local height = (rows * t.cellHeight) + ((rows + 1) * t.cellSpacing)
  return width, height
end

--- Get centered position on main screen
--- @return number x, number y
function M:centeredPosition()
  local width, height = self:canvasSize()
  local screen = hs.screen.mainScreen()
  local frame = screen:frame()
  return frame.x + (frame.w - width) / 2,
         frame.y + (frame.h - height) / 2
end

--- Build elements for a single cell
--- @param action table Action data
--- @param rowIdx number Row index
--- @param colIdx number Column index
--- @return table Array of canvas elements for this cell
--- @return table Cell element indexes
function M:buildCellElements(action, rowIdx, colIdx)
  local elements = {}
  local t = self.theme
  local keyId = action.keyId or string.format("%dx%d", rowIdx, colIdx)

  local cellX, cellY = cellPosition(t, rowIdx, colIdx)
  local iconX, iconY = iconPosition(t, cellX, cellY)

  local isEmpty = action.empty == true
  local isNotFound = action.notFound == true
  local alpha = (isEmpty or isNotFound) and t.cellEmptyAlpha or 1.0
  local textColor = (isEmpty or isNotFound) and t.textColorDimmed or t.textColor

  local cellIndexes = {}

  -- Background
  cellIndexes.bgIndex = 1
  table.insert(elements, createCellBackground(keyId, t, cellX, cellY, alpha))

  -- Border
  table.insert(elements, createCellBorder(keyId, t, cellX, cellY, alpha, isEmpty))

  -- Icon
  cellIndexes.iconIndex = #elements + 1
  if action.icon then
    table.insert(elements, createIconImage(keyId, t, iconX, iconY, action.icon, alpha))
  elseif isEmpty then
    -- Empty cells get just a black square, no letter
    table.insert(elements, {
      id = keyId .. "_icon_bg",
      type = "rectangle",
      action = "fill",
      frame = {x = iconX, y = iconY, w = t.iconSize, h = t.iconSize},
      fillColor = colorWithAlpha(t.emptyCellIconColor, alpha),
      roundedRectRadii = {xRadius = t.iconCornerRadius, yRadius = t.iconCornerRadius},
    })
  else
    local text = action.description or action.key or "?"
    local bgEl, letterEl = createPlaceholderIcon(keyId, t, iconX, iconY, text, alpha)
    table.insert(elements, bgEl)
    table.insert(elements, letterEl)
  end

  -- Hotkey label
  if action.key then
    cellIndexes.hotkeyIndex = #elements + 1
    table.insert(elements, createHotkeyLabel(keyId, t, cellX, cellY, action.mods, action.key, textColor))
  end

  -- Description label
  if action.description and action.description ~= "" then
    cellIndexes.descIndex = #elements + 1
    table.insert(elements, createDescriptionLabel(keyId, t, cellX, cellY, action.description, textColor))
  end

  return elements, cellIndexes, keyId
end

--- Build canvas elements array
--- @return table Array of canvas element definitions
function M:buildElements()
  local elements = {}
  local t = self.theme
  local width, height = self:canvasSize()

  -- Background
  table.insert(elements, {
    type = "rectangle",
    action = "fill",
    frame = {x = 0, y = 0, w = width, h = height},
    fillColor = t.backgroundColor,
    roundedRectRadii = {xRadius = t.gridCornerRadius, yRadius = t.gridCornerRadius},
  })

  -- Cells
  for rowIdx, row in ipairs(self.actionTable) do
    for colIdx, action in ipairs(row) do
      if not action.key and not action.description then
        goto continue
      end

      local cellElements, cellIndexes, keyId = self:buildCellElements(action, rowIdx, colIdx)

      -- Adjust indexes to account for elements already in array
      local offset = #elements
      cellIndexes.bgIndex = cellIndexes.bgIndex + offset
      cellIndexes.iconIndex = cellIndexes.iconIndex + offset
      if cellIndexes.hotkeyIndex then
        cellIndexes.hotkeyIndex = cellIndexes.hotkeyIndex + offset
      end
      if cellIndexes.descIndex then
        cellIndexes.descIndex = cellIndexes.descIndex + offset
      end

      for _, el in ipairs(cellElements) do
        table.insert(elements, el)
      end

      self.cellElements[keyId] = cellIndexes

      ::continue::
    end
  end

  return elements
end

--- Build and show the canvas
function M:show()
  local t0 = hs.timer.absoluteTime()

  -- Clean up any pending canvases from rapid show/hide
  for _, c in ipairs(pendingDeletes) do
    pcall(function() c:delete() end)
  end
  pendingDeletes = {}

  if self.canvas then
    self.canvas:delete()
  end

  local width, height = self:canvasSize()
  local x, y = self:centeredPosition()

  self.canvas = hs.canvas.new({x = x, y = y, w = width, h = height})
  self.canvas:level("overlay")
  self.canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)

  local t1 = hs.timer.absoluteTime()
  local elements = self:buildElements()
  local t2 = hs.timer.absoluteTime()

  -- Batch insert all elements at once (faster than individual inserts)
  self.canvas:replaceElements(elements)

  local t3 = hs.timer.absoluteTime()
  self.canvas:show(self.theme.fadeTime)

  local setupMs = (t1 - t0) / 1000000
  local buildMs = (t2 - t1) / 1000000
  local insertMs = (t3 - t2) / 1000000
  print(string.format("[CanvasRenderer] setup=%.1fms build=%.1fms insert=%.1fms pending=%d",
    setupMs, buildMs, insertMs, #pendingDeletes))
end

--- Hide and delete the canvas
function M:hide()
  if self.canvas then
    local canvasToDelete = self.canvas
    self.canvas = nil
    -- Track pending delete
    table.insert(pendingDeletes, canvasToDelete)
    -- Delete after fade completes to ensure proper cleanup
    hs.timer.doAfter(self.theme.fadeTime + 0.05, function()
      canvasToDelete:delete()
      -- Remove from pending list
      for i, c in ipairs(pendingDeletes) do
        if c == canvasToDelete then
          table.remove(pendingDeletes, i)
          break
        end
      end
    end)
    canvasToDelete:hide(self.theme.fadeTime)
  end
end

--- Update a cell's icon image
--- @param keyId string The cell's key ID
--- @param image hs.image The new icon image
function M:updateIcon(keyId, image)
  if not self.canvas then return end

  local indexes = self.cellElements[keyId]
  if not indexes then return end

  -- Remove placeholder elements
  local iconBgId = keyId .. "_icon_bg"
  local iconLetterId = keyId .. "_icon_letter"

  for i = #self.canvas, 1, -1 do
    local el = self.canvas[i]
    if el and (el.id == iconBgId or el.id == iconLetterId) then
      self.canvas:removeElement(i)
    end
  end

  -- Find cell position and insert icon
  local t = self.theme
  for rowIdx, row in ipairs(self.actionTable) do
    for colIdx, action in ipairs(row) do
      local cellKeyId = action.keyId or string.format("%dx%d", rowIdx, colIdx)
      if cellKeyId == keyId then
        local cellX, cellY = cellPosition(t, rowIdx, colIdx)
        local iconX, iconY = iconPosition(t, cellX, cellY)
        self.canvas:insertElement(createIconImage(keyId, t, iconX, iconY, image, 1.0))
        return
      end
    end
  end
end

--- Highlight a cell (for selection feedback)
--- @param keyId string The cell's key ID
function M:highlightCell(keyId)
  -- No-op for API compatibility
end

--- Generate a deterministic placeholder color from a string
--- @param str string Input string
--- @return table Color table
function M:placeholderColor(str)
  return Color.fromString(str)
end

--- Get first letter of a string (uppercase)
--- @param str string Input string
--- @return string First letter uppercase
function M:firstLetter(str)
  if not str or str == "" then return "?" end
  return string.upper(string.sub(str, 1, 1))
end

--- Format hotkey for display
--- @param mods table Modifier keys
--- @param key string The key
--- @return string Formatted hotkey
function M:formatHotkey(mods, key)
  local result = ""
  if mods and #mods > 0 then
    local modMap = {cmd = "⌘", ctrl = "⌃", alt = "⌥", shift = "⇧", fn = "fn"}
    for _, mod in ipairs(mods) do
      result = result .. (modMap[string.lower(mod)] or mod)
    end
  end
  return result .. string.upper(key)
end

return M
