--- === hs_grid_hammer.CanvasRenderer ===
---
--- Native canvas rendering for the grid.
--- Replaces GridCraft's WebView with hs.canvas for 10-100x faster rendering.

local function _require(name)
  _hs_grid_hammer_modules = _hs_grid_hammer_modules or {}
  if not _hs_grid_hammer_modules[name] then
    _hs_grid_hammer_modules[name] = dofile(hs.spoons.resourcePath(name))
  end
  return _hs_grid_hammer_modules[name]
end

local Theme = _require("Theme.lua")
local Color = _require("Color.lua")

local M = {}
M.__index = M

--- Modifier key symbols for hotkey labels
local MOD_SYMBOLS = {cmd = "⌘", ctrl = "⌃", alt = "⌥", shift = "⇧", fn = "fn"}

--------------------------------------------------------------------------------
-- Private helper functions
--------------------------------------------------------------------------------

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
    fillColor = Color.withAlpha(theme.cellBackground, alpha),
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
    strokeColor = Color.withAlpha(theme.cellBorder, alpha),
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
    for _, mod in ipairs(mods) do
      hotkeyText = hotkeyText .. (MOD_SYMBOLS[string.lower(mod)] or mod)
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
      fillColor = Color.withAlpha(t.emptyCellIconColor, alpha),
      roundedRectRadii = {xRadius = t.iconCornerRadius, yRadius = t.iconCornerRadius},
    })
  else
    local text = action.description or action.key or "?"
    local bgEl, letterEl = createPlaceholderIcon(keyId, t, iconX, iconY, text, alpha)
    table.insert(elements, bgEl)
    cellIndexes.iconLetterIndex = #elements + 1
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
      if cellIndexes.iconLetterIndex then
        cellIndexes.iconLetterIndex = cellIndexes.iconLetterIndex + offset
      end
      if cellIndexes.hotkeyIndex then
        cellIndexes.hotkeyIndex = cellIndexes.hotkeyIndex + offset
      end
      if cellIndexes.descIndex then
        cellIndexes.descIndex = cellIndexes.descIndex + offset
      end

      -- Store cell position for updateIcon
      local cellX, cellY = cellPosition(self.theme, rowIdx, colIdx)
      cellIndexes.cellX = cellX
      cellIndexes.cellY = cellY

      for _, el in ipairs(cellElements) do
        table.insert(elements, el)
      end

      self.cellElements[keyId] = cellIndexes

      ::continue::
    end
  end

  return elements
end

--- Build and show the canvas.
--- On first call, creates canvas and builds all elements.
--- On subsequent calls, repositions (screen may change) and shows.
function M:show()
  if self.canvas then
    -- Reposition for current screen and show
    local x, y = self:centeredPosition()
    local width, height = self:canvasSize()
    self.canvas:frame({x = x, y = y, w = width, h = height})
    self.canvas:show(self.theme.fadeTime)
    return
  end

  local width, height = self:canvasSize()
  local x, y = self:centeredPosition()

  self.canvas = hs.canvas.new({x = x, y = y, w = width, h = height})
  self.canvas:level("overlay")
  self.canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)

  local elements = self:buildElements()
  self.canvas:replaceElements(elements)
  self.canvas:show(self.theme.fadeTime)
end

--- Hide the canvas (keeps it alive for reuse)
function M:hide()
  if self.canvas then
    self.canvas:hide(self.theme.fadeTime)
  end
end

--- Destroy the canvas completely (for reload/reconfiguration)
function M:destroy()
  if self.canvas then
    self.canvas:delete()
    self.canvas = nil
    self.cellElements = {}
  end
end

--- Update a cell's icon image (in-place replacement, no remove/insert)
--- @param keyId string The cell's key ID
--- @param image hs.image The new icon image
function M:updateIcon(keyId, image)
  if not self.canvas then return end

  local indexes = self.cellElements[keyId]
  if not indexes then return end

  -- Replace the placeholder bg with the real icon image in-place
  local t = self.theme
  local iconX, iconY = iconPosition(t, indexes.cellX, indexes.cellY)
  self.canvas[indexes.iconIndex] = createIconImage(keyId, t, iconX, iconY, image, 1.0)

  -- Hide the letter element by setting alpha to 0
  if indexes.iconLetterIndex then
    self.canvas:elementAttribute(indexes.iconLetterIndex, "textColor", {white = 1.0, alpha = 0})
  end
end

return M
